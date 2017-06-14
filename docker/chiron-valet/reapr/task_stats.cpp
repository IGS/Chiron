#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <map>
#include <string>
#include <utility>
#include <algorithm>
#include <iomanip>
#include <list>

#include "fasta.h"
#include "trianglePlot.h"
#include "coveragePlot.h"
#include "histogram.h"
#include "utils.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"
#include "tabix/tabix.hpp"

using namespace BamTools;
using namespace std;

const string ERROR_PREFIX = "[REAPR stats] ";


struct Region
{
    string id;
    unsigned long start;
    unsigned long end;
};


struct CmdLineOptions
{
    unsigned int binWidth;
    unsigned long minInsert; // cutoff for outer frag size to count as proper pair
    unsigned long maxInsert; // cutoff for outer frag size to count as proper pair
    uint16_t minMapQuality;  // ignore reads mapped with quality less than this
    vector<Region> regions;
    string bamInfile;
    string gapsInfile;
    string outprefix;
    string perfectFile;
    string refGCfile;
    string gc2covFile;
    string statsInfile; // insert.stats.txt made by preprocess
    unsigned long printPlotsSkip;
    string printPlotsChr;
    unsigned long printPlotsStart;
    unsigned long printPlotsEnd;
    unsigned long plotCount;
    string rangeID;
    unsigned long aveFragmentLength;
    float innerAveFragCov;   // mean coverage of inner fragments. Used to normalize fragment coverage
    unsigned long rangeStart;
    unsigned long rangeEnd;
    unsigned long maxReadLength; // for allocating memory
    ofstream plot_ofs;
    unsigned long areaSkip; // calculate triangle error every n^th base. This is the skip
    unsigned long samples; // when simulating triangle error, use this many iterations
    unsigned long maxOuterFragCov; // only used when simulating the triangle error
};


struct Stats
{
    TrianglePlot innerTriplot;
    TrianglePlot outerTriplot;
    CoveragePlot covProper;
    CoveragePlot covOrphan;
    CoveragePlot covBadInsert;
    CoveragePlot covWrongOrient;
    CoveragePlot covProperRev;
    CoveragePlot covOrphanRev;
    CoveragePlot covBadInsertRev;
    CoveragePlot covWrongOrientRev;
    CoveragePlot softClipFwdLeft;
    CoveragePlot softClipRevLeft;
    CoveragePlot softClipFwdRight;
    CoveragePlot softClipRevRight;
    vector<unsigned long> perfectCov;
    Histogram globalReadCov;
    Histogram globalFragmentCov;
    Histogram globalFragmentLength;
    Histogram globalFCDerror;
    Histogram clipProportion;
    vector<unsigned int> refGC;
    vector<float> gc2cov;
    double lastTriArea;

    // in sorted BAM file, the reads are in order, which means the fragments, where
    // we include the reads as part of the fragments, are ordered by start position.
    // But they are not in order if we don't include the reads, since reads could
    // be of different lengths or clipped. Use a multiset so that fragments are automatically
    // kept in order
    multiset<pair<unsigned long, unsigned long> > outerFragments;  // fragment positions, including reads
    multiset<pair<unsigned long, unsigned long> > innerFragments;  // fragment positions, not including reads
};



// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops);

// Fills vector with perfect mapping coverage from file.
// File expected to be one number (= coverage) per line
void getPerfectMapping(Tabix* ti, string& refname,  vector<unsigned long>& v_in, unsigned long refLength);

// Prints all stats up to (not including) the given base to os.
// Updates values in stats accoringly.
void printStats(CmdLineOptions& ops, string& refname, unsigned long pos, Stats& stats, map<string, list<pair<unsigned long, unsigned long> > >& gaps);

// Loads the contents of file into vector.  The file is expected to be
// of the form:
// GC      coverage
// (tab separated), where GC is all integers in [0,100] in ascending numerical order.
void loadGC2cov(string& filename, vector<float>& v_in);

// Loads the GC from bgzipped tabixed file, for just the given reference sequence.
// Fills the vector with GC content at each position of the sequence (v_in[n] = GC at position n (zero based))
void loadGC(Tabix& ti, string& refname, vector<unsigned int>& v_in);

void setBamReaderRegion(BamReader& bamReader, Region& region, SamHeader& samHeader);


int main(int argc, char* argv[])
{
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    BamReader bamReader;
    BamAlignment bamAlign;
    SamHeader header;
    RefVector references;
    int32_t currentRefID = -1;
    string currentRefIDstring = "";
    bool firstRecord = true;
    string out_stats = options.outprefix + ".global_stats.txt";
    Stats stats;
    stats.globalFragmentCov = Histogram(1);
    stats.globalReadCov = Histogram(1);
    stats.globalFCDerror = Histogram(1);
    stats.globalFragmentLength = Histogram(1);
    stats.clipProportion = Histogram(1);

    map<string, list<pair<unsigned long, unsigned long> > > gaps;
    Tabix ti_gc(options.refGCfile);
    Tabix* ti_perfect;

    if (options.perfectFile.size())
        ti_perfect = new Tabix(options.perfectFile);


    cout << "#chr\tpos\tperfect_cov\tread_cov\tprop_cov\torphan_cov\tbad_insert_cov\tbad_orient_cov\tread_cov_r\tprop_cov_r\torphan_cov_r\tbad_insert_cov_r\tbad_orient_cov_r\tfrag_cov\tfrag_cov_err\tFCD_mean\tclip_fl\tclip_rl\tclip_fr\tclip_rr\tFCD_err\tmean_frag_length\n";

    loadGaps(options.gapsInfile, gaps);
    loadGC2cov(options.gc2covFile, stats.gc2cov);
    if (options.printPlotsSkip)
    {
        string plots_outfile = options.outprefix + ".plots";
        options.plot_ofs.open(plots_outfile.c_str());

        if (!options.plot_ofs.good())
        {
            cerr << ERROR_PREFIX << "Error opening file '" << plots_outfile << "'" << endl;
            return 1;
        }
        options.plotCount = 0;
    }

    // Go through input bam file getting local stats
    if (!bamReader.Open(options.bamInfile))
    {
        cerr << ERROR_PREFIX << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();

    // If we're only looking at some regions, check the bam file is indexed
    if (options.regions.size())
    {
        if (!bamReader.LocateIndex())
        {
            cerr << ERROR_PREFIX << "Couldn't find index for bam file '" << options.bamInfile << "'!" << endl;
            exit(1);
        }

        if (!bamReader.HasIndex())
        {
            cerr << ERROR_PREFIX << "No index for bam file '" << options.bamInfile << "'!" << endl;
            exit(1);
        }

        setBamReaderRegion(bamReader, options.regions[0], header);
/*
        if (header.Sequences.Contains(options.rangeID))
        {
            int id = bamReader.GetReferenceID(options.rangeID);
            int left = options.rangeStart ? options.rangeStart : -1;
            int right = options.rangeEnd ? options.rangeEnd : -1;
            bamReader.SetRegion(id, left, id, right);
        }
        else
        {
            cerr << ERROR_PREFIX << "Error. " << options.rangeID << " not found in bam file" << endl;
            return 1;
        }
*/
    }




    unsigned long regionsIndex = 0;
    bool incrementedRegionsIndex = false;

    while (1)
    {
        if (!bamReader.GetNextAlignmentCore(bamAlign))
        {
            incrementedRegionsIndex = true;
            if (regionsIndex + 1 < options.regions.size())
            {
                regionsIndex++;
                setBamReaderRegion(bamReader, options.regions[regionsIndex], header);
                continue;
            }
            else
            {
                break;
            }
        }

        if (!bamAlign.IsMapped()
              ||  bamAlign.IsDuplicate()
              ||  bamAlign.MapQuality < options.minMapQuality)
        {
            continue;
        }

        // Deal with the case when we find a new reference sequence in the bam
        if (currentRefID != bamAlign.RefID || incrementedRegionsIndex)
        {
            if (firstRecord)
            {
                firstRecord = false;
            }
            else
            {
                printStats(options, currentRefIDstring, references[currentRefID].RefLength, stats, gaps);
            }

            currentRefID = bamAlign.RefID;
            currentRefIDstring = references[bamAlign.RefID].RefName;

            if (options.perfectFile.size())
            {
                getPerfectMapping(ti_perfect, currentRefIDstring, stats.perfectCov, references[currentRefID].RefLength);
            }



            unsigned int startPos = options.regions.size() && options.regions[regionsIndex].start > 0 ? options.regions[regionsIndex].start - 1: 0;

            stats.innerTriplot.clear(startPos);
            stats.outerTriplot.clear(startPos);
            stats.covProper = CoveragePlot(options.maxReadLength, startPos);
            stats.covOrphan = CoveragePlot(options.maxReadLength, startPos);
            stats.covBadInsert = CoveragePlot(options.maxReadLength, startPos);
            stats.covWrongOrient = CoveragePlot(options.maxReadLength, startPos);
            stats.covProperRev = CoveragePlot(options.maxReadLength, startPos);
            stats.covOrphanRev = CoveragePlot(options.maxReadLength, startPos);
            stats.covBadInsertRev = CoveragePlot(options.maxReadLength, startPos);
            stats.covWrongOrientRev = CoveragePlot(options.maxReadLength, startPos);
            stats.softClipFwdLeft = CoveragePlot(options.maxReadLength, startPos);
            stats.softClipRevLeft = CoveragePlot(options.maxReadLength, startPos);
            stats.softClipFwdRight = CoveragePlot(options.maxReadLength, startPos);
            stats.softClipRevRight = CoveragePlot(options.maxReadLength, startPos);
            stats.innerFragments.clear();
            stats.outerFragments.clear();
            loadGC(ti_gc, currentRefIDstring, stats.refGC);
            incrementedRegionsIndex = false;
        }

        int64_t readEnd = bamAlign.GetEndPosition();

        // print all stats to left of current read
        printStats(options, currentRefIDstring, bamAlign.Position, stats, gaps);

        // update count of soft-clipped bases.  Don't care what type of read pair this is
        if (bamAlign.CigarData[0].Type == 'S')
        {
            if (bamAlign.IsReverseStrand())
            {
                stats.softClipRevLeft.add(bamAlign.Position - 1);
            }
            else
            {
                stats.softClipFwdLeft.add(bamAlign.Position - 1);
            }
        }

        if (bamAlign.CigarData.back().Type == 'S')
        {
            if (bamAlign.IsReverseStrand())
            {
                stats.softClipRevRight.add(readEnd);
            }
            else
            {
                stats.softClipFwdRight.add(readEnd);
            }
        }

        // Work out what kind of read this is and update the right read coverage
        // histogram
        short pairOrientation = getPairOrientation(bamAlign);

        // if an orphaned read
        if (!bamAlign.IsMateMapped() || pairOrientation == UNPAIRED || pairOrientation == DIFF_CHROM)
        {
            if (bamAlign.IsReverseStrand()) stats.covOrphanRev.add(readEnd);
            else stats.covOrphan.add(readEnd);
        }
        // correct orienation (but insert size could be good or bad)
        else if (pairOrientation == INNIE)
        {
            int64_t fragStart = readEnd + 1;
            int64_t fragEnd = bamAlign.MatePosition - 1;
            if (0 < bamAlign.InsertSize && abs(bamAlign.InsertSize) < options.maxInsert * 5) stats.globalFragmentLength.add(bamAlign.InsertSize, 1);

            // if insert size is bad
            if (abs(bamAlign.InsertSize) < options.minInsert || abs(bamAlign.InsertSize) > options.maxInsert)
            {
                if (bamAlign.IsReverseStrand()) stats.covBadInsertRev.add(readEnd);
                else stats.covBadInsert.add(readEnd);

            }
            // otherwise, this is a proper pair
            else
            {
                if (bamAlign.IsReverseStrand()) stats.covProperRev.add(readEnd);
                else stats.covProper.add(readEnd);

                // update insert size ditribution and fragment coverage. We only want
                // to count each fragment once: in a sorted bam the first appearance
                // of a fragment is when the insert size is positive
                if (bamAlign.InsertSize < 0)
                {
                    continue;
                }

                stats.outerFragments.insert(stats.outerFragments.end(), make_pair(bamAlign.Position, bamAlign.Position + bamAlign.InsertSize - 1));

                // update inner fragment stuff
                if (fragStart < fragEnd)
                {
                    stats.innerFragments.insert(stats.innerFragments.end(), make_pair(fragStart, fragEnd));
                }
            }
        }
        // wrong orientation
        else if (pairOrientation == SAME || pairOrientation == OUTTIE)
        {
            if (bamAlign.IsReverseStrand()) stats.covWrongOrientRev.add(readEnd);
            else stats.covWrongOrient.add(readEnd);
        }
        else
        {
            cerr << ERROR_PREFIX << "Didn't expect this to happen..." << endl;
        }
    }

    // print the remaining stats from the last ref sequence in the bam
    //unsigned long endCoord = options.rangeID.size() && options.rangeEnd ? options.rangeEnd : references[currentRefID].RefLength;
    unsigned long endCoord = options.regions.size() && options.regions.back().end != 0 ? options.regions.back().end : references[currentRefID].RefLength;
    printStats(options, currentRefIDstring, endCoord, stats, gaps);

    // Make some global plots
    stats.globalReadCov.plot(options.outprefix + ".read_coverage", "pdf", "Read coverage", "Frequency");
    stats.globalFragmentCov.plot(options.outprefix + ".fragment_coverage", "pdf", "Fragment coverage", "Frequency");
    stats.globalFragmentLength.plot(options.outprefix + ".fragment_length", "pdf", "Fragment length", "Frequency");

    stats.globalReadCov.writeToFile(options.outprefix + ".read_coverage.dat", 0, 1);
    stats.globalFragmentCov.writeToFile(options.outprefix + ".fragment_coverage.dat", 0, 1);
    stats.globalFragmentLength.writeToFile(options.outprefix + ".fragment_length.dat", 0, 1);

    // print some global stats
    ofstream ofs(out_stats.c_str());
    if (!ofs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << out_stats << "'" << endl;
        return 1;
    }

    double mean, sd;
    unsigned long x;
    ofs.precision(2);
    fixed(ofs);
    stats.globalReadCov.meanAndStddev(mean, sd);
    ofs << "read_cov_mean\t" << mean << "\n"
        << "read_cov_sd\t" << sd   << "\n"
        << "read_cov_mode\t" << stats.globalReadCov.mode(x) << "\n";

    stats.globalFragmentCov.meanAndStddev(mean, sd);
    ofs << "fragment_cov_mean\t" << mean << "\n"
        << "fragment_cov_sd\t" << sd   << "\n"
        << "fragment_cov_mode\t" << stats.globalFragmentCov.mode(x) << "\n";

    stats.globalFragmentLength.meanAndStddev(mean, sd);
    ofs << "fragment_length_mean\t" << mean << "\n"
        << "fragment_length_sd\t" << sd   << "\n"
        << "fragment_length_mode\t" << stats.globalFragmentLength.mode(x) << "\n";

    ofs << "fragment_length_min\t" << options.minInsert << "\n"
        << "fragment_length_max\t" << options.maxInsert << "\n";

    if (options.perfectFile.size())
    {
        ofs << "use_perfect\t1\n";
    }
    else
    {
        ofs << "use_perfect\t0\n";
    }

    ofs << "sample_ave_fragment_length\t" << options.aveFragmentLength << "\n";
    ofs << "fcd_skip\t" << options.areaSkip << endl;
    ofs.close();

    stats.globalFCDerror.setPlotOptionTrim(6);
    stats.globalFCDerror.setPlotOptionXdivide(100);
    stats.globalFCDerror.setPlotOptionUseLeftOfBins(true);
    stats.globalFCDerror.plot(options.outprefix + ".FCDerror", "pdf", "FCD Error", "Frequency");
    stats.globalFCDerror.writeToFile(options.outprefix + ".FCDerror.dat", 0, 0.01);
    if (options.perfectFile.size())
        delete ti_perfect;

    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 2;
    int i;

    usage = "[options] <preprocess output directory> <outfiles prefix>\n\n\
options:\n\n\
-f <int>\n\tInsert size [ave from stats.txt]\n\
-i <int>\n\tMinimum insert size [pc1 from stats.txt]\n\
-j <int>\n\tMaximum insert size [pc99 from stats.txt]\n\
-m <int>\n\tMaximum read length (this doesn't need to be exact, it just\n\
\tdetermines memory allocation, so must be >= max read length) [2000]\n\
-p <string>\n\tName of .gz perfect mapping file made by 'perfectmap'\n\
-q <int>\n\tIgnore reads with mapping quality less than this [0]\n\
-s <int>\n\tCalculate FCD error every n^th base\n\
\t[ceil((fragment size) / 1000)]\n\
-u <string>\n\tFile containing list of chromosomes to look at\n\
\t(one per line)\n\
";
/*
-r id[:start-end]\n\tOnly look at the ref seq with this ID, and\n\
\toptionally in the given base range\n\
-t <int>\n\t-t N will make file of triangle plot data at every\n\
\tN^th  position. This file could be big!\n\
\tRecommended usage is in conjunction with -r option\n\
";
*/
    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        cerr << "usage:\ntask_stats " << usage;
        exit(1);
    }


    // set defaults
    ops.maxReadLength = 2000;
    ops.binWidth = 10;
    ops.minMapQuality = 0;
    ops.perfectFile = "";
    ops.printPlotsSkip = 0;
    ops.rangeID = "";
    ops.rangeStart = 0;
    ops.rangeEnd = 0;
    ops.areaSkip = 0;
    ops.minInsert = 0;
    ops.aveFragmentLength = 0;
    ops.maxInsert = 0;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans

        // non booleans are of form -option value, so check
        // next value in array is there before using it!
        if (strcmp(argv[i], "-b") == 0)
            ops.binWidth = atoi(argv[i+1]);
        else if (strcmp(argv[i], "-g") == 0)
            ops.aveFragmentLength = atoi(argv[i+1]);
        else if (strcmp(argv[i], "-i") == 0)
            ops.minInsert = atoi(argv[i+1]);
        else if (strcmp(argv[i], "-j") == 0)
            ops.maxInsert = atoi(argv[i+1]);
        else if (strcmp(argv[i], "-m") == 0)
            ops.maxReadLength = atoi(argv[i+1]);
        else if (strcmp(argv[i], "-p") == 0)
            ops.perfectFile = argv[i+1];
        else if (strcmp(argv[i], "-q") == 0)
            ops.minMapQuality = atof(argv[i+1]);
        else if (strcmp(argv[i], "-r") == 0)
        {
            string locus(argv[i+1]);
            size_t pos_colon = locus.rfind(':');
            if (pos_colon == string::npos)
            {
                ops.rangeID = locus;
            }
            else
            {
                ops.rangeID = locus.substr(0, pos_colon);
                size_t pos_dash = locus.find('-', pos_colon);
                if (pos_dash == string::npos)
                {
                    cerr << ERROR_PREFIX << "Error getting coords from this input: " << locus << endl;
                    exit(1);
                }

                ops.rangeStart = atoi(locus.substr(pos_colon + 1, pos_dash - pos_colon).c_str());
                ops.rangeEnd = atoi(locus.substr(pos_dash + 1).c_str());


                if (ops.rangeEnd < ops.rangeStart)
                {
                    cerr << ERROR_PREFIX << "Range end < range start.  Cannot continue" << endl;
                    exit(1);
                }
            }
        }
        else if (strcmp(argv[i], "-s") == 0)
        {
            ops.areaSkip = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-t") == 0)
        {
            ops.printPlotsSkip = atoi(argv[i+1]);
            ops.printPlotsChr = argv[i+2];
            ops.printPlotsStart = atoi(argv[i+3]);
            ops.printPlotsEnd = atoi(argv[i+4]);
            i += 3;
        }
        else if (strcmp(argv[i], "-u") == 0)
        {
            // load regions from file into vector
            string fname = argv[i+1];
            ifstream ifs(fname.c_str());
            if (!ifs.good())
            {
                cerr << ERROR_PREFIX << "Error opening file '" << fname << "'" << endl;
                exit(1);
            }

            string line;

            while (getline(ifs, line))
            {
                vector<string> v;
                split(line, '\t', v);
                Region r;
                r.id = v[0];
/*
                if (v.size() > 1)
                {
                    r.start = atoi(v[1].c_str());
                    r.end = atoi(v[2].c_str());
                }
                else
                {
                    r.start = 0;
                    r.end = 0;
                }
*/
                // doing regions within a chromosome is buggy, so don't do it for now
                r.start = r.end = 0;
                ops.regions.push_back(r);
            }
            ifs.close();
        }
        else
        {
            cerr << ERROR_PREFIX << "Error! Switch not recognised: " << argv[i] << endl;
            exit(1);
        }
        i++;
    }

    if (argc - i != requiredArgs || argv[i+1][0] == '-')
    {
        cerr << usage;
        exit(1);
    }

    string preprocessDirectory = argv[i];
    ops.gapsInfile = preprocessDirectory + "/00.assembly.fa.gaps.gz";
    ops.refGCfile = preprocessDirectory + "/00.assembly.fa.gc.gz";
    ops.gc2covFile = preprocessDirectory + "/00.Sample/gc_vs_cov.lowess.dat";
    ops.bamInfile = preprocessDirectory + "/00.in.bam";
    ops.statsInfile = preprocessDirectory + "/00.Sample/insert.stats.txt";
    ops.outprefix = argv[i+1];

    ops.innerAveFragCov = 0;
    ops.samples = 100000;
    ops.maxOuterFragCov = 2000;

    // get stats from file
    ifstream ifs(ops.statsInfile.c_str());
    if (!ifs.good())
    {
        cerr << "Error opening file '" << ops.statsInfile << "'" << endl;
        exit(1);
    }
    string line;

    while (getline(ifs, line))
    {
        vector<string> v;
        split(line, '\t', v);

        if (v[0].compare("pc1") == 0 && ops.minInsert == 0)
        {
            ops.minInsert = atoi(v[1].c_str());
        }
        else if (v[0].compare("ave") == 0 && ops.aveFragmentLength == 0)
        {
            ops.aveFragmentLength = atoi(v[1].c_str());
        }
        else if (v[0].compare("pc99") == 0 && ops.maxInsert == 0)
        {
            ops.maxInsert = atoi(v[1].c_str());
        }
        else if (v[0].compare("inner_mean_cov") == 0)
        {
            ops.innerAveFragCov = atof(v[1].c_str());
        }
    }

    if (ops.minInsert == 0 || ops.aveFragmentLength == 0 || ops.maxInsert == 0 || ops.innerAveFragCov == 0)
    {
        cerr << ERROR_PREFIX << "Error getting stats from file '" << ops.statsInfile << "'" << endl;
        exit(1);
    }

    // set area skip in terms of ave insert size, unless user already chose it
    if (!ops.areaSkip)
    {
        ops.areaSkip = ceil(1.0 * ops.aveFragmentLength / 1000);
    }
}


void printStats(CmdLineOptions& ops, string& refname, unsigned long pos, Stats& stats, map<string, list<pair<unsigned long, unsigned long> > >& gaps)
{
if (pos < stats.outerTriplot.centreCoord()) return;

    // see if any gaps in this reference sequence
    map<string, list<pair<unsigned long, unsigned long> > >::iterator gapsIter = gaps.find(refname);
    list<pair<unsigned long, unsigned long> >::iterator iter;

    if (gapsIter != gaps.end())
    {
        iter = gapsIter->second.begin();
    }

    for (unsigned long i = stats.outerTriplot.centreCoord(); i < pos; i++)
    {
        unsigned long gapStart = 0;
        unsigned long gapEnd = 0;
        unsigned long leftGapDistance = 0;
        unsigned long rightGapDistance = 0;
        bool inGap = false;
        bool nearGap = false;

        // update position of gaps iterator, so i is either to left of
        // next gap, or i lies in a gap pointed to by iter
        if (gapsIter != gaps.end())
        {
            while (iter != gapsIter->second.end() && iter->second < i)
            {
                iter++;
            }

            // if i lies in a gap
            if (iter != gapsIter->second.end() && i >= iter->first)
            {
                inGap = true;
                gapStart = iter->first;
                gapEnd = iter->second;
            }
            else
            {
                if (iter != gapsIter->second.begin())
                {
                    iter--;
                    leftGapDistance = i - iter->second;
                    iter++;
                }
                if (iter != gapsIter->second.end())
                {
                    rightGapDistance = iter->first  - i;
                }

                if (leftGapDistance != 0 && (leftGapDistance < rightGapDistance || rightGapDistance == 0) && leftGapDistance < ops.aveFragmentLength - 1)
                {
                    iter--;
                    nearGap = true;
                    gapStart = iter->first;
                    gapEnd = iter->second;
                    iter++;
                }
                else if (rightGapDistance != 0 && (rightGapDistance < leftGapDistance || leftGapDistance == 0)  && rightGapDistance < ops.aveFragmentLength - 1)
                {
                    nearGap = true;
                    gapStart = iter->first;
                    gapEnd = iter->second;
                }
            }
        }
        unsigned long readCov = stats.covProper.depth() + stats.covOrphan.depth() + stats.covBadInsert.depth() + stats.covWrongOrient.depth();
        unsigned long readCovRev = stats.covProperRev.depth() + stats.covOrphanRev.depth() + stats.covBadInsertRev.depth() + stats.covWrongOrientRev.depth();


        cout << refname << "\t"
             << i + 1 << "\t";

        if (ops.perfectFile.size())
        {
            if (stats.perfectCov.size())
            {
                cout << stats.perfectCov[i] << "\t";
            }
            else
            {
                cout << 0 << "\t";
            }
        }
        else
        {
            cout << "-1\t";
        }

        unsigned long innerFragCov = stats.innerTriplot.depth();
        float innerFragCovCorrected = inGap ? 0 : 1.0 * (innerFragCov - stats.gc2cov[stats.refGC[i]]) / ops.innerAveFragCov;

        double triArea;

        if (i % ops.areaSkip == 0)
        {
            triArea = stats.outerTriplot.areaError(ops.maxInsert, ops.aveFragmentLength, inGap || nearGap, gapStart, gapEnd);
            stats.lastTriArea = triArea;
            if (triArea > -1)
            {
                stats.globalFCDerror.add((long) 100 * triArea,1);
            }
        }
        else
        {
            triArea = stats.lastTriArea;
        }

        cout << readCov << "\t"
             << (readCov ? 1.0 * stats.covProper.depth() / readCov : 0) << "\t"
             << (readCov ? 1.0 * stats.covOrphan.depth() / readCov : 0) << "\t"
             << (readCov ? 1.0 * stats.covBadInsert.depth() / readCov : 0) << "\t"
             << (readCov ? 1.0 * stats.covWrongOrient.depth() / readCov : 0) << "\t"
             << readCovRev << "\t"
             << (readCovRev ? 1.0 * stats.covProperRev.depth() / readCovRev : 0) << "\t"
             << (readCovRev ? 1.0 * stats.covOrphanRev.depth() / readCovRev : 0) << "\t"
             << (readCovRev ? 1.0 * stats.covBadInsertRev.depth() / readCovRev : 0) << "\t"
             << (readCovRev ? 1.0 * stats.covWrongOrientRev.depth() / readCovRev : 0) << "\t"
             << innerFragCov << "\t"
             << innerFragCovCorrected << "\t"
             << stats.outerTriplot.mean() << "\t"
             << stats.softClipFwdLeft.front() << "\t"
             << stats.softClipRevLeft.front() << "\t"
             << stats.softClipFwdRight.front() << "\t"
             << stats.softClipRevRight.front() << "\t"
             << triArea << "\t"
             << stats.outerTriplot.meanFragLength() << "\n";


        if (readCov)
        {
            stats.clipProportion.add((long) 100 * stats.softClipFwdLeft.front() / readCov, 1);
            stats.clipProportion.add((long) 100 * stats.softClipFwdRight.front() / readCov, 1);
        }
        if (readCovRev)
        {
            stats.clipProportion.add((long) 100 * stats.softClipRevLeft.front() / readCovRev, 1);
            stats.clipProportion.add((long) 100 * stats.softClipRevRight.front() / readCovRev, 1);
        }

        if (ops.printPlotsSkip && refname.compare(ops.printPlotsChr) == 0 && ops.printPlotsStart <= i + 1 && i + 1 <= ops.printPlotsEnd)
        {
            if (ops.plotCount % ops.printPlotsSkip == 0) {
                string plot = stats.outerTriplot.toString(ops.maxInsert);
                ops.plot_ofs << refname << "\t" << i + 1 << "\t" << ops.maxInsert;

                if (plot.size())
                {
                    ops.plot_ofs << "\t" << stats.outerTriplot.toString(ops.maxInsert);
                }
                ops.plot_ofs << "\n";
            }

            ops.plotCount++;
        }
        else if (ops.printPlotsSkip && refname.compare(ops.printPlotsChr) == 0 && ops.printPlotsEnd < i + 1)
        {
            ops.plot_ofs.close();
            exit(0);
        }

        stats.innerTriplot.shift(1);
        stats.innerTriplot.add(stats.innerFragments);
        stats.outerTriplot.shift(1);
        stats.outerTriplot.add(stats.outerFragments);
        stats.covProper.increment();
        stats.covOrphan.increment();
        stats.covBadInsert.increment();
        stats.covWrongOrient.increment();
        stats.covProperRev.increment();
        stats.covOrphanRev.increment();
        stats.covBadInsertRev.increment();
        stats.covWrongOrientRev.increment();
        stats.softClipFwdLeft.increment();
        stats.softClipRevLeft.increment();
        stats.softClipFwdRight.increment();
        stats.softClipRevRight.increment();
        if (stats.covProper.depth() + stats.covProperRev.depth() ) stats.globalReadCov.add(stats.covProper.depth() + stats.covProperRev.depth(), 1);
        if (stats.outerTriplot.depth()) stats.globalFragmentCov.add(stats.outerTriplot.depth(), 1);
    }
}


void getPerfectMapping(Tabix* ti, string& refname,  vector<unsigned long>& v_in, unsigned long refLength)
{
    string line;
    vector<string> data;
    v_in.clear();
    if(ti->setRegion(refname))
    {
        while (ti->getNextLine(line)) {
            split(line, '\t', data);
            v_in.push_back(atoi(data[2].c_str()));
        }
    }

    if (v_in.size() == 0)
    {
        cerr << ERROR_PREFIX << "Warning: didn't get any perfect mapping info for '" << refname << "'.  Assuming zero perfect coverage" << endl;
    }
    else if (v_in.size() != refLength)
    {
        cerr << ERROR_PREFIX << "Mismatch in sequence length when getting perfect mapping coverage." << endl
             << "I found " << v_in.size() << " lines for sequence '" << refname << "'.  Expected " << refLength << endl;
        exit(1);
    }
}



void loadGC2cov(string& filename, vector<float>& v_in)
{
    ifstream ifs(filename.c_str());
    string line;

    if (!ifs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << filename << "'" << endl;
        exit(1);
    }

    while (getline(ifs, line))
    {
        vector<string> tmp;
        split(line, '\t', tmp);
        unsigned int gc = atoi(tmp[0].c_str());

        // sanity check we've got the right GC
        if (gc != v_in.size())
        {
            cerr << ERROR_PREFIX << "Error in GC to coverage file '" << filename << "'." << endl
                 << "Need GC in numerical order from 0 to 100.  Problem around this line:" << endl
                 << line << endl;
            exit(1);
        }

        v_in.push_back(atof(tmp[1].c_str()));
    }

    ifs.close();
}



void loadGC(Tabix& ti, string& refname, vector<unsigned int>& v_in)
{
    v_in.clear();
    ti.setRegion(refname);
    vector<string> tmp;
    string line;

    // load the GC into vector
    while (ti.getNextLine(line))
    {
        split(line, '\t', tmp);
        v_in.push_back(atoi(tmp[2].c_str()));
    }
}



void setBamReaderRegion(BamReader& bamReader, Region& region, SamHeader& header)
{
    if (header.Sequences.Contains(region.id))
    {
        int id = bamReader.GetReferenceID(region.id);
        if (region.start == 0 && region.end == 0)
        {
            bamReader.SetRegion(id, 1, id, bamReader.GetReferenceData()[id].RefLength);
        }
        else // this currently can't happen. It's buggy.
        {
            bamReader.SetRegion(id, region.start - 1, id, region.end - 1);
        }
    }
    else
    {
        cerr << ERROR_PREFIX << "Error. " << region.id << " not found in bam file" << endl;
        exit(1);
    }
}

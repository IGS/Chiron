#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <map>
#include <list>
#include <algorithm>
#include <cmath>
#include <set>

#include "utils.h"
#include "errorWindow.h"
#include "histogram.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"
#include "tabix/tabix.hpp"

using namespace BamTools;
using namespace std;

const string ERROR_PREFIX = "[REAPR score] ";
const string TOOL_NAME = "REAPR";
const short CHR = 0;
const short POS = 1;
const short PERFECT_COV = 2;
const short READ_F = 3;
const short READ_PROP_F = 4;
const short READ_ORPHAN_F = 5;
const short READ_ISIZE_F = 6;
const short READ_BADORIENT_F = 7;
const short READ_R = 8;
const short READ_PROP_R = 9;
const short READ_ORPHAN_R = 10;
const short READ_ISIZE_R = 11;
const short READ_BADORIENT_R = 12;
const short FRAG_COV = 13;
const short FRAG_COV_CORRECT = 14;
const short FCD_MEAN = 15;
const short CLIP_FL = 16;
const short CLIP_RL = 17;
const short CLIP_FR = 18;
const short CLIP_RR = 19;
const short FCD_ERR = 20;
const short CLIP_FAIL = 42;
const short GAP = 43;
const short READ_COV = 44;



struct CmdLineOptions
{
    string bamInfile;
    string gapsInfile;
    string globalStatsInfile;  // the one made by 'stats'
    string outprefix;
    string statsInfile;
    int64_t minInsert;  // to count as a proper read pair
    int64_t maxInsert;  // to count as a proper read pair
    unsigned long fragMin;  // minimum inner fragment coverage
    unsigned long windowLength;
    unsigned long readCovWinLength;
    unsigned long usePerfect;  // min perfect coverage (if being used)
    bool perfectWins;
    double readRatioMax;
    unsigned long minReadCov;
    double windowPercent;
    double clipCutoff; // used to callpielup of soft clipping errors
    unsigned long maxGap;  // max gap length to call errors over
    unsigned long outerInsertSize; // ave outer fragment size. Get from stats file made by stats (which got it from preprocess
                                   // stats file)
    ofstream ofs_breaks;
    unsigned long minMapQuality; // ignore reads with mapping qualiy less than this
    float minReportScore; // cutoff for reporting high score regions
    unsigned long minScoreReportLength;
    float maxFragCorrectCov; // cutoff in relative error of fragment coverage for repeat calling
    unsigned long minRepeatLength; // min repeat length to report
    short readType;
    double fcdCutoff;
    unsigned long fcdWindow;
    float scoreDivider;
    bool verbose;
    bool debug;
    bool callRepeats;
};


struct BAMdata
{
    BamReader bamReader;
    SamHeader header;
    RefVector references;
};


struct Link
{
    string id;
    string hitId;
    unsigned long start;
    unsigned long end;
    unsigned long hitStart;
    unsigned long hitEnd;
};


// for sorting by start/end position
bool compare_link (Link first, Link second)
{
    return first.start < second.start;
}

template <class T>
inline string toString(const T& t)
{
    stringstream ss;
    ss << t;
    return ss.str();
}


struct Error
{
    unsigned long start;
    unsigned long end;
    short type;
};



string getNearbyGaps(list<Error>::iterator p, list<pair<unsigned long, unsigned long > >& gaps, list<pair<unsigned long, unsigned long > >::iterator gapIter);


// use to sort by start position
bool compareErrors(const Error& e, const Error& f);

// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops, map<short, ErrorWindow>& windows);

void updateErrorList(list<Error>& l, Error& e);

void scoreAndFindBreaks(CmdLineOptions& ops, map<short, list<Error> >& errors_map, list<pair<unsigned long, unsigned long > > &gaps, unsigned long seqLength, string& seqName, vector<float>& scores, vector<bool>& perfectCov, BAMdata& bamData);

void updateScoreHist(map<float, unsigned long>& hist, vector<float>& scores);


void bam2possibleLink(CmdLineOptions& ops, string& refID, unsigned long start, unsigned long end, string& hitName, unsigned long& hitStart, unsigned long& hitEnd, BAMdata& bamData);

double region2meanScore(CmdLineOptions& ops, string& seqID, unsigned long start, unsigned long end, short column);



int main(int argc, char* argv[])
{
    map<short, ErrorWindow> windows;
    CmdLineOptions options;
    parseOptions(argc, argv, options, windows);
    map<string, list<pair<unsigned long, unsigned long> > > globalGaps;
    map<short, list<Error> > errors;
    loadGaps(options.gapsInfile, globalGaps);
    string line;
    string currentRefID = "";
    string fout_breaks(options.outprefix + ".errors.gff");
    map<float, unsigned long>  scoreHist;

    options.ofs_breaks.open(fout_breaks.c_str());

    if (!options.ofs_breaks.good())
    {
        cerr << ERROR_PREFIX << "Error opening '" << fout_breaks << "'" << endl;
        exit(1);
    }

    unsigned long lastPos = 0;
    vector<float> scores;
    vector<bool> perfectCov;
    BAMdata bamData;
    Tabix ti(options.statsInfile);

    // open bam file ready for when we look for links to other regions
    if (!bamData.bamReader.Open(options.bamInfile))
    {
        cerr << ERROR_PREFIX << "Error opening bam file " << options.bamInfile << endl;
        exit(1);
    }

    if (!bamData.bamReader.LocateIndex())
    {
        cerr << ERROR_PREFIX << "Couldn't find index for bam file '" << options.bamInfile << "'!" << endl;
        exit(1);
    }

    if (!bamData.bamReader.HasIndex())
    {
        cerr << ERROR_PREFIX << "No index for bam file '" << options.bamInfile << "'!" << endl;
        exit(1);
    }

    bamData.header = bamData.bamReader.GetHeader();
    bamData.references = bamData.bamReader.GetReferenceData();

    if (bamData.header.Sequences.Size() == 0)
    {
        cerr << ERROR_PREFIX << "Error reading header of BAM file.  Didn't find any sequences" << endl;
        return(1);
    }

    while (ti.getNextLine(line))
    {
        if (line[0] == '#') continue;

        float currentScore;
        vector<string> data;
        string tmp;
        split(line, '\t', data);

        if (options.verbose && lastPos % 100000 == 0)
        {
            cerr << ERROR_PREFIX << "progress" << '\t' << data[CHR] << '\t' << lastPos << endl;
        }

        if (data[CHR].compare(currentRefID))
        {
            if (currentRefID.size() != 0)
            {
                // just got to new ref ID, so need to print out stuff from last one
                scoreAndFindBreaks(options, errors, globalGaps[currentRefID], lastPos, currentRefID, scores, perfectCov, bamData);
                updateScoreHist(scoreHist, scores);
            }

            currentRefID = data[CHR];
            map<string, list<pair<unsigned long, unsigned long> > >::iterator p = globalGaps.find(currentRefID);
            errors.clear();
            scores.clear();
            perfectCov.clear();

            for (map<short, ErrorWindow>::iterator p = windows.begin(); p != windows.end(); p++)
            {
                p->second.clear(atoi(data[POS].c_str()));
            }
        }

        // update perfect cov
        if (options.usePerfect)
        {
            if (atoi(data[PERFECT_COV].c_str()) > 0)
            {
                perfectCov.push_back(true);
            }
            else
            {
                perfectCov.push_back(false);
            }
        }


        // update the windows
        for (map<short, ErrorWindow>::iterator p = windows.begin(); p != windows.end(); p++)
        {
            if (p->second.fail())
            {
                Error tmp;
                tmp.start = p->second.start();
                tmp.end = p->second.end();
                tmp.type = p->first;
                updateErrorList(errors[p->first], tmp);
            }

            if (p->first == READ_COV)
            {
                p->second.add( atoi(data[POS].c_str()), atoi(data[READ_F].c_str()) + atoi(data[READ_R].c_str()) );
            }
            else
            {
                p->second.add(atoi(data[POS].c_str()),  atof(data[p->first].c_str()) );
            }
        }

        // update the score
        currentScore = (options.usePerfect && windows[PERFECT_COV].lastFail()) ? 1 : 0;
        currentScore += windows[FCD_ERR].lastFail() ? 1 : 0;

        if (!options.perfectWins || currentScore)
        {
            currentScore += windows[READ_F].lastFail() ? 0.5 : 0;
            currentScore += windows[READ_R].lastFail() ? 0.5 : 0;
            currentScore += windows[READ_PROP_F].lastFail() ? 0.5 : 0;
            currentScore += windows[READ_PROP_R].lastFail() ? 0.5 : 0;
            //currentScore += windows[FCD_ERR].lastFail() ? 1 : 0;
        }

        // Even if we have perfect coverage, could still have a collapsed repeat
        if (options.callRepeats)
        {
            currentScore += windows[FRAG_COV_CORRECT].lastFail() ? 1 : 0;
        }

        // too much soft clipping?
        unsigned long depthFwd = atoi(data[READ_F].c_str());
        unsigned long depthRev = atoi(data[READ_R].c_str());
        bool fl = depthFwd && atof(data[CLIP_FL].c_str()) / depthFwd >= options.clipCutoff;
        bool fr = depthFwd && atof(data[CLIP_FR].c_str()) / depthFwd >= options.clipCutoff;
        bool rl = depthRev && atof(data[CLIP_RL].c_str()) / depthRev >= options.clipCutoff;
        bool rr = depthRev && atof(data[CLIP_RR].c_str()) / depthRev >= options.clipCutoff;

        if ((fl && rl) || (fr && rr))
        {
            Error err;
            err.start = err.end = atoi(data[POS].c_str());
            err.type = CLIP_FAIL;
            updateErrorList(errors[CLIP_FAIL], err);
            if (!options.perfectWins || (options.usePerfect && windows[PERFECT_COV].lastFail())) currentScore++;
        }

        scores.push_back(1.0 * currentScore / options.scoreDivider);
        lastPos = atoi(data[POS].c_str());
    }

    // sort out the final chromosome from the input stats
    scoreAndFindBreaks(options, errors, globalGaps[currentRefID], lastPos, currentRefID, scores, perfectCov, bamData);
    updateScoreHist(scoreHist, scores);
    options.ofs_breaks.close();
    string scoreHistFile(options.outprefix + ".score_histogram.dat");
    ofstream ofsScore(scoreHistFile.c_str());
    if (!ofsScore.good())
    {
        cerr << ERROR_PREFIX << "error opening file '" << scoreHistFile << "'" << endl;
        exit(1);
    }

    for (map<float, unsigned long>::iterator i = scoreHist.begin(); i != scoreHist.end(); i++)
    {
        ofsScore << i->first << '\t' << i->second << endl;
    }

    ofsScore.close();

    return 0;
}



void parseOptions(int argc, char** argv, CmdLineOptions& ops, map<short, ErrorWindow>& windows)
{
    string usage;
    short requiredArgs = 5;
    int i;
    usage = "\
where 'stats prefix' is the output prefix used when stats was run\n\n\
Options:\n\n\
-f <int>\n\tMinimum inner fragment coverage [1]\n\
-g <int>\n\tMax gap length to call over [0.5 * outer_mean_insert_size]\n\
-l <int>\n\tLength of window [100]\n\
-p <int>\n\tUse perfect mapping reads score with given min coverage.\n\
\tIncompatible with -P.\n\
-P <int>\n\tSame as -p, but force the score to be zero at any position with\n\
\tat least the given coverage of perfect mapping reads and which has an\n\
\tOK insert plot, , i.e. perfect mapping reads + insert distribution\n\
\toverride all other tests when calculating the score.\n\
\tIncompatible with -p.\n\
-q <float>\n\tMax bad read ratio [0.33]\n\
-r <int>\n\tMin read coverage [max(1, mean_read_cov - 4 * read_cov_stddev)]\n\
-R <float>\n\tRepeat calling cutoff. -R N means call a repeat if fragment\n\
\tcoverage is >= N * (expected coverage).\n\
\tUse -R 0 to not call repeats [2]\n\
-s <int>\n\tMin score to report in errors file [0.4]\n\
-u <int>\n\tFCD error window length for error calling [insert_size / 2]\n\
-w <float>\n\tMin \% of bases in window needed to call as bad [0.8]\n\n\
";

    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        usage = "[options] <assembly.fa.gaps.gz> <in.bam> <stats prefix> <FCD cutoff> <prefix of output files>\n\n" + usage;
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        usage = "[options] <assembly.fa.gaps.gz> <in.bam> <stats prefix> <FCD cutoff> <prefix of output files> | bgzip -c > out.scores.gz\n\n" + usage;
        cerr << "usage: task_score " << usage;
        exit(1);
    }

    string statsPrefix = argv[argc-3];
    ops.globalStatsInfile = statsPrefix + ".global_stats.txt";
    ifstream ifs(ops.globalStatsInfile.c_str());
    if (!ifs.good())
    {
        cerr << ERROR_PREFIX << "error opening file '" << ops.globalStatsInfile << "'" << endl;
        exit(1);
    }

    string line;
    double readCovMean = -1;
    double readCovSd = -1;
    double fragCovMean = -1;
    double fragCovSd = -1;
    long usePerfect = -1;
    bool perfectWins = false;

    while (getline(ifs, line))
    {
        vector<string> v;
        split(line, '\t', v);

        if (v[0].compare("read_cov_mean") == 0)
        {
            readCovMean = atof(v[1].c_str());
        }
        else if (v[0].compare("read_cov_sd") == 0)
        {
            readCovSd = atof(v[1].c_str());
        }
        else if (v[0].compare("fragment_cov_mean") == 0)
        {
            fragCovMean = atof(v[1].c_str());
        }
        else if (v[0].compare("fragment_cov_sd") == 0)
        {
            fragCovSd = atof(v[1].c_str());
        }
        else if (v[0].compare("fragment_length_min") == 0)
        {
            ops.minInsert = atoi(v[1].c_str());
        }
        else if (v[0].compare("fragment_length_max") == 0)
        {
            ops.maxInsert = atoi(v[1].c_str());
        }
        else if (v[0].compare("use_perfect") == 0)
        {
            usePerfect = atoi(v[1].c_str()) == 1 ? 5 : 0;
            perfectWins = usePerfect == 0 ? false : true;
        }
        else if (v[0].compare("sample_ave_fragment_length") == 0)
        {
            ops.outerInsertSize = atoi(v[1].c_str());
        }
    }

    if (readCovMean == -1 || readCovSd == -1 || fragCovMean == -1 || fragCovSd == -1 || usePerfect == -1)
    {
        cerr << ERROR_PREFIX << "Error getting stats from '" << ops.globalStatsInfile << "'" << endl;
        exit(1);
    }

    ifs.close();

    // set defaults
    ops.clipCutoff = 0.5;
    ops.fragMin = 1;
    ops.minReadCov = readCovMean > 4 * readCovSd ? readCovMean - 4 * readCovSd : 1;
    ops.minReportScore = 0.5;
    ops.minScoreReportLength = 10;
    ops.maxGap = 0;
    ops.perfectWins = false;
    ops.readRatioMax = 0.5;
    ops.usePerfect = 0;
    ops.windowLength = 0;
    ops.windowPercent = 0.8;
    ops.verbose = false;
    ops.fcdWindow = 0;
    ops.callRepeats = true;
    ops.debug = false;
    ops.maxFragCorrectCov = 2;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans
        if (strcmp(argv[i], "-d") == 0)
        {
            ops.debug = true;
            ops.verbose =true;
            continue;
        }
        if (strcmp(argv[i], "-v") == 0)
        {
            ops.verbose = true;
            continue;
        }

        // non booleans ....
        if (strcmp(argv[i], "-f") == 0)
        {
            ops.fragMin = atoi(argv[i+1]);
        }
        if (strcmp(argv[i], "-g") == 0)
        {
            ops.maxGap = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-l") == 0)
        {
            ops.windowLength = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-p") == 0)
        {
            if (ops.usePerfect)
            {
                cerr << ERROR_PREFIX << "Error! both -p and -P used. Cannot continue" << endl;
                exit(1);
            }
            ops.usePerfect = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-P") == 0)
        {
            if (ops.usePerfect)
            {
                cerr << ERROR_PREFIX << "Error! both -p and -P used. Cannot continue" << endl;
                exit(1);
            }
            ops.usePerfect = atoi(argv[i+1]);
            ops.perfectWins = true;
        }
        else if (strcmp(argv[i], "-q") == 0)
        {
            ops.readRatioMax = atof(argv[i+1]);
        }
        else if (strcmp(argv[i], "-R") == 0)
        {
            ops.maxFragCorrectCov = atof(argv[i+1]);
            if (ops.maxFragCorrectCov == 0) ops.callRepeats = false;
        }
        else if (strcmp(argv[i], "-r") == 0)
        {
            ops.minReadCov = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-s") == 0)
        {
            ops.minReportScore = atof(argv[i+1]);
        }
        else if (strcmp(argv[i], "-u") == 0)
        {
            ops.fcdWindow = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-w") == 0)
        {
            ops.windowPercent = atof(argv[i+1]);
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

    ops.gapsInfile = argv[i];
    ops.bamInfile = argv[i+1];
    ops.fcdCutoff = atof(argv[i+3]);
    ops.outprefix = argv[i+4];
    ops.statsInfile = statsPrefix + ".per_base.gz";

    // If user didn't specify whether or not to use perfect reads, use the global stats file to decide
    if (ops.usePerfect == 0 && perfectWins)
    {
        ops.usePerfect = usePerfect;
        ops.perfectWins = true;
    }

    //if (!ops.maxGap) ops.maxGap = ops.outerInsertSize * 8 / 10;
    if (!ops.maxGap) ops.maxGap = ops.outerInsertSize / 2;
    if (!ops.fcdWindow) ops.fcdWindow = ops.outerInsertSize > 1000 ? ops.outerInsertSize / 2 :  ops.outerInsertSize;
    if (!ops.windowLength) ops.windowLength = 100;
    ops.readCovWinLength = 5;
    ops.minMapQuality = 0;
    ops.minRepeatLength = ops.windowLength;
    ops.scoreDivider = ops.usePerfect ? 7.0 : 6.0;

    // set up the error windows
    if (ops.usePerfect)
    {
        windows[PERFECT_COV]      = ErrorWindow(1, ops.usePerfect, 0, 30, 1, true, false);
    }

    windows[READ_F]           = ErrorWindow(1, max(ops.minReadCov / 2, (unsigned long) 1), 0, ops.readCovWinLength, ops.windowPercent, true, false);
    windows[READ_PROP_F]      = ErrorWindow(1, 0.66, 0, ops.windowLength, ops.windowPercent, true, false);
    windows[READ_ORPHAN_F]    = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[READ_ISIZE_F]     = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[READ_BADORIENT_F] = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[READ_R]           = ErrorWindow(1, max(ops.minReadCov / 2, (unsigned long) 1), 0, ops.readCovWinLength, ops.windowPercent, true, false);
    windows[READ_PROP_R]      = ErrorWindow(1, 0.66, 0, ops.windowLength, ops.windowPercent, true, false);
    windows[READ_ORPHAN_R]    = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[READ_ISIZE_R]     = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[READ_BADORIENT_R] = ErrorWindow(1, 0, ops.readRatioMax, ops.windowLength, ops.windowPercent, false, true);
    windows[FRAG_COV]         = ErrorWindow(1, ops.fragMin, 0, 1, 1, true, false);
    windows[READ_COV]         = ErrorWindow(1, ops.minReadCov, 0, ops.windowLength, ops.windowPercent, true, false);
    if (ops.callRepeats)
    {
        windows[FRAG_COV_CORRECT] = ErrorWindow(1, 0, ops.maxFragCorrectCov, ops.minRepeatLength, 0.95, false, true);
    }
    else
    {
        ops.scoreDivider--;
    }
    windows[FCD_ERR] = ErrorWindow(1, 0, ops.fcdCutoff, ops.fcdWindow, ops.windowPercent, false, true);

    string parametersFile = ops.outprefix + ".parameters.txt";
    ofstream ofs(parametersFile.c_str());
    if (!ofs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << parametersFile << "'" << endl;
        exit(1);
    }

    // write the parameters to stderr
    ofs << "fragment_length_min\t" << ops.minInsert << endl
        << "fragment_length_ave\t" << ops.outerInsertSize << endl
        << "fragment_length_max\t" << ops.maxInsert << endl
        << "min_inner_fragment_coverage\t" << ops.fragMin << endl
        << "max_inner_fragment_coverage_relative_error\t" << (ops.callRepeats ? ops.maxFragCorrectCov : -1) << endl
        << "window_length\t" << ops.windowLength << endl
        << "window_percent\t" << ops.windowPercent << endl
        << "read_coverage_window\t" << ops.readCovWinLength << endl
        << "use_perfect\t" << ops.usePerfect << endl
        << "perfect_wins\t" << ops.perfectWins << endl
        << "read_ratio_max\t" << ops.readRatioMax << endl
        << "min_read_coverage\t" << ops.minReadCov << endl
        << "clip_cutoff\t" << ops.clipCutoff << endl
        << "max_callable_gap_length\t" << ops.maxGap << endl
        << "FCD_err_cutoff\t" << ops.fcdCutoff << endl
        << "FCD_err_window\t" << ops.fcdWindow << endl
        << "min_map_qual\t" << ops.minMapQuality << endl
        << "min_report_score\t" << ops.minReportScore << endl;

    ofs.close();
}


void updateErrorList(list<Error>& l, Error& e)
{
    if (l.empty())
    {
        l.push_back(e);
    }
    else
    {
        if (e.start - 1 <= l.back().end)
        {
            l.back().end = e.end;
        }
        else
        {
            l.push_back(e);
        }
    }
}


void scoreAndFindBreaks(CmdLineOptions& ops, map<short, list<Error> >& errors_map, list<pair<unsigned long, unsigned long > > &gaps, unsigned long seqLength, string& seqName, vector<float>& scores, vector<bool>& perfectCov, BAMdata& bamData)
{
    if (ops.verbose)
    {
        cerr << ERROR_PREFIX << "scoring and error calling on sequence " << seqName << endl;
    }

    unsigned long scoreIndex = 0;
    map<unsigned long, string> gff_out;  // start position -> gff line

    // Pull out all the regions of high fragment coverage
    if (ops.callRepeats)
    {
        for (list<Error>::iterator p = errors_map[FRAG_COV_CORRECT].begin(); p != errors_map[FRAG_COV_CORRECT].end(); p++)
        {
            gff_out[p->start + 1] += seqName + "\t" + TOOL_NAME + "\tRepeat\t" + toString(p->start + 1) + "\t" + toString(p->end + 1) + "\t" + toString(region2meanScore(ops, seqName, p->start, p->end, FRAG_COV_CORRECT)) + "\t.\t.\tNote=Warning: Collapsed repeat;colour=6\n";
        }

        errors_map.erase(FRAG_COV_CORRECT);
    }

    // Pull out all the soft clipping errors, but don't count those next to a gap
    list<pair<unsigned long, unsigned long > >::iterator gapsIter = gaps.begin();
    unsigned long gapLimit = 5;

    for (list<Error>::iterator clipIter = errors_map[CLIP_FAIL].begin(); clipIter != errors_map[CLIP_FAIL].end(); clipIter++)
    {
        while (gapsIter != gaps.end() && clipIter->start > gapsIter->second + gapLimit)
        {
            gapsIter++;
        }
        if (clipIter->start >= 10 && clipIter->start + 10 < seqLength && (gapsIter == gaps.end() || clipIter->start + gapLimit < gapsIter->first)) {
            gff_out[clipIter->start] += seqName + "\t" + TOOL_NAME + "\tClip\t" + toString(clipIter->start) + '\t' + toString(clipIter->end) + "\t.\t.\t.\tNote=Warning: Soft clip failure;colour=7\n";
        }
    }

    errors_map.erase(CLIP_FAIL);

    // Pull out all the low read coverage errors. Don't include gaps.
    vector<pair <unsigned long, unsigned long> > fwdReadcovErrs;
    gapsIter = gaps.begin();

    for (list<Error>::iterator readIter = errors_map[READ_COV].begin(); readIter != errors_map[READ_COV].end(); readIter++)
    {
        while (gapsIter != gaps.end() && readIter->start > gapsIter->second)
        {
            gapsIter++;
        }
        if (gapsIter == gaps.end() || readIter->end < gapsIter->first) {
            gff_out[readIter->start + 1] += seqName + "\t" + TOOL_NAME + "\tRead_cov\t" + toString(readIter->start + 1) + '\t' + toString(readIter->end + 1) + "\t.\t.\t.\tNote=Warning: Low read coverage;colour=8\n";
        }
    }
    errors_map.erase(READ_COV);

    // Pull out all the not-enough-perfect-coverage regions.  Don't include gaps
    if (ops.usePerfect)
    {
        list<pair<unsigned long, unsigned long > >::iterator gapsIter = gaps.begin();

        for (list<Error>::iterator perfIter = errors_map[PERFECT_COV].begin(); perfIter != errors_map[PERFECT_COV].end(); perfIter++)
        {
            while (gapsIter != gaps.end() && perfIter->start > gapsIter->second)
            {
                gapsIter++;
            }
            if (gapsIter == gaps.end() || perfIter->end < gapsIter->first) {
                gff_out[perfIter->start + 1] += seqName + "\t" + TOOL_NAME + "\tPerfect_cov\t" + toString(perfIter->start + 1) + '\t' + toString(perfIter->end + 1) + "\t.\t.\t.\tNote=Warning: Low perfect unique coverage;colour=9\n";
            }
        }
        errors_map.erase(PERFECT_COV);
    }

    // can't call a score over a gap, so set them all to -1
    list<pair<unsigned long, unsigned long> >::iterator gapIter;
    for (gapIter =  gaps.begin(); gapIter != gaps.end(); gapIter++)
    {
        for (unsigned long i = gapIter->first;  i <= gapIter->second; i++)
        {
            scores[i] = -1;
        }
    }

    // look for run of high scores
    ErrorWindow scoreWindow(1, 0, ops.minReportScore, ops.minScoreReportLength, ops.windowPercent, false, true);
    list<Error> scoreErrors;

    for (unsigned int i = 0; i< scores.size(); i++)
    {
        if (scoreWindow.fail())
        {
            Error err;
            err.start = scoreWindow.start();
            err.end = scoreWindow.end();
            err.type = 1;  // type is irrelevant here, we know it's a score failure
            updateErrorList(scoreErrors, err);
        }
        scoreWindow.add(i + 1, scores[i]);
    }


    // update the gff output with the bad score errors
    for (list<Error>::iterator p = scoreErrors.begin(); p != scoreErrors.end(); p++)
    {
        // not optimal, but get the max error in this window by going back to the scores vector
        float maxScore = 0;

        for (unsigned int i = p->start - 1; i < p->end - 1; i++)
        {
            maxScore = max(scores[i], maxScore);
        }
        gff_out[p->start + 1] += seqName + '\t' + TOOL_NAME + "\tLow_score\t" + toString(p->start + 1) + '\t' + toString(p->end + 1) + '\t' + toString(1 - maxScore) + "\t.\t.\tNote=Warning: Low score;colour=10\n";
    }

    scoreWindow.clear(1);
    scoreErrors.clear();

    // Pull out all the runs of not proper pair reads, looking for links to elsewhere in the genome.
    vector<short> indexes;
    indexes.push_back(READ_ORPHAN_F);
    indexes.push_back(READ_ISIZE_F);
    indexes.push_back(READ_BADORIENT_F);
    indexes.push_back(READ_ORPHAN_R);
    indexes.push_back(READ_ISIZE_R);
    indexes.push_back(READ_BADORIENT_R);
    list<pair<unsigned long, unsigned long> > links;


    for (unsigned long i = 0; i < indexes.size(); i++)
    {
        for (list<Error>::iterator p = errors_map[indexes[i]].begin(); p != errors_map[indexes[i]].end(); p++)
        {
            links.push_back(make_pair(p->start, p->end));
        }

        errors_map.erase(indexes[i]);
    }

    // sort the links and merge the overlaps
    links.sort();
    for (list<pair<unsigned long, unsigned long> >::iterator p = links.begin(); p != links.end(); p++)
    {
        list<pair<unsigned long, unsigned long> >::iterator nextLink = p;
        nextLink++;

        if (nextLink != links.end())
        {
            if (nextLink->first <= p->second)
            {
                p->second = nextLink->second;
                links.erase(nextLink);
            }
        }
    }

    // update the gff errors with the merge links, when we get a hit.
    // If no hit, then just report a warning of bad read orientation (as long as
    // it's not at a contig end)
    for (list<pair<unsigned long, unsigned long> >::iterator p = links.begin(); p != links.end(); p++)
    {
        unsigned long hitStart = 0;
        unsigned long hitEnd = 0;
        string hitName;

        bam2possibleLink(ops, seqName, p->first, p->second, hitName, hitStart, hitEnd, bamData);
        if (hitName.size() && !(hitName.compare(seqName) == 0 && p->first <= hitEnd + ops.maxInsert && hitStart <= p->second + ops.maxInsert))
        {
            gff_out[p->first + 1] += seqName + "\t" + TOOL_NAME + "\tLink\t" + toString(p->first + 1) + '\t' + toString(p->second + 1) + "\t.\t.\t.\tNote=Warning: Link " + hitName + ":" + toString(hitStart+1) + "-" + toString(hitEnd+1)  + ";colour=11\n";
        }
        else if (p->first > ops.outerInsertSize && p->second + ops.outerInsertSize < seqLength)
        {
            gff_out[p->first + 1] += seqName + "\t" + TOOL_NAME + "\tRead_orientation\t" + toString(p->first + 1) + '\t' + toString(p->second + 1)  + "\t.\t.\t.\tNote=Warning: Bad read orientation;colour=1\n";
        }
    }

    // we don't want to call an insert size failure next to a gap which is too long, since
    // we wouldn't expect proper fragmet coverage next to a gap which can't be spanned by read pairs.
    // So, get the coords of all the flanking regions of the long gaps
    list<pair< unsigned long, unsigned long> > longGapFlanks;
    longGapFlanks.push_back(make_pair(0, ops.outerInsertSize));

    for (gapIter = gaps.begin(); gapIter != gaps.end(); gapIter++)
    {
        if (gapIter->second - gapIter->first + 1 > ops.maxGap)
        {
            // add region to left of gap
            if (gapIter->first > 1)
            {
                unsigned long start = gapIter->first < ops.outerInsertSize ? 0 : gapIter->first - ops.outerInsertSize;
                unsigned long end = gapIter->first - 1;
                if (longGapFlanks.size() && longGapFlanks.back().second >= end)
                {
                    longGapFlanks.back().second = end;
                }
                else
                {
                    longGapFlanks.push_back(make_pair(start, end));
                }
            }

            // add region to right of gap
            unsigned long start = gapIter->second + 1;
            unsigned long end = min(gapIter->second + ops.outerInsertSize, seqLength - 1);
            longGapFlanks.push_back(make_pair(start, end));
        }
    }

    // add a fake bit to stop calls at the end of the sequnce
    if (longGapFlanks.back().first + ops.outerInsertSize > seqLength)
    {
        longGapFlanks.back().first = seqLength > ops.outerInsertSize ? seqLength - ops.outerInsertSize : 0;
    }

    if (longGapFlanks.back().second + ops.outerInsertSize > seqLength)
    {
        longGapFlanks.back().second = seqLength - 1;
    }
    else if (seqLength > ops.outerInsertSize)
    {
        longGapFlanks.push_back(make_pair(seqLength - ops.outerInsertSize, seqLength - 1));
    }

    // look for fragment coverage too low failures (check if over a gap or near contig end)
    gapIter = gaps.begin();
    list<pair< unsigned long, unsigned long> >::iterator gapFlankIter = longGapFlanks.begin();
    list<pair< unsigned long, unsigned long> > lowFragCovGaps; // keep track to stop calling insert dist error over low coverage gaps
    unsigned long gapExtra = 5;

    for (list<Error>::iterator p = errors_map[FRAG_COV].begin(); p != errors_map[FRAG_COV].end(); p++)
    {
        // update iterators so that they are not to the left of the current tri area error
        while (gapIter != gaps.end() && gapIter->second < p->start) gapIter++;
        while (gapFlankIter != longGapFlanks.end() && gapFlankIter->second < p->start) gapFlankIter++;

        // check we're not at a scaffold end
        if (p->end <= ops.outerInsertSize || p->start + ops.outerInsertSize > seqLength)
        {
            continue;
        }

        // if overlaps a gap that is short enough
        if (gapIter != gaps.end() && gapIter->first <= p->end && gapIter->second - gapIter->first + 1 <= ops.maxGap)
        {
            gff_out[p->start + 1] += seqName + "\t" + TOOL_NAME + "\tFrag_cov_gap\t" + toString(p->start + 1) + "\t" + toString(p->end + 1) + "\t" + toString(region2meanScore(ops, seqName, p->start + 1, p->end + 1, FRAG_COV)) +  "\t.\t.\tNote=Error: Fragment coverage too low over gap " + getNearbyGaps(p, gaps, gapIter)  + ";colour=12\n";
            if (p->start < gapExtra)
            {
                lowFragCovGaps.push_back(make_pair(0, p->end + gapExtra));
            }
            else
            {
                lowFragCovGaps.push_back(make_pair(p->start - gapExtra, p->end + gapExtra));
            }
        }
        // if this error doesn't overlap a gap and is not too near a large gap
        else if ( (gapIter == gaps.end() || gapIter->first > p->end) && (gapFlankIter == longGapFlanks.end() || gapFlankIter->first > p->end) )
        {
            gff_out[p->start + 1] += seqName + "\t" + TOOL_NAME + "\tFrag_cov\t" + toString(p->start + 1) + "\t" + toString(p->end + 1) + "\t" + toString(region2meanScore(ops, seqName, p->start + 1, p->end + 1, FRAG_COV)) + "\t.\t.\tNote=Error: Fragment coverage too low;color=15\n";
        }
    }

    // look for triangle plot failures (check if over a gap or near contig end)
    gapIter = gaps.begin();
    gapFlankIter = longGapFlanks.begin();
    list<pair< unsigned long, unsigned long> >::iterator gapLowCovIter = lowFragCovGaps.begin();

    for (list<Error>::iterator p = errors_map[FCD_ERR].begin(); p != errors_map[FCD_ERR].end(); p++)
    {
        // update iterators so that they are not to the left of the current tri area error
        while (gapIter != gaps.end() && gapIter->second < p->start) gapIter++;
        while (gapFlankIter != longGapFlanks.end() && gapFlankIter->second < p->start) gapFlankIter++;
        while (gapLowCovIter != lowFragCovGaps.end() && gapLowCovIter->second < p->start) gapLowCovIter++;

        // check if we're next to a gap that has already been called
        if (gapLowCovIter != lowFragCovGaps.end() && gapLowCovIter->first <= p->end)
        {
            continue;
        }

        // check we're not at a scaffold end
        if (p->end <= ops.outerInsertSize || p->start + ops.outerInsertSize > seqLength)
        {
            continue;
        }

        // if overlaps a gap that is short enough
        if (gapIter != gaps.end() && gapIter->first <= p->end && gapIter->second - gapIter->first + 1 <= ops.maxGap)
        {
            gff_out[p->start + 1] += seqName + "\t" + TOOL_NAME + "\tFCD_gap\t" + toString(p->start + 1) + "\t" + toString(p->end + 1) + "\t" + toString(region2meanScore(ops, seqName, p->start + 1, p->end + 1, FCD_ERR)) +  "\t.\t.\tNote=Error: FCD failure over gap " + getNearbyGaps(p, gaps, gapIter) + ";colour=16\n";
        }
        // if this error doesn't overlap a gap and is not too near a large gap
        else if ( (gapIter == gaps.end() || gapIter->first > p->end)  && (gapFlankIter == longGapFlanks.end() || gapFlankIter->first > p->end) )
        {
            gff_out[p->start + 1] += seqName + "\t" + TOOL_NAME + "\tFCD\t" + toString(p->start + 1) + "\t" + toString(p->end + 1) + "\t" + toString(region2meanScore(ops, seqName, p->start + 1, p->end + 1, FCD_ERR)) + "\t.\t.\tNote=Error: FCD failure;colour=17\n";
        }
    }

    // write the remaining scores to file
    while (scoreIndex < scores.size())
    {
        double s = scores[scoreIndex] == -1 ? -1 : 1 - scores[scoreIndex];
        cout << seqName << '\t' << scoreIndex + 1 << '\t' << s << '\n';
        scoreIndex++;
    }

    // write the gff lines
    for(map<unsigned long, string>::iterator p = gff_out.begin(); p != gff_out.end(); p++)
    {
        ops.ofs_breaks << p->second;
    }
    ops.ofs_breaks.flush();
}


void updateScoreHist(map<float, unsigned long>& hist, vector<float>& scores)
{
    for (vector<float>::iterator i = scores.begin(); i != scores.end(); i++)
    {
        hist[*i]++;
    }
}


bool compareErrors(const Error& e, const Error& f)
{
    return e.start < f.start;
}


void bam2possibleLink(CmdLineOptions& ops, string& refID, unsigned long start, unsigned long end, string& hitName, unsigned long& hitStart, unsigned long& hitEnd, BAMdata& bamData)
{
    BamAlignment bamAlign;
    map<string, list<unsigned long> > hitPositions;
    map<string, Histogram> histsBigBins;
    hitName = "";
    unsigned long readCount = 0;
    unsigned long readTotal = 0;
    unsigned long binWidth = (end - start + 2 * ops.maxInsert) / 2;

    // Set the region in the BAM file to be read
    if (bamData.header.Sequences.Contains(refID))
    {
        int id = bamData.bamReader.GetReferenceID(refID);
        if (!bamData.bamReader.SetRegion(id, start - 1, id, end - 1))
        {
            cerr << ERROR_PREFIX << "Error jumping to region " << refID << ":" << start << "-" << end << " in bam file" << endl;
            exit(1);
        }
    }
    else
    {
        cerr << ERROR_PREFIX << "Error. Sequence '" << refID << "' not found in bam file" << endl;
        exit(1);
    }
    // parse BAM, looking for hits in common
    while (bamData.bamReader.GetNextAlignmentCore(bamAlign))
    {
        readTotal++;
        if (!bamAlign.IsMapped() ||  bamAlign.IsDuplicate() ||  bamAlign.MapQuality < ops.minMapQuality)
        {
            continue;
        }

        short pairOrientation = getPairOrientation(bamAlign);

        // want paired reads where the mate is outside insert size range, or on a different chr
        if (pairOrientation == DIFF_CHROM // || pairOrientation == OUTTIE || pairOrientation == SAME
            || (pairOrientation == INNIE && (abs(bamAlign.InsertSize) < ops.minInsert || abs(bamAlign.InsertSize) > ops.maxInsert)))
        {
            string id = bamData.references[bamAlign.MateRefID].RefName;
            hitPositions[id].push_back(bamAlign.MatePosition);
            map<string, Histogram>::iterator p = histsBigBins.find(id);
            if (p == histsBigBins.end())
            {
                histsBigBins[id] = Histogram(binWidth);
            }
            histsBigBins[id].add(bamAlign.MatePosition, 1);
            readCount++;
        }
    }

    // work out if they mostly hit in the same place
    if (histsBigBins.size() == 0) return;

    string modeID;
    unsigned long maxModeVal = 0;
    unsigned long maxMode = 0;

    for (map<string, Histogram>::iterator p = histsBigBins.begin(); p != histsBigBins.end(); p++)
    {
        unsigned long modeVal;
        unsigned long mode = p->second.mode(modeVal);

        if (modeVal > maxModeVal)
        {
            maxModeVal = modeVal;
            maxMode = mode;
            modeID = p->first;
        }
    }

    // The big bins were half the width of our window of interest, so to get all
    // the hits, we need to check the bin either side of the mode
    unsigned long totalHits = maxModeVal;
    totalHits += histsBigBins[modeID].get(maxMode - binWidth);
    totalHits += histsBigBins[modeID].get(maxMode + binWidth);

    // get more accurate position of the hits
    if (1.0 * totalHits / readCount > 0.5)
    {
        unsigned long startCoord = binWidth > maxMode ? 0 : maxMode - binWidth;
        unsigned long endCoord = maxMode + binWidth;

        hitPositions[modeID].sort();
        list<unsigned long>::iterator  p = hitPositions[modeID].begin();
        while (p != hitPositions[modeID].end() && *p < startCoord)
        {
            p++;
        }
        if (p == hitPositions[modeID].end()) p--;
        hitStart = *p;
        p = hitPositions[modeID].end();
        p--;
        while (p != hitPositions[modeID].begin() && *p > endCoord)
        {
            p--;
        }
        hitEnd = *p;
        hitName = modeID;
    }
}

double region2meanScore(CmdLineOptions& ops, string& seqID, unsigned long start, unsigned long end, short column)
{
    Tabix tbx(ops.statsInfile);
    double total = 0;
    string line;
    vector<string> data;
    stringstream ss;
    ss << seqID << ':' << start << '-' << end;
    string region(ss.str());
    tbx.setRegion(region);

    while (tbx.getNextLine(line)) {
        split(line, '\t', data);
        total += atof(data[column].c_str());
    }

    return total / (end - start + 1);
}


string getNearbyGaps(list<Error>::iterator p, list<pair<unsigned long, unsigned long > >& gaps, list<pair<unsigned long, unsigned long > >::iterator gapIter)
{
    list<pair<unsigned long, unsigned long > >::iterator iter = gapIter;
    vector<unsigned long> v;

    while (iter->second >= p->start)
    {
        v.push_back(iter->first + 1);
        v.push_back(iter->second + 1);
        if (iter == gaps.begin())
        {
            break;
        }
        else
        {
            iter--;
        }
    }

    iter = gapIter;
    iter++;
    while (iter != gaps.end() && iter->first <= p->end)
    {
        v.push_back(iter->first + 1);
        v.push_back(iter->second + 1);
        iter++;
    }

    sort(v.begin(), v.end());

    stringstream ss;

    for (unsigned int i = 0; i < v.size(); i+=2)
    {
         ss << ',' << v[i] << '-' << v[i+1];
    }

    string s = ss.str();
    return s.size() ? s.substr(1) : "";
}

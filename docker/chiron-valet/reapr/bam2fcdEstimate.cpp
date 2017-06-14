#include <iostream>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

#include "utils.h"
#include "histogram.h"
#include "trianglePlot.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"

using namespace BamTools;
using namespace std;

const string ERROR_PREFIX = "[REAPR bam2fcdEstimate] ";

struct CmdLineOptions
{
    long maxInsert;
    unsigned long sampleStep;
    bool verbose;
    string bamInfile;
    string gapsInfile;
    string outfile;
    unsigned long maxSamples;
};


void initialiseFCDHists(vector<Histogram>& v, CmdLineOptions& ops);
void updateFCDHists(vector<Histogram>& hists, vector<double>& heights);

// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops);

int main(int argc, char* argv[])
{
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    BamReader bamReader;
    BamAlignment bamAlign;
    SamHeader header;
    RefVector references;
    TrianglePlot triplot(options.maxInsert);
    unsigned long histCounter = 0;
    int32_t currentRefID = -1;
    bool firstRecord = true;
    multiset<pair<unsigned long, unsigned long> > fragments;
    vector<Histogram> fcdLHS, fcdRHS;
    initialiseFCDHists(fcdLHS, options);
    initialiseFCDHists(fcdRHS, options);

    map<string, list<pair<unsigned long, unsigned long> > > globalGaps;
    loadGaps(options.gapsInfile, globalGaps);

    if (!bamReader.Open(options.bamInfile))
    {
        cerr << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();

    while (bamReader.GetNextAlignmentCore(bamAlign) && histCounter < options.maxSamples)
    {
        if (!bamAlign.IsMapped() || bamAlign.IsDuplicate()
             || bamAlign.InsertSize <= 0
             || bamAlign.InsertSize > options.maxInsert) continue;

        if (currentRefID != bamAlign.RefID)
        {
            if (firstRecord)
            {
                firstRecord = false;
            }
            else
            {
                triplot.clear(0);
                fragments.clear();
            }
            currentRefID = bamAlign.RefID;
        }
        while (bamAlign.Position > triplot.centreCoord())
        {
            triplot.add(fragments);
            if (triplot.depth() > 0)
            {
                vector<double> leftHeights;
                vector<double> rightHeights;
                triplot.getHeights(options.maxInsert, leftHeights, rightHeights);
                updateFCDHists(fcdLHS, leftHeights);
                updateFCDHists(fcdRHS, rightHeights);
                histCounter++;
                if (options.verbose && histCounter % 100 == 0)
                {
                    cerr << ERROR_PREFIX << "progress:" << histCounter << endl;
                }
            }
            triplot.shift(options.sampleStep);
        }


        short pairOrientation = getPairOrientation(bamAlign);

        if (pairOrientation == INNIE)
        {
            fragments.insert(fragments.end(), make_pair(bamAlign.Position, bamAlign.Position + bamAlign.InsertSize - 1));
        }
    }

    ofstream ofs(options.outfile.c_str());

    if (!ofs.good())
    {
        cerr << "Error opening file '" << options.outfile << "'" << endl;
        return 1;
    }

    ofs << "#position\theight" << endl;

    for (unsigned int i = 0; i < fcdLHS.size(); i++)
    {
        double leftMean, rightMean;
        double stddev;
        fcdLHS[i].meanAndStddev(leftMean, stddev);
        fcdRHS[i].meanAndStddev(rightMean, stddev);
        leftMean = (fcdLHS[i].size() == 0) ? 0 : 0.001 * (leftMean - 0.5);
        rightMean = (fcdRHS[i].size() == 0) ? 0 : 0.001 * (rightMean - 0.5);
        ofs << i << '\t' << 0.5 * (leftMean + rightMean) << endl;
    }


    ofs.close();
    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 4;
    int i;
    ops.sampleStep = 0;
    ops.verbose = false;
    ops.maxSamples = 100000;

    usage = "[options] <in.bam> <assembly.gaps.gz> <max insert size> <output file>\n\n\
options:\n\n\
-m <int>\n\tMaximum number of FCDs to analyse [100000]\n\
-s <int>\n\tSample every n^th base [max(insert_size / 2, 500)]\n\
";

    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        cerr << "usage:\nbam2insert " << usage;
        exit(1);
    }

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans  (there aren't any (yet...))
        if (strcmp(argv[i], "-v") == 0)
        {
            ops.verbose = true;
            continue;
        }

        // non booleans are of form -option value, so check
        // next value in array is there before using it!
        if (strcmp(argv[i], "-m") == 0)
        {
            ops.maxSamples = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-s") == 0)
        {
            ops.sampleStep = atoi(argv[i+1]);
        }
        else
        {
            cerr <<  "Error! Switch not recognised: " << argv[i] << endl;
            exit(1);
        }
        i++;
    }

    if (argc - i != requiredArgs || argv[i+1][0] == '-')
    {
        cerr << usage;
        exit(1);
    }

    ops.bamInfile = argv[i];
    ops.gapsInfile = argv[i+1];
    ops.maxInsert = atoi(argv[i+2]);
    ops.outfile = argv[i+3];
    if(ops.sampleStep == 0)
    {
        ops.sampleStep = max(ops.maxInsert / 2, (long) 500);
    }
}

void initialiseFCDHists(vector<Histogram>& v, CmdLineOptions& ops)
{
    for (unsigned long i = 0; i <= ops.maxInsert; i++)
    {
        v.push_back(Histogram(1));
    }
}



void updateFCDHists(vector<Histogram>& hists, vector<double>& heights)
{
    for (unsigned long i = 0; i < hists.size(); i++)
    {
        hists[i].add(1000 * heights[i], 1);
    }
}

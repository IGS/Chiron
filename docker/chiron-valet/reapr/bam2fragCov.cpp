#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <algorithm>
#include <iomanip>

#include "coveragePlot.h"
#include "utils.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"

using namespace BamTools;
using namespace std;


struct CmdLineOptions
{
    string bamInfile;
    long minInsert;
    long maxInsert;
    uint16_t minMapQuality;
    unsigned long sample;
};

void updateCovInfo(unsigned long pos, CoveragePlot& covPlot, multiset<pair<unsigned long, unsigned long> >& frags, vector<unsigned long>& covVals);

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
    int32_t currentRefID = -1;
    string currentRefIDstring = "";
    bool firstRecord = true;
    vector<unsigned long> fragCoverageVals;
    CoveragePlot fragCovPlot(options.maxInsert, 0);
    multiset<pair<unsigned long, unsigned long> > fragments; // fragment positions sorted by start position
    unsigned long baseCounter = 0;

    // Go through input bam file getting insert coverage
    if (!bamReader.Open(options.bamInfile))
    {
        cerr << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();

    while (bamReader.GetNextAlignmentCore(bamAlign))
    {
        if (!bamAlign.IsMapped()
              ||  bamAlign.IsDuplicate()
              ||  bamAlign.MapQuality < options.minMapQuality)
        {
            continue;
        }

        // Deal with the case when we find a new reference sequence in the bam
        if (currentRefID != bamAlign.RefID)
        {
            if (firstRecord)
            {
                firstRecord = false;
            }
            else
            {
                updateCovInfo(references[currentRefID].RefLength, fragCovPlot, fragments, fragCoverageVals);
                //printStats(options, currentRefIDstring, references[currentRefID].RefLength, stats, gaps);
                for (unsigned long i = 0; i < fragCoverageVals.size(); i++)
                {
                    cout << currentRefIDstring << '\t' << i + 1 << '\t' << fragCoverageVals[i] << '\n';
                    if (baseCounter > options.sample) return 0;
                    baseCounter++;
                }
            }

            currentRefID = bamAlign.RefID;
            currentRefIDstring = references[bamAlign.RefID].RefName;
            fragCovPlot = CoveragePlot(options.maxInsert, 0);
            fragments.clear();
            fragCoverageVals.clear();
        }

        short pairOrientation = getPairOrientation(bamAlign);
        updateCovInfo(bamAlign.Position, fragCovPlot, fragments, fragCoverageVals);

        // if correct orienation (but insert size could be good or bad)
        if (pairOrientation == INNIE)
        {
            // update fragment coverage. We only want
            // to count each fragment once: in a sorted bam the first appearance
            // of a fragment is when the insert size is positive
            if (options.minInsert <= bamAlign.InsertSize && bamAlign.InsertSize <= options.maxInsert)
            {
                int64_t fragStart = bamAlign.GetEndPosition() + 1;
                int64_t fragEnd = bamAlign.MatePosition - 1;
                if (fragStart <= fragEnd) fragments.insert(fragments.end(), make_pair(fragStart, fragEnd));
            }
        }
    }

    // print the remaining stats from the last ref sequence in the bam
    updateCovInfo(references[currentRefID].RefLength, fragCovPlot, fragments, fragCoverageVals);
    for (unsigned long i = 0; i < fragCoverageVals.size(); i++)
    {
        cout << currentRefIDstring << '\t' << i + 1 << '\t' << fragCoverageVals[i] << '\n';
        if (baseCounter > options.sample) return 0;
        baseCounter++;
    }

    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 3;
    int i;

    if (argc < requiredArgs)
    {
        cerr << "usage:\nbam2fragCov [options] <in.bam> <min insert> <max insert>\n\n\
Gets fragment coverage from a BAM file. Uses 'inner' fragments, i.e. the\n\
inner mate pair distance (or the fragment size, minus the length of reads)\n\
min/max insert should be cutoffs for the insert size.\n\
options:\n\n\
-s <int>\n\tNumber of bases to sample [2000000]\n\
";
        exit(1);
    }

    // set defaults
    ops.minMapQuality = 0;
    ops.sample = 1000000;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans

        // non booleans are of form -option value, so check
        // next value in array is there before using it!
        if (strcmp(argv[i], "-s") == 0)
        {
            ops.sample = atoi(argv[i+1]);
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
    ops.minInsert = atoi(argv[i+1]);
    ops.maxInsert = atoi(argv[i+2]);
}


void updateCovInfo(unsigned long pos, CoveragePlot& covPlot, multiset<pair<unsigned long, unsigned long> >& frags, vector<unsigned long>& covVals)
{
    for (unsigned long i = covVals.size(); i < pos; i++)
    {
        covPlot.increment();
        // add any new fragments to the coverage plot, if there are any
        while (frags.size() && frags.begin()->first == i)
        {
            covPlot.add(frags.begin()->second);
            frags.erase(frags.begin());
        }
        covVals.push_back(covPlot.depth());
    }
}


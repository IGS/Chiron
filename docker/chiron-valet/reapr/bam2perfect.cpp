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

#include "utils.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"
#include "api/BamWriter.h"

using namespace BamTools;
using namespace std;


struct CmdLineOptions
{
    string bamInfile;
    string outPrefix;
    long minInsert;
    long maxInsert;
    uint16_t maxRepetitiveQuality;
    uint16_t minPerfectQuality;
    unsigned long perfectAlignmentScore;
};


// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops);

// Writes alignments, up to the position endPos
void writeAlignments(multimap<unsigned long, BamAlignment>& alignments, BamWriter& bamWriterPerfect, unsigned long endPos);

int main(int argc, char* argv[])
{
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    BamReader bamReader;
    BamAlignment bamAlign;
    SamHeader header;
    RefVector references;
    int32_t currentRefID = -1;
    bool firstRecord = true;
    map<string, BamAlignment> perfectBamAlignments;
    multimap<unsigned long, BamAlignment> alignmentsToWritePerfect; // kept in reference pos order
    BamWriter bamWriterPerfect, bamWriterRepetitive;
    string perfectOut = options.outPrefix + ".perfect.bam";
    string repetitiveOut = options.outPrefix + ".repetitive.bam";

    if (!bamReader.Open(options.bamInfile))
    {
        cerr << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();
    bamWriterPerfect.Open(perfectOut, header, references);
    bamWriterRepetitive.Open(repetitiveOut, header, references);

    while (bamReader.GetNextAlignmentCore(bamAlign))
    {
        if (currentRefID != bamAlign.RefID)
        {
            if (firstRecord)
            {
                firstRecord = false;
            }
            else
            {
                writeAlignments(alignmentsToWritePerfect, bamWriterPerfect, references[currentRefID].RefLength);
                perfectBamAlignments.clear();
                alignmentsToWritePerfect.clear();
            }

            currentRefID = bamAlign.RefID;
        }

        if (bamAlign.IsMapped() && bamAlign.Position > 2 * options.maxInsert)
        {
            writeAlignments(alignmentsToWritePerfect, bamWriterPerfect, bamAlign.Position - 2 * options.maxInsert);
        }

        if (bamAlign.IsDuplicate()) continue;

        bamAlign.BuildCharData();
        bool alignmentIsPerfect = true;

        if (!bamAlign.IsMapped()
              || !bamAlign.IsMateMapped()
              || bamAlign.MapQuality < options.minPerfectQuality)
        {
            alignmentIsPerfect = false;
        }
        else
        {
            uint32_t alignmentScore;
            if (!bamAlign.GetTag("AS", alignmentScore))
            {
                cerr << "Read " << bamAlign.Name << " doesn't have an alignment score AS:...  Cannot continue" << endl;
                return(1);
            }
            if (alignmentScore < options.perfectAlignmentScore)
            {
                alignmentIsPerfect = false;
            }
            else
            {
                short pairOrientation = getPairOrientation(bamAlign);

                if (pairOrientation != INNIE
                        || options.minInsert > abs(bamAlign.InsertSize)
                        || abs(bamAlign.InsertSize) > options.maxInsert)
                {
                    alignmentIsPerfect = false;
                }
            }
        }

        multimap<string, BamAlignment>::iterator iter = perfectBamAlignments.find(bamAlign.Name);
        if (alignmentIsPerfect)
        {
            bamAlign.SetIsProperPair(1);
            if (iter == perfectBamAlignments.end())
            {
                perfectBamAlignments[bamAlign.Name] = bamAlign;
            }
            else
            {
                alignmentsToWritePerfect.insert(make_pair(iter->second.Position, iter->second));
                perfectBamAlignments.erase(iter);
                alignmentsToWritePerfect.insert(make_pair(bamAlign.Position, bamAlign));
            }
        }
        else
        {
            if (iter != perfectBamAlignments.end())
            {
                perfectBamAlignments.erase(iter);
            }
        }

        if (bamAlign.IsMapped() && bamAlign.MapQuality <= options.maxRepetitiveQuality)
        {
            bamWriterRepetitive.SaveAlignment(bamAlign);
        }
    }

    writeAlignments(alignmentsToWritePerfect, bamWriterPerfect, references[currentRefID].RefLength);

    bamWriterPerfect.Close();
    bamWriterRepetitive.Close();
    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 7;
    int i;

    if (argc < requiredArgs)
    {
        cerr << "usage:\nbam2fragCov [options] <in.bam> <out prefix> <min insert> <max insert> <repetitive qual max> <perfect qual min> <min alignment score>\n\n\
options:\n\n\
-q <int>\n\tMinimum mapping quality [10]\n\n\
Writes new BAM file contining only read pairs which:\n\
 - point towards each other\n\
 - are in the given insert size range\n\
 - both have at least the chosen mapping quality (set by -q)\n\
 - Have an alignment score >= the chosen value\n\n\
It ignores whether or not the reads are flagged as proper pairs.  All reads in the\n\
output BAM will be set to be proper pairs (0x0002)\n\
";
        exit(1);
    }

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // fill this in if options get added...
    }

    if (argc - i != requiredArgs || argv[i+1][0] == '-')
    {
        cerr << usage;
        exit(1);
    }

    ops.bamInfile = argv[i];
    ops.outPrefix = argv[i+1];
    ops.minInsert = atoi(argv[i+2]);
    ops.maxInsert = atoi(argv[i+3]);
    ops.maxRepetitiveQuality = atoi(argv[i+4]);
    ops.minPerfectQuality = atoi(argv[i+5]);
    ops.perfectAlignmentScore = atoi(argv[i+6]);
}


void writeAlignments(multimap<unsigned long, BamAlignment>& alignments, BamWriter& bamWriterPerfect, unsigned long endPos)
{
    set<unsigned long> toErase;

    for (map<unsigned long, BamAlignment>::iterator p = alignments.begin(); p != alignments.end(); p++)
    {
        if (p->second.Position >= endPos) break;
        bamWriterPerfect.SaveAlignment(p->second);
        toErase.insert(p->first);
    }

    for (set<unsigned long>::iterator p = toErase.begin(); p != toErase.end(); p++)
    {
        alignments.erase(*p);
    }

}


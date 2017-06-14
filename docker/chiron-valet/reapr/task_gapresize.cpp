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

#include "trianglePlot.h"
#include "utils.h"
#include "fasta.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"

using namespace BamTools;
using namespace std;

const string ERROR_PREFIX = "[REAPR gapresize] ";

struct CmdLineOptions
{
    string bamInfile;
    string assemblyInfile;
    string outprefix;
    unsigned long minGapToResize;
    unsigned long maxFragLength;
    unsigned long aveFragLength;
};


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
    string currentRefIDstring = "";

    Fasta fa;
    ifstream ifs(options.assemblyInfile.c_str());

    if (!ifs.good())
    {
        cerr << "Error opening file '" << options.assemblyInfile << "'" << endl;
        exit(1);
    }

    string info_outfile = options.outprefix + ".info";
    ofstream ofs_info(info_outfile.c_str());
    if (!ofs_info.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << info_outfile << "'" << endl;
        exit(1);
    }

    ofs_info << "#chr\toriginal_coords\toriginal_lgth\toriginal_fcd_err\tnew_coords\tnew_lgth\tnew_fcd_err\tfragment_depth" << endl;


    string fasta_outfile = options.outprefix + ".fasta";
    ofstream ofs_fasta(fasta_outfile.c_str());
    if (!ofs_fasta.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << fasta_outfile << "'" << endl;
        exit(1);
    }

    if (!bamReader.Open(options.bamInfile))
    {
        cerr << ERROR_PREFIX << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

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

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();
    TrianglePlot triplot(0);

    // Go through input fasta file, checking each gap in each sequence
    while (fa.fillFromFile(ifs))
    {
        long basesOffset = 0;
        list<pair<unsigned long, unsigned long> > gaps;
        fa.findGaps(gaps);

        for(list<pair<unsigned long, unsigned long> >::iterator gapIter = gaps.begin(); gapIter != gaps.end(); gapIter++)
        {
            // set the range of the bam reader.  We need fragments within max insert size of either end
            // of the gap, and spanning the gap.
            unsigned long rangeStart = gapIter->first <= options.maxFragLength ? 1 : gapIter->first - options.maxFragLength;
            int id = bamReader.GetReferenceID(fa.id);
            bamReader.SetRegion(id, rangeStart, id, gapIter->first);
            unsigned long oldGapLength = gapIter->second - gapIter->first + 1;
            triplot.clear(gapIter->first);
            bool considerThisGap = (gapIter->second - gapIter->first + 1 >= options.minGapToResize);

            if (considerThisGap)
            {
                // put all the fragments into the triangle plot
                while (bamReader.GetNextAlignmentCore(bamAlign))
                {
                    if (!bamAlign.IsMapped() || bamAlign.IsDuplicate())
                    {
                        continue;
                    }

                    short pairOrientation = getPairOrientation(bamAlign);
                    int64_t fragEnd = bamAlign.Position + bamAlign.InsertSize - 1;
                    if (!bamAlign.IsReverseStrand() && pairOrientation == INNIE && bamAlign.InsertSize > 0 && gapIter->second < fragEnd && fragEnd <= gapIter->second + options.maxFragLength)
                    {
                        pair<unsigned long, unsigned long> fragment(bamAlign.Position, fragEnd);
                        triplot.add(fragment);
                    }
                }
            }

            if (triplot.depth() > 0)
            {
                unsigned long bestGapLength = 0;
                double minimumError = -1;
                triplot.optimiseGap(options.maxFragLength, options.aveFragLength, gapIter->first, gapIter->second, bestGapLength, minimumError);
                unsigned long newGapStart = gapIter->first + basesOffset;
                unsigned long newGapEnd = newGapStart + bestGapLength;
                fa.seq.replace(gapIter->first + basesOffset, oldGapLength, bestGapLength, 'N');

                ofs_info << fa.id
                         << '\t' << gapIter->first + 1 << '-' << gapIter->second + 1
                         << '\t' << oldGapLength
                         << '\t' << triplot.areaError(options.maxFragLength, options.aveFragLength, true, gapIter->first, gapIter->second)
                         << '\t' << newGapStart + 1 << '-' << newGapEnd
                         << '\t' << bestGapLength
                         << '\t' << minimumError
                         << '\t' << triplot.depth()
                         << endl;

                basesOffset += bestGapLength;
                basesOffset -= oldGapLength;
            }
            else
            {
                unsigned long newGapStart = gapIter->first + basesOffset;
                unsigned long newGapEnd = gapIter->second + basesOffset;

                ofs_info << fa.id
                         << '\t' << gapIter->first + 1 << '-' << gapIter->second + 1
                         << '\t' << oldGapLength
                         << '\t' << '.'
                         << '\t' << newGapStart + 1 << '-' << newGapEnd + 1
                         << '\t' << newGapEnd - newGapStart + 1
                         << '\t' << '.';

                if (considerThisGap)
                    ofs_info << '\t' << triplot.depth() << endl;
                else
                    ofs_info << '\t' << '.' << endl;
            }
        }

        fa.print(ofs_fasta);
    }

    ifs.close();
    ofs_info.close();
    ofs_fasta.close();
    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 5;
    int i;
    ops.minGapToResize = 1;

    usage = "<assembly.fasta> <in.bam> <ave fragment length> <max fragment length> <prefix of outfiles>\n\n\
Options:\n\n\
-g <int>\n\tOnly consider gaps of at least this length [1]\n\n\
";

    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        cerr << "usage:\ntask_gapresize " << usage;
        exit(1);
    }

    for (i = 1; i < argc - requiredArgs; i++)
    {
        if (strcmp(argv[i], "-g") == 0)
        {
            ops.minGapToResize = atoi(argv[i+1]);;
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

    ops.assemblyInfile = argv[i];
    ops.bamInfile = argv[i+1];
    ops.aveFragLength = atoi(argv[i+2]);
    ops.maxFragLength = atoi(argv[i+3]);
    ops.outprefix = argv[i+4];
}


#include <iostream>
#include <cstring>
#include <fstream>
#include <string>

#include "utils.h"
#include "histogram.h"
#include "api/BamMultiReader.h"
#include "api/BamReader.h"

using namespace BamTools;
using namespace std;

struct CmdLineOptions
{
    unsigned int binWidth;
    long minInsert;
    long maxInsert;
    unsigned long sample;
    string bamInfile;
    string faiInfile;
    string outprefix;
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
    Histogram innies(options.binWidth);
    Histogram outies(options.binWidth);
    Histogram samies(options.binWidth);
    string out_stats = options.outprefix + ".stats.txt";
    unsigned long fragCounter = 0;
    vector<pair< string, unsigned long> > sequencesAndLengths;
    orderedSeqsFromFai(options.faiInfile, sequencesAndLengths);

    if (!bamReader.Open(options.bamInfile))
    {
        cerr << "Error opening bam file '" << options.bamInfile << "'" << endl;
        return 1;
    }

    header = bamReader.GetHeader();
    references = bamReader.GetReferenceData();

    for (vector<pair< string, unsigned long> >:: iterator iter = sequencesAndLengths.begin(); iter != sequencesAndLengths.end(); iter++)
    {
        int id = bamReader.GetReferenceID(iter->first);
        bamReader.SetRegion(id, 1, id, iter->second);

        while (bamReader.GetNextAlignmentCore(bamAlign))
        {
            if (!bamAlign.IsMapped() || bamAlign.IsDuplicate()
                    || bamAlign.InsertSize > options.maxInsert || bamAlign.InsertSize < options.minInsert) continue;

            short pairOrientation = getPairOrientation(bamAlign);

            fragCounter += options.sample ? 1 : 0;
            if (options.sample && fragCounter > options.sample) break;

            if (pairOrientation == DIFF_CHROM || pairOrientation == UNPAIRED) continue;
            if (bamAlign.MatePosition < bamAlign.GetEndPosition() || bamAlign.InsertSize <= 0)  continue;

            if (pairOrientation == SAME)
            {
                samies.add(bamAlign.InsertSize, 1);
            }
            else if (pairOrientation == INNIE)
            {
                innies.add(bamAlign.InsertSize, 1);
            }
            else if (pairOrientation == OUTTIE)
            {
                outies.add(bamAlign.InsertSize, 1);
            }
        }

        if (options.sample && fragCounter > options.sample) break;
    }

    // Make a plot of each histogram
    innies.plot(options.outprefix + ".in", "pdf", "Insert size", "Frequency");
    outies.plot(options.outprefix + ".out", "pdf", "Insert size", "Frequency");
    samies.plot(options.outprefix + ".same", "pdf", "Insert size", "Frequency");

    // print some stats for the innies
    ofstream ofs(out_stats.c_str());
    if (!ofs.good())
    {
        cerr << "Error opening file '" << out_stats << "'" << endl;
        return 1;
    }

    double mean, sd, pc1, pc99;
    unsigned long x;
    ofs.precision(0);
    fixed(ofs);
    innies.meanAndStddev(mean, sd);
    innies.endPercentiles(pc1, pc99);
    ofs << "mean\t" << mean << "\n"
        << "sd\t" << sd << "\n"
        << "mode\t" << innies.mode(x) << "\n"
        << "pc1\t" << pc1 << "\n"
        << "pc99\t" << pc99 << "\n";

    ofs.close();
    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 3;
    int i;

    usage = "[options] <in.bam> <assembly.fa.fai> <outfiles prefix>\n\n\
options:\n\n\
-b <int>\n\tBin width to use when making histograms [10]\n\
-m <int>\n\tMin insert size [0]\n\
-n <int>\n\tMax insert size [20000]\n\
-s <int>\n\tMax number of fragments to sample. Using -s N\n\
\twill take the first N fragments from the BAM file [no max]\n\
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

    // set defaults
    ops.binWidth = 10;
    ops.minInsert = 0;
    ops.maxInsert = 20000;
    ops.sample = 0;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans  (there aren't any (yet...))

        // non booleans are of form -option value, so check
        // next value in array is there before using it!
        if (strcmp(argv[i], "-b") == 0)
        {
            ops.binWidth = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-m") == 0)
        {
            ops.minInsert = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-n") == 0)
        {
            ops.maxInsert = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-s") == 0)
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
    ops.faiInfile = argv[i+1];
    ops.outprefix = argv[i+2];
}


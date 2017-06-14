#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstring>

#include "fasta.h"

using namespace std;


struct Stats
{
    double mean;
    unsigned long n50[9];
    unsigned long n50n[9];
    unsigned long longest;
    unsigned long shortest;
    unsigned long number;
    unsigned long totalLength;
    unsigned long nCount;
    unsigned long gapCount;
};


struct CmdLineOps
{
    unsigned long minLength;
    int infileStartIndex;
};


void parseOptions(int argc, char** argv, CmdLineOps& ops);
Stats file2stats(string filename, CmdLineOps& ops);

void print_stats(string fname, Stats& s);

int main(int argc, char* argv[])
{
    CmdLineOps ops;
    parseOptions(argc, argv, ops);
    bool first = true;

    for (int i = ops.infileStartIndex; i < argc; i++)
    {
        Stats s = file2stats(argv[i], ops);
        if (!first) cout << "-------------------------------" << endl;
        first = false;
        print_stats(argv[i], s);
    }

    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOps& ops)
{
    string usage;
    ops.minLength = 1;
    ops.infileStartIndex = 1;

    usage = "usage: stats [options] list of fasta files\n\n\
options:\n\
-l <int>\n\tMinimum length cutoff for each sequence [1]\n";

    if (argc < 2)
    {
        cerr << usage;
        exit(1);
    }

    while (argv[ops.infileStartIndex][0] == '-')
    {
        if (strcmp(argv[ops.infileStartIndex], "-l") == 0)
        {
            ops.minLength = atoi(argv[ops.infileStartIndex + 1]);
            ops.infileStartIndex += 2;
        }
        else
        {
            cerr << "error parsing options, somewhere around this: " << argv[ops.infileStartIndex] << endl;
            exit(1);
        }
    }
}


Stats file2stats(string filename, CmdLineOps& ops)
{
    Stats s;
    vector<unsigned long> seqLengths;
    unsigned long cumulativeLength = 0;
    ifstream ifs(filename.c_str());
    Fasta fa;

    if (!ifs.good())
    {
        cerr << "[n50] Error opening file '" << filename << "'" << endl;
        exit(1);
    }

    s.totalLength = 0;
    s.nCount = 0;
    s.gapCount = 0;

    while(fa.fillFromFile(ifs))
    {
        if (fa.length() >= ops.minLength)
        {
            unsigned long l = fa.length();
            seqLengths.push_back(l);
            s.totalLength += l;
            s.nCount += fa.nCount();
            s.gapCount += fa.getNumberOfGaps();
        }
    }

    ifs.close();

    for (unsigned long i = 0; i < 9; i++)
    {
        s.n50[i] = 0;
        s.n50n[i] = 0;
    }

    if (seqLengths.size() == 0)
    {
        s.longest = 0;
        s.shortest = 0;
        s.number = 0;
        s.mean = 0;
        s.totalLength = 0;
        return s;
    }

    sort(seqLengths.begin(), seqLengths.end());
    s.longest = seqLengths.back();
    s.shortest = seqLengths.front();
    s.number = seqLengths.size();
    s.mean = 1.0 * s.totalLength / s.number;

    unsigned long k = 0;

    for (unsigned long j = 0; j <  seqLengths.size(); j++)
    {
        unsigned long i = seqLengths.size() - 1 - j;
        cumulativeLength += seqLengths[i];

        while (k < 9 && cumulativeLength >= s.totalLength * 0.1 * (k + 1))
        {
            s.n50[k] = seqLengths[i];
            s.n50n[k] = seqLengths.size() - i;
            k++;
        }
    }

    return s;
}


void print_stats(string fname, Stats& s)
{
    cout.precision(2);

    cout << "filename\t" << fname << endl
         << "bases\t" << s.totalLength << endl
         << "sequences\t" << s.number << endl
         << "mean_length\t" << fixed << s.mean << endl
         << "longest\t" << s.longest << endl
         << "N50\t" << s.n50[4] << endl << "N50_n\t" << s.n50n[4] << endl
         << "N60\t" << s.n50[5] << endl << "N60_n\t" << s.n50n[5] << endl
         << "N70\t" << s.n50[6] << endl << "N70_n\t" << s.n50n[6] << endl
         << "N80\t" << s.n50[7] << endl << "N80_n\t" << s.n50n[7] << endl
         << "N90\t" << s.n50[8] << endl << "N90_n\t" << s.n50n[8] << endl
         << "N100\t" << s.shortest << endl << "N100_n\t" << s.number << endl
         << "gaps\t" << s.gapCount << endl
         << "gaps_bases\t" << s.nCount << endl;
}

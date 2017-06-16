#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <list>

#include "fasta.h"

using namespace std;

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        cerr << "usage:\nscaff2contig <in.fasta> [min length, default = 1]" << endl;
        exit(1);
    }

    Fasta fa;
    string infile = argv[1];
    unsigned long minLength = argc == 3 ? atoi(argv[2]) : 1;

    ifstream ifs(infile.c_str());

    if (!ifs.good())
    {
        cerr << "Error opening file '" << infile << "'" << endl;
        exit(1);
    }

    // for each sequence in the input file, find the gaps, print contigs
    while (fa.fillFromFile(ifs))
    {
        list<pair<unsigned long, unsigned long> > gaps;
        fa.findGaps(gaps);

        if (gaps.size() == 0)
        {
            fa.print(cout);
            continue;
        }

        unsigned long counter = 1;
        unsigned long previousGapEnd = 0;
        bool first = true;

        for(list<pair<unsigned long, unsigned long> >::iterator p = gaps.begin(); p != gaps.end(); p++)
        {
            unsigned long startCoord;

            if (first)
            {
                startCoord = 0;
                first = false;
            }
            else
            {
                startCoord = previousGapEnd + 1;
            }

            previousGapEnd = p->second;
            if (p->first - startCoord < minLength) continue;

            stringstream ss;
            ss << fa.id << "_" << counter << "_" << startCoord + 1 << "_" << p->first;
            string id = ss.str();
            string seq = fa.seq.substr(startCoord, p->first - startCoord);
            Fasta ctg(id, seq);
            ctg.print(cout);
            counter++;
        }

        unsigned long lastLength = fa.length() - gaps.back().second - 1;
        if (lastLength >= minLength)
        {
            stringstream ss;
            ss << fa.id << "_" << counter << "_" << gaps.back().second + 2 << "_" << fa.length();
            string id = ss.str();
            string seq = fa.seq.substr(gaps.back().second + 1, lastLength);
            Fasta ctg(id, seq);
            ctg.print(cout);
        }

    }

    ifs.close();
    return 0;
}


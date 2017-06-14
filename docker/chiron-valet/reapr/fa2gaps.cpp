#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <string>
#include <list>

#include "fasta.h"

using namespace std;

int main(int argc, char* argv[])
{
    if (argc != 2)
    {
        cerr << "usage:\nfa2gaps <in.fasta>" << endl;
        exit(1);
    }

    Fasta fa;
    string infile = argv[1];

    ifstream ifs(infile.c_str());

    if (!ifs.good())
    {
        cerr << "Error opening file '" << infile << "'" << endl;
        exit(1);
    }

    // for each sequence in the input file, print the gap locations
    while (fa.fillFromFile(ifs))
    {
        list<pair<unsigned long, unsigned long> > gaps;
        fa.findGaps(gaps);

        for(list<pair<unsigned long, unsigned long> >::iterator p = gaps.begin(); p != gaps.end(); p++)
        {
            cout << fa.id << '\t' << p->first + 1 << '\t' << p->second + 1 << '\n';
        }
    }

    ifs.close();
    return 0;
}


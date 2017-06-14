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

#include "fasta.h"

using namespace std;


struct CmdLineOptions
{
    unsigned long windowWidth;
    string fastaInfile;
};

// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops);


int main(int argc, char* argv[])
{
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    Fasta fa;
    ifstream ifs(options.fastaInfile.c_str());
    cout.precision(0);

    if (!ifs.good())
    {
        cerr << "Error opening file '" << options.fastaInfile << "'" << endl;
        exit(1);
    }

    // for each sequence in the input file, print
    // gc around each base
    while (fa.fillFromFile(ifs))
    {
        transform(fa.seq.begin(), fa.seq.end(), fa.seq.begin(), ::toupper);
        list<pair<unsigned long, unsigned long> > gaps;
        list<pair<unsigned long, unsigned long> > sections;

        fa.findGaps(gaps);
        unsigned long halfWindow = options.windowWidth / 2;
        list<pair<unsigned long, unsigned long> >::iterator gapsIter;

        if (gaps.empty())
        {
            sections.push_back(make_pair(0, fa.length() - 1));
        }
        else
        {
            unsigned long previousPos = 0;

            for (gapsIter = gaps.begin(); gapsIter != gaps.end(); gapsIter++)
            {
                sections.push_back(make_pair(previousPos, gapsIter->first - 1));
                previousPos = gapsIter->second + 1;
            }

            sections.push_back(make_pair(gaps.back().second + 1, fa.length() - 1));
        }

        gapsIter = gaps.begin();  // this will point at the gap immediately after the current section
                                  // in the following loop

        for (list<pair<unsigned long, unsigned long> >::iterator sectionIter  = sections.begin(); sectionIter != sections.end(); sectionIter++)
        {
            list<char> window;
            unsigned long window_size = 0; // keep track because list.size() is "up to linear", which seems to mean "linear".
            unsigned long gcCount = 0;
            unsigned long sectionLength = sectionIter->second - sectionIter->first + 1;
            double gc;

            // fill list up to window width (if section is not too short) and count the GC
            while (window_size <= options.windowWidth && window_size <= sectionLength)
            {
                window.push_back(fa.seq[window_size + sectionIter->first]);
                window_size++;
                gcCount += window.back() == 'G' || window.back() == 'C' ? 1 : 0;
            }

            gc = 100.0 * gcCount / window_size;

            if (sectionLength <= options.windowWidth)
            {
                for (unsigned long i = 0; i < sectionLength; i++)
                {
                    cout << fixed << fa.id << '\t' << sectionIter->first + i + 1 << '\t' << gc << '\n';
                }
            }
            else
            {
                // print the start: everything before half a window width
                for (unsigned long i = 0; i < halfWindow; i++)
                {
                    cout << fixed << fa.id << '\t' << sectionIter->first + i + 1 << '\t' << gc << '\n';
                }

                // print the middle part of the section
                for (unsigned long i = halfWindow; i + halfWindow < sectionLength; i++)
                {
                    window.push_back(fa.seq[sectionIter->first + i]);
                    gcCount += window.back() == 'G' || window.back() == 'C' ? 1 : 0;
                    gcCount -= window.front() == 'G' || window.front() == 'C' ? 1 : 0;
                    window.pop_front();
                    cout << fixed << fa.id << '\t' << sectionIter->first + i + 1 << '\t' << 100.0 * gcCount / window_size << '\n';
                }

                // print the end part of the section
                gc = 100.0 * gcCount / window_size;

                for (unsigned long i = halfWindow + 1; i < options.windowWidth; i++)
                {
                    cout << fixed << fa.id << '\t' << sectionIter->first + sectionLength - options.windowWidth + i + 1 << '\t' << gc << '\n';
                }
            }
            // do the GC over the next gap (if there is one)
            if (gapsIter != gaps.end())
            {
                unsigned long gapEnd = gapsIter->second;
                gapsIter++;

                // print the GC content over the gap
                for (unsigned long i = sectionIter->second + 1; i <= gapEnd; i++)
                {
                    cout << fixed << fa.id << '\t' << i + 1 << '\t' << 0 << '\n';

                }
            }

        }
    }

    ifs.close();

    return 0;
}


void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 1;
    int i;

    usage = "[options] <in.fasta>\n\n\
options:\n\n\
-w <int>\n\tWindow width around each base used to calculate GC content [101]\n\
";

    if (argc <= requiredArgs)
    {
        cerr << "usage:\nfa2gc " << usage;
        exit(1);
    }

    ops.windowWidth = 101;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        if (strcmp(argv[i], "-w") == 0)
        {
            ops.windowWidth = atoi(argv[i+1]);
        }
        else
        {
            cerr <<  "Error! Switch not recognised: " << argv[i] << endl;
            exit(1);
        }
        i++;
    }

    // round up window to nearest odd number
    ops.windowWidth += ops.windowWidth % 2 ? 0 : 1;

    ops.fastaInfile = argv[i];
}



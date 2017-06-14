#include <iostream>
#include <cstdlib>
#include <string>
#include <cstring>
#include <sstream>
#include <fstream>
#include <map>
#include <set>
#include <vector>
#include <assert.h>
#include "fasta.h"
#include "utils.h"
#include "tabix/tabix.hpp"

using namespace std;

const string ERROR_PREFIX = "[REAPR break] ";

string int2string(int number);

struct Breakpoint
{
    unsigned long start;
    unsigned long end;
    short type;
};

struct CmdLineOptions
{
    double minTriError;
    unsigned long minScaffLength;
    unsigned long minMainScaffLength;
    bool breakContigs;
    unsigned long breakContigsTrim;
    bool ignoreContigErrors;
    string fastaIn;
    string outprefix;
    string gff;
};

// deals with command line options: fills the options struct
void parseOptions(int argc, char** argv, CmdLineOptions& ops);

int main(int argc, char** argv)
{
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    Fasta seq;
    string line;
    map<string, set<pair<unsigned long, unsigned long> > > gapsToBreak;
    map<string, set<pair<unsigned long, unsigned long> > > badRegions;
    map<string, set<pair<unsigned long, unsigned long> > > contigBreakFlanks;
    ifstream inStream;
    ofstream outStreamFasta, outStreamBin;
    Tabix ti(options.gff);
    string fastaOut = options.outprefix + ".broken_assembly.fa";
    string binOut = options.outprefix + ".broken_assembly_bin.fa";
    vector<pair< string, unsigned long> > refLengths;
    string binPrefix = "REAPR_bin.";

    // For each chromosome, get an (ordered by coord) list of the gaps to be broken and the
    // sections to be replaced by Ns. Some of these regions can intersect.
    while (ti.getNextLine(line))
    {
        vector<string> v;
        split(line, '\t', v);
        string id = v[0];

        // we break when errors are called over a gap, replace with Ns when
        // error called in a contig (i.e. not over a gap)
        if (v[2].compare("Frag_cov_gap") == 0)
        {
            // scaffold19_size430204    REAPR   Frag_cov_gap    362796  363397  0.00166113  .   .   Note=Error: Fragment coverage too low over gap 363104-363113;colour=12
            vector<string> a,b,c;
            split(v.back(), ';', a);
            split(a[a.size() - 2], ' ', b);
            split(b.back(), ',', c);
            for (unsigned long i = 0; i < c.size(); i++)
            {
                vector<string> d;
                split(c[i], '-', d);
                unsigned long start = atoi(d[0].c_str()) - 1;
                unsigned long end = atoi(d[1].c_str()) - 1;
                gapsToBreak[id].insert(make_pair(start, end));
            }
        }
        else if (v[2].compare("FCD_gap") == 0 && atof(v[5].c_str()) >= options.minTriError)
        {
            // scaffold7_size612284 REAPR   FCD_gap 547103  553357  0.781932    .   .   Note=Error: FCD failure over gap 550388-550397,552547-552686;colour=16
            vector<string> a,b,c;
            split(v.back(), ';', a);
            split(a[a.size() - 2], ' ', b);
            split(b.back(), ',', c);
            for (unsigned long i = 0; i < c.size(); i++)
            {
                vector<string> d;
                split(c[i], '-', d);
                unsigned long start = atoi(d[0].c_str()) - 1;
                unsigned long end = atoi(d[1].c_str()) - 1;
                gapsToBreak[id].insert(make_pair(start, end));
            }
        }
        else if (!options.ignoreContigErrors &&
                  (v[2].compare("Frag_cov") == 0 || (v[2].compare("FCD") == 0 && atof(v[5].c_str()) >= options.minTriError)) )
        {
            // scaffold6_size716595 REAPR   Frag_cov    600296  601454  0   .   .   Note=Error: Fragment coverage too low;color=15
            unsigned long start = atoi(v[3].c_str()) - 1;
            unsigned long end = atoi(v[4].c_str()) - 1;
            if (options.breakContigs)
            {
                unsigned long middle = 0.5 * (start + end);
                gapsToBreak[id].insert(make_pair(middle, middle));
                if (options.breakContigsTrim)
                {
                    start = middle >= options.breakContigsTrim ? middle - options.breakContigsTrim : 0;
                    end = middle + options.breakContigsTrim;
                    contigBreakFlanks[id].insert(make_pair(start, end));
                }
            }
            else
            {
                badRegions[id].insert(make_pair(start, end));
            }
        }
    }



    // for each chromosome, the replace by Ns errors could intersect. Take the union of them each time two intersect
    for (map<string, set<pair<unsigned long, unsigned long> > >::iterator namesIter = badRegions.begin(); namesIter != badRegions.end(); namesIter++)
    {
        set<pair<unsigned long, unsigned long> > newRegions;

        for (set<pair<unsigned long, unsigned long> >::iterator posIter = namesIter->second.begin(); posIter != namesIter->second.end(); posIter++)
        {
            if (newRegions.size() == 0)
            {
                newRegions.insert(*posIter);
            }
            else
            {
                set<pair<unsigned long, unsigned long> >::iterator lastRegion = newRegions.end();
                lastRegion--;
                // if last region added intersects with the current region
                if (lastRegion->first <= posIter->second && posIter->first <= lastRegion->second)
                {
                    unsigned long start = min(lastRegion->first, posIter->first);
                    unsigned long end = max(lastRegion->second, posIter->second);
                    newRegions.erase(lastRegion);
                    newRegions.insert(make_pair(start, end));
                }
                else // no overlap
                {
                    newRegions.insert(*posIter);
                }
            }
        }

        badRegions[namesIter->first] = newRegions;
    }

    inStream.open(options.fastaIn.c_str());

    if (! inStream.is_open())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << options.fastaIn << "'" << endl;
        return 1;
    }

    outStreamFasta.open(fastaOut.c_str());

    if (! outStreamFasta.is_open())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << fastaOut << "'" << endl;
        return 1;
    }

    outStreamBin.open(binOut.c_str());

    if (! outStreamBin.is_open())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << binOut << "'" << endl;
        return 1;
    }
    // do the breaking
    while (seq.fillFromFile(inStream))
    {
        map<string, set<pair<unsigned long, unsigned long> > >::iterator gapsToBreakNamesIter = gapsToBreak.find(seq.id);
        map<string, set<pair<unsigned long, unsigned long> > >::iterator badRegionsNamesIter = badRegions.find(seq.id);
        map<string, set<pair<unsigned long, unsigned long> > >::iterator contigBreakFlanksIter = contigBreakFlanks.find(seq.id);

        // replace each region flanking a contig error with Ns. This is only
        // relevant if -a and -t were used.
        if (contigBreakFlanksIter != contigBreakFlanks.end())
        {
            for(set<pair<unsigned long, unsigned long> >::iterator p = contigBreakFlanksIter->second.begin(); p != contigBreakFlanksIter->second.end(); p++)
            {
                unsigned long start = p->first;
                unsigned long end = min(p->second, seq.length() - 1);
                seq.seq.replace(start, end - start + 1, end - start + 1, 'N');
            }
        }

        // replace the bad regions with Ns, write these sequences out to the "bin" assembly.
        // Each of these sequences is broken at any bad gaps flagged. (Sometimes the errors
        // over and not over a gap can overlap.)
        if (badRegionsNamesIter != badRegions.end())
        {
            set<pair<unsigned long, unsigned long> >::iterator gapsIter;
            if (gapsToBreakNamesIter != gapsToBreak.end())
            {
                gapsIter = gapsToBreakNamesIter->second.begin();
            }

            for (set<pair<unsigned long, unsigned long> >::iterator p = badRegionsNamesIter->second.begin(); p != badRegionsNamesIter->second.end(); p++)
            {
                vector<unsigned long> binRegions;
                binRegions.push_back(p->first);

                if (gapsToBreakNamesIter != gapsToBreak.end())
                {
                    while (gapsIter != gapsToBreakNamesIter->second.end() && gapsIter->second < p->first)
                    {
                        gapsIter++;
                    }

                    while (gapsIter != gapsToBreakNamesIter->second.end() && gapsIter->first <= p->second)
                    {
                        if (binRegions.size())
                        {
                            assert(binRegions.back() < gapsIter->first);
                        }
                        binRegions.push_back(max(p->first, gapsIter->first));
                        binRegions.push_back(min(gapsIter->second, p->second));
                        gapsIter++;
                    }
                }

                binRegions.push_back(p->second);

                for (unsigned long i = 0; i < binRegions.size(); i+= 2)
                {
                    Fasta contig = seq.subseq(binRegions[i], binRegions[i+1]);
                    stringstream ss;
                    unsigned long startBasesTrimmed, endBasesTrimmed;
                    contig.trimNs(startBasesTrimmed, endBasesTrimmed);
                    ss << binRegions[i] + 1 + startBasesTrimmed << '_' << binRegions[i+1] - endBasesTrimmed + 1;
                    contig.id = binPrefix + contig.id + "_" + ss.str();
                    if (contig.length() > options.minMainScaffLength)
                    {
                        contig.print(outStreamFasta, 60);
                    }
                    else if (contig.length() >= options.minScaffLength)
                    {
                        contig.print(outStreamBin, 60);
                    }
                }

                seq.seq.replace(p->first, p->second - p->first + 1, p->second - p->first + 1, 'N');
            }
        }

        // if there's no breaks to be made at gaps
        if (gapsToBreakNamesIter == gapsToBreak.end())
        {
            unsigned long startBasesTrimmed, endBasesTrimmed;
            seq.trimNs(startBasesTrimmed, endBasesTrimmed);

            if (startBasesTrimmed || endBasesTrimmed)
            {
                stringstream ss;
                ss << startBasesTrimmed + 1 << '_' << seq.length() - endBasesTrimmed - startBasesTrimmed;
                seq.id += "_" + ss.str();
                if (seq.length() >= options.minScaffLength)
                {
                    seq.print(outStreamFasta, 60);
                }
            }
            else
            {
                if (seq.length() >= options.minScaffLength)
                {
                    seq.print(outStreamFasta, 60);
                }
            }
        }
        else // gaps to be broken
        {
            set<pair<unsigned long, unsigned long> > contigCoords;
            vector<unsigned long> breakpoints;
            breakpoints.push_back(0);

            for (set<pair<unsigned long, unsigned long> >::iterator gapsIter = gapsToBreakNamesIter->second.begin(); gapsIter != gapsToBreakNamesIter->second.end(); gapsIter++)
            {
                if (breakpoints.size())
                {
                    assert(breakpoints.back() <= gapsIter->first);
                }

                breakpoints.push_back(gapsIter->first == 0 ? 0 : gapsIter->first - 1);
                breakpoints.push_back(gapsIter->second + 1);
            }

            breakpoints.push_back(seq.length() - 1);

            for (unsigned long i = 0; i < breakpoints.size(); i+= 2)
            {
                Fasta contig = seq.subseq(breakpoints[i], breakpoints[i+1]);
                stringstream ss;
                unsigned long startBasesTrimmed, endBasesTrimmed;
                contig.trimNs(startBasesTrimmed, endBasesTrimmed);
                ss << breakpoints[i] + 1 + startBasesTrimmed << '_' << breakpoints[i+1] - endBasesTrimmed + 1;
                contig.id += "_" + ss.str();
                if (contig.length() >= options.minScaffLength)
                {
                    contig.print(outStreamFasta, 60);
                }
            }
        }
    }

    inStream.close();
    outStreamFasta.close();
    outStreamBin.close();

    return 0;
}

void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 3;
    int i;
    usage = "\
where 'errors.gff.gz' is the errors gff file made when running score.\n\n\
Options:\n\
-a\n\tAgressive breaking: break contigs at any FCD or low_frag error, as\n\
\topposed to the default of replacing with Ns. Contigs are broken at the\n\
\tmidpoint of each error. Also see option -t. Incompatible with -b\n\
-b\n\tIgnore FCD and low fragment coverage errors that do not contain\n\
\ta gap (the default is to replace these with Ns). incompatible with -a\n\
-e <float>\n\tMinimum FCD error [0]\n\
-l <int>\n\tMinimum sequence length to output [100]\n\
-m <int>\n\tMax sequence length to write to the bin. Sequences longer\n\
\tthan this are written to the main assembly output. This is to stop\n\
\tlong stretches of sequence being lost [999]\n\
-t <int>\n\tWhen -a is used, use this option to specify how many bases\n\
\tare trimmed off the end of each new contig around a break.\n\
\t-t N means that, at an FCD error, a contig is broken at the middle\n\
\tcoordinate of the error, then N bases are\n\
\ttrimmed off each new contig end [0]\n\
";

    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        usage = "[options] <assembly.fa> <errors.gff.gz> <outfiles prefix>\n\n" + usage;
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        usage = "[options] <assembly.fa> <errors.gff.gz> <outfiles prefix>\n\n" + usage;
        cerr << "usage: task_break " << usage;
        exit(1);
    }

    ops.minTriError = 0;
    ops.minScaffLength = 100;
    ops.minMainScaffLength = 999;
    ops.breakContigs = false;
    ops.ignoreContigErrors = false;
    ops.breakContigsTrim = 0;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        if (strcmp(argv[i], "-a") == 0)
        {
            ops.breakContigs = true;
            continue;
        }
        if (strcmp(argv[i], "-b") == 0)
        {
            ops.ignoreContigErrors = true;
            continue;
        }

        if (strcmp(argv[i], "-e") == 0)
        {
            ops.minTriError = atof(argv[i+1]);
        }
        else if (strcmp(argv[i], "-l") == 0)
        {
            ops.minScaffLength = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-m") == 0)
        {
            ops.minMainScaffLength = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-t") == 0)
        {
            ops.breakContigsTrim = atoi(argv[i+1]);
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

    if (ops.ignoreContigErrors && ops.breakContigs)
    {
        cerr << ERROR_PREFIX << "Options -a and -b are incompatible. Cannot continue" << endl;
        exit(1);
    }

    if (ops.breakContigsTrim && !ops.breakContigs)
    {
        cerr << ERROR_PREFIX << "Warning: ignoring -t " << ops.breakContigsTrim << " because -a was not used" << endl;
    }

    ops.fastaIn = argv[i];
    ops.gff = argv[i+1];
    ops.outprefix = argv[i+2];
}


string int2string(int number)
{
    stringstream ss;
    ss << number;
    return ss.str();
}

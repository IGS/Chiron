#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>

#include "utils.h"
#include "histogram.h"
#include "tabix/tabix.hpp"

using namespace std;


struct CmdLineOptions
{
    string statsInfile;
    string preprocessDir;
    unsigned long windowWidth;
    unsigned long windowStep;
    unsigned long maxWindows;
    unsigned long windowPercentCutoff;
    unsigned long fragmentLength;
    bool debug;
    string  outprefix;
};

const short FCD_ERR_COLUMN = 20;
const string ERROR_PREFIX = "[REAPR fcdrate] ";

void parseOptions(int argc, char** argv, CmdLineOptions& options);

void getGradient(vector<double>& x, vector<double>& y, vector<double>& d1x, vector<double>& d1y);

void printVectors(string prefix, vector<double>& x, vector<double>& y);

string vector2Rstring(vector<double>& x);

unsigned long normalise(vector<double> & v);

unsigned long fragmentLengthFromFile(string fname);


int main(int argc, char* argv[])
{
    string line;
    CmdLineOptions options;
    parseOptions(argc, argv, options);
    Tabix ti(options.statsInfile);
    ti.getNextLine(line); // ignore the header line
    unsigned long windowCount = 0;
    list<double> fcdErrors;
    double maxCutoff = 5;
    unsigned long fcdAccuracy = 50;
    unsigned long stepCounter = 0;
    vector<unsigned long> fcdCutoffs(maxCutoff * fcdAccuracy + 1, 0);
    vector<pair< string, unsigned long> > sequencesAndLengths;
    orderedSeqsFromFai(options.preprocessDir + "/00.assembly.fa.fai", sequencesAndLengths);

    for (vector<pair< string, unsigned long> >:: iterator iter = sequencesAndLengths.begin(); iter != sequencesAndLengths.end() && iter->second > 2 * options.fragmentLength + options.windowWidth && windowCount < options.maxWindows ; iter++)
    {
        stringstream regionSS;
        regionSS << iter->first << ':' << options.fragmentLength << '-' << iter->second - options.fragmentLength;
        string region(regionSS.str());
        if (options.debug) cerr << regionSS.str() << endl;
        ti.setRegion(region);
        fcdErrors.clear();
        stepCounter = 0;

        while (ti.getNextLine(line) && windowCount < options.maxWindows)
        {
            string tmp;
            stringstream ss(line);


            for (short i = 0; i <= FCD_ERR_COLUMN; i++)
            {
                getline(ss, tmp, '\t');
            }

            double fcdError = atof(tmp.c_str());

            if (fcdError == -1)
            {
                fcdErrors.clear();
                stepCounter = 0;
            }
            else if (fcdErrors.size() < options.windowWidth)
            {
                fcdErrors.push_back(fcdError);
            }
            else
            {
                if (stepCounter < options.windowStep)
                {
                    fcdErrors.push_back(fcdError);
                    fcdErrors.pop_front();
                    stepCounter++;
                }

                if (stepCounter == options.windowStep)
                {
                    if (options.debug && windowCount %100 == 0)
                        cerr << "windowCount\t" << windowCount << endl;
                    vector<double> errs(fcdErrors.begin(), fcdErrors.end());
                    sort(errs.begin(), errs.end());
                    double ninetiethValue = min(maxCutoff, errs[errs.size() * options.windowPercentCutoff / 100]);
                    fcdCutoffs[ninetiethValue * fcdAccuracy]++;
                    windowCount++;
                    stepCounter = 0;
                }
            }

        }

    }

    vector<double> cumulativeErrorCountsXvals;
    vector<double> cumulativeErrorCountsYvals;

    unsigned long total = 0;

    for (unsigned long i = 0; i < fcdCutoffs.size(); i++)
    {
        cumulativeErrorCountsXvals.push_back(1.0 * i / fcdAccuracy);
        cumulativeErrorCountsYvals.push_back(1.0 * (windowCount - fcdCutoffs[i] - total) / windowCount);
        total += fcdCutoffs[i];
    }


    vector<double> cumulativeErrorCountsD1Xvals;
    vector<double> cumulativeErrorCountsD1Yvals;
    vector<double> cumulativeErrorCountsD2Xvals;
    vector<double> cumulativeErrorCountsD2Yvals;


    getGradient(cumulativeErrorCountsXvals, cumulativeErrorCountsYvals, cumulativeErrorCountsD1Xvals, cumulativeErrorCountsD1Yvals);
    unsigned long minValueIndexD1 = normalise(cumulativeErrorCountsD1Yvals);
    getGradient(cumulativeErrorCountsD1Xvals, cumulativeErrorCountsD1Yvals, cumulativeErrorCountsD2Xvals, cumulativeErrorCountsD2Yvals);
    normalise(cumulativeErrorCountsD2Yvals);

    unsigned long cutoffIndex;

    for (cutoffIndex = cumulativeErrorCountsD2Yvals.size(); cutoffIndex > max(minValueIndexD1,minValueIndexD1); cutoffIndex--)
    {
        if (cumulativeErrorCountsD1Yvals[cutoffIndex] < -0.05 && cumulativeErrorCountsD2Yvals[cutoffIndex] > 0.05)
        {
            cutoffIndex++;
            break;
        }
    }


    if (options.debug)
    {
        for (unsigned long i = 0; i < fcdCutoffs.size(); i++)
        {
            cout << "fcd\t" << 1.0 * i / fcdAccuracy << '\t' << fcdCutoffs[i] << endl;
        }
        printVectors("d0", cumulativeErrorCountsXvals, cumulativeErrorCountsYvals);
        printVectors("d1", cumulativeErrorCountsD1Xvals, cumulativeErrorCountsD1Yvals);
        printVectors("d2", cumulativeErrorCountsD2Xvals, cumulativeErrorCountsD2Yvals);
    }

    double fcdCutoff = 0.5 * (cumulativeErrorCountsD1Xvals[cutoffIndex] + cumulativeErrorCountsD1Xvals[cutoffIndex+1]);

    string outfile = options.outprefix + ".info.txt";
    ofstream ofs(outfile.c_str());
    if (!ofs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << outfile << "'" << endl;
        return 1;
    }

    ofs << "#fcd_cutoff\twindow_length\twindows_sampled\tpercent_cutoff" << endl
        << fcdCutoff << '\t'
        << options.windowWidth << '\t'
        << windowCount << '\t'
        << options.windowPercentCutoff << endl;
    ofs.close();

    outfile = options.outprefix + ".plot.R";
    ofs.open(outfile.c_str());
    if (!ofs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << outfile << "'" << endl;
        return 1;
    }

    ofs << "fcd_cutoff = " << fcdCutoff << endl
        << "x=" << vector2Rstring(cumulativeErrorCountsXvals) << endl
        << "y=" << vector2Rstring(cumulativeErrorCountsYvals) << endl
        << "xd1=" << vector2Rstring(cumulativeErrorCountsD1Xvals) << endl
        << "yd1=" << vector2Rstring(cumulativeErrorCountsD1Yvals) << endl
        << "xd2=" << vector2Rstring(cumulativeErrorCountsD2Xvals) << endl
        << "yd2=" << vector2Rstring(cumulativeErrorCountsD2Yvals) << endl
        << "pdf(\"" << options.outprefix + ".plot.pdf\")" << endl
        << "plot(x, y, xlab=\"FCD cutoff\", ylim=c(-1,1), xlim=c(0," << fcdCutoff + 0.5 << "), ylab=\"Proportion of failed windows\", type=\"l\")" << endl
        << "abline(v=fcd_cutoff, col=\"red\")" << endl
        << "lines(xd2, yd2, col=\"blue\", lty=2)" << endl
        << "lines(xd1, yd1, col=\"green\", lty=2)" << endl
        << "text(fcd_cutoff+0.02, 0.8, labels=c(paste(\"y =\", fcd_cutoff)), col=\"red\", adj=c(0,0))" << endl
        << "dev.off()" << endl;

    ofs.close();
    systemCall("R CMD BATCH --no-save " + outfile + " " + outfile + "out");
    return 0;
}



void parseOptions(int argc, char** argv, CmdLineOptions& ops)
{
    string usage;
    short requiredArgs = 3;
    int i;

    usage = "[options] <preprocess directory> <stats prefix> <prefix of outut files>\n\n\
where 'stats prefix' is output files prefix used when stats was run\n\n\
Options:\n\n\
-l <int>\n\tWindow length [insert_size / 2] (insert_size is taken to be\n\
\tsample_ave_fragment_length in the file global_stats.txt file made by stats)\n\
-p <int>\n\tPercent of bases in window > fcd cutoff to call as error [80]\n\
-s <int>\n\tStep length for window sampling [100]\n\
-w <int>\n\tMax number of windows to sample [100000]\n\
";

    if (argc == 2 && strcmp(argv[1], "--wrapperhelp") == 0)
    {
        cerr << usage << endl;
        exit(1);
    }
    else if (argc < requiredArgs)
    {
        cerr << "usage:\ntask_fcdrate " << usage;
        exit(1);
    }

    // set defaults
    ops.windowWidth = 0;
    ops.windowPercentCutoff = 80;
    ops.maxWindows = 100000;
    ops.windowStep = 100;
    ops.debug = false;

    for (i = 1; i < argc - requiredArgs; i++)
    {
        // deal with booleans
        if (strcmp(argv[i], "-d") == 0)
        {
            ops.debug = true;
            continue;
        }

        // non booleans are of form -option value, so check
        // next value in array is there before using it!
        if (strcmp(argv[i], "-l") == 0)
        {
            ops.windowWidth = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-p") == 0)
        {
            ops.windowPercentCutoff = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-s") == 0)
        {
            ops.windowStep = atoi(argv[i+1]);
        }
        else if (strcmp(argv[i], "-w") == 0)
        {
            ops.maxWindows = atoi(argv[i+1]);
        }
        else
        {
            cerr << ERROR_PREFIX <<  "Error! Switch not recognised: " << argv[i] << endl;
            exit(1);
        }
        i++;
    }

    if (argc - i != requiredArgs || argv[i+1][0] == '-')
    {
        cerr << usage;
        exit(1);
    }

    ops.preprocessDir = argv[i];
    string statsPrefix = argv[i+1];
    ops.outprefix = argv[i+2];
    ops.statsInfile = statsPrefix + ".per_base.gz";
    ops.fragmentLength = fragmentLengthFromFile(statsPrefix + ".global_stats.txt");

    if (ops.windowWidth == 0)
        ops.windowWidth = ops.fragmentLength > 1000 ? ops.fragmentLength / 2 :  ops.fragmentLength;
}


void getGradient(vector<double>& x, vector<double>& y, vector<double>& d1x, vector<double>& d1y)
{
    unsigned short pointSkip = 2;
    for (unsigned long i = 0; i < x.size() - pointSkip; i++)
    {
        d1x.push_back(0.5 * (x[i+pointSkip] + x[i]));
        d1y.push_back( (y[i+pointSkip] - y[i]) / (x[i+pointSkip] - x[i]) );
    }
}


string vector2Rstring(vector<double>& x)
{
    stringstream ss;
    ss << "c(";

    for (unsigned long i = 0; i < x.size(); i++)
    {
        ss << x[i] << ",";
    }

    string out = ss.str();
    return out.substr(0, out.size() - 1) + ")";
}


unsigned long normalise(vector<double> & v)
{
    unsigned long maxValueIndex = 0;

    for (unsigned long i = 1; i < v.size(); i++)
    {
        if ( abs(v[i]) > abs(v[maxValueIndex]) )
        {
            maxValueIndex = i;
        }
    }

    double scaleFactor = abs(1.0 / v[maxValueIndex]);

    for (unsigned long i = 0; i < v.size(); i++)
    {
        v[i] *= scaleFactor;
    }

    return maxValueIndex;
}


void printVectors(string prefix, vector<double>& x, vector<double>& y)
{
    for (unsigned long i = 0; i < x.size(); i++)
    {
        cout << prefix << '\t' << x[i] << '\t' << y[i] << endl;
    }
}

unsigned long fragmentLengthFromFile(string fname)
{
    ifstream ifs(fname.c_str());

    if (!ifs.good())
    {
        cerr << ERROR_PREFIX << "Error opening file '" << fname << "'" << endl;
        exit(1);
    }

    string line;

    while (getline(ifs, line))
    {
        vector<string> v;
        split(line, '\t', v);
        if (v[0].compare("sample_ave_fragment_length") == 0)
            return (unsigned long)atoi(v[1].c_str());
    }

    ifs.close();
    cerr << ERROR_PREFIX << "Error getting fragment length from file '" << fname << "'" << endl;
    exit(1);
}

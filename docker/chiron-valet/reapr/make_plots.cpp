#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <iostream>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <map>

using namespace std;

const short CHR = 0;
const short POS = 1;
const short PERFECT_COV = 2;
const short READ_F = 3;
const short READ_PROP_F = 4;
const short READ_ORPHAN_F = 5;
const short READ_ISIZE_F = 6;
const short READ_BADORIENT_F = 7;
const short READ_R = 8;
const short READ_PROP_R = 9;
const short READ_ORPHAN_R = 10;
const short READ_ISIZE_R = 11;
const short READ_BADORIENT_R = 12;
const short FRAG_COV = 13;
const short FRAG_COV_CORRECT = 14;
const short FCD_MEAN = 15;
const short CLIP_FL = 16;
const short CLIP_RL = 17;
const short CLIP_FR = 18;
const short CLIP_RR = 19;
const short FCD_ERR = 20;


int main(int argc, char* argv[])
{
    map<string, vector<short> > plots;
    map<string, ofstream*> plot_handles;
    bool firstLine = true;
    string line;
    string preout = argv[1];

    plots["read_cov"].push_back(READ_F);
    plots["read_cov"].push_back(READ_R);
    plots["frag_cov"].push_back(FRAG_COV);
    plots["frag_cov_cor"].push_back(FRAG_COV_CORRECT);
    plots["FCD_err"].push_back(FCD_ERR);

    plots["read_ratio_f"].push_back(READ_PROP_F);
    plots["read_ratio_f"].push_back(READ_ORPHAN_F);
    plots["read_ratio_f"].push_back(READ_ISIZE_F);
    plots["read_ratio_f"].push_back(READ_BADORIENT_F);

    plots["read_ratio_r"].push_back(READ_PROP_R);
    plots["read_ratio_r"].push_back(READ_ORPHAN_R);
    plots["read_ratio_r"].push_back(READ_ISIZE_R);
    plots["read_ratio_r"].push_back(READ_BADORIENT_R);

    plots["clip"].push_back(CLIP_FL);
    plots["clip"].push_back(CLIP_RL);
    plots["clip"].push_back(CLIP_FR);
    plots["clip"].push_back(CLIP_RR);

    while (getline(cin, line) && !cin.eof())
    {
        vector<string> data;
        string tmp;

        // split the line into a vector
        stringstream ss(line);
        data.clear();

        while(getline(ss, tmp, '\t'))
        {
            data.push_back(tmp);
        }

        // open all the files, if it's the first line of the file
        if (firstLine)
        {
            // check if need to make perfect read mapping plot file
            if (data[2].compare("-1")) plots["perfect_cov"].push_back(PERFECT_COV);

            // open the plot files
            for (map<string, vector<short> >::iterator p = plots.begin(); p != plots.end(); p++)
            {
                string fname = preout + "." + p->first + ".plot";
                plot_handles[p->first] = new ofstream(fname.c_str());

                if (! plot_handles[p->first]->good())
                {
                    cerr << "Error opening file " << fname << endl;
                    return 1;
                }
            }

            firstLine = false;
        }

        // write data to output files
        for (map<string, vector<short> >::iterator p = plots.begin(); p != plots.end(); p++)
        {
            *(plot_handles[p->first]) << data[0] << '\t' << data[1] << '\t' << data[p->second.front()];

            for (vector<short>::iterator i = p->second.begin() + 1; i < p->second.end(); i++)
            {
                *plot_handles[p->first] << "\t" + data[*i];
            }

            *plot_handles[p->first] << "\n";
        }
    }

    // close the plot files
    for (map<string, vector<short> >::iterator p = plots.begin(); p != plots.end(); p++)
    {
        plot_handles[p->first]->close();
    }

    return 0;
}


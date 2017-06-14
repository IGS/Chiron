#include "utils.h"


short getPairOrientation(BamAlignment& al, bool reverse)
{
    if (!(al.IsPaired() && al.IsMapped() && al.IsMateMapped()))
    {
        return UNPAIRED;
    }
    else if (al.RefID != al.MateRefID)
    {
        return DIFF_CHROM;
    }
    else if (al.IsReverseStrand() == al.IsMateReverseStrand())
    {
        return SAME;
    }
    else if ((al.Position <= al.MatePosition) == al.IsMateReverseStrand())
    {
        return reverse ? OUTTIE : INNIE;
    }
    else if ((al.Position > al.MatePosition) == al.IsMateReverseStrand())
    {
        return reverse ? INNIE : OUTTIE;
    }
    // logically impossible for this to happen...
    else
    {
        cerr << "Unexpected error in getPairOrientation().  Aborting." << endl;
        exit(1);
    }
}


void loadGaps(string fname, map<string, list<pair<unsigned long, unsigned long > > >& gaps)
{
    Tabix ti(fname);
    string line;

    while (ti.getNextLine(line))
    {
        vector<string> data;
        split(line, '\t', data);
        gaps[data[0]].push_back( make_pair(atoi(data[1].c_str()) - 1, atoi(data[2].c_str()) - 1) );
    }
}


void split(const string &s, char delim, vector<string> &elems)
{
    stringstream ss(s);
    string item;
    elems.clear();

    while(getline(ss, item, delim))
    {
        elems.push_back(item);
    }
}


void systemCall(string cmd)
{
    if (system(NULL))
    {
        int retcode = system(cmd.c_str());

        if (retcode)
        {
            cerr << "Error in system call. Error code=" << retcode << ".  Command was:"
                << endl << cmd << endl;
            exit(1);
        }
    }
    else
    {
        cerr << "Error in system call.  Shell not available" << endl;
        exit(1);
    }
}


bool sortByLength(const pair< string, unsigned long>& p1, const pair< string, unsigned long>& p2)
{
    return p1.second > p2.second;
}


void orderedSeqsFromFai(string faiFile, vector<pair< string, unsigned long> >& seqs)
{
    ifstream ifs(faiFile.c_str());
    if (!ifs.good())
    {
        cerr << "Error opening file '" << faiFile << "'" << endl;
        exit(1);
    }

    string line;

    while (getline(ifs, line))
    {
        vector<string> tmp;
        split(line, '\t', tmp);
        seqs.push_back(make_pair(tmp[0], atoi(tmp[1].c_str())));
    }

    ifs.close();
    sort(seqs.begin(), seqs.end(), sortByLength);
}


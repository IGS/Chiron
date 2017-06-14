#include "fasta.h"

Fasta::Fasta() : id(""), seq("") {}
Fasta::Fasta(string& name, string& s) : id(name), seq(s) {}


void Fasta::print(ostream& outStream, unsigned int lineWidth) const
{
    if (lineWidth == 0)
    {
        outStream << ">" << id << endl << seq << endl;
    }
    else
    {
        outStream << ">" << id << endl;

        for (unsigned int i = 0; i < length(); i += lineWidth)
        {
            outStream << seq.substr(i, lineWidth) << endl;
        }
    }
}


Fasta Fasta::subseq(unsigned long start, unsigned long end)
{
    Fasta fa;
    fa.id = id;
    fa.seq = seq.substr(start, end - start + 1);
    return fa;
}


unsigned long Fasta::length() const
{
    return seq.length();
}


void Fasta::findGaps(list<pair<unsigned long, unsigned long> >& lIn)
{
    unsigned long pos = seq.find_first_of("nN");
    lIn.clear();

    while (pos != string::npos)
    {
        unsigned long start = pos;
        pos = seq.find_first_not_of("nN", pos);
        if (pos == string::npos)
        {
            lIn.push_back(make_pair(start, seq.length() - 1));
        }
        else
        {
            lIn.push_back(make_pair(start, pos - 1));
            pos = seq.find_first_of("nN", pos);
        }
    }
}

unsigned long Fasta::getNumberOfGaps()
{
    list<pair<unsigned long, unsigned long> > gaps;
    findGaps(gaps);
    return gaps.size();
}

bool Fasta::fillFromFile(istream& inStream)
{
    string line;
    seq = "";
    id = "";
    getline(inStream, line);

    // check if we're at the end of the file
    if (inStream.eof())
    {
        return false;
    }
    // Expecting a header line.  If not, abort
    else if (line[0] == '>')
    {
        id = line.substr(1);
    }
    else
    {
        cerr << "Error reading fasta file!" << endl
             << "Expected line starting with '>', but got this:" << endl
             << line << endl;
         exit(1);
    }

    // Next lines should be sequence, up to next header, or end of file
    while ((inStream.peek() != '>') && (!inStream.eof()))
    {
        getline(inStream, line);
        seq += line;
    }

    return true;
}


unsigned long Fasta::nCount()
{
    return count(seq.begin(), seq.end(), 'n') + count(seq.begin(), seq.end(), 'N');
}


void Fasta::trimNs(unsigned long& startBases, unsigned long& endBases)
{
    list<pair<unsigned long, unsigned long> > gaps;
    findGaps(gaps);
    startBases = endBases = 0;
    if (gaps.size())
    {
        if (gaps.back().second == length() - 1)
        {
           endBases = gaps.back().second - gaps.back().first + 1;
           seq.resize(gaps.back().first);
        }

        if (gaps.front().first == 0)
        {
            startBases = gaps.front().second + 1;
            seq.erase(0, startBases);
        }
    }
}



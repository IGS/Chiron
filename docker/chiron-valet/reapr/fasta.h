#ifndef FASTA_H
#define FASTA_H

#include <iostream>
#include <string>
#include <fstream>
#include <algorithm>
#include <list>


using namespace std;

class Fasta
{
public:
    Fasta();
    Fasta(string& name, string& s);

    // prints the sequence to outStream, with lineWidth bases on each
    // line.  If lineWidth = 0, no linebreaks are printed in the sequence.
    void print(ostream& outStream, unsigned int lineWidth = 60) const;

    // returns number of bases in sequence
    unsigned long length() const;

    // returns a new fasta object which is subseq of the original.
    // ID will be same as original
    Fasta subseq(unsigned long start, unsigned long end);

    // fills vector with (start, end) positions of each gap in the sequence
    void findGaps(list<pair<unsigned long, unsigned long> >& lIn);

    unsigned long getNumberOfGaps();

    // reads next sequence from file, filling contents appropriately
    // Returns true if worked ok, false if at end of file
    bool fillFromFile(istream& inStream);

    // Returns the number of 'N' + 'n' in the sequence
    unsigned long nCount();

    // Removes any Ns off the start/end of the sequence. Sets startBases and endBases to number
    // of bases trimmed off each end
    void trimNs(unsigned long& startBases, unsigned long& endBases);

    string id;
    string seq;
};

#endif // FASTA_H

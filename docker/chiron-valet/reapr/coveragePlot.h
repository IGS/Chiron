#ifndef COVERAGEPLOT_H
#define COVERAGEPLOT_H

#include <deque>


using namespace std;


class CoveragePlot
{
public:
    // construct a coverage plot, with max read length n and position pos
    CoveragePlot();
    CoveragePlot(unsigned long n, unsigned long pos);

    // move the coord of the plot 1 base to the right
    void increment();

    // returns the coverage at the current base
    unsigned long depth();

    // return the zero element depth
    unsigned long front();

    // add a read that ends at position n
    void add(unsigned long n);

    // returns the position of the plot
    unsigned long position();

private:
    unsigned long coord_;
    unsigned long depth_;
    deque<unsigned long> depthDiff_;
};

#endif // COVERAGEPLOT

#ifndef TRIANGLEPLOT_H
#define TRIANGLEPLOT_H

#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <map>
#include <algorithm>
#include <set>
#include <vector>
#include <cmath>

#include "utils.h"

using namespace std;

class TrianglePlot
{
public:
    // construct a triangle plot, centred at the given position
    TrianglePlot(unsigned long centreCoord = 0);

    // move the centre of the plot to the right n bases
    void shift(unsigned long n);

    // move the centre to the given position
    void move(unsigned long n);

    // Updates the plot, by adding the given fragment at <start, end>, if that
    // fragment covers the centre of the plot.
    // Returns true iff the fragment could be added.
    bool add(pair<unsigned long, unsigned long>& fragment);

    // adds all possible fragments from the set to the plot.
    // Each fragment that is added gets deleted from the list
    void add(multiset<pair<unsigned long, unsigned long> >& frags);

    // Returns the mean of the plot.  Returns zero if the plot has no fragments - you
    // can check this with a call to depth().
    double mean();

    // returns the centre position of the plot
    unsigned long centreCoord();

    // returns the depth of the plot, i.e. number of fragments covering its position
    unsigned long depth();

    // returns the mean fragment length
    double meanFragLength();

    // empties the plot and sets the centre coord to n
    void clear(unsigned long n = 0);

    // Returns the y values of the plot in the form:
    // y1 y2 ...
    // y values are space separated.  So if maxInsert was 5, would have 11 values
    // for plot (for x an int in [-5,5]), e.g:
    //        0 1 2 2 2 3 3 2 0 0 0
    string toString(unsigned long maxInsert);

    void getHeights(unsigned long maxInsert, vector<double>& leftHeights, vector<double>& rightHeights);

    double areaError(unsigned long maxInsert, unsigned long meanInsert, bool gapCorrect = false, unsigned long gapStart = 0, unsigned long gapEnd = 0);

    void optimiseGap(unsigned long maxInsert, unsigned long meanInsert, unsigned long gapStart, unsigned long gapEnd, unsigned long& bestGapLength, double& bestError);


private:
    unsigned long totalDepth_;
    long depthSum_;
    unsigned long centreCoord_;
    unsigned long totalFragLength_;

    struct fragcomp
    {
        bool operator() (const pair<unsigned long, unsigned long>& i, const pair<unsigned long, unsigned long>& j) const
        {
           return i.second < j.second;
        }
    };

    // stores fragments sorted by end position, coords zero-based relative to the genome, not this plot
    multiset< pair<unsigned long, unsigned long>, fragcomp> fragments_;

    // returns the theoretical height of a triangle plot at 'position', a gap from 'gapStart' to 'gapEnd'
    double getTheoryHeight(unsigned long gapStart, unsigned long gapEnd, unsigned long position, unsigned long meanInsert);

    // compare a pair by their second elements
    bool comparePairBySecond(pair<unsigned long, unsigned long>& first, pair<unsigned long, unsigned long>& second);
};

#endif // TRIANGLEPLOT

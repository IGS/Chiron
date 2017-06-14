#ifndef HISTOGRAM_H
#define HISTOGRAM_H

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <map>
#include <string>
#include <cmath>
#include <vector>
#include <ctype.h>
#include "utils.h"

using namespace std;

class Histogram
{
public:
    // Construct a histogram with the given bin width
    Histogram(unsigned int bin = 50);

    // picks a value at random from the histogram
    unsigned long sample();

    // adds count to the bin which value falls into
    void add(unsigned long val, unsigned long count);

    // clears the histogram
    void clear();

    // returns true iff the histogram is empty
    bool empty();

    // returns the bin width of the histogram
    unsigned int binWidth();

    // get value of the bin which position falls into
    unsigned long get(long pos);

    // returns a count of the numbers in the histogram
    // (i.e. sum of size of each bin)
    unsigned long size();

    // returns the mode of the histogram (returns zero if the histogram
    // is empty, so check if it's empty first!)
    // 'val' will be set to the value at the mode
    double mode(unsigned long& val);

    // returns the mode value within one standard deviation of the mean
    double modeNearMean();

    // gets the mean and standard deviation (does nothing if the histogram is empty)
    void meanAndStddev(double& mean, double& stddev);

    // gets the first and last percentiles
    void endPercentiles(double& first, double& last);


    // p in [0,1]
    double leftPercentile(double p);

    double minimumBin();

    // trim determines the x range when plotting, which will be [mode - trim * stddev, mode + trim * stddev]
    void setPlotOptionTrim(double trim);

    // when plotting, divide every x value by this number (default is to do no dividing).
    // This is handy when using a Histogram store non-integers (rounded a bit, obviously)
    void setPlotOptionXdivide(double divisor);

    // When plotting, default is to use middle of each bin as the x coords.
    // Set this to use the left of the bin instead
    void setPlotOptionUseLeftOfBins(bool useLeft);

    //  When plotting, add in a vertical dashed red line at the given value
    void setPlotOptionAddVline(double d);

    // make a plot of the histogram.  file extension 'ext' must be pdf or png
    // xlabel, ylabel = labels for x and y axes respectively. plotExtra is added
    // to tha call to plot in R
    void plot(string outprefix, string ext, string xlabel, string ylabel);

    // write data to file, tab-delimited per line: bin count.
    // offset is amount to add to x (bin) values.  -1 means
    // add 1/2 bin width.
    void writeToFile(string fname, double offset, double xMultiplier);

    map<unsigned long, unsigned long>::const_iterator begin();
    map<unsigned long, unsigned long>::const_iterator end();

private:
    unsigned int binWidth_;
    map<unsigned long, unsigned long> bins_;
    vector<unsigned long> reverseCDF_;
    bool plotLabelXcoordsLeftBin_;
    double plotXdivide_;
    double plotTrim_;
    vector<double> plotVlines_;
};

#endif // HISTOGRAM_H

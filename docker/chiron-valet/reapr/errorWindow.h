#ifndef ERRORWINDOW_H
#define ERRORWINDOW_H

#include <deque>

using namespace std;

class ErrorWindow
{
public:
    // set everything to zero
    ErrorWindow();

    // construct an error window, with max read length n and position pos
    ErrorWindow(unsigned long coord, double min, double max, unsigned long minLength, double minPC, bool useMin, bool useMax);

    void clear(unsigned long start);  // resets to the given position

    unsigned long start(); // returns start position of window
    unsigned long end();   // returns end position of window

    bool fail(); // returns true iff window is bad

    bool lastFail(); // returns true iff last element added failed the test

    // add a number to the end of the window
    void add(unsigned long pos, double val);

private:
    unsigned long coord_;
    double min_, max_;            // values in [min_, max_] are OK
    unsigned long minLength_;   // min length of window to consider
    double minPC_;       // min % of positions to be failures across min length of window
    bool useMin_, useMax_;
    deque<bool> passOrFail_; // 1 == fail
    deque<unsigned long> failCoords_;

};

#endif // ERRORWINDOW

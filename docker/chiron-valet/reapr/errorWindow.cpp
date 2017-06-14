#include "errorWindow.h"


ErrorWindow::ErrorWindow() {}

ErrorWindow::ErrorWindow(unsigned long coord, double min, double max, unsigned long minLength, double minPC, bool useMin, bool useMax) : coord_(coord), min_(min), max_(max), minLength_(minLength), minPC_(minPC), useMin_(useMin), useMax_(useMax) {}


void ErrorWindow::clear(unsigned long coord)
{
    coord_ = coord;
    passOrFail_.clear();
    failCoords_.clear();
}

unsigned long ErrorWindow::start()
{
    return failCoords_.size() ? failCoords_.front() : coord_;
}

unsigned long ErrorWindow::end()
{
    return failCoords_.size() ? failCoords_.back() : coord_;
}

bool ErrorWindow::fail()
{
    unsigned long size = end() - start() + 1;
    return size >= minLength_ && 1.0 * failCoords_.size() / size >= minPC_;
}


bool ErrorWindow::lastFail()
{
    return passOrFail_.size() && passOrFail_.back();
}

void ErrorWindow::add(unsigned long pos, double val)
{
    if ( (useMin_ && val < min_) || (useMax_ && val > max_) )
    {
        failCoords_.push_back(pos);
        passOrFail_.push_back(true);
    }
    else
    {
        passOrFail_.push_back(false);
    }

    if (passOrFail_.size() > minLength_)
    {
        if (passOrFail_.front())
        {
            failCoords_.pop_front();
        }
        passOrFail_.pop_front();
        coord_++;
    }
}



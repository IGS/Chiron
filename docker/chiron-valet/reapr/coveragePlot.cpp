#include "coveragePlot.h"

CoveragePlot::CoveragePlot()
{
    CoveragePlot(0, 0);
}

CoveragePlot::CoveragePlot(unsigned long n, unsigned long pos) : coord_(pos), depth_(0)
{
    depthDiff_ = deque<unsigned long>(n + 1, 0);
}


void CoveragePlot::increment()
{
    coord_++;
    depth_ -= depthDiff_[0];
    depthDiff_.pop_front();
    depthDiff_.push_back(0);
}

unsigned long CoveragePlot::depth()
{
    return depth_;
}


unsigned long CoveragePlot::front()
{
    return depthDiff_[0];
}


void CoveragePlot::add(unsigned long n)
{
    depth_++;
    depthDiff_[n - coord_ + 1]++;
}


unsigned long CoveragePlot::position()
{
    return coord_;
}


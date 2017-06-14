#include "trianglePlot.h"


TrianglePlot::TrianglePlot(unsigned long centreCoord) : totalDepth_(0), depthSum_(0), centreCoord_(centreCoord), totalFragLength_(0) {}


void TrianglePlot::shift(unsigned long n)
{
    // total depth is unchanged.
    centreCoord_ += n;
    depthSum_ -= n * totalDepth_;

    // remove fragments which end before the new centre position
    while (fragments_.size())
    {
        multiset< pair<unsigned long, unsigned long> >::iterator p = fragments_.begin();

        // remove this coord, if necessary
        if (p->second < centreCoord_)
        {
            // translate the coords
            long start = p->first - centreCoord_;
            long end = p->second - centreCoord_;

            // update the depths
            depthSum_ += ( start * (start - 1) - end * (end + 1) ) / 2;
            totalDepth_ += start - end - 1;

            // update the total frag length
            totalFragLength_ -= end - start + 1;

            // forget about this fragment: it doesn't cover the centre position
            fragments_.erase(p);
        }
        else
        {
            break;
        }
    }
}


void TrianglePlot::move(unsigned long n)
{
    shift(n - centreCoord_);
}


bool TrianglePlot::add(pair<unsigned long, unsigned long>& fragment)
{
    // add the fragment, if possible
    if (fragment.first <= centreCoord_ && centreCoord_ <= fragment.second)
    {
        // translate the coords
        long start = fragment.first - centreCoord_;
        long end = fragment.second - centreCoord_;

        // update the depths
        depthSum_ += ( end * (end + 1) - start * (start - 1)) / 2;
        totalDepth_ += end - start + 1;
        totalFragLength_ += end - start + 1;

        // update the list of fragments covering this plot
        fragments_.insert(fragments_.end(), fragment);

        return true;
    }
    else if (fragment.second < centreCoord_)
    {
        return true;
    }
    // if can't add the fragment, nothing to do
    else
    {
        return false;
    }
}

void TrianglePlot::add(multiset<pair<unsigned long, unsigned long> >& frags)
{
    multiset<pair<unsigned long, unsigned long> >::iterator p;
    while (frags.size())
    {
        p = frags.begin();
        pair<unsigned long, unsigned long> frag = *p;
        if (add(frag))
        {
            frags.erase(p);
        }
        else
        {
            break;
        }
    }
}


double TrianglePlot::mean()
{
    return totalDepth_ == 0 ? 0 : 1.0 * depthSum_ / totalDepth_;
}


unsigned long TrianglePlot::centreCoord()
{
    return centreCoord_;
}


unsigned long TrianglePlot::depth()
{
    return fragments_.size();
}

double TrianglePlot::meanFragLength()
{
    return fragments_.size() ? totalFragLength_ / fragments_.size() : 0;
}


void TrianglePlot::clear(unsigned long n)
{
    fragments_.clear();
    totalDepth_ = 0;
    depthSum_ = 0;
    centreCoord_ = n;
    totalFragLength_ = 0;
}

bool TrianglePlot::comparePairBySecond(pair<unsigned long, unsigned long>& i, pair<unsigned long, unsigned long>& j)
{
    return i.second < j.second;
}


void TrianglePlot::getHeights(unsigned long maxInsert, vector<double>& leftHeights, vector<double>& rightHeights)
{
    if (fragments_.size() == 0)
        return;

    leftHeights.clear();
    for (unsigned long i = 0; i <= maxInsert; i++)
    {
        leftHeights.push_back(0);
    }
    rightHeights.clear();
    for (unsigned long i = 0; i <= maxInsert; i++)
    {
        rightHeights.push_back(0);
    }

    unsigned long rightHeight = 0;

    for (multiset< pair<unsigned long, unsigned long> >:: iterator p = fragments_.begin(); p != fragments_.end(); p++)
    {
        rightHeights[p->second - centreCoord_]++;
        rightHeight++;
        leftHeights[centreCoord_ - p->first]++;
    }

    unsigned long leftHeight = fragments_.size();

    for(unsigned long i = 1; i < maxInsert - 1; i++)
    {
        leftHeights[i-1] = 1.0 * leftHeight / fragments_.size();
        leftHeight -= leftHeights[i];
        rightHeights[i-1] = 1.0 * rightHeight / fragments_.size();
        rightHeight -= rightHeights[i];
    }
}


string TrianglePlot::toString(unsigned long maxInsert)
{
    if (fragments_.size() == 0)
    {
        return "";
    }

    stringstream ss;
    vector<unsigned long> leftHeights(maxInsert, 0);
    vector<unsigned long> rightHeights(maxInsert, 0);
    unsigned long rightHeight = 0;

    for (multiset< pair<unsigned long, unsigned long> >:: iterator p = fragments_.begin(); p != fragments_.end(); p++)
    {
        rightHeights[p->second - centreCoord_]++;
        rightHeight++;
        leftHeights[centreCoord_ - p->first]++;
    }

    unsigned long height = 0;

    for (unsigned long i = maxInsert - 1; i > 0; i--)
    {
        height += leftHeights[i];
        ss << height << " ";
    }

    ss << 0 << " " << fragments_.size() << " ";

    for (unsigned long i = 1; i < maxInsert; i++)
    {
        ss << rightHeight << " ";
        rightHeight -= rightHeights[i];
    }

    ss << rightHeight;
    return ss.str();
}


double TrianglePlot::getTheoryHeight(unsigned long gapStart, unsigned long gapEnd, unsigned long position, unsigned long meanInsert)
{
    long s = (long) gapStart - (long) centreCoord_; // gap start centred on zero
    long e = (long) gapEnd - (long) centreCoord_;   // gap end centred on zero
    long p = (long) position - (long) centreCoord_; // position centred at zero
    long i = (long) meanInsert;

    if (p <= -i || p >= i)
    {
        return 0;
    }

    // theory height depends on where the gap is relative to the centre of the plot.
    if (s <= 0 && 0 <= e)
    {
        if (p <= e - i || s + i <= p)
            return 0;
        else if (p < s)
            return 1.0 * (p - e + i) / (s + i - e);
        else if (p <= e)
            return 1.0;
        else
            return -1.0 * (p - s - i) / (s + i - e);
    }
    else if (s > 0 && e > i)
    {
        if (p < s - i)
            return 1.0 * (p + i) / s;
        else if (p <= 0)
            return 1.0;
        else if (p < s)
            return -1.0 * (p - s) / s;
        else
            return 0;
    }
    else if (e < 0 && s < -i)
    {
        if (p <= e)
            return 0;
        else if (p < 0)
            return -1.0 * (p - e) / e;
        else if (p <= e + i)
            return 1.0;
        else
            return 1.0 * (p - i) / e;
    }
    else
    {
        if (-i <= s && s <= e && e < 0)
        {
            s += (long) i;
            e += (long) i;
        }

        if (!(0 <= s && s <= e && e <= i))
        {
            cerr << "Unexpected error in FCD theory height estimation. Abort!" << endl
                 << "gapStart=" << gapStart << ". gapEnd=" << gapEnd << ". position=" << position << ".  centre=" << centreCoord_ << ". s=" << s << ". e=" << e << ". i=" << i << endl;
            exit(1);
        }

       if (p < s - i)
           return 1.0 * (p + i) / (s + i - e);
       else if (p <= e - i)
           return 1.0 * s / (s + i - e);
       else if (p <= 0)
           return 1.0 * (1.0 + 1.0 * p / (s + i - e));
       else if (p < s)
           return 1.0 * (1.0 - 1.0 * p / (s + i - e));
       else if (p <= e)
           return 1.0 - 1.0 * s / (s + i - e);
       else
           return -1.0 * (p - i) / (s + i - e);
    }
}


double TrianglePlot::areaError(unsigned long maxInsert, unsigned long meanInsert, bool gapCorrect, unsigned long gapStart, unsigned long gapEnd)
{
    if (fragments_.size() == 0) return -1;
    double area = 0;
    vector<unsigned long> leftHeights(maxInsert + 1, 0);
    vector<unsigned long> rightHeights(maxInsert + 1, 0);
    unsigned long rightHeight = 0;

    for (multiset< pair<unsigned long, unsigned long> >:: iterator p = fragments_.begin(); p != fragments_.end(); p++)
    {
        rightHeights[min(p->second - centreCoord_, maxInsert)]++;
        rightHeight++;
        leftHeights[min(centreCoord_ - p->first, maxInsert)]++;
    }

    unsigned long leftHeight = fragments_.size();

    for (unsigned long i = 1; i < maxInsert - 1; i++)
    {
        leftHeight -= leftHeights[i];
        rightHeight -= rightHeights[i];
        double theoryLeftHeight;
        double theoryRightHeight;
        if (gapCorrect)
        {
            theoryLeftHeight = getTheoryHeight(gapStart, gapEnd, centreCoord_ - i, meanInsert);
            theoryRightHeight = getTheoryHeight(gapStart, gapEnd, centreCoord_ + i, meanInsert);
        }
        else
        {
            theoryLeftHeight = theoryRightHeight = max(0.0, 1.0 - 1.0 * i / meanInsert);
        }

        area += abs(theoryLeftHeight - 1.0 * leftHeight / fragments_.size());
        area += abs(theoryRightHeight - 1.0 * rightHeight / fragments_.size());
    }

    return min(5.0, area / meanInsert);
}


void TrianglePlot::optimiseGap(unsigned long maxInsert, unsigned long meanInsert, unsigned long gapStart, unsigned long gapEnd, unsigned long& bestGapLength, double& bestError)
{
    // we can only do this if the centre coord of the plot is inside the gap
    if (centreCoord_ < gapStart || centreCoord_ > gapEnd)
    {
        cerr << "Error in TrianglePlot::optimiseGap. coord=" << centreCoord_ << " is not in gap " << gapStart << "-" << gapEnd << endl;
        exit(1);
    }

    unsigned long originalCentreCoord = centreCoord_;
    multiset< pair<unsigned long, unsigned long>, fragcomp> originalFragments(fragments_);
    unsigned long originalTotalDepth_ = totalDepth_;
    unsigned long originalDepthSum = depthSum_;
    unsigned long originalTotalFragLength = totalFragLength_;
    bestGapLength = 0;
    bestError = 999999;
    unsigned long bigStep = 10;
    for (unsigned long gapLength = 1; gapLength < maxInsert / 2; gapLength += bigStep)
    {
        clear();
        unsigned long thisGapEnd = gapStart + gapLength - 1;
        centreCoord_ = gapStart + (thisGapEnd - gapStart) / 2;

        for (multiset< pair<unsigned long, unsigned long> >:: iterator p = originalFragments.begin(); p != originalFragments.end(); p++)
        {
            pair<unsigned long, unsigned long> fragment(p->first, thisGapEnd + p->second - gapEnd);
            add(fragment);
        }

        double error = areaError(maxInsert, meanInsert, true, gapStart, thisGapEnd);
        if (error < bestError)
        {
            bestError = error;
            bestGapLength = gapLength;
        }
    }

    unsigned long windowStart = bestGapLength < bigStep ? 1 : bestGapLength - bigStep;

    for (unsigned long gapLength = windowStart; gapLength < min(maxInsert / 2, bestGapLength + bigStep - 1); gapLength++)
    {
        clear();
        unsigned long thisGapEnd = gapStart + gapLength - 1;
        centreCoord_ = gapStart + (thisGapEnd - gapStart) / 2;

        for (multiset< pair<unsigned long, unsigned long> >:: iterator p = originalFragments.begin(); p != originalFragments.end(); p++)
        {
            pair<unsigned long, unsigned long> fragment(p->first, thisGapEnd + p->second - gapEnd);
            add(fragment);
        }

        double error = areaError(maxInsert, meanInsert, true, gapStart, thisGapEnd);

        if (error < bestError)
        {
            bestError = error;
            bestGapLength = gapLength;
        }
    }

    fragments_ = originalFragments;
    centreCoord_ = originalCentreCoord;
    totalDepth_ = originalTotalDepth_;
    depthSum_ = originalDepthSum;
    totalFragLength_ = originalTotalFragLength;
}


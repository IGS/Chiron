#include "histogram.h"

Histogram::Histogram(unsigned int bin)
{
    binWidth_ = bin;
    plotLabelXcoordsLeftBin_ = false;
    plotXdivide_ = 0;
    plotTrim_ = 4;
}


unsigned long Histogram::sample()
{
    // work out the reverese CDF if not already known
    if (reverseCDF_.empty())
    {
        map<unsigned long, vector<unsigned long> > cdfMap;
        unsigned long sum = 0;
        unsigned long total = size();

        for (unsigned int i = 0; i < 101; i++)
        {
            reverseCDF_.push_back(0);
        }

        // first work out the cdf
        for(map<unsigned long, unsigned long>::iterator p = bins_.begin(); p != bins_.end(); p++)
        {
            sum += p->second;
            unsigned long key = floor(100.0 * sum / total);
            cdfMap[key].push_back(p->first);
        }

        for(map<unsigned long, vector<unsigned long> >::iterator p = cdfMap.begin(); p != cdfMap.end(); p++)
        {
            // work out the mean of current vector
            unsigned long s = 0;
            for (unsigned long i = 0; i < p->second.size(); i++)
            {
               s+= p->second[i];
            }
            reverseCDF_[p->first] = floor(s / p->second.size());
        }

        // interpolate the missing (==0) values
        unsigned int index = 0;
        while (index < reverseCDF_.size())
        {
            if (reverseCDF_[index] == 0)
            {
                // find next non-zero value
                unsigned int nextNonzero = index;
                while (reverseCDF_[nextNonzero] == 0) {nextNonzero++;}

                // interpolate the missing values
                for (unsigned int k = index - 1; k < nextNonzero; k++)
                {
                    reverseCDF_[k] = floor(reverseCDF_[index - 1] + 1.0 * (reverseCDF_[nextNonzero] - reverseCDF_[index - 1]) * (k - index + 1) / (nextNonzero - index + 1));
                }
                index = nextNonzero + 1;
            }
            else
            {
                index++;
            }
        }
    }

    // now pick value at random and return the bin midpoint
    return reverseCDF_[rand() % 101];
}



void Histogram::add(unsigned long val, unsigned long count)
{
    val = binWidth_ * (val / binWidth_);
    bins_[val] += count;
}


void Histogram::clear()
{
    bins_.clear();
}


bool Histogram::empty()
{
    return bins_.empty();
}


unsigned int Histogram::binWidth()
{
    return binWidth_;
}


unsigned long Histogram::get(long pos)
{
    pos = binWidth_ * (pos / binWidth_);
    map<unsigned long, unsigned long>::iterator p = bins_.find(pos);
    return p == bins_.end() ? 0 : p->second;
}

unsigned long Histogram::size()
{
    unsigned long size = 0;

    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); iter != bins_.end(); iter++)
    {
        size += iter->second;
    }
    return size;
}


double Histogram::mode(unsigned long& val)
{
    if (bins_.size() == 0) return 0;

    val = 0;
    unsigned long mode = 0;

    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); iter != bins_.end(); iter++)
    {
        if (val < iter->second)
        {
            mode = iter->first;
            val = iter->second;
        }
    }

    return mode + 0.5 * binWidth_;
}


double Histogram::modeNearMean()
{
    if (bins_.size() == 0) return 0;
    unsigned long val;
    double mean, testMode, stddev;
    testMode = mode(val);
    meanAndStddev(mean, stddev);

    // is the real mode ok?
    if (abs(mean - testMode) < stddev) return testMode;
cerr << "[modeNearMean] looking for mode near mean.  testMode=" << testMode << ". mean=" << mean << ". stddev=" << stddev << endl;
    // look for a mode nearer the mean
    val = 0;
    testMode = 0;
    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); iter != bins_.end(); iter++)
    {
        if (abs(iter->first + 0.5 * binWidth_ - mean) < stddev && val < iter->second)
        {
            testMode = iter->first;
            val = iter->second;
        }
    }

    return testMode + 0.5 * binWidth_;
}

double Histogram::leftPercentile(double p)
{
    if (bins_.size() == 0) return 0;

    unsigned long sum = 0;

    // get the sum, up to the mode
    unsigned long total = 0;
    unsigned long modeValue;
    double thisMode = mode(modeValue);
    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); (double) iter->first <= thisMode; iter++)
    {
        total += iter->second;
    }

    total -= modeValue / 2;

    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); iter != bins_.end(); iter++)
    {
        if (sum + iter->second  > total * p)
        {
            // interpolate between the two bins.
            double yDiff = 1.0 * (1.0 * total * p - sum) / iter->second;
            return 1.0 * iter->first + 1.0 * yDiff / binWidth_;
        }
        sum += iter->second;
    }

    map<unsigned long, unsigned long>::iterator i = bins_.end();
    i--;
    return i->first + 0.5 * binWidth_;
}


void Histogram::endPercentiles(double& first, double& last)
{
    if (bins_.size() == 0) return;
    unsigned long sum = 0;
    unsigned long total = size();
    first = bins_.begin()->first + 0.5 * binWidth_;

    for (map<unsigned long, unsigned long>::iterator iter = bins_.begin(); iter != bins_.end(); iter++)
    {
        sum += iter->second;
        if (sum > total * 0.01)
        {
            first = iter->first + 0.5 * binWidth_;
            break;
        }
    }

    sum = 0;
    last = bins_.rbegin()->first + 0.5 * binWidth_;

    for (map<unsigned long, unsigned long>::reverse_iterator iter = bins_.rbegin(); iter != bins_.rend(); iter++)
    {
        sum += iter->second;
        if (sum > total * 0.01)
        {
            last = iter->first + 0.5 * binWidth_;
            break;
        }
    }
}

double Histogram::minimumBin()
{
    if (bins_.size() == 0)
        return -1;

    return bins_.begin()->first + 0.5 * binWidth_;
}

map<unsigned long, unsigned long>::const_iterator Histogram::begin()
{
    return bins_.begin();
}


map<unsigned long, unsigned long>::const_iterator Histogram::end()
{
    return bins_.end();
}


void Histogram::meanAndStddev(double& mean, double& stddev)
{
    if (bins_.size() == 0) return;

    double  sum = 0;
    unsigned long count = 0;

    // first work out the mean
    for (map<unsigned long, unsigned long>::iterator p = bins_.begin(); p != bins_.end(); p++)
    {
        sum += p->second * (p->first + 0.5 * binWidth_);
        count += p->second;
    }

    mean = sum / count;

    // now do standard deviation
    count = 0;
    sum = 0;

    for (map<unsigned long, unsigned long>::iterator p = bins_.begin(); p != bins_.end(); p++)
    {
        sum += p->second * ( 0.5 * binWidth_ + p->first - mean) * ( 0.5 * binWidth_ + p->first - mean);
        count += p->second;
    }

    stddev = sqrt(sum / (1.0 * count));
}

void Histogram::setPlotOptionTrim(double trim)
{
    plotTrim_ = trim;
}

void Histogram::setPlotOptionXdivide(double divisor)
{
    plotXdivide_ = divisor;
}

void Histogram::setPlotOptionUseLeftOfBins(bool useLeft)
{
    plotLabelXcoordsLeftBin_ = useLeft;
}


void Histogram::setPlotOptionAddVline(double d)
{
   plotVlines_.push_back(d);
}


void Histogram::plot(string outprefix, string ext, string xlabel, string ylabel)
{
    if (bins_.size() == 0)
    {
        return;
    }

    string outfile_plot = outprefix + '.' + ext;
    string outfile_R = outprefix + ".R";
    ofstream ofs(outfile_R.c_str());

    if (!ofs.good())
    {
        cerr << "Error opening file '" << outfile_R << "'" <<  endl;
        exit(1);
    }

    unsigned long currentBin;
    double mean, stddev;
    meanAndStddev(mean, stddev);
    mean = mean ? mean : 1;

    stringstream xCoords;
    stringstream yCoords;

    currentBin = bins_.begin()->first;

    for (map<unsigned long, unsigned long>::iterator p = bins_.begin(); p != bins_.end(); p++)
    {
        double xval = p->first;
        if (!plotLabelXcoordsLeftBin_) xval += 0.5 * binWidth_;

        if (plotTrim_ && xval < mean - plotTrim_ * stddev)
        {
            continue;
        }
        else if (plotTrim_ && xval > mean + plotTrim_ * stddev)
        {
            break;
        }

        if (plotXdivide_) xval /= plotXdivide_;


        while (currentBin < p->first)
        {
            double x = currentBin;
            if (!plotLabelXcoordsLeftBin_) currentBin += 0.5 * binWidth_;
            if (plotXdivide_) x /= plotXdivide_;
            xCoords << ',' << x;
            yCoords << ",0";
            currentBin += binWidth_;
        }

        xCoords << ',' << xval;
        yCoords << ',' << p->second;
        currentBin += binWidth_;
    }

    string x = xCoords.str();
    string y = yCoords.str();

    if (x[x.size() - 1] == ',')
        x.resize(x.size() - 1);

    if (y[y.size() - 1] == ',')
        y.resize(y.size() - 1);

    ofs << "x = c(" << x.substr(1, x.size() - 1) << ')' << endl
        << "y = c(" << y.substr(1, y.size() - 1) << ')' << endl
        << ext << "(\"" << outfile_plot << "\")" << endl
        << "plot(x, y, xlab=\"" << xlabel << "\", ylab=\"" << ylabel << "\", type=\"l\")" << endl;

    for (vector<double>::iterator i = plotVlines_.begin(); i != plotVlines_.end(); i++)
    {
        ofs << "abline(v=" << *i << ", col=\"red\", lty=2)" << endl;
    }

    ofs << "dev.off()" << endl;
    ofs.close();
    systemCall("R CMD BATCH " + outfile_R + " " + outfile_R + "out");
}


void Histogram::writeToFile(string fname, double offset, double xMultiplier)
{
    ofstream ofs(fname.c_str());
    if (!ofs.good())
    {
        cerr << "Error opening file for writing '" << fname << "'" << endl;
        exit(1);
    }

    offset = offset == -1 ? 0.5 * binWidth_ : offset;

    for (map<unsigned long, unsigned long>::iterator p = bins_.begin(); p != bins_.end(); p++)
    {
        ofs << xMultiplier * (offset + p->first) << '\t' << p->second << endl;;
    }
    ofs.close();
}

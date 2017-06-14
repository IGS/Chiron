#ifndef UTILS_H
#define UTILS_H

#include <stdlib.h>
#include <stdio.h>
#include <list>
#include <string>
#include <cstring>
#include <vector>
#include <algorithm>

#include "api/BamMultiReader.h"
#include "api/BamReader.h"
#include "tabix/tabix.hpp"

const short INNIE = 1;
const short OUTTIE = 2;
const short SAME = 3;
const short DIFF_CHROM = 4;
const short UNPAIRED = 5;


using namespace BamTools;
using namespace std;

// Returns the orientation of read pair in bam alignment, as
// one of the constants INNIE, OUTTIE, SAME, DIFF_CHROM, UNPAIRED.
// Setting reverse=true will swap whether INNIE or OUTTIE are returned:
// useful if you have reads pointing outwards instead of in.
short getPairOrientation(BamAlignment& al, bool reverse=false);

// fills each list with (start, end) positions of gaps in the input file, of the form:
// sequence_name<TAB>start<TAB>end
// and this file is expected to be bgzipped and tabixed
// Map key = sequence_name
void loadGaps(string fname, map<string, list<pair<unsigned long, unsigned long > > >& gaps);

// splits the string on delimiter, filling vector with the result
void split(const string& s, char delim, vector<string>& elems);

// Does a system call.  Dies if command returns non-zero error code
void systemCall(string cmd);

// Fills vector with sequence names from fai file, in decreasing size order
void orderedSeqsFromFai(string faiFile, vector<pair< string, unsigned long> >& seqs);


bool sortByLength(const pair< string, unsigned long>& p1, const pair< string, unsigned long>& p2);

#endif // UTILS_H

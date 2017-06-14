#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;

my ($scriptname, $scriptdir) = fileparse($0);
my %options;
my $usage = qq/<assembly.fa> <reads_1.fastq> <reads_2.fastq> <ave insert size> <prefix of output files>

Note: the reads can be gzipped.  If the extension is '.gz', then they
are assumed to be gzipped and dealt with accordingly (i.e. called something
like reads_1.fastq.gz reads_2.fastq.gz).

IMPORTANT: all reads must be the same length.
/;


my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if ($#ARGV != 4 or !($ops_ok)) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $ref_fa = $ARGV[0];
my $reads_1 = $ARGV[1];
my $reads_2 = $ARGV[2];
my $fragsize = $ARGV[3];
my $preout = $ARGV[4];
my $findknownsnps = File::Spec->catfile($scriptdir, 'findknownsnps');
my $ERROR_PREFIX = '[REAPR perfect_map]';
my $raw_coverage_file = "$preout.tmp.cov.txt";
my $tmp_bin = "$preout.tmp.bin";
my $tmp_bin_single_match = "$tmp_bin\_single_match.fastq";
my $tabix = File::Spec->catfile($scriptdir, 'tabix/tabix');
my $bgzip = File::Spec->catfile($scriptdir, 'tabix/bgzip');
my $samtools = File::Spec->catfile($scriptdir, 'samtools');
my $all_bases_outfile = "$preout.perfect_cov.gz";
my $hist_outfile = "$preout.hist";
my @coverage = (0) x 101;
my %ids_with_coverage;
my $reads_for_snpomatic_1 = "$preout.tmp.reads_1.fq";
my $reads_for_snpomatic_2 = "$preout.tmp.reads_2.fq";
my $frag_variance = int(0.5 * $fragsize);

# we want an indexed fasta file
unless (-e "$ref_fa.fai"){
    system_call("$samtools faidx $ref_fa");
}

# snp-o-matic can't take gzipped reads, so decompress them first if necessary
if ($reads_1 =~ /\.gz$/) {
    system_call("gunzip -c $reads_1 > $reads_for_snpomatic_1");
}
else {
    symlink($reads_1, $reads_for_snpomatic_1) or die "Error making symlink $reads_1, $reads_for_snpomatic_1";
}

if ($reads_2 =~ /\.gz$/) {
    system_call("gunzip -c $reads_2 > $reads_for_snpomatic_2");
}
else {
    symlink($reads_2, $reads_for_snpomatic_2) or die "Error making symlink $reads_2, $reads_for_snpomatic_2";
}

# get the read length
open F, "$reads_for_snpomatic_1" or die "$ERROR_PREFIX Error opening file '$reads_for_snpomatic_1'";
<F>;  # first ID line @... of fastq file
my $line = <F>;
chomp $line;
my $read_length = length $line;
close F;

# do the mapping with snpomatic, makes file of perfect read coverage at each position of the genome
system_call("$findknownsnps --genome=$ref_fa --fastq=$reads_for_snpomatic_1 --fastq2=$reads_for_snpomatic_2 --bins=$tmp_bin --binmask=0100 --fragment=$fragsize --variance=$frag_variance --chop=10");
system_call("$findknownsnps --genome=$ref_fa --fastq=$tmp_bin_single_match --pair=$read_length --fragment=$fragsize --variance=$frag_variance --coverage=$raw_coverage_file --chop=10");

unlink $reads_for_snpomatic_1 or die "Error deleting $reads_for_snpomatic_1";
unlink $reads_for_snpomatic_2 or die "Error deleting $reads_for_snpomatic_2";

# use perfect coverage file to make a tabixed file of the perfect coverage
open FIN, "$raw_coverage_file" or die "$ERROR_PREFIX Error opening '$raw_coverage_file'";
open FOUT, "| $bgzip -c >$all_bases_outfile" or die "$ERROR_PREFIX Error opening '$all_bases_outfile'";
print FOUT "#chr\tposition\tcoverage\n";
<FIN>;
while (<FIN>) {
    my @a = split /\t/;
    my $s = $a[3] + $a[4] + $a[5] + $a[6];
    print FOUT "$a[0]\t$a[1]\t$s\n";
    $coverage[$s > 100 ? 100 : $s]++;
    unless (exists $ids_with_coverage{$a[0]}) {
        $ids_with_coverage{$a[0]} = 1;
    }
}

close FIN;
close FOUT;

# sequences with no coverage at all are not in the snpomatic output,
# so check against the fai file to mop up the zero coverage base count
open FIN, "$ref_fa.fai" or die "$ERROR_PREFIX Error opening $ref_fa.fai";
while (<FIN>) {
    my @a = split /\t/;
    unless (exists $ids_with_coverage{$a[0]}) {
        $coverage[0] += $a[1];
    }
}
close FIN;


open FOUT, ">$hist_outfile" or die "$ERROR_PREFIX Error opening '$hist_outfile'";
print FOUT "#coverage\t#number_of_bases\n";

for my $i (0..$#coverage) {
    print FOUT "$i\t$coverage[$i]\n";
}

close FOUT;


system_call("$tabix -f -b 2 -e 2 $all_bases_outfile");
unlink $tmp_bin_single_match or die "$ERROR_PREFIX Error deleting file $tmp_bin_single_match";
unlink $raw_coverage_file or die "$ERROR_PREFIX Error deleting file $raw_coverage_file";


sub system_call {
    my $cmd  = shift;
    if (system($cmd)) {
        print STDERR "$ERROR_PREFIX Error in system call:\n$cmd\n";
        exit(1);
    }
}

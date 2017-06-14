#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;

my ($scriptname, $scriptdir) = fileparse($0);
my %options;
my $usage = qq/[options] <in.bam> <prefix of output files> <min insert> <max insert> <repetitive max qual> <perfect min qual> <perfect min alignment score>

Options:
  -noclean
        Use this to not delete the temporary bam file

Alternative to using perfectmap, for large genomes.

Takes a BAM, which must have AS:... tags in each line. Makes file
of perfect mapping depth, for use with the REAPR pipeline.  Recommended to
use 'reapr perfectmap' instead, unless your genome is large (more than ~300MB),
since although very fast to run, 'reapr perfectmap' uses a lot of memory.

A BAM file made by 'reapr smaltmap' is suitable input.

Reads in pair pointing towards each other, with the given minimum
alignment score and mapping quality and within the given insert size range
are used to generate the coverage across the genome.

Additionally, regions with repetitive coverage are called, by taking read
pairs where at least one read of the pair (is mapped and) has mapping
quality less than or equal to <repetitive max qual>.
/;


my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
    'noclean',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if ($#ARGV != 6 or !($ops_ok)) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $bam_in = $ARGV[0];
my $out_prefix = $ARGV[1];
my $min_insert = $ARGV[2];
my $max_insert = $ARGV[3];
my $max_repeat_map_qual = $ARGV[4];
my $min_perfect_map_qual = $ARGV[5];
my $min_align_score = $ARGV[6];
my $bam2perfect = File::Spec->catfile($scriptdir, 'bam2perfect');
my $bgzip = File::Spec->catfile($scriptdir, 'tabix/bgzip');
my $tabix = File::Spec->catfile($scriptdir, 'tabix/tabix');
my $ERROR_PREFIX = '[REAPR perfectfrombam]';
my $perfect_bam = "$out_prefix.tmp.perfect.bam";
my $repetitive_bam = "$out_prefix.tmp.repetitive.bam";
my $samtools = File::Spec->catfile($scriptdir, 'samtools');
my %seq_lengths;
my %used_seqs;
my $hist_file = "$out_prefix.hist";
my $perfect_cov_out = "$out_prefix.perfect_cov.gz";
my $repetitive_regions_out = "$out_prefix.repetitive_regions.gz";
my @coverage = (0) x 101;


# Make a new BAM with just the perfect + uniquely mapped reads
system_call("$bam2perfect $bam_in $out_prefix.tmp $min_insert $max_insert $max_repeat_map_qual $min_perfect_map_qual $min_align_score");

# Get sequence length info from bam header
open F, "$samtools view -H $bam_in |" or die "$ERROR_PREFIX Error reading header of '$bam_in'";
while (<F>) {
    if (/^\@SQ/) {
        my $id;
        my $length;
        if (/\tSN:(.*?)[\t\n]/) {
            $id = $1;
        }
        if (/\tLN:(.*)[\t\n]/) {
            $length = $1;
        }

        unless (defined $id and defined $length) {
            die "Error parsing \@SQ line from header of bam at this line:\n$_";
        }

        $seq_lengths{$id} = $length;
    }
}

close F or die $!;

# run samtools mpileup on the perfect coverage BAM, writing the coverage to a new file.
# Have to be careful because mpileup only reports bases with != coverage.
open FIN, "$samtools mpileup $perfect_bam | cut -f 1,2,4|" or die "$ERROR_PREFIX Error running samtools mpileup on '$perfect_bam'";
open FOUT, "| $bgzip -c > $perfect_cov_out" or die "$ERROR_PREFIX Error opening '$perfect_cov_out'";
my $current_ref = "";
my $current_pos = 1;


while (<FIN>) {
    chomp;
    my ($ref, $pos, $cov) = split /\t/;

    if ($current_ref ne $ref) {
        if ($current_ref ne "") {
            while ($current_pos <= $seq_lengths{$current_ref}) {
                print FOUT "$current_ref\t$current_pos\t0\n";
                $coverage[0]++;
                $current_pos++;
            }
        }
        $used_seqs{$ref} = 1;
        $current_ref = $ref;
        $current_pos = 1;
    }

    while ($current_pos < $pos) {
        print FOUT "$ref\t$current_pos\t0\n";
        $coverage[0]++;
        $current_pos++;
    }

    print FOUT "$ref\t$pos\t$cov\n";
    $coverage[$cov > 100 ? 100 : $cov]++;
    $current_pos++;
}


while ($current_pos <= $seq_lengths{$current_ref}) {
    print FOUT "$current_ref\t$current_pos\t0\n";
    $coverage[0]++;
    $current_pos++;
}

close FIN or die $!;
close FOUT or die $!;
system_call("$tabix -f -b 2 -e 2 $perfect_cov_out");


# make histogram of coverage file.  First need to account
# for the sequences that had no coverage
for my $seq (keys %seq_lengths) {
    unless (exists $used_seqs{$seq}) {
        $coverage[0] += $seq_lengths{$seq};
    }
}

open F, ">$hist_file" or die "$ERROR_PREFIX Error opening file '$hist_file'";
print F "#coverage\tnumber_of_bases\n";

for my $i (0..$#coverage) {
    print F "$i\t$coverage[$i]\n";
}

close F;

# get the regions of nonzero repetitive coverage from the
# repetitive BAM
open FIN, "$samtools mpileup -A -C 0  $repetitive_bam | cut -f 1,2,4|" or die "$ERROR_PREFIX Error running samtools mpileup on '$repetitive_bam'";
open FOUT, "| $bgzip -c > $repetitive_regions_out" or die "$ERROR_PREFIX Error opening '$repetitive_regions_out'";
$current_ref = "";
my $interval_start = -1;
my $interval_end = -1;

while (<FIN>) {
    chomp;
    my ($ref, $pos, $cov) = split /\t/;

    if ($current_ref ne $ref) {
        if ($current_ref ne "") {
            print FOUT "$current_ref\t$interval_start\t$interval_end\n";
        }
        $current_ref = $ref;
        $interval_start = $interval_end = $pos;
    }
    else {
        if ($pos == $interval_end + 1) {
            $interval_end++;
        }
        else {
            print FOUT "$current_ref\t$interval_start\t$interval_end\n";
            $interval_start = $interval_end = $pos;
        }
    }
}

print FOUT "$current_ref\t$interval_start\t$interval_end\n";
close FIN or die $!;
close FOUT or die $!;

unless ($options{noclean}) {
    unlink $perfect_bam or die $!;
    unlink $repetitive_bam or die $!;
}

sub system_call {
    my $cmd  = shift;
    if (system($cmd)) {
        print STDERR "$ERROR_PREFIX Error in system call:\n$cmd\n";
        exit(1);
    }
}


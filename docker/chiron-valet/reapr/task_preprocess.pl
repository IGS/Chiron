#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;
use List::Util qw[min max];
use File::Copy;

my ($scriptname, $scriptdir) = fileparse($0);
my %options;
my $usage = qq/<assembly.fa> <in.bam> <output directory>
/;

my $ERROR_PREFIX = '[REAPR preprocess]';

my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if ($#ARGV != 2 or !($ops_ok)) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $fasta_in = $ARGV[0];
my $bam_in = $ARGV[1];
my $outdir = $ARGV[2];

-e $fasta_in or die "$ERROR_PREFIX Cannot find file '$fasta_in'. Aborting\n";
-e $bam_in or die "$ERROR_PREFIX Cannot find file '$bam_in'. Aborting\n";

my $prefix = '00';
my $ref = "$prefix.assembly.fa";
my $bam = "$prefix.in.bam";
my $gaps_file = "$prefix.assembly.fa.gaps.gz";
my $gc_file = "$prefix.assembly.fa.gc.gz";
my $bases_to_sample = 1000000;
my $total_frag_sample_bases = 4000000;
my $sample_dir = "$prefix.Sample";
my $fcd_file = File::Spec->catfile($sample_dir, 'fcd.txt');
my $insert_prefix = File::Spec->catfile($sample_dir, 'insert');
my $frag_cov_file = File::Spec->catfile($sample_dir, 'fragCov.gz');
my $gc_vs_cov_data_file = File::Spec->catfile($sample_dir, 'gc_vs_cov.dat');
my $ideal_fcd_file = File::Spec->catfile($sample_dir, 'ideal_fcd.txt');
my $lowess_prefix = File::Spec->catfile($sample_dir, 'gc_vs_cov.lowess');
my $r_script = File::Spec->catfile($sample_dir, 'gc_vs_cov.R');
my $tabix = File::Spec->catfile($scriptdir, 'tabix/tabix');
my $bgzip = File::Spec->catfile($scriptdir, 'tabix/bgzip');
my $samtools = File::Spec->catfile($scriptdir, 'samtools');

# make directory and soft links to required files
$fasta_in = File::Spec->rel2abs($fasta_in);
$bam_in = File::Spec->rel2abs($bam_in);

if (-d $outdir) {
    die "$ERROR_PREFIX Directory '$outdir' already exists.  Cannot continue\n";
}

mkdir $outdir or die $!;
chdir $outdir or die $!;
symlink $fasta_in, $ref or die $!;
symlink $bam_in, $bam or die $!;
mkdir $sample_dir or die $!;

# we want indexed fasta and bam files.
# Check if they are already indexed, run the indexing if needed or soft link index files
if (-e "$fasta_in.fai") {
    symlink "$fasta_in.fai", "$ref.fai";
}
else {
    system_call("$samtools faidx $ref");
}

if (-e "$bam_in.bai") {
    symlink "$bam_in.bai", "$bam.bai";
}
else {
    system_call("$samtools index $bam");
}

# make gaps file of gaps in reference
my $fa2gaps = File::Spec->catfile($scriptdir, 'fa2gaps');
system_call("$fa2gaps $ref | $bgzip -c > $gaps_file");
system_call("$tabix -f -b 2 -e 3 $gaps_file");

# get insert distribution from a sample of the BAM
my $bam2insert = File::Spec->catfile($scriptdir, 'bam2insert');
system_call("$bam2insert -n 50000 -s 2000000 $bam $ref.fai $insert_prefix");

# get the insert stats from output file from bam2insert
my %insert_stats = (
    mode => -1,
    mean => -1,
    pc1 => -1,
    pc99 => -1,
    sd => -1,
);

open F, "$insert_prefix.stats.txt" or die $!;
while (<F>) {
    chomp;
    my ($stat, $val) = split /\t/;
    $insert_stats{$stat} = $val;
}
close F;

foreach (keys %insert_stats) {
    if ($insert_stats{$_} == -1) {
        print STDERR "$ERROR_PREFIX Error getting insert stat $_ from file $insert_prefix.stats.txt\n";
        exit(1);
    }
}

# with large insert libraries, can happen that the mode can be very small,
# even though the mean is something like 30k.  Check for this by looking for
# the mode within a standard deviations of the mean.
my $ave_insert = get_mean($insert_stats{mode}, $insert_stats{mean}, $insert_stats{sd}, "$insert_prefix.in");

# update the insert stats file with the 'average insert size'
open F, ">>$insert_prefix.stats.txt" or die $!;
print F "ave\t$ave_insert\n";
close F;

# get GC content across the genome
if (-e "$fasta_in.gc.gz") {
    symlink "$fasta_in.gc.gz", "$gc_file";
    symlink "$fasta_in.gc.gz.tbi", "$gc_file.tbi";
}
else {
    my $fa2gc =  File::Spec->catfile($scriptdir, 'fa2gc');
    system_call("$fa2gc -w $ave_insert $ref | $bgzip -c > $gc_file");
    system_call("$tabix -f -b 2 -e 2 $gc_file");
}


my %ref_lengths;
my @ref_seqs; # we need them in order as well as hashed with name->length
open F, "$ref.fai" or die $!;
while (<F>) {
    chomp;
    my ($chrom, $length) = split;
    $ref_lengths{$chrom} = $length;
    push @ref_seqs, $chrom;
}
close F;

# work out how far to go into BAM file when getting a sample of fragment coverage.
# This depends on gaps in the reference
my %regions_to_sample;
my @gaps;
my $sampled_bases = 0;
my $current_id = "";
my $ref_seqs_index = 0;
my $last_pos_for_frag_sample = 0;
my $frag_sample_bases = 0;  # number of bases to use when sampling fragment coverage

while ($sampled_bases < $bases_to_sample and $ref_seqs_index <= $#ref_seqs) {
    # skip sequences that are too short
    if ($ref_lengths{$ref_seqs[$ref_seqs_index]} < 3 * $ave_insert) {
        $frag_sample_bases += $ref_lengths{$ref_seqs[$ref_seqs_index]};
        $ref_seqs_index++;
        next;
    }

    @gaps = ();
    push @gaps, [0, $ave_insert];

    # get gaps for current ref seq
    open F, "$tabix $gaps_file $ref_seqs[$ref_seqs_index] | " or die $!;
    while (<F>) {
        chomp;
        my ($chr, $start, $end) = split;

        if ($gaps[-1][1] >= $start) {
            $gaps[-1][1] = $end;
        }
        else {
            push @gaps, [$start, $end];
        }
    }

    close F;

    # add fake gap at end of current seq, the length of the insert size
    my $insert_from_end_pos = $ref_lengths{$ref_seqs[$ref_seqs_index]} - $ave_insert;

    # need to first remove any gaps which are completely contained in where the
    # new gap would be
    while ($gaps[-1][0] >= $insert_from_end_pos) {
        pop @gaps;
    }

    # extend the last gap
    if ($gaps[-1][1] >= $insert_from_end_pos) {
        $gaps[-1][1] = $ref_lengths{$ref_seqs[$ref_seqs_index]} - 1;
    }
    # add the final gap after the existing last gap
    else {
        push @gaps, [$insert_from_end_pos, $ref_lengths{$ref_seqs[$ref_seqs_index]} - 1];
    }

    # if there's only one gap then skip this sequence  (the whole thing is pretty much Ns)
    if ($#gaps == 0) {
        $ref_seqs_index++;
        next;
    }

    $regions_to_sample{$ref_seqs[$ref_seqs_index]} = ();
    my $last_end = 0;

    # update regions of interest for sampling
    my $new_bases = 0;
    for my $i (0..($#gaps - 1)){
        my $start = $gaps[$i][1] + 1;
        my $end = $gaps[$i+1][0] - 1;
        my $region_length = $end - $start + 1;

        # if region gets us enough sampled bases
        if ($sampled_bases + $region_length >= $bases_to_sample) {
            $region_length = $bases_to_sample - $sampled_bases;
            $end = $start + $region_length - 1;
        }

        push @{$regions_to_sample{$ref_seqs[$ref_seqs_index]}}, [$start, $end];
        $sampled_bases += $region_length;
        $frag_sample_bases += $gaps[$i+1][0] - $gaps[$i][0] + 1;

        if ($sampled_bases >= $bases_to_sample) {
            last;
        }
        elsif ($i == $#gaps - 1) {
            $frag_sample_bases +=  $gaps[$i+1][1] -  $gaps[$i+1][0] + 1;
        }
    }

    $ref_seqs_index++;
}

$frag_sample_bases += 1000;  # just for paranoia with off by one errors

# get fragment coverage for a sample of the genome
my $bam2fragCov =  File::Spec->catfile($scriptdir, 'bam2fragCov');
system_call("$bam2fragCov -s $frag_sample_bases $bam $insert_stats{pc1} $insert_stats{pc99} | $bgzip -c > $frag_cov_file");
system_call("$tabix -f -b 2 -e 2 $frag_cov_file");

# now get the GC vs coverage data, and also work out the mean fragment coverage
my $frag_cov_total = 0;
my $frag_cov_base_count = 0;
open F, ">$gc_vs_cov_data_file" or die $!;

for my $chr (keys %regions_to_sample) {
    for my $ar (@{$regions_to_sample{$chr}}) {
        my ($start, $end) = @{$ar};
        my $region = "$chr:$start-$end";
        print "$ERROR_PREFIX sampling region $region.  Already sampled $frag_cov_base_count bases\n";
        open GC, "$tabix $gc_file $region |" or die $!;
        open COV, "$tabix $frag_cov_file $region |" or die $!;

        while (my $gc_line = <GC>) {
            my $cov_line = <COV>;
            # might hav been no coverage of this in the bam file, in which case there will be nothing in
            # the sample coverage file, so skip it
            unless ($cov_line) {
                print STDERR "$ERROR_PREFIX No coverage in $region. Skipping\n";
                last;
            }
            chomp $cov_line or die "$ERROR_PREFIX Error reading sample coverage file, opened with: tabix $frag_cov_file $region";
            chomp $gc_line or die "$ERROR_PREFIX Error reading sample GC file, opened with: tabix $gc_file $region";
            my (undef, undef, $cov) = split /\t/, $cov_line;
            my (undef, undef, $gc) = split /\t/, $gc_line;
            print F "$gc\t$cov\n";
            $frag_cov_total += $cov;
            $frag_cov_base_count++;
        }

        close GC;
        close COV;
    }
}

close F;

if ($frag_cov_base_count == 0) {
    print STDERR qq{$ERROR_PREFIX Error sampling from files '$frag_cov_file', '$gc_file'
Most likely causes are:
1. A character in the assembly sequence names that
   broke tabix, such as :,| or -. You can check for this by running
   reapr facheck
2. A mismatch of names in the input BAM and assembly fasta files.
   A common cause is trailing whitespace in the fasta file, or
   everything after the first whitesace character in a name being
   removed by the mapper, so the name is different in the BAM file.
3. There is not enough fragment coverage because the assembly is
   too fragmented. You may want to compare your mean contig length with
   the insert size of the reads. Also have a look at this plot of the
   insert size distribution:
   00.Sample/insert.in.pdf
};
    exit(1);
}

open F, ">>$insert_prefix.stats.txt" or die $!;
print F "inner_mean_cov\t" . ($frag_cov_total / $frag_cov_base_count) . "\n";
close F;

if ($frag_cov_total == 0) {
    print STDERR "$ERROR_PREFIX Something went wrong sampling fragment coverage - didn't get any coverage.\n";
    exit(1);
}


if ($sampled_bases == 0) {
    print STDERR "$ERROR_PREFIX Something went wrong sampling bases for GC/coverage estimation\n";
    exit(1);
}
else {
    print "$ERROR_PREFIX Sampled $frag_cov_base_count bases for GC/coverage estimation\n";
}

# Do some R stuff: plot cov vs GC, run lowess and make a file
# of the lowess numbers
open F, ">$r_script" or die $!;
print F qq/data=read.csv(file="$gc_vs_cov_data_file", colClasses=c("numeric", "integer"), header=F, sep="\t", comment.char="")
l=lowess(data)
data_out=unique(data.frame(l\$x,l\$y))
write(t(data_out), sep="\t", ncolumns=2, file="$lowess_prefix.dat.tmp")
pdf("$lowess_prefix.pdf")
  smoothScatter(data, xlab="GC", ylab="Coverage")
  lines(data_out)
dev.off()
/;

close F;

system_call("R CMD BATCH $r_script " . $r_script . "out");

# We really want a value for each GC value in 0..100, so interpolate
# the values made by R.
# Any not found values will be set to -1
open F, "$lowess_prefix.dat.tmp" or die $!;


my @gc2cov = (-1) x 101;

while (<F>) {
    chomp;
    my ($gc, $cov) = split;
    next if $cov < 0;
    $gc2cov[$gc] = $cov;
}

close F;

unlink "$lowess_prefix.dat.tmp" or die $!;

# interpolate any missing values
my $first_known = 0;
my $last_known = 100;
while ($gc2cov[$first_known] == -1) {$first_known++}
while ($gc2cov[$last_known] == -1) {$last_known--}

for my $i ($first_known..$last_known) {
    if ($gc2cov[$i] == -1) {
        my $left = $i;
        while ($gc2cov[$left] == -1) {$left--}
        my $right = $i;
        while ($gc2cov[$right] == -1) {$right++}

        for my $j ($left + 1 .. $right - 1) {
            $gc2cov[$j] = $gc2cov[$left] + ($gc2cov[$right] - $gc2cov[$left]) * ($j - $left) / ($right - $left);
        }
    }
}

# linearly extrapolate the missing values at the start, using first two
# values that we do have for gc vs coverage, but we don't want negative values.
if ($gc2cov[0] == -1) {
    my $i = 0;
    while ($gc2cov[$i] == -1) {$i++};
    die "Error in getting GC vs coverage. Not enough data?" if ($i > 99 or $gc2cov[$i + 1] == -1);

    my $diff = $gc2cov[$i + 1] - $gc2cov[$i];
    $i--;
    while ($i >= 0) {
        $gc2cov[$i] = $gc2cov[$i+1] - $diff < 0 ? $gc2cov[$i+1] : $gc2cov[$i+1] - $diff;
        $i--;
    }
}

# linearly extrapolate the missing values at the end, using last two
# values that we do have for gc vs coverage. but we don't want negative values
if ($gc2cov[-1] == -1) {
    my $i = 100;
    while ($i > 0 and $gc2cov[$i] == -1) {
        $i--;
    }

    my $diff = $gc2cov[$i-1] - $gc2cov[$i];
    $i++;
    while ($i <= 100) {
        $gc2cov[$i] = $gc2cov[$i-1] - $diff < 0 ? $gc2cov[$i-1] : $gc2cov[$i-1] - $diff;
        $i++;
    }
}


# write the gc -> coverage to a file
open F, ">$lowess_prefix.dat" or die $!;

for my $i (0..100){
    print F "$i\t$gc2cov[$i]\n";
}

close F;


sub system_call {
    my $cmd  = shift;
    if (system($cmd)) {
        print STDERR "$ERROR_PREFIX Error in system call:\n$cmd\n";
        exit(1);
    }
}


sub get_mean {
    my $mode = shift;
    my $mean = shift;
    my $sd = shift;
    my $fname_prefix = shift;

    my $ave = -1;

    if (abs($mode - $mean) > $sd) {
        print STDERR "$ERROR_PREFIX Warning: mode insert size $mode is > a standard deviation from the mean $mean\n";
        print STDERR "$ERROR_PREFIX ... looking for new mode nearer to the mean ...\n";
        my $max_count = -1;
        my $range_min = $mean - $sd;
        my $range_max = $mean + $sd;

        open F, "$fname_prefix.R" or die "$ERROR_PREFIX Error opening file '$fname_prefix.R'";
        my $xvals = <F>;
        my $yvals = <F>;
        close F;

        $xvals = substr($xvals, 6, length($xvals) - 8);
        print "$xvals\n";
        my @x_r_vector = split(/,/, $xvals);
        $yvals = substr($yvals, 6, length($yvals) - 8);
        my @y_r_vector = split(/,/, $yvals);

        for my $i (0..$#x_r_vector) {
            my $isize = $x_r_vector[$i];
            my $count = $y_r_vector[$i];

            if ($range_min <= $isize and $isize <= $range_max and $count > $max_count) {
                $max_count = $count;
                $ave = $isize;
            }
        }

        if ($ave == -1) {
            print STDERR "$ERROR_PREFIX ... error getting new mode. Cannot continue.\n",
                  "$ERROR_PREFIX You might want to have a look at the insert plot $fname_prefix.pdf\n";
            exit(1);
        }
        else {
            print STDERR "$ERROR_PREFIX     ... got new mode $ave\n",
                  "$ERROR_PREFIX         ... you might want to sanity check this by inspecting the insert plot $fname_prefix.pdf\n";
        }
    }
    else {
        $ave = $mode;
    }
    return $ave;
}

#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;
use File::Spec::Link;

my ($scriptname, $scriptdir) = fileparse($0);
my %options = (
   k => 13,
   s => 2,
   y => 0.5,
   u => 1000,
   n => 1,
);

my $usage = qq/[options] <assembly.fa> <reads_1.fastq> <reads_2.fastq> <out.bam>

Maps read pairs to an asembly with SMALT, making a final BAM file that
is sorted, indexed and has duplicates removed.

The n^th read in reads_1.fastq should be the mate of the n^th read in
reads_2.fastq.

It is assumed that reads are 'innies', i.e. the correct orientation
is reads in a pair pointing towards each other (---> <---).

Options:

-k <int>
\tThe -k option (kmer hash length) when indexing the genome
\twith 'smalt index' [$options{k}]
-s <int>
\tThe -s option (step length) when indexing the genome
\twith 'smalt index' [$options{s}]
-m <int>
\tThe -m option when mapping reads with 'smalt map' [not used by default]
-n <int>
\tThe number of threads used when running 'smalt map' [$options{n}]
-y <float>
\tThe -y option when mapping reads with 'smalt map'.
\tThe default of 0.5 means that at least 50% of each read must map
\tperfectly. Depending on the quality of your reads, you may want to
\tincrease this to be more stringent (or consider using -m) [$options{y}]
-x
\tUse this to just print the commands that will be run, instead of
\tactually running them
-u <int>
\tThe -u option of 'smalt sample'. This is used to estimate the insert
\tsize from a sample of the reads, by mapping every n^th read pair [$options{u}]
/;

my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
    'k=i',
    's=i',
    'y=f',
    'm:i',
    'n=i',
    'u=i',
    'x',
);

if ($options{wrapperhelp}) {
    die $usage;
}

if ($#ARGV != 3 or !($ops_ok)) {
    die "usage:\n$scriptname $usage";
}

my $assembly = $ARGV[0];
my $reads_1 = $ARGV[1];
my $reads_2 = $ARGV[2];
my $final_bam = $ARGV[3];
my $ERROR_PREFIX = '[REAPR smaltmap]';
my $samtools = File::Spec->catfile($scriptdir, 'samtools');
my $smalt = File::Spec->catfile($scriptdir, 'smalt');
my $tmp_prefix = "$final_bam.tmp.$$.smaltmap";
my $smalt_index = "$tmp_prefix.smalt_index";
my $smalt_sample = "$tmp_prefix.smalt_sample";
my $raw_bam = "$tmp_prefix.raw.bam";
my $rmdup_bam = "$tmp_prefix.rmdup.bam";
my $header = "$tmp_prefix.header";

# check input files exist
foreach my $f ($assembly, $reads_1, $reads_2) {
    unless (-e $f) {
        print STDERR "$ERROR_PREFIX Can't find file '$f'\n";
        exit(1);
    }
}

# Run facheck on the input assembly and die if it doesn't like it.
my $this_script = File::Spec::Link->resolve($0);
$this_script = File::Spec->rel2abs($this_script);
my $reapr = File::Spec->catfile($scriptdir, 'reapr.pl');
my $cmd = "$reapr facheck $assembly";
if (system($cmd)) {
    print STDERR "
$ERROR_PREFIX reapr facheck failed - there is at least one sequence name
the input file '$assembly' that will break the pipeline.

Please make a new fasta file using:
reapr facheck $assembly $assembly.facheck
";
    exit(1);
}

# Common reason for this pipeline failing is a fasta file that samtools
# doesn't like. Try running faidx on it (if .fai file doesn't exist
# already). The .fai file would get made in the samtools view -T .. call
# anyway.
unless (-e "$assembly.fai") {
    my $cmd = "$samtools faidx $assembly";
    if (system($cmd)) {
        print STDERR "$ERROR_PREFIX Error in system call:\n$cmd\n\n";
        print STDERR "This means samtools is unhappy with the assembly
fasta file '$assembly'.

Common causes are empty lines in the file, or inconsistent line lengths
(all sequence lines must have the same length, except the last line of
any sequence which can be shorter). Cannot continue.
";
        unlink "$assembly.fai" or die $!;
        exit(1);
    }
}

# make a list of commands to be run
my @commands;

# index the genome
push @commands, "$smalt index -k $options{k} -s $options{s} $smalt_index $assembly";

# estimae the insert size
push @commands, "$smalt sample -u $options{u} -o $smalt_sample $smalt_index $reads_1 $reads_2";

# run the mapping
my $m_option = '';
if ($options{m}) {
    $m_option = "-m $options{m}";
}

my $n_option = '';
if ($options{n} > 1) {
    $n_option = "-n $options{n}";
}

push @commands, "$smalt map -r 0 -x -y $options{y} $n_option $m_option -g $smalt_sample -f samsoft $smalt_index $reads_1 $reads_2"
               . q{ | awk '$1!~/^#/'  }  # SMALT writes some stuff to do with the sampling to stdout
               . " | $samtools view -S -T $assembly -b - > $raw_bam";

# sort the bam by coordinate
#push @commands, "$samtools sort $raw_bam $raw_bam.sort";
push @commands, "$samtools sort -@ 2 -o $raw_bam.sort $raw_bam"

# remove duplicates
push @commands, "$samtools rmdup $raw_bam.sort.bam $rmdup_bam";

# Bamtools needs the @HD line of the BAM to be present.
# So need to make new header for the BAM

# need to get tab characters printed properly. Can't rely on echo -e working, so pipe through awk
push @commands, q~echo "@HD VN:1.0 SO:coordinate" | awk '{OFS="\t"; $1=$1; print}' > ~ . "$header";
push @commands, "$samtools view -H $rmdup_bam >> $header";
push @commands, "$samtools reheader $header $rmdup_bam > $final_bam";

# index the BAM
push @commands, "$samtools index $final_bam";

# clean up temp files
push @commands, "rm $tmp_prefix.*";

# run the commands
foreach my $cmd (@commands) {
    if ($options{x}) {
        print "$cmd\n";
    }
    else {
        print "$ERROR_PREFIX Running: $cmd\n";
        if (system($cmd)) {
            print STDERR "$ERROR_PREFIX Error in system call:\n$cmd\n";
            exit(1);
        }
    }
}


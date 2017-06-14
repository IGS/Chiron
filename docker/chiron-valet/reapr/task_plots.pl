#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Spec;

my ($scriptname, $scriptdir) = fileparse($0);
my %options;

my $usage = qq/[options] <in.stats.gz> <out prefix> <assembly.fa> <contig id>

Options:

-s <scores prefix>
\tThis should be the outfiles prefix used when score was run
/;

my $ops_ok = GetOptions(
    \%options,
    'score_prefix:s',
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    die $usage;
}

if ($#ARGV != 3 or !($ops_ok)) {
    die "usage:\n$scriptname $usage";
}

my $stats = File::Spec->rel2abs($ARGV[0]);
my $outprefix = File::Spec->rel2abs($ARGV[1]);
my $ref_fa = File::Spec->rel2abs($ARGV[2]);
my $ref_id = $ARGV[3];
my $ERROR_PREFIX = '[REAPR plots]';

# check input files exist
unless (-e $stats) {
    print STDERR "$ERROR_PREFIX Can't find stats file '$stats'\n";
    exit(1);
}


unless (-e $ref_fa) {
    print STDERR "$ERROR_PREFIX Can't find assmbly fasta file '$ref_fa'\n";
    exit(1);
}


my $tabix = File::Spec->catfile($scriptdir, 'tabix/tabix');
my $bgzip = File::Spec->catfile($scriptdir, 'tabix/bgzip');
my $samtools = File::Spec->catfile($scriptdir, 'samtools');
my @plot_list = ('frag_cov', 'frag_cov_cor', 'read_cov', 'read_ratio_f', 'read_ratio_r', 'clip', 'FCD_err');
my @file_list;
my $fa_out = "$outprefix.ref.fa";
my $gff_out;

foreach (@plot_list) {
    push @file_list, "$outprefix.$_.plot";
}

# make the standard plot files
my $plot_prog = File::Spec->catfile($scriptdir, "make_plots");
system_call("$tabix $stats '$ref_id' | $plot_prog $outprefix");

# if requested, make a sores plot file and gff errors file
if ($options{score_prefix}) {
    # scores
    my $scores_in = $options{score_prefix} . ".per_base.gz";
    my $score_plot = "$outprefix.score.plot";
    system_call("$tabix $scores_in '$ref_id' > $score_plot");
    push @file_list, $score_plot;

    # gff
    my $gff_in = $options{score_prefix} . ".errors.gff.gz";
    $gff_out = "$outprefix.errors.gff.gz";
    system_call("$tabix $gff_in '$ref_id' | $bgzip -c > $gff_out");
}

# check if a perfect_cov plot file was made
my $perfect_plot = "$outprefix.perfect_cov.plot";
if (-e $perfect_plot) {push @file_list, $perfect_plot};

# get the reference sequence from the fasta file
system_call("$samtools faidx $ref_fa '$ref_id' > $fa_out");

# bgzip the plots
foreach (@file_list) {
    system_call("$bgzip $_");
    if (/\.gff$/) {
        system_call("$tabix -p gff $_.gz");
    }
    else {
        system_call("$tabix -b 2 -e 2 $_.gz");
    }
    $_ .= ".gz";

}



# write shell script to start artemis
my $bash_script = "$outprefix.run_art.sh";
open FILE, ">$bash_script" or die $!;
print FILE "#!/usr/bin/env bash
set -e
art -Duserplot='";
print FILE join (",", sort @file_list);
if ($options{score_prefix}) {
    print FILE "' $fa_out + $gff_out\n";
}
else {
    print FILE "' $fa_out\n";
}
close FILE;
chmod 0755, $bash_script;


# usage: system_call(string)
# Runs the string as a system call, dies if call returns nonzero error code
sub system_call {
    my $cmd  = shift;
    if (system($cmd)) {
        print STDERR "Error in system call:\n$cmd\n";
        exit(1);
    }
}

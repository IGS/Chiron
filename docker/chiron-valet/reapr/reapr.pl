#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use File::Spec::Link;

my $reapr = File::Spec->rel2abs($0);
my $this_script = File::Spec::Link->resolve($0);
$this_script = File::Spec->rel2abs($this_script);
my ($scriptname, $scriptdir) = fileparse($this_script);
$scriptdir = File::Spec->rel2abs($scriptdir);
my $tabix = File::Spec->catfile($scriptdir, 'tabix/tabix');
my $bgzip = File::Spec->catfile($scriptdir, 'tabix/bgzip');
my $version = '1.0.18';

if ($#ARGV == -1) {
    die qq/REAPR version: $version
Usage:
    reapr <task> [options]

Common tasks:
    facheck    - checks IDs in fasta file
    smaltmap   - map read pairs using SMALT: makes a BAM file to be used as
                 input to the pipeline
    perfectmap - make perfect uniquely mapping plot files
    pipeline   - runs the REAPR pipeline, using an assembly and mapped reads
                 as input, and optionally results of perfectmap.
                 (It runs facheck, preprocess, stats, fcdrate, score,
                 summary and break)
    plots      - makes Artemis plot files for a given contig, using results
                 from stats (and optionally results from score)
    seqrename  - renames all sequences in a BAM file: use this if you already
                 mapped your reads but then found facheck failed - saves
                 remapping the reads so that pipeline can be run

Advanced tasks:
    preprocess - preprocess files: necessary for running stats
    stats      - generates stats from a BAM file
    fcdrate    - estimates FCD cutoff for score, using results from stats
    score      - calculates scores and assembly errors, using results from stats
    summary    - make summary stats file, using results from score
    break      - makes broken assembly, using results from score
    gapresize  - experimental, calculates gap sizes based on read mapping
    perfectfrombam - generate perfect mapping plots from a bam file (alternative
                     to using perfectmap for large genomes)
/;
}

my %tasks = (
    'perfectmap' => "task_perfectmap.pl",
    'smaltmap' => "task_smaltmap.pl",
    'preprocess' => "task_preprocess.pl",
    'stats' => "task_stats",
    'break' => "task_break",
    'score' => "task_score",
    'plots' => "task_plots.pl",
    'pipeline'  => "task_pipeline.pl",
    'seqrename' => "task_seqrename.pl",
    'summary' => "task_summary.pl",
    'facheck' => 'task_facheck.pl',
    'gapresize' => 'task_gapresize',
    'fcdrate' => 'task_fcdrate',
    'perfectfrombam' => 'task_perfectfrombam.pl',
);

for my $k (keys %tasks) {
    $tasks{$k} = File::Spec->catfile($scriptdir, $tasks{$k});
}


if ($tasks{$ARGV[0]}) {
    if ($#ARGV == 0) {
        print STDERR "usage:\nreapr $ARGV[0] ";
        exec "$tasks{$ARGV[0]} --wrapperhelp" or die;
    }
    else {
        my $cmd;

        if ($ARGV[0] eq "score") {
            my $score_out = "$ARGV[-1].per_base.gz";
            my $errors_out = "$ARGV[-1].errors.gff";
            $cmd = "$tasks{$ARGV[0]} " . join(" ", @ARGV[1..$#ARGV]) . "  | $bgzip -f -c > $score_out && $tabix -f -b 2 -e 2 $score_out && $bgzip -f $errors_out && $tabix -f -p gff $errors_out.gz";
        }
        else {
            $cmd = "$tasks{$ARGV[0]} " . join(" ", @ARGV[1..$#ARGV]);

            if ($ARGV[0] eq "stats") {
                my $outfile = "$ARGV[-1].per_base.gz";
                $cmd .= "  | $bgzip -f -c > $outfile && $tabix -f -b 2 -e 2 $outfile";
            }
        }

        exec $cmd or die;
    }
}
else {
    die qq/Task "$ARGV[0]" not recognised.\n/;
}

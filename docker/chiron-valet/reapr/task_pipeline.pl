#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';

my ($scriptname, $scriptdir) = fileparse($0);
my $reapr = File::Spec->catfile($reapr_dir, 'reapr/reapr');

my %options = (fcdcut => 0);

my $usage = qq/[options] <assembly.fa> <in.bam> <out directory> [perfectmap prefix]

where 'perfectmap prefix' is optional and should be the prefix used when task
perfectmap was run.

It is assumed that reads in in.bam are 'innies', i.e. the correct orientation
is reads in a pair pointing towards each other (---> <---).

Options:

-stats|fcdrate|score|break option=value
\tYou can pass options to stats, fcdrate, score or break
\tif you want to change the default settings. These
\tcan be used multiple times to use more than one option. e.g.:
\t\t-stats i=100 -stats j=1000
\tIf an option has no value, use 1. e.g.
\t\t-break b=1
-fcdcut <float>
\tSet the fcdcutoff used when running score. Default is to
\trun fcdrate to determine the cutoff. Using this option will
\tskip fcdrate and use the given value.
-x
\tBy default, a bash script is written to run all
\tthe pipeline stages. Using this option stops the
\tscript from being run.
/;

my $ERROR_PREFIX = '[REAPR pipeline]';

my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
    'stats=s%',
    'fcdrate=s%',
    'score=s%',
    'break=s%',
    'x',
    'fcdcut=f',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if (!($ops_ok) or $#ARGV < 2) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $ref = $ARGV[0];
my $bam = $ARGV[1];
my $dir = $ARGV[2];
my $version = '1.0.18';
my $bash_script = "$dir.run-pipeline.sh";
my $stats_prefix = '01.stats';
my $fcdrate_prefix = '02.fcdrate';
my $score_prefix = '03.score';
my $break_prefix = '04.break';
my $summary_prefix = '05.summary';

my $perfect_prefix = "";
if ($#ARGV == 3) {
    $perfect_prefix = File::Spec->rel2abs($ARGV[3]);
}

# make a bash script that runs all the pipeline commands
my %commands;
$commands{facheck} = "$reapr facheck $ref";
$commands{preprocess} = "$reapr preprocess $ref $bam $dir\n"
. "cd $dir";

if ($perfect_prefix) {
    $commands{stats} = "$reapr stats " . hash_to_ops($options{stats}) . " -p $perfect_prefix.perfect_cov.gz ./ $stats_prefix";
    $commands{score} = "$reapr score " . hash_to_ops($options{score}) . " -P 5 00.assembly.fa.gaps.gz 00.in.bam $stats_prefix \$fcdcutoff $score_prefix";
}
else {
    $commands{stats} = "$reapr stats " . hash_to_ops($options{stats}) . " ./ $stats_prefix";
    $commands{score} = "$reapr score " . hash_to_ops($options{score}) . " 00.assembly.fa.gaps.gz 00.in.bam $stats_prefix \$fcdcutoff $score_prefix";
}

if ($options{fcdcut} == 0) {
    $commands{fcdrate} = "$reapr fcdrate " . hash_to_ops($options{fcdrate}) . " ./ $stats_prefix $fcdrate_prefix\n"
                           . "fcdcutoff=`tail -n 1 $fcdrate_prefix.info.txt | cut -f 1`";
}
else {
    $commands{fcdrate} = "echo \"$ERROR_PREFIX ... skipping. User provided cutoff: $options{fcdcut}\"\n"
                            . "fcdcutoff=$options{fcdcut}";
}

my $break_ops = hash_to_ops($options{break});
$break_ops =~ s/\-a 1/-a/;
$break_ops =~ s/-b 1/-b/;
$commands{break} = "$reapr break $break_ops 00.assembly.fa $score_prefix.errors.gff.gz $break_prefix";
$commands{summary} = "$reapr summary 00.assembly.fa $score_prefix $break_prefix $summary_prefix";

open F, ">$bash_script" or die "$ERROR_PREFIX Error opening file for writing '$bash_script'";
print F "set -e\n"
. "echo \"Running reapr version $version pipeline:\"\n"
. "echo \"$reapr " . join(' ', @ARGV) . "\"\n\n";

for my $task (qw/facheck preprocess stats fcdrate score break summary/) {
    print F "echo \"$ERROR_PREFIX Running $task\"\n"
        . "$commands{$task}\n\n";
}

close F;

$options{x} or exec "bash $bash_script" or die $!;

sub hash_to_ops {
    my $h = shift;
    my $s = '';
    for my $k (keys %{$h}) {
        $s .= " -$k " . $h->{$k}
    }
    $s =~ s/^\s+//;
    return $s;
}


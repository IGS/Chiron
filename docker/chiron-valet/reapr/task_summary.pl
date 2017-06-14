#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;
use List::Util qw[min max];

my ($scriptname, $scriptdir) = fileparse($0);
my %options = ('min_insert_error' => 0);
my $usage = qq/[options] <assembly.fa> <score prefix> <break prefix> <outfiles prefix>

where 'score prefix' is the outfiles prefix used when score was run, and
'break prefix' is the outfiles prefix used when break was run.

Options:

-e <float>
\tMinimum FCD error [0]
/;

my $ERROR_PREFIX = '[REAPR summary]';

my $ops_ok = GetOptions(
    \%options,
    'min_insert_error|e=f',
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if ($#ARGV != 3 or !($ops_ok)) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $ref_fa = $ARGV[0];
my $score_prefix = $ARGV[1];
my $break_prefix = $ARGV[2];
my $out_prefix = $ARGV[3];
my $ref_broken_fa = "$break_prefix.broken_assembly.fa";
my $errors_gff = "$score_prefix.errors.gff.gz";
my $score_dat_file = "$score_prefix.score_histogram.dat";
my $ref_fai = "$ref_fa.fai";
my $out_tsv = "$out_prefix.stats.tsv";
my $out_report = "$out_prefix.report.txt";
my $out_report_tsv = "$out_prefix.report.tsv";

my @n50_stats = qw(bases
sequences
mean_length
longest
N50
N50_n
N60
N60_n
N70
N70_n
N80
N80_n
N90
N90_n
N100
N100_n
gaps
gaps_bases);


my @stats_keys = qw(
length
errors
errors_length
perfect_cov
perfect_cov_length
repeat
repeat_length
clip
clip_length
score
score_length
frag_dist
frag_dist_length
frag_dist_gap
frag_dist_gap_length
frag_cov
frag_cov_length
frag_cov_gap
frag_cov_gap_length
read_cov
read_cov_length
link
link_length
read_orientation
read_orientation_length
);


my @stats_keys_for_report = qw(
perfect_bases
frag_dist
frag_dist_gap
frag_cov
frag_cov_gap
score
link
clip
repeat
read_cov
perfect_cov
read_orientation
);


my %stats_keys_for_report_to_outstring = (
    'perfect_bases' => 'error_free',
    'perfect_cov' => 'low_perfect_cov',
    'repeat' => 'collapsed_repeat',
    'clip' => 'soft_clipped',
    'score' => 'low_score',
    'frag_dist' => 'FCD',
    'frag_dist_gap' => 'FCD_gap',
    'frag_cov' => 'frag_cov',
    'frag_cov_gap' => 'frag_cov_gap',
    'read_cov' => 'read_cov',
    'link' => 'link',
    'read_orientation' => 'read_orientation',
);





my %gff2stat = (
    'Repeat' => 'repeat',
    'Low_score' => 'score',
    'Clip'   => 'clip',
    'FCD' => 'frag_dist',
    'FCD_gap' => 'frag_dist_gap',
    'Frag_cov' => 'frag_cov',
    'Frag_cov_gap' => 'frag_cov_gap',
    'Read_cov' => 'read_cov',
    'Link' => 'link',
    'Perfect_cov' => 'perfect_cov',
    'Read_orientation' => 'read_orientation',
);


open OUT, ">$out_tsv" or die "$ERROR_PREFIX Error opening file $out_tsv";
print OUT "#id\t" . join("\t", @stats_keys) . "\n";

open FAI, $ref_fai or die "$ERROR_PREFIX Error opening file $ref_fai";
my %ref_lengths;
my @ref_ids;  # need these because some sequences are not in the errors file and
              # might as well preserve the order of the sequences

while (<FAI>) {
    chomp;
    my ($id, $length) = split /\t/;
    $ref_lengths{$id} = $length;
    push @ref_ids, $id;
}

close FAI;

my %error_stats;

open GFF, "gunzip -c $errors_gff |" or die "$ERROR_PREFIX Error opening file $errors_gff";
my $ref_id_index = 0;

while (<GFF>) {
    chomp;
    my @gff = split /\t/;

    # make new hash if it's the first time we've seen this sequence
    unless (exists $error_stats{$gff[0]}) {
        $error_stats{$gff[0]} = {};

        foreach (@stats_keys) {
            $error_stats{$gff[0]}{$_} = 0;
        }
        $error_stats{$gff[0]}{length} = $ref_lengths{$gff[0]};
    }

    # update the error counts for this sequence
    exists $gff2stat{$gff[2]} or die "$ERROR_PREFIX Didn't recognise type of error '$gff[2]' from gff file. Cannot continue";

    next if ($gff[2] =~ /^Insert/ and $gff[5] <= $options{min_insert_error});

    $error_stats{$gff[0]}{$gff2stat{$gff[2]}}++;
    $error_stats{$gff[0]}{"$gff2stat{$gff[2]}_length"} += $gff[4] - $gff[3] + 1;
    $error_stats{$gff[0]}{errors}++;
    $error_stats{$gff[0]}{errors_length} += $gff[4] - $gff[3] + 1;
}

close GFF;

# print the output, adding up total stats for whole assembly along the way
my %whole_assembly_stats;
foreach (@stats_keys) {
    $whole_assembly_stats{$_} = 0;
}
foreach my $id (@ref_ids) {
    if (exists $error_stats{$id}) {
        my $outstring = "$id\t";
        $error_stats{length} = $ref_lengths{$id};

        foreach (@stats_keys) {
            $outstring .= $error_stats{$id}{$_} . "\t";
            $whole_assembly_stats{$_} += $error_stats{$id}{$_};
        }
        chomp $outstring;
        print OUT "$outstring\n";
    }
    else {
        print OUT "$id\t$ref_lengths{$id}\t" . join("\t", (0) x 22) .  "\n";
        $whole_assembly_stats{length} += $ref_lengths{$id};
    }
}

print OUT "WHOLE_ASSEMBLY";
foreach (@stats_keys) {
    print OUT "\t", $whole_assembly_stats{$_};
}
print OUT "\n";
close OUT;


open my $fh, ">$out_report" or die "$ERROR_PREFIX Error opening file '$out_report'";
my $n50_exe = File::Spec->catfile($scriptdir, 'n50');

print $fh "Stats for original assembly '$ref_fa':\n";
my %stats_original;
get_n50($n50_exe, $ref_fa, \%stats_original);
print $fh n50_to_readable_string(\%stats_original);

my $total_bases = $stats_original{'bases'};

# get the % perfect bases from the histogram written by score
my $perfect_bases = 0;
open F, "$score_dat_file" or die "$ERROR_PREFIX Error opening file $score_dat_file";
while (<F>) {
    chomp;
    my ($score, $count) = split /\t/;
    if ($score == 0) {
        $perfect_bases = $count;
        last;
    }
}

close F;

$total_bases != 0 or die "Error getting %perfect bases.  Total base count of zero from file '$score_dat_file'\n";
my $percent_perfect = sprintf("%.2f", 100 * $perfect_bases / $total_bases);
print $fh "Error free bases: $percent_perfect\% ($perfect_bases of $total_bases bases)\n",
          "\n" , $whole_assembly_stats{frag_dist} + $whole_assembly_stats{frag_dist_gap} + $whole_assembly_stats{frag_cov} + $whole_assembly_stats{frag_cov_gap}, " errors:\n",
          "FCD errors within a contig: $whole_assembly_stats{frag_dist}\n",
          "FCD errors over a gap: $whole_assembly_stats{frag_dist_gap}\n",
          "Low fragment coverage within a contig: $whole_assembly_stats{frag_cov}\n",
          "Low fragment coverage over a gap: $whole_assembly_stats{frag_cov_gap}\n",
          "\n", $whole_assembly_stats{score} + $whole_assembly_stats{link} + $whole_assembly_stats{clip} + $whole_assembly_stats{repeat} + $whole_assembly_stats{read_cov} + $whole_assembly_stats{perfect_cov} + $whole_assembly_stats{read_orientation}  , " warnings:\n",
          "Low score regions: $whole_assembly_stats{score}\n",
          "Links: $whole_assembly_stats{link}\n",
          "Soft clip: $whole_assembly_stats{clip}\n",
          "Collapsed repeats: $whole_assembly_stats{repeat}\n",
          "Low read coverage: $whole_assembly_stats{read_cov}\n",
          "Low perfect coverage: $whole_assembly_stats{perfect_cov}\n",
          "Wrong read orientation: $whole_assembly_stats{read_orientation}\n";


print $fh "\nStats for broken assembly '$ref_broken_fa':\n";
my %stats_broken;
get_n50($n50_exe, $ref_broken_fa, \%stats_broken);
print $fh n50_to_readable_string(\%stats_broken);
close $fh;

$whole_assembly_stats{perfect_bases} = $perfect_bases;

open F, ">$out_report_tsv" or die "$ERROR_PREFIX Error opening file '$out_report_tsv'";
print F "#filename\t" . join("\t", @n50_stats) . "\t";

foreach(@n50_stats) {
    print F $_ . "_br\t";
}


print F make_tsv_string(\@stats_keys_for_report, \%stats_keys_for_report_to_outstring) . "\n"
        . File::Spec->rel2abs($ref_fa) . "\t"
        . make_tsv_string(\@n50_stats, \%stats_original) . "\t"
        . make_tsv_string(\@n50_stats, \%stats_broken) . "\t"
        . make_tsv_string(\@stats_keys_for_report, \%whole_assembly_stats) . "\n";
close F;


sub get_n50 {
    my $exe = shift;
    my $infile = shift;
    my $hash_ref = shift;


    open F, "$exe $infile|" or die "$ERROR_PREFIX Error getting N50 from $infile";
    while (<F>) {
        chomp;
        my ($stat, $value) = split;
        $hash_ref->{$stat} = $value;
    }
    close F or die $!;
}

sub n50_to_readable_string {
    my $h = shift;
    return "Total length: $h->{bases}
Number of sequences: $h->{sequences}
Mean sequence length: $h->{mean_length}
Length of longest sequence: $h->{longest}
N50 = $h->{N50}, n = $h->{N50_n}
N60 = $h->{N60}, n = $h->{N60_n}
N70 = $h->{N70}, n = $h->{N70_n}
N80 = $h->{N80}, n = $h->{N80_n}
N90 = $h->{N90}, n = $h->{N90_n}
N100 = $h->{N100}, n = $h->{N100_n}
Number of gaps: $h->{gaps}
Total gap length: $h->{gaps_bases}
";
}

sub make_tsv_string {
    my $keys = shift;
    my $h = shift;
    my $s = "";
    foreach(@{$keys}) {
        $s .= $h->{$_} . "\t";
    }
    $s =~ s/\t$//;
    return $s;
}

#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;

my ($scriptname, $scriptdir) = fileparse($0);
my $samtools = File::Spec->catfile($scriptdir, 'samtools');
my %options;
my $usage = qq/<rename file> <in.bam> <out.bam>

where <rename file> is the file *.info made by 'facheck', which
contains the mapping of old name to new name
/;

my $ERROR_PREFIX = '[REAPR seqrename]';

my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if (!($ops_ok) or $#ARGV != 2) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}


my $old2new_file = $ARGV[0];
my $bam_in = $ARGV[1];
my $bam_out = $ARGV[2];

# hash the old -> new names
my %old2new;
open F, $old2new_file or die $!;

while (<F>) {
    chomp;
    my ($old, $new) = split /\t/;
    $old =~ s/\s+$//;
    $old2new{$old} = $new;
}
close F;
$old2new{'*'} = '*';
$old2new{'='} = '=';

# make the new bam file
open FIN, "$samtools view -h $bam_in|" or die $!;
open FOUT, "| $samtools view -bS - > $bam_out" or die $!;

while (<FIN>) {
    chomp;
    my @a  =split /\t/;

    if ($a[0] =~ /^\@SQ/) {
        $a[1] = "SN:" . $old2new{substr($a[1], 3)};
    }
    elsif ($a[0] !~ /^\@/) {
        $a[2] = $old2new{$a[2]};
        $a[6] = $old2new{$a[6]};
    }

    print FOUT join("\t", @a), "\n";
}

close FIN;
close FOUT;

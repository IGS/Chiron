#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Getopt::Long;

my ($scriptname, $scriptdir) = fileparse($0);
my %options;
my $usage = qq/<in.fa> [out_prefix]

Checks that the names in the fasta file are ok.  Things like
trailing whitespace or characters |':- could break the pipeline.

If out_prefix is not given, it will die when a bad ID is found.
No output means everything is OK.

If out_prefix is given, writes a new fasta file out_prefix.fa with new
names, and out_prefix.info which has the mapping from old name to new name.
/;


my $ERROR_PREFIX = '[REAPR facheck]';

my $ops_ok = GetOptions(
    \%options,
    'wrapperhelp',
);

if ($options{wrapperhelp}) {
    print STDERR "$usage\n";
    exit(1);
}

if ($#ARGV < 0 or $#ARGV > 1 or !($ops_ok)) {
    print STDERR "usage:\n$scriptname $usage\n";
    exit(1);
}

my $fasta_in = $ARGV[0];
my $out_prefix = $#ARGV == 1 ? $ARGV[1] : "";
-e $fasta_in or die "$ERROR_PREFIX Cannot find file '$fasta_in'\n";
my %new_id_counts;
open FIN, $fasta_in or die "$ERROR_PREFIX Error opening '$fasta_in'\n";

if ($out_prefix) {
    my $fasta_out = "$out_prefix.fa";
    my $info_out = "$out_prefix.info";
    open FA_OUT, ">$fasta_out" or die "$ERROR_PREFIX Error opening '$fasta_out'\n";
    open INFO_OUT, ">$info_out" or die "$ERROR_PREFIX Error opening '$info_out'\n";
    print INFO_OUT "#old_name\tnew_name\n";
}

while (<FIN>) {
    chomp;

    if (/^>/) {
        my ($name) = split /\t/;
        $name =~ s/^.//;
        my $new_name = check_name($name, \%new_id_counts, $out_prefix);
        if ($out_prefix) {
            print FA_OUT ">$new_name\n";
            print INFO_OUT "$name\t$new_name\n";
        }
    }
    elsif ($out_prefix) {
        print FA_OUT "$_\n";
    }
}

close FIN;

if ($out_prefix) {
    close FA_OUT;
    close INFO_OUT;
}

# checks if the given name is OK.
# arg 0 = name to be checked
# arg 1 = refrence to hash of new id counts
# arg 2 = ouput files prefix
# Returns new name
sub check_name {
    my $old_id = shift;
    my $h = shift;
    my $pre = shift;
    my $new_id = $old_id;
    $new_id =~ s/[,;'|:\+\-\s\(\)\{\}\[\]]/_/g;

    if ($old_id ne $new_id and $pre eq "") {
            print "Sequence name '$old_id' not OK and will likely break pipeline\n";
            exit(1);
    }
    $h->{$new_id}++;

    if ($h->{$new_id} == 1) {
        return $new_id;
    }
    else {
        return "$new_id." . $h->{$new_id};
    }
}


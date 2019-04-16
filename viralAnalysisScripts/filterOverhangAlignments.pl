#!/usr/bin/perl
# This script takes the read overhang alignments (in paf format) and converts them to an association table

use strict;
my $usage = "perl $0 <input overhang paf file> <original read-virus paf file> <output association table>\n";

chomp(@ARGV);
unless(scalar(@ARGV) == 3){
	print $usage;
	exit;
}

my %data;
open(my $IN, "< $ARGV[0]");
while(my $line = <$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	if($segs[11] == 0){next;}
	
	$segs[0] =~ s/\:\d+\-\d+$//;
	push(@{$data{$segs[0]}}, $segs[5]);
}
close $IN;

open(my $IN, "< $ARGV[1]");
while(my $line = <$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	if(exists($data{$segs[0]})){
		push(@{$data{$segs[0]}}, $segs[5]);
	}
}
close $IN;

open(my $OUT, "> $ARGV[2]");
foreach my $keys (keys(%data)){
	if(scalar(@{$data{$keys}}) > 2)){
		next; # too many mappings for this read!
	}
	print "$keys\t" . join("\t", @{$data{$keys}}) . "\n";
}
close $OUT;
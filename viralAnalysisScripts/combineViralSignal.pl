#!/usr/bin/perl
# This script is designed to combine and condense the graph output from the Hi-C links and the PacBio read alignments

use strict;
my $usage = "perl $0 <hic links graph file> <pacbio read alignment graph file>\n";

unless(scalar(@ARGV) == 2){
	print $usage;
	exit;
}

chomp(@ARGV); 
open(IN, "< $ARGV[0]"); 
my %data; 
my $ h = <IN>; 
while(<IN>){
	chomp; 
	my @s = split(/\t/); 
	$data{$s[0]}->{$s[1]} = [$s[3], $s[4], $s[5]];
} 
close IN; 

print "VirusCtg\tHostCtg\tCategory\tVirusGenus\tHostKingdom\tHostGenus\n"; 

open(IN, "< $ARGV[1]"); 
my %seen; 
while(<IN>){
	chomp; 
	my @s = split(/\t/); 
	if(exists($data{$s[0]}->{$s[1]})){
		print "$s[0]\t$s[1]\tBOTH\t$s[3]\t$s[4]\t$s[5]\n";
	}else{
		print "$s[0]\t$s[1]\tPACB\t$s[3]\t$s[4]\t$s[5]\n";
	} 
	$seen{$s[0]}->{$s[1]} = 1;
} 

foreach my $v (keys(%data)){
	foreach my $c (keys(%{$data{$v}})){ 
		if(!exists($seen{$v}->{$c})){
			print "$v\t$c\tHIC\t" . join("\t", @{$data{$v}->{$c}}) . "\n";
		}
	}
}
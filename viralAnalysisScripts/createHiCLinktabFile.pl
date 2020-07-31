#!/usr/bin/perl
# This is a quick and dirty way to generate a Hi-C link graph between contigs of interest

use strict;
my $usage = "perl $0 <list of viral contigs> <input Hi-C alignment SAM file> <output association graph>\n";

chomp(@ARGV);
unless(scalar(@ARGV) == 3){
	print $usage;
	exit;
}

my %ctgset;
open(my $IN, "< $ARGV[0]");
while(my $line = <$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	$ctgset{$segs[0]} = 1;
}
close $IN;

my %assocHash; #{virus} -> {ctg} = count
open(my $IN, "< $ARGV[1]");
while(my $line = <$IN>){
	if($line =~ /^@/){next;}
	chomp($line);
	my @segs = split(/\t/, $line);
	if(exists($ctgset{$segs[2]})){
		# We only count one pair of the links to avoid redundancy!
		if($segs[6] ne $segs[2]){
			$assocHash{$segs[2]}->{$segs[6]} += 1;
		}
	}
}
close $IN;

open(my $OUT, "> $ARGV[2]");
foreach my $vctg (sort {$a cmp $b} keys(%assocHash)){
	foreach my $nctg (sort {$a cmp $b} keys(%{$assocHash{$vctg}})){
		print {$OUT} "$vctg\t$nctg\t" . $assocHash{$vctg}->{$nctg} . "\n";
	}
}
close $OUT;

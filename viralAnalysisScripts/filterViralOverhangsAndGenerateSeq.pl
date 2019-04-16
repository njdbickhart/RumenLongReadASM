#!/usr/bin/perl
# This is the follow-up script that can be used to filter long-read viral overhangs and to generate a fasta file for realignment

use strict;
my $usage = "perl $0 <input viral overhang bed> <original error-corrected read fasta> <bp threshold for filtering> <output filtered fasta>\n"

chomp(@ARGV);

unless(scalar(@ARGV) == 4){
	print $usage;
	exit;
}

if( -s $ARGV[3]){
	print "Delete existing subread fasta file: $ARGV[3] [y/n]?\n";
	my $decision = STDIN;
	if($decision =~ /^y/){
		print "Deleting...\n";
		system("rm $ARGV[3]");
	}elsif($decision =~ /^n/){
		print "You're own your own, kid!\n";
	}else{
		print "Does not compute! Please pick a proper answer next time!\n";
		exit;
	}
}

open(my $IN, "< $ARGV[0]");
my @list;
while(my $line = <$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	if($segs[2] - $segs[1] > $ARGV[2]){
		if(scalar(@list) >= 500){
			print STDERR "printing 500 subreads...\n";
			system("samtools faidx $ARGV[1] " . join(" ", @list) . " >> $ARGV[3]");
			@list = ();
		}
		push(@list, "$segs[0]:$segs[1]-$segs[2]");
	}
}
close $IN;
print STDERR "Finished writing to file!\n";
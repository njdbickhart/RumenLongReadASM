#!/usr/bin/perl
#name  length  GC      N       cov12   cov13   cov10   cov11   cov16   cov17   cov14   cov15   cov8    cov9    cov0    cov1    cov2    cov3    cov4      cov5    cov6    cov7    cov_sum superkingdom.t.24       superkingdom.s.25       superkingdom.c.26       superkingdom.hits.27    phylum.t.28       phylum.s.29     phylum.c.30     phylum.hits.31  order.t.32      order.s.33      order.c.34      order.hits.35   family.t.36     family.s.37       family.c.38     family.hits.39  genus.t.40      genus.s.41      genus.c.42      genus.hits.43   species.t.44    species.s.45    species.c.46      species.hits.47
#
# m54033_170728_182325/51183710/18606_32318       tig00498290     tig00002216
# m170520_182357_42132_c101155652550000001823254307191782_s1_p0/143026/17204_23133        tig00002119     tig00003445
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/96559/0_7449      tig00002223     tig00498166
# m170520_052942_42132_c101155652550000001823254307191780_s1_p0/153514/0_8699     tig02637554     tig00010608
# m54033_170729_110344/47711085/0_10928   tig00501820     tig00088402
# m54033_170730_162324/64750109/20151_27866       tig00498827     tig00005384

use strict;
my $usage = "perl $0 <input blobtools data> <Hi-C link table> <output filename>\n";

unless(scalar(@ARGV) == 3){
	print $usage;
	exit;
}

# Populate genus association hash
open(my $IN, "< $ARGV[0]") || die "Could not open blobtools data!\n";
my $genusidx = 0; my $kingidx = 0;
my %genusAssoc;
my %kingAssoc;
while(my $line = <$IN>){
	if($line =~ /^##/){next;}
	elsif($line =~ /^# /){
		$line =~ s/^# //;
		my @segs = split(/\s+/, $line);
		for(my $x = 0; $x < scalar(@segs); $x++){
			if($segs[$x] =~ /^genus.t/){
				$genusidx = $x;
			}elsif($segs[$x] =~ /^superkingdom.t/){
				$kingidx = $x;
			}
		}
	}else{
		my @segs = split(/\t/, $line);
		$genusAssoc{$segs[0]} = $segs[$genusidx];
		$kingAssoc{$segs[0]} = $segs[$kingidx];
	}
}
close $IN;

# Generate association count hash
open(my $IN, "< $ARGV[1]");
my %count;
while(my $line =<$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	$count{$segs[0]}->{$segs[1]} = $segs[2];
}
close $IN;

# Now, generate larger table with association data, taxonomy and magnitude
open(my $OUT, "> $ARGV[2]");
print {$OUT} "VirusCtg\tHostCtg\tReadMapCnt\tVirusGenus\tHostKingdom\tHostGenus\n";
foreach my $virus (keys(%count)){
	foreach my $ctg (sort{$count{$virus}->{$b} <=> $count{$virus}->{$a}} keys(%{$count{$virus}})){
		my $ctgKing = $kingAssoc{$ctg};
		my $ctgGenus = $genusAssoc{$ctg};
		my $virusGenus = $genusAssoc{$virus};
		print {$OUT} "$virus\t$ctg\t" . $count{$virus}->{$ctg} . "\t$virusGenus\t$ctgKing\t$ctgGenus\n";
	}
}
close $OUT;

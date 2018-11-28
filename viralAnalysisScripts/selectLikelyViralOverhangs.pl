#!/usr/bin/perl
# This is a one-shot script designed to process paf files for pacbio longread overhangs
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/7052/0_7126       7084    1274    6945    -       tig00499241     14167   8230    13990     3129    5809    60      tp:A:P  cm:i:283        s1:i:3105       s2:i:1971       dv:f:0.0382
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/10930/32417_45124 12705   3873    9067    +       tig00006933     14469   37      4948      631     5430    0       tp:A:S  cm:i:46 s1:i:427        dv:f:0.1097
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/12019/0_8460      8289    7257    8284    +       tig00003445     25924   2       1039      697     1045    60      tp:A:P  cm:i:72 s1:i:694        s2:i:0  dv:f:0.0246
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/12332/0_11594     11784   8825    11708   -       tig00498233     24287   21257   24239     1200    2987    0       tp:A:S  cm:i:106        s1:i:1176       dv:f:0.0528
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/27147/20338_33448 13135   72      6468    -       tig00005252     18616   12663   18566     2413    6432    60      tp:A:P  cm:i:188        s1:i:2268       s2:i:0  dv:f:0.0598
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/27177/0_9517      9467    362     5322    -       tig00003616     18859   13807   18830     3705    5059    21      tp:A:P  cm:i:356        s1:i:3695       s2:i:3458       dv:f:0.0247
# m170518_064744_42132_c101164092550000001823269008151702_s1_p0/27177/9562_19060  9419    4172    9155    +       tig00003616     18859   13807   18847     4173    5074    22      tp:A:P  cm:i:450        s1:i:4167       s2:i:3884       dv:f:0.0159

use strict;
use POSIX;
my $usage = "perl $0 <input paf file> <output file basename>\n";

chomp(@ARGV); 

unless(scalar(@ARGV) ==2){
	print $usage;
	exit;
}
# Output files:
# 1. unmapped subread bed file
# 2. contig mapping stats
# 3. contig -> read associations
# 4. unfiltered mapping stats
open(my $FA, "> $ARGV[1].subread.bed");
#open(my $MAP, "> $ARGV[1].map.stats");
open(my $CTG, "> $ARGV[1].ctg-read.associations");
open(my $TOT, "> $ARGV[1].unfiltered.stats");
open(my $IN, "< $ARGV[0]") || die "Could not open input PAF file!\n";
my %totStats; # stat container. Hash of arrays. Hash keys: "read_len", "read_size", "map_read_size", "unmap_read_size", "map_read_len", "readmq", "mapreadmq"
my %ctgreads; # container for contig read associations
my $read_errors = 0;
while(my $line = <$IN>){
	chomp $line;
	my @segs = split(/\t/, $line);
	push(@{$totStats{"read_len"}}, $segs[1]);
	push(@{$totStats{"read_size"}}, $segs[3] - $segs[2]);
	push(@{$totStats{"readmq"}}, $segs[11]);
	if($segs[9] > 500 && ($segs[7] < 200 || $segs[6] - $segs[8] < 200)){
		my $unmap_read_size = 0;
		my $right_end = ($segs[6] - $segs[8] < 200)? 1 : 0;
		my $read_unmapright = ($segs[1] - $segs[3] > $segs[1] - $segs[2])? 1 : 0;
		my $unmapPortion = 0;
		push(@{$totStats{"mapreadmq"}}, $segs[11]);
		push(@{$totStats{"map_read_len"}}, $segs[1]);
		push(@{$totStats{"map_read_size"}}, $segs[3] - $segs[2]);
		push(@{$ctgreads{$segs[5]}}, $segs[0]);
		if($segs[4] eq "+"){
			# read: ------
			# ctg:  --
			if($right_end && $read_unmapright){
				print {$FA} "$segs[0]\t$segs[3]\t$segs[1]\t$segs[5]\n";
				push(@{$totStats{"unmap_read_size"}}, $segs[1] - $segs[3]);
			}elsif(!$right_end && !$read_unmapright){
			# read: ------
			# ctg:     ---
				print {$FA} "$segs[0]\t0\t$segs[2]\t$segs[5]\n";
				push(@{$totStats{"unmap_read_size"}}, $segs[2]);
			}else{
				$read_errors++;
			}
		}else{
			# read: ------
			# ctg:  --
			if($right_end && !$read_unmapright){
                                print {$FA} "$segs[0]\t0\t$segs[2]\t$segs[5]\n";
                                push(@{$totStats{"unmap_read_size"}}, $segs[2]);
                        }elsif(!$right_end && !$read_unmapright){
			# read: ------
			# ctg:     ---	
			        print {$FA} "$segs[0]\t$segs[3]\t$segs[1]\t$segs[5]\n";
                                push(@{$totStats{"unmap_read_size"}}, $segs[1] - $segs[3]);
			}else{
				$read_errors++;
			}
		}
	}
}
close $FA;

# Now print CTG associations
foreach my $ctg (sort {scalar(@{$ctgreads{$b}}) <=> scalar(@{$ctgreads{$a}})} keys(%ctgreads)){
	print {$CTG} "$ctg\t" . scalar(@{$ctgreads{$ctg}}) . "\t" . join("\t", @{$ctgreads{$ctg}}) . "\n";
}
close $CTG;

# Now print stats
my @statTypes = ("COUNT", "SUM", "MIN", "MAX", "AVG", "MEDIAN", "STDEV");
print {$TOT} "\t" . join("\t", @statTypes) . "\n";
foreach my $keys (sort{$a cmp $b} keys %totStats){
	my %values = generateStats($totStats{$keys});
	my @svals;
	foreach my $s (@statTypes){
		push(@svals, $values{$s});
	}
	print {$TOT} "$keys\t" . join("\t", @svals) . "\n";
}
close $TOT;

print "Finished. Identified $read_errors errors\n";

exit;

sub generateStats{
	my ($aref) = @_;
	#my %values;
	my $sum=0;
	my $sqr=0;

	foreach my $v (@{$aref}){
		$sum += $v;
		$sqr += ($v * $v);
	}

	my @sort = sort{$a <=> $b} @{$aref};
	my $n = scalar(@sort);
	my $med = ($n % 2 == 0)? ($sort[$n/2 -1] + $sort[$n/2]) / 2 : $sort[floor($n/2)];
	if($n > 1){
		my %values = ("SUM" => $sum, "COUNT" => $n, "MEDIAN" => $med, "AVG" => ($sum / $n), "MIN" => $sort[0], "MAX" => $sort[-1], "STDEV" => sqrt( ($sqr * $n - $sum * $sum)/($n * ($n - 1))));
		return %values;
	}else{
		return ("SUM" => 0, "COUNT" => 0, "MEDIAN" => 0, "AVG" => 0, "MIN" => 0, "MAX" => 0, "STDEV" => 0);
	}
}

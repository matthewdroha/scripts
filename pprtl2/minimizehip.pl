#!/usr/intel/pkgs/perl/5.40.1/bin/perl

# Usage
# minimizehip.pl <input ldb.list or lib.list file>  <output directory for minimized file>
# Output directory is optional, default is $cwd

use v5.34.0;
use strict;
use warnings;
use English;
use IO::File;
use IO::Dir;
use File::Basename;
use Cwd;


my $listfile = shift;
my $outdir  = shift;

unless ($listfile) {
  die "-E- Input hip list file does not exist.  Provide on command line.\n";
}

if ($outdir) {
	die "-E- Outdir directory does not exist: $outdir\n" unless -d $outdir
} else {
	$outdir = cwd;
}


my $listfileh = new IO::File;
$listfileh->open($listfile) or die "-E- Could not open listfile for reading: $listfile\n";


my @hips;
my %hip_hash;
my $hip_key;
my $original_ldblib_count = 0;
while(<$listfileh>) {
	if (/^(\#HIP:\S+)\s*$/) {
		push(@hips, $1);
		$hip_key = $1;
		$hip_hash{$hip_key} = q(NOT FOUND);
	}
	if (/^(\S+\.(l?db|lib))\s*$/) {
		$original_ldblib_count++;
		my $ldblib = $1;
		# mroha: Rework to have smarts to set to nearest setpoint (Example: closest target to 0.85v and 100c)
		if (($ldblib =~ /(((\.|_)(nom|tttt)(\.|_)|\.85v|p85|850v|0\.85|0\.65|1p45)\S+((t|T)100|_1(0|1)0|100c|\-100\-))|(bgrgen3|dtsgen3|ip76xhptp_|pmaxgen6cbb|ucie_\w+phy_m(\d+)_\S+p76)|(0\.85\-tttt\-100\-)/) and not (/tmin/)) {
		  $hip_hash{$hip_key} = $ldblib;
	        }
        }
}
$listfileh->close;


my $basefilename = basename($listfile);
my $outfile = qq(${outdir}/${basefilename}.minimized);
my $outfileh = new IO::File;
my $final_ldblib_count = 0;
$outfileh->open(">$outfile") or die "-E- Could not open outfile for writing: $outfile\n";
print $outfileh qq(#Input .list file: $listfile\n\n);
foreach my $hip (@hips) {
	print $outfileh qq($hip\n);
	print $outfileh qq($hip_hash{$hip}\n\n\n);
	if ($hip_hash{$hip} =~ /\.(l?db|lib)/) {
		$final_ldblib_count++;
	}
}
my $original_hip_count = scalar @hips;
my $final_hip_count = scalar keys %hip_hash;
my $hips_missing_ldblib_count = $original_hip_count - $final_ldblib_count;
print $outfileh qq(#ORIGINAL_HIP_COUNT           : $original_hip_count\n);
print $outfileh qq(#FINAL_HIP_COUNT              : $final_hip_count\n);
print $outfileh qq(#ORIGINAL_LDB_OR_LIB_COUNT    : $original_ldblib_count\n);
print $outfileh qq(#FINAL_LDB_OR_LIB_COUNT       : $final_ldblib_count\n);
print $outfileh qq(#HIPS_MISSING_LDB_OR_LIB_COUNT: $hips_missing_ldblib_count\n);
say qq(#Minimized file written to: $outfile);
say qq(#HIP_COUNT:$final_hip_count\n);
say qq(#HIPS_MISSING_LDB_OR_LIB_COUNT: $hips_missing_ldblib_count  \(grep -B1 'NOT FOUND' and fix regexp if count greater than zero\));
if ($hips_missing_ldblib_count == 0) {
	print $outfileh qq(#PASS. All HIPs present..\n);
	say qq(#PASS. All HIPs present.);
}
$outfileh->close;

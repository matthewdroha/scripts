#!/usr/intel/pkgs/perl/5.40.1/bin/perl

# Usage
# minimizehip.pl <input ldb.list or lib.list file>  <output directory for minimized file>
# Output directory is optional, default is $cwd

use v5.40.1;
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


my $listfileh = IO::File->new;
$listfileh->open($listfile) or die "-E- Could not open listfile for reading: $listfile\n";


my @hips;
my %hip_hash;
my %hip_name;
my %hip_corner;
my %hip_candidates;
my $hip_key;
my $original_ldblib_count = 0;
my $voltage_target = 0.85;
my $temperature_target = 100;
while(<$listfileh>) {
	if (/^\#HIP:(\S+)\s*$/) {
		$hip_key = qq(#HIP:$1);
		push(@hips, $hip_key);
		$hip_name{$hip_key}       = $1;
		$hip_hash{$hip_key}       = q(NOT FOUND);
		$hip_corner{$hip_key}     = q(NO CORNER);
		$hip_candidates{$hip_key} = [];
	}
	if (/^(\S+\.(l?db|lib))\s*$/) {
		$original_ldblib_count++;
		push(@{$hip_candidates{$hip_key}}, $1) if defined $hip_key;
    }
}
$listfileh->close;


# Numeric field encodings differ per HIP vendor: 0.85v / 0p85 / 0p630v for voltage,
# 100c / m40c / -40c / neg40 / T125 / Tm40 / TT_100 / rcsscmaxpcss_m40 for temperature.
# Multi-voltage HIPs list several voltages; the first one is the primary supply.
sub parse_corner {
	my ($file, $hipname) = @_;

	my $n = basename($file);
	$n =~ s/\.(?:l?db|lib)$//;
	# Drop the HIP name so its digits are not mistaken for corner fields.
	$n =~ s/^\Q$hipname\E(?=[._-])//i if defined $hipname and length $hipname;

	# Normalize negative signs and 'T'-prefixed temperatures into delimited fields.
	$n =~ s/(?<=[._-])neg(?=\d)/m/gi;
	$n =~ s/(?<=[._-])-(?=\d)/m/g;
	$n =~ s/(?<=[._-])([Tt])(?=[mM]?\d)/${1}_/g;

	my @volts;
	while ($n =~ /(?<![0-9A-Za-z])(\d+(?:[.pP]\d+)?)[vV](?![0-9A-Za-z])/g) {
		push(@volts, to_num($1));
	}
	unless (@volts) {
		while ($n =~ /(?<![0-9A-Za-z])(\d+[.pP]\d+)(?![0-9A-Za-z])/g) {
			my $v = to_num($1);
			push(@volts, $v) if $v >= 0.1 and $v <= 3.0;
		}
	}

	my @temps;
	while ($n =~ /(?<![0-9A-Za-z])([mM]?)(\d+)[cC](?![0-9A-Za-z])/g) {
		push(@temps, to_signed($1, $2));
	}
	unless (@temps) {
		while ($n =~ /(?<![0-9A-Za-z])[Tt]_([mM]?)(\d+)(?![0-9A-Za-z])/g) {
			push(@temps, to_signed($1, $2));
		}
	}
	unless (@temps) {
		# Bare integer fields; the magnitude filter drops stray single digits.
		while ($n =~ /(?<![0-9A-Za-z])(?<![0-9][.pP])([mM]?)(\d+)(?![.pP]\d)(?![0-9A-Za-z])/g) {
			my $t = to_signed($1, $2);
			next unless $t == 0 or abs($t) >= 10;
			push(@temps, $t) if $t >= -100 and $t <= 250;
		}
	}

	return ($volts[0], $temps[0]);
}

sub to_num {
	my ($s) = @_;
	$s =~ s/p/./i;
	return $s + 0;
}

sub to_signed {
	my ($sign, $digits) = @_;
	return $sign ? -($digits + 0) : $digits + 0;
}

# Rank key: voltage delta, then temperature delta, then deterministic preferences.
sub rank_key {
	my ($file, $hipname) = @_;
	my ($v, $t) = parse_corner($file, $hipname);
	my $base = basename($file);
	return [
		(defined $v ? abs($v - $voltage_target)     : 999),
		(defined $t ? abs($t - $temperature_target) : 999),
		($base =~ /noise|(?:^|[._-])rv(?:[._-]|$)/  ? 1 : 0),
		($base =~ /(?:^|[._-])nom(?![0-9A-Za-z])/   ? 0 : 1),
		($base =~ /(?:^|[._-])(?:tttt|nom)/         ? 0 : 1),
		($base =~ /\.max\./ ? 0 : $base =~ /\.min\./ ? 1 : 2),
		$base,
		$v,
		$t,
	];
}

foreach my $hip (@hips) {
	my $best;
	my $best_key;
	foreach my $file (@{$hip_candidates{$hip}}) {
		my $key = rank_key($file, $hip_name{$hip});
		next if defined $best_key and not better_key($key, $best_key);
		($best, $best_key) = ($file, $key);
	}
	next unless defined $best;
	$hip_hash{$hip}   = $best;
	$hip_corner{$hip} = sprintf(q(%sV %sC),
		defined $best_key->[7] ? $best_key->[7] : q(?),
		defined $best_key->[8] ? $best_key->[8] : q(?));
}

sub better_key {
	my ($a_key, $b_key) = @_;
	for my $i (0 .. 5) {
		return 1 if $a_key->[$i] < $b_key->[$i];
		return 0 if $a_key->[$i] > $b_key->[$i];
	}
	return $a_key->[6] lt $b_key->[6] ? 1 : 0;
}


my $basefilename = basename($listfile);
my $outfile = qq(${outdir}/${basefilename}.minimized);
my $outfileh = IO::File->new;
my $final_ldblib_count = 0;
$outfileh->open(">$outfile") or die "-E- Could not open outfile for writing: $outfile\n";
print $outfileh qq(#Input .list file: $listfile\n);
print $outfileh qq(#Target corner: ${voltage_target}V ${temperature_target}C\n\n);
foreach my $hip (@hips) {
	print $outfileh qq($hip\n);
	print $outfileh qq(#CORNER:$hip_corner{$hip}\n);
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

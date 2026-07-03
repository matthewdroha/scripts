#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::File;
use Env;
use File::Basename;


my $fubmetals_cmd = "/p/mpg/proc/common2/utils/tool_utils/lay_utils/1.0_2009_01_15/bin/fubmetals_info";

my $snfile = shift;
my $snfilefh = IO::File->new;
unless (-e $snfile) {
  die "A .sn file must be provided as an argument\n";
}
$snfilefh->open($snfile) or die "Could not open SN file for reading: $snfile\n";

my $macro_found = 0;
my $in_instance_call = 0;
my $cell = '';
my $blackboxre;
my $instance;
my $master;
my @record;
my %power_hash;
while (<$snfilefh>) {
  if ($macro_found) {
    if ((/^\@/) and ($in_instance_call)) {
      my $powernets = join(' ', sort keys %power_hash);
      print "${instance} ${master} ${powernets}\n";
      $in_instance_call = 0;
    }
    if (/^\s*(\@\S+)\s+($blackboxre)\s+/) {
      $instance = $1;
      $master = $2;
      $in_instance_call = 1;
      %power_hash = ();
      @record = split;
      shift @record;
      shift @record;
      foreach my $net (@record) {
	if ($net =~ /^vc/) {
	  $power_hash{$net} = 1;
	}
      }
    }
    elsif ($in_instance_call) {
      if (/^\+\s+\S+/) {
	@record = split;
	foreach my $net (@record) {
	  if ($net =~ /^vc/) {
	    $power_hash{$net} = 1;
	  }
	}
      }
      if (/^\.EOM/) {
	$in_instance_call = 0;
      }
    }      
  } else {
    unless ($cell) {
      if (/Cell\s+:\s+(\w+)/) {
	$cell = $1;
      }
    }
    elsif (/\.MACRO/) {
      $blackboxre = `${fubmetals_cmd} -fub ${cell} -carmelboxes`;
      $blackboxre =~ s/\{|\}//g;
      $blackboxre =~ s/\s+/\|/g;
      $blackboxre =~ s/\|$//;
      print "     Target Fub->($cell)\n";
      print "Black Box RegEx->($blackboxre)\n";
      $macro_found = 1;
    }
  }
}
$snfilefh->close;

unless ($macro_found) {
  die "Provided file is not an SN file.  No .MACRO statement in file\n";
}



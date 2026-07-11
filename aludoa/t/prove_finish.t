#!/usr/intel/pkgs/perl/5.34.0/bin/perl

# prove_finish.t
# (C) Copyright Intel Corporation, 2019, Matthew Roha, matthew.d.roha@intel.com
#
# Documentation after __END__
#

use v5.34.0;
use strict;
use warnings;
use English;
use IO::File;
use File::Basename;
use File::Spec;
use Getopt::Long;
use Test::More;

my ($tfile, $tdir, $WORKAREA);

BEGIN {
  $tfile = File::Spec->rel2abs(__FILE__);
  $tdir = dirname($tfile);
  push (@INC, $tdir);  # not used yet
  $ENV{WORKAREA} = $WORKAREA = "${tdir}/alu";
}

Getopt::Long::Configure("prefix_pattern=(--)");
our ($opt_proj, $opt_proj_version, $opt_cfg, $opt_grp, $opt_baseline_version);
my $options_ok = GetOptions("proj=s", "proj_version=s", "cfg=s", "grp=s", "baseline_version=s");
my $testprefix = basename($tfile, '.t');

sub get_intel_datetime {
  my $label = shift;
  unless ($label) {$label = ""};
  my $date_command = q(echo "`/usr/intel/bin/workweek -f '%a %b %d %T %Z %Y'` `/usr/intel/bin/workweek -f 'WW%02IW' 'now-1*day'`.`/usr/intel/bin/workweek -f '%u'`");
  my $datestring = ${label}." ".`$date_command`;
  return $datestring;
}

plan tests => 1;

is(diag(get_intel_datetime($testprefix)), 0, "prove_finish_datestamp");


__END__

=pod

=head1 DESCRIPTION

Grab finish time

=cut

#!/usr/intel/pkgs/perl/5.34.0/bin/perl

# schema.t
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

plan tests => 5;

is($options_ok, 1, q(prove command line options ok)) or BAIL_OUT(qq(command line options not valid;  should be one of --proj, --proj_version, --cfg, --grp, --baseline_version));

is(($options_ok and defined $opt_proj), 1, 'opt_proj provided') or BAIL_OUT("proj value not provided. Example: prove :: --proj mmg --proj_version latest");

is(-e "/p/hdk/pu_tu/prd/${opt_proj}_infra_configs/${opt_proj_version}", 1, 'proj version exists') or BAIL_OUT("proj version does not exist: /p/hdk/pu_tu/prd/${opt_proj}_infra_configs/${opt_proj_version}");

my $baseline_version = qq();
if ($opt_baseline_version) {
  system qq(ln -sfn /p/hdk/pu_tu/prd/baseline_tools/${opt_proj}/${opt_baseline_version} ${WORKAREA}/baseline_tools);
} 

is (-d qq(${WORKAREA}/baseline_tools), 1, q(baseline_tools exists)) or BAIL_OUT(qq(baseline_tools does not resolve to a directory: ${WORKAREA}/baseline_tools));

my $cfg_switch = qq();
if ($opt_cfg) {
  $cfg_switch = qq(-cfg $opt_cfg);
}

my $grp_switch = qq();
if ($opt_grp) {
  $grp_switch = qq(-grp $opt_grp);
}


#foreach my $cfg (qw(cicg mig cig dteg)) {

is(system("/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -schema_check -verbose -cmd \'/bin/true\' >& ${WORKAREA}/${opt_proj}.prove.schema_check")/256, 0, "cth_psetup schema_check $opt_proj") or BAIL_OUT("DOA schema check for -p ${opt_proj}/${opt_proj_version}");

#}


__END__

=pod

=head1 DESCRIPTION

Contains schema_only check for target liteinfra

=cut

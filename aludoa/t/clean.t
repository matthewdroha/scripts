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

plan tests => 2;

is($options_ok, 1, q(prove command line options ok)) or BAIL_OUT(qq(command line options not valid;  should be one of --proj, --proj_version, --cfg, --grp, --baseline_version));

is(($options_ok and defined $opt_proj), 1, 'opt_proj provided') or BAIL_OUT("proj value not provided. Example: prove :: --proj mmg --proj_version latest");

system(qq(rm -rf ${WORKAREA}/subip));
system(qq(rm -rf ${WORKAREA}/output));
system(qq(rm -rf ${WORKAREA}/${opt_proj}.prove.*));
system(qq(rm -f ${WORKAREA}/env.dump));

__END__

=pod

=head1 DESCRIPTION

Cleans alu workarea

=cut

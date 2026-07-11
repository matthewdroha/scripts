#!/usr/intel/pkgs/perl/5.26.1/bin/perl

use v5.26.1;
use strict;
use warnings;
use English;
use IO::File;
use File::Basename;
use File::Spec;
use Test::More;

my $tfile;

BEGIN {
  $tfile = File::Spec->rel2abs(__FILE__);
  push @INC, dirname($tfile);
}

plan tests => 5;
use_ok('ProveUtils');
is(exists $ENV{'CFG_PROJECT'}, 1, 'CFG_PROJECT set') or BAIL_OUT('$CFG_PROJECT not set');
is(exists $ENV{'TSA_PATH_OVR'}, 1, 'TSA_PATH_OVR set') or BAIL_OUT('$TSA_PATH_OVR not set');
is(duplicate_tests_in_testrules($tfile), 0, 'No duplicate tests in testrules.yml') or BAIL_OUT('Test(s) listed multiple times in testrules.yml');
is(tests_not_in_testrules($tfile), 0, 'Tests need to be listed testrules.yml') or BAIL_OUT('Test(s) missing from testrules.yml');

#TODO: {
#  local $TODO = "Extra tests can run at the end OK";
#  is(tests_not_in_testrules($tfile), 0, 'Tests need to be listed testrules.yml') or BAIL_OUT('Test(s) missing from testrules.yml');
#}

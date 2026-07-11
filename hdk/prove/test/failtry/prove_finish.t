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
  push @INC, q(/nfs/fm/disks/w.mroha.102/prove);
  $tfile = File::Spec->rel2abs(__FILE__);
}

my $testprefix = basename($tfile, '.t');
plan tests => 1;
use_ok('ProveUtils');
diag(get_intel_datetime($testprefix));

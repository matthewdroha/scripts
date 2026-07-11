#!/usr/intel/pkgs/perl/5.26.1/bin/perl

use v5.26.1;
use strict;
use warnings;
use English;
use IO::File;
use File::Basename;
use File::Spec;
use Test::More;

BEGIN {
  push @INC, q(/nfs/fm/disks/w.mroha.102/prove);
}

plan tests => 2;
use_ok('ProveUtils');
is(exists $ENV{'CFG_PROJECT'}, 1, 'CFG_PROJECT set') or BAIL_OUT('$CFG_PROJECT not set');

#!/usr/intel/pkgs/perl/5.26.1/bin/perl


use v5.26.1;
use strict;
use warnings;
use IO::File;
use File::Basename;
use Getopt::Long;
use File::Spec;

my $pmfile;

BEGIN {
  push @INC, q(/nfs/fm/disks/w.mroha.102/prove);
  $pmfile = File::Spec->rel2abs(__FILE__);
}

use ProveUtils;

my $dut = q(phygsk);
write_prove_summary_xlsx($pmfile, $dut);


#!/usr/intel/pkgs/perl/5.26.1/bin/perl

use v5.26.1;
use strict;
use warnings;
use IO::File;
use File::Basename;
use Getopt::Long;
use File::Spec;

our ($tfile, $logfileh, $dut, $ip_root);

BEGIN {
  push @INC, q(/nfs/fm/disks/w.mroha.102/prove);
  $tfile = File::Spec->rel2abs(__FILE__);
}

use Test::More;
use ProveUtils;

my $tdir = dirname($tfile);
$ip_root = $tdir =~ s/\/t$//r;
# If --ip-root <path> specified, it wins
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("ip-root=s", => \$ip_root);


my $command_string = <<'ENDCMD';
simbuild -dut phygske -1c -CUST ADPS -1c-
ENDCMD


my @commands = get_commands_from_string($command_string);
my $count = scalar @commands;

plan tests =>  $count + 1;

is(-d "${ip_root}/cfg", 1, '$ip_root/cfg exists') or BAIL_OUT("\$ip_root/cfg directory doesn't exist: ${ip_root}/cfg");
open_handles($tfile, \$logfileh);
test_commands($tfile, \@commands, $ip_root, $logfileh);

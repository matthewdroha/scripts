#!/usr/intel/pkgs/perl/5.14.1-threads/bin/perl

=pod

=head1 COPYRIGHT

--------------------------------------------------------------------------------
INTEL CONFIDENTIAL

(C) Copyright Intel Corporation, 2017
All Rights Reserved.
The source code contained or described herein and all documents related to the
source code ("Material") are owned by Intel Corporation or its suppliers or
licensors. Title to the Material remains with Intel Corporation or its
suppliers and licensors. The Material contains trade secrets and proprietary
and confidential information of Intel or its suppliers and licensors. The
Material is protected by worldwide copyright and trade secret laws and treaty
provisions. No part of the Material may be used, copied, reproduced, modified,
published, uploaded, posted, transmitted, distributed, or disclosed in any way
without Intels prior express written permission.

No license under any patent, copyright, trade secret or other intellectual
property right is granted to or conferred upon you by disclosure or delivery
of the Materials, either expressly, by implication, inducement, estoppel or
otherwise. Any license under such intellectual property rights must be express
and approved by Intel in writing.

--------------------------------------------------------------------------------


=head1 NAME

build_toolver_csv.pl - Build .csv summary from basline tools and setup tool session hashes

Author: Matthew Roha


=head SYNOPSIS

build_toolver_csv.pl is an executable script to do the following:
(1) Loads Baseline tool data to tracking hash
(2) Loads MAT tool data to tracking hash
(4) Loads UE setup sd tool data to tracking hash for 1222, 1273, and 1274
(3) Load 1613, 1639, and 1713 overrides into tracking hash

Information in standard hash:
- tool
- FE, BE, or both  (in onecfg and UE)
- source (Baseline, MAT, etc)
- tsetup tool
- version

=head DESCRIPTION


=cut

use v5.14.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use Time::Local;
use IO::File;
use IO::Dir;
use Cwd;


BEGIN {
  push (@INC, q(/p/hdk/rtl/proj_tools/baseline_tools/master/1.4.10));
}

my $debug = 1;

say qq(DEBUG Perl version: $^V) if $debug;

my %common_hash;

# Precondition required variables to read baseline
$ENV{'MODEL_ROOT'} = $ENV{'HOME'};
$ENV{'CFG_PROJECT'} = q(sip);

# Load GeneralVars
require GeneralVars;
say qq(DEBUG RTL_PROJ_TOOLS $ToolData::RTL_PROJ_TOOLS) if $debug;
say qq(DEBUG RTL_CAD_ROOT $ToolData::RTL_CAD_ROOT) if $debug;
$ENV{RTL_CAD_ROOT} = $ToolData::RTL_CAD_ROOT;
$ENV{RTL_PROJ_TOOLS} = $ToolData::RTL_PROJ_TOOLS;


# Load Baseline_domainToolData
require Baseline_domainToolData;
my $kit = q(HDK 1.4.10 ONESRC);
my $source = q(BASELINE_DOMAIN);
my $process = q(ALL);
my $mat_rule = '';
foreach my $tool (keys %ToolData::ToolConfig_tools) {
  if (exists $ToolData::ToolConfig_tools{$tool}{'VERSION'}) {
    my $version = $ToolData::ToolConfig_tools{$tool}{'VERSION'};
    $version =~ s/(n\/a)|(NoToolVer)|(undef)/NOT_SET/;
    $common_hash{$tool}{$source}{'TOOL'} = $tool;
    $common_hash{$tool}{$source}{'VERSION'} = $version;
    $common_hash{$tool}{'FE'} = 1;
    $common_hash{$tool}{$source}{'KIT'} = $kit;
    $common_hash{$tool}{$source}{'SOURCE'} = $source;
    $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = 'NOT_TSETUP';
    $common_hash{$tool}{$source}{'MAT_RULE'} = $mat_rule;
    $common_hash{$tool}{$source}{'PROCESS'} = $process;
    say qq(DEBUG $tool $version $source $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'}) if $debug;
  }
}


# Load Baseline Tools  (which also calls the MAT list)
require Baseline_ToolData;
foreach my $tool (keys %ToolData::ToolConfig_tools) {
  if (exists $common_hash{$tool}) {
    say qq(DEBUG Found tool $tool already in common_hash, skipping...) if $debug;
    next;
  }
  if (exists $ToolData::ToolConfig_tools{$tool}{'VERSION'}) {
    my $version = $ToolData::ToolConfig_tools{$tool}{'VERSION'};
    $version =~ s/(n\/a)|(NoToolVer)|(undef)/NOT_SET/;
    $source = 'BASELINE';
    $mat_rule = '';
    if (exists $ToolData::ToolConfig_tools{$tool}{'MAT_RULE'}) {
      $source = 'MAT';
      $mat_rule = $ToolData::ToolConfig_tools{$tool}{'MAT_RULE'};
    }
    if (exists $ToolData::ToolConfig_tools{$tool}{OTHER}{'MAT_RULE'}) {
      $source = 'MAT';
      $mat_rule = $ToolData::ToolConfig_tools{$tool}{OTHER}{'MAT_RULE'};
    }
    say qq(DEBUG $source TOOL FOUND: $tool) if $debug;
    $common_hash{$tool}{$source}{'TOOL'} = $tool;
    $common_hash{$tool}{$source}{'VERSION'} = $version;
    $common_hash{$tool}{'FE'} = 1;
    $common_hash{$tool}{$source}{'KIT'} = $kit;
    $common_hash{$tool}{$source}{'SOURCE'} = $source;
    $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = 'NOT_TSETUP';
    $common_hash{$tool}{$source}{'MAT_RULE'} = $mat_rule;
    $common_hash{$tool}{$source}{'PROCESS'} = $process;
    if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}) {
      if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'TSETUP_TOOLNAME'}) {
	$common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'TSETUP_TOOLNAME'};
      }
    }
    say qq(DEBUG $tool $version $source $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'}) if $debug;
  }
}


# Write out csv for Excel consumption
my $csvfile = "1410.toolver.csv";
my $csvfile_h = IO::File->new;
$csvfile_h->open(">$csvfile") or die "Could not open csvfile for writing: $csvfile\n";
my @field_list = qw(TOOL KIT SOURCE PROCESS VERSION MAT_RULE TSETUP_TOOLNAME);
my $csv_header = join(',', @field_list);
$csvfile_h->print("$csv_header\n");
#say qq($csv_header);
my @csv_data;
foreach my $tool (sort { "\U$a" cmp "\U$b" } keys %common_hash) {
  if ($tool =~ /stage_bman/) {next;};
  foreach my $source (sort keys %{ $common_hash{$tool} }) {
    if ($source =~ /^(BE)|(FE)$/) {next;}
    my @csv_values = ();
    foreach my $field (@field_list) {
      if ($debug) {
        if ($field eq 'TSA') {next}
        unless (defined $common_hash{$tool}{$source}{$field}) {
          say qq (DEBUG MISSING DATA DURING WRITE CSV $tool $source $field);
        }
      }
      push (@csv_values, $common_hash{$tool}{$source}{$field});
    }
    my $csv_row = join(',', @csv_values);
    $csvfile_h->print("$csv_row\n");
    #say qq($csv_row);
  }
}


sub numerically {$a <=> $b;}

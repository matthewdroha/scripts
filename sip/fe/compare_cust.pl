#!/usr/intel/pkgs/perl/5.20.1-threads/bin/perl

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

compare_cust.pl - Compare two TSA customer registry hashes

Author: Matthew Roha


=head SYNOPSIS

compare_cust.pl is an executable script to do the following:
(1) Report missing CUST definitions between two CUST cfg files
(2) Report process definition differences between two CUST cfg files
(3) Report differences in toolset definitions between two CUST cfg files


=head DESCRIPTION


=cut


use v5.20.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use Time::Local;
use IO::File;
use IO::Dir;


say qq(Perl version: $^V);

my $file1 = shift;
my $file2 = shift;

unless (-e $file1) {
  die "Could not open file1 for reading: $file1\n";
}
our %ToolConfig_tools;
require $file1;


unless (-e $file2) {
  die "Could not open file2 for reading: $file2\n";
}
# Need to rename hash in external file for now
our %ToolConfig_tools_new;
require $file2;

# In original file, but not in new file
say qq(\n---);
say qq(Checking for CUST values in original file but not in new file);
my $diff_found = 0;
my %common_cust;
foreach my $CUST (keys %ToolConfig_tools) {
  if(exists $ToolConfig_tools_new{$CUST}) {
    $common_cust{$CUST} = 1;
  } else {
    say qq(** CUST->($CUST) in original file but not in new file **);
    $diff_found = 1;
  }
}
unless ($diff_found) {
  say qq(All CUST values in original file exists in new file);
}
say qq(---\n);

# In new file, but not in original file
say qq(\n---);
say qq(Checking for CUST values in new file but not in original file);
$diff_found = 0;
foreach my $CUST (keys %ToolConfig_tools_new) {
  if(exists $ToolConfig_tools{$CUST}) {
    $common_cust{$CUST} = 1;
  } else {
    say qq(** CUST->($CUST) in original file but not in new file **);
    $diff_found = 1;
  }
}
unless ($diff_found) {
  say qq(All CUST values in new file exist in original file);
}
say qq(---\n);


# Check for PROCESS differences between CUST keys
$diff_found = 0;
say qq(\n---);
say qq(Checking for PROCESS differences between cust files);
foreach my $CUST (keys %common_cust) {
  my $original_process = $ToolConfig_tools{$CUST}{PROCESS};
  my $new_process = $ToolConfig_tools_new{$CUST}{PROCESS};
  if ($original_process ne $new_process) {
    say qq(** Key->($CUST) Orig->($original_process) New->($new_process). Mismatch between CUST settings **);
    $diff_found = 1;
  }
}
unless ($diff_found) {
  say qq(PROCESS settings for all CUST values match);
}
say qq(---\n);


# Check for toolset list and value differences

# TOOLSET in original file but not in new file
$diff_found = 0;
say qq(\n---);
say qq(Checking for TOOLSETs in original file but not in new file);
my %toolset_hash;
foreach my $CUST (keys %common_cust) {
  foreach my $toolset (keys %{ $ToolConfig_tools{$CUST} }) {
    if ($toolset =~ /TOOLSET/) {
      if (exists $ToolConfig_tools_new{$CUST}{$toolset}) {
	$toolset_hash{$CUST}{$toolset} = 1;
      } else {
	say qq(** Key->($CUST) Toolset->($toolset) in original file but not in new file **);
	$diff_found = 1;
      }
    }
  }
}
unless ($diff_found) {
  say qq(All TOOLSET values in original file exist in new file);
}
say qq(---\n);


# TOOLSET in new file but not in original file
$diff_found = 0;
say qq(\n---);
say qq(Checking for TOOLSETs in new file but not in original file);
foreach my $CUST (keys %common_cust) {
  foreach my $toolset (keys %{ $ToolConfig_tools_new{$CUST} }) {
    if ($toolset =~ /TOOLSET/) {
      if (exists $ToolConfig_tools{$CUST}{$toolset}) {
	$toolset_hash{$CUST}{$toolset} = 1;
      } else {
	say qq(** Key->($CUST) Toolset->($toolset) in new file but not in original file **);
	$diff_found = 1;
      }
    }
  }
}
unless ($diff_found) {
  say qq(All TOOLSET values in new file exist in original file);
}
say qq(---\n);


# Check TOOLSET values where common
$diff_found = 0;
say qq(\n---);
say qq(Checking for lock setting differences between TOOLSETs);
foreach my $CUST (keys %toolset_hash) {
  foreach my $toolset (keys % {$toolset_hash{$CUST}}) {
    my $original_toolset = $ToolConfig_tools{$CUST}{$toolset};
    my $new_toolset = $ToolConfig_tools_new{$CUST}{$toolset};
    if ($original_toolset ne $new_toolset) {
      say qq(** CUST->($CUST) TOOLSET->($toolset) Original->($original_toolset) New->($new_toolset). Mismatch between TOOLSET settings **);
      $diff_found = 1;
    }
  }
}
unless ($diff_found) {
  say qq(PROCESS settings for all CUST values match);
}
say qq(---\n);

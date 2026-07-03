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
  push (@INC, q(/p/hdk/rtl/proj_tools/baseline_tools/master/1.4.2));
}

my $tsa_version;
my $debug;

if (scalar @ARGV == 2) {
  $tsa_version = shift @ARGV;
  $debug = 1;
}
elsif (scalar @ARGV == 1) {
  $tsa_version = shift @ARGV;
  $debug = 0;
} else {
  die "build_toolver_csv.pl <TSA VERSION> [-debug]\n";
}


say qq(DEBUG Perl version: $^V) if $debug;

# TSA version and input files location
my $input_dir = qq(/nfs/fm/disks/fm_hip_00023/tsa/${tsa_version});
my $common_dir = qq(/nfs/fm/disks/fm_hip_00023/tsa/common);

# Load earmarks
my %earmarks;
my $common_dir_h = IO::Dir->new;
$common_dir_h->open($common_dir) or die "Could not open directory for reading: $common_dir\n";
my @earmark_files = grep /^earmark\.tools\.\w+$/, $common_dir_h->read;

$common_dir_h->close;
if (@earmark_files) {
  foreach my $earmark_file (@earmark_files) {
    say qq(DEBUG Earmark file $earmark_file) if $debug;
    my $earmark_file_h = IO::File->new;
    my $target_file = qq(${common_dir}/${earmark_file});
    $earmark_file_h->open($target_file) or die "Could not open file for reading: $target_file\n";
    my $earmark = $earmark_file;
    $earmark =~ s/earmark\.tools\.//;
    while (<$earmark_file_h>) {
      my @record = split;
      foreach my $tool (@record) {
        $earmarks{$tool}{$earmark} = 1;
        say qq(DEBUG Found earmark $tool $earmark) if $debug;
      }
    }
    $earmark_file_h->close;
  }
}


my %common_hash;
my %doc_hash;

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
my $kit = q(HDK 1.4.2 ONESRC);
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
    if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}) {
      if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'}) {
        $doc_hash{$tool}{'HDK_RELEASE_NOTES'} = $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'};
        if (exists $ToolData::ToolConfig_tools{$tool}{'PATH'}) {
          my $tool_path = $ToolData::ToolConfig_tools{$tool}{'PATH'};
          $doc_hash{$tool}{'HDK_RELEASE_NOTES'} =~ s/\&get_tool_path\(\)/$tool_path/;
        }
      }
    }
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
    if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}) {
      if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'}) {
        $doc_hash{$tool}{'HDK_RELEASE_NOTES'} = $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'};
        if (exists $ToolData::ToolConfig_tools{$tool}{'PATH'}) {
          my $tool_path = $ToolData::ToolConfig_tools{$tool}{'PATH'};
          $doc_hash{$tool}{'HDK_RELEASE_NOTES'} =~ s/\&get_tool_path\(\)/$tool_path/;
        }
      }
    }
    say qq(DEBUG $tool $version $source $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'}) if $debug;
  }
}



# Load tool session files from UE backend setup (pre-ran and defined above)
my %uesource;
$uesource{'HDK1.4.2_73P1'}{'FILE'} = qq(${input_dir}/p1273d1/tools.session.p1273d1);
$uesource{'HDK1.4.2_73P1'}{'PROCESS'} = q(p1273.1);

$uesource{'HDK1.4.2_22P2'}{'FILE'} = qq(${input_dir}/p1222d2/tools.session.p1222d2);
$uesource{'HDK1.4.2_22P2'}{'PROCESS'} = q(p1222.2);

$uesource{'HDK1.4.2_74P0'}{'FILE'} = qq(${input_dir}/p1274d0/tools.session.p1274d0);
$uesource{'HDK1.4.2_74P0'}{'PROCESS'} = q(p1274.0);

$mat_rule = '';
$kit = q(HDK 1.4.2 UESETUP);
foreach my $source (keys %uesource) {
  unless (-e $uesource{$source}{'FILE'}) {die "Could not open file for reading: $uesource{$source}{'FILE'}\n";}
  my $dumper_file = $uesource{$source}{'FILE'};
  my $toolVersionHash = do $dumper_file;
  $process = $uesource{$source}{'PROCESS'};;
  foreach my $tool (keys %{ $toolVersionHash }) {
    my $version;
    if (exists $$toolVersionHash{$tool}{'version'}) {
      $version = $$toolVersionHash{$tool}{'version'};
      my @record = split ('/', $version);
      $version = pop(@record);
      $version =~ s/(n\/a)|(NoToolVer)|(undef)/NOT_SET/;
      $common_hash{$tool}{$source}{'TOOL'} = $tool;
      $common_hash{$tool}{$source}{'VERSION'} = $version;
      $common_hash{$tool}{'BE'} = 1;
      $common_hash{$tool}{$source}{'KIT'} = $kit;
      $common_hash{$tool}{$source}{'SOURCE'} = $source;
      $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = 'SETPROJ';
      $common_hash{$tool}{$source}{'MAT_RULE'} = $mat_rule;
      $common_hash{$tool}{$source}{'PROCESS'} = $process;
    }
  }
}


# Load lock overrides (which includes BE overrides)
my %locksource;
$locksource{'1713 Lock - 1273'}{'FILE'} = qq(${input_dir}/p1273d1/ToolData.p1273.common.snap);
$locksource{'1713 Lock - 1273'}{'PROCESS'} = q(p1273.1);


$locksource{'1713 Lock - 1222'}{'FILE'} = qq(${input_dir}/p1222d2/ToolData.p1222.common.snap);
$locksource{'1713 Lock - 1222'}{'PROCESS'} = q(p1222.2);


$locksource{'1713 Lock - 1274'}{'FILE'} = qq(${input_dir}/p1274d0/ToolData.p1274.common.snap);
$locksource{'1713 Lock - 1274'}{'PROCESS'} = q(p1274.0);


foreach my $source (keys %locksource) {
  unless (-e $locksource{$source}{'FILE'}) {die "Could not open file for reading: $locksource{$source}{'FILE'}\n";} 
  my $dumper_file = $locksource{$source}{'FILE'};
  our %ToolConfig_tools = ();
  require $dumper_file;
  $process = $locksource{$source}{'PROCESS'};
  foreach my $tool (keys %ToolConfig_tools) {
    my $version;
    if (exists $ToolConfig_tools{$tool}{VERSION}) {
      $version = $ToolConfig_tools{$tool}{VERSION};
      my @record = split ('/', $version);
      $version = pop(@record);
      $version =~ s/(n\/a)|(NoToolVer)|(undef)/NOT_SET/;
      $common_hash{$tool}{$source}{'TOOL'} = $tool;
      $common_hash{$tool}{$source}{'VERSION'} = $version;
      $common_hash{$tool}{'FE'} = 1;
      $common_hash{$tool}{$source}{'KIT'} = $source;
      $common_hash{$tool}{$source}{'SOURCE'} = $source;
      $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = 'NOT_TSETUP';
      $common_hash{$tool}{$source}{'MAT_RULE'} = $mat_rule;
      $common_hash{$tool}{$source}{'PROCESS'} = $process;
      if (exists $ToolConfig_tools{$tool}{'OTHER'}) {
        if (exists $ToolConfig_tools{$tool}{'OTHER'}{'TSETUP_TOOLNAME'}) {
          $common_hash{$tool}{$source}{'TSETUP_TOOLNAME'} = $ToolConfig_tools{$tool}{'OTHER'}{'TSETUP_TOOLNAME'};
        }
      }
      if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}) {
        if (exists $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'}) {
          $doc_hash{$tool}{'HDK_RELEASE_NOTES'} = $ToolData::ToolConfig_tools{$tool}{'OTHER'}{'HDK_RELEASE_NOTES'};
          if (exists $ToolData::ToolConfig_tools{$tool}{'PATH'}) {
            my $tool_path = $ToolData::ToolConfig_tools{$tool}{'PATH'};
            $doc_hash{$tool}{'HDK_RELEASE_NOTES'} =~ s/\&get_tool_path\(\)/$tool_path/;
          }
        }
      }
      if ($tool eq 'tsa_dc_config') {
        if (exists $ToolConfig_tools{$tool}{SETUP}) {
          if (exists $ToolConfig_tools{$tool}{SETUP}{-be_tool_override}) {
            foreach my $override_tool (keys %{ $ToolConfig_tools{$tool}{SETUP}{-be_tool_override} }) {
              my $override_version = $ToolConfig_tools{$tool}{SETUP}{-be_tool_override}{$override_tool};
              my $override_source = qq($source UE_OVERRIDE);
              $common_hash{$override_tool}{$override_source}{'TOOL'} = $override_tool;
              $common_hash{$override_tool}{$override_source}{'VERSION'} = $override_version;
              $common_hash{$override_tool}{'BE'} = 1;
              $common_hash{$override_tool}{$override_source}{'KIT'} = $source;
              $common_hash{$override_tool}{$override_source}{'SOURCE'} = $override_source;
              $common_hash{$override_tool}{$override_source}{'TSETUP_TOOLNAME'} = 'NOT_TSETUP';
              $common_hash{$override_tool}{$override_source}{'MAT_RULE'} = $mat_rule;
              $common_hash{$override_tool}{$override_source}{'PROCESS'} = $process;
            }
          }
        }
      }
    }
  }
}



# Resolve any where tool versions are aliased to a different tool name through &get_tool_version
foreach my $tool (keys %common_hash) {
  foreach my $source (keys %{ $common_hash{$tool} }) {
    if ($source =~ /^(BE)|(FE)$/) {next;}
    my $version = $common_hash{$tool}{$source}{'VERSION'};
    say qq(DEBUG BEFORE:$tool $version) if $debug;
    if ($version =~ /get_tool_version\(\W?(\w+)\W?\)/) {
      my $alias_tool = $1;
      say qq(DEBUG VERSION ALIAS FOUND: $source $tool $version $alias_tool) if $debug;
      if (exists $common_hash{$alias_tool}) {
        say qq(DEBUG ALIAS TOOL FOUND) if $debug;
        if ($source =~ /^\s*(.+)\s+UE_OVERRIDE/) {
          my $local_source = $1;
          say qq(DEBUG SEARCH LOCAL SOURCE $local_source $alias_tool) if $debug;
          if (exists $common_hash{$alias_tool}{$local_source}{'VERSION'}) {
            say qq(DEBUG FOUND MATCH Move $source $tool TO $local_source $alias_tool $common_hash{$alias_tool}{$local_source}{'VERSION'}) if $debug;
            $common_hash{$tool}{$source}{'VERSION'} = $common_hash{$alias_tool}{$local_source}{'VERSION'};
          }
        } else {
          foreach my $local_source (keys %{ $common_hash{$alias_tool} }) {
            if ($local_source =~ /^(BE)|(FE)$/) {next;}
            say qq(DEBUG SEARCH LOCAL SOURCE $local_source $alias_tool) if $debug;
            if (exists $common_hash{$alias_tool}{$local_source}{'VERSION'}) {
              if ($local_source =~ /BASELINE|MAT/) {
                say qq(DEBUG FOUND MATCH Move $source $tool TO $local_source $alias_tool $common_hash{$alias_tool}{$local_source}{'VERSION'}) if $debug;
                $common_hash{$tool}{$source}{'VERSION'} = $common_hash{$alias_tool}{$local_source}{'VERSION'};
                last;
              }
            }
          }
        }
      }
    }
  }
}


my %sources;
foreach my $tool (keys %common_hash) {
  foreach my $source (keys %{ $common_hash{$tool} }) {
    $sources{$source} = 1;
  }
}

foreach my $source (keys %sources) {
  say qq(DEBUG SOURCE:$source) if $debug;
}


# Set final tool attributes
foreach my $tool (keys %common_hash) {

  # Classify source type:  FE, BE, or both 
  my $final = '';
  my $fe = 0;
  my $be = 0;
  if (exists $common_hash{$tool}{'FE'}) {$fe = 1;}
  if (exists $common_hash{$tool}{'BE'}) {$be = 1;}
  if ($fe and $be) { $final = q(FE/BE);}
  elsif ($fe) { $final = q(FE);}
  elsif ($be) { $final = q(BE);}
  else {$final = q(ERROR);}

  # Set earmarks
  my @earmark_list;
  my $earmark_string = '';
  if (exists $earmarks{$tool}) {
    #@earmark_list = map { '@'. $_} sort keys %{ $earmarks{$tool} };
    $earmark_string = join(' ', map { '@'. $_} sort keys %{ $earmarks{$tool} });
  }

  # Set MAT rule
  my $mat_rule = '';
  if (exists $common_hash{$tool}{'MAT'}) {
    $mat_rule = $common_hash{$tool}{'MAT'}{'MAT_RULE'}
  }


  # Resolve final tool version for lock
  my $baseline;
  my $override;
  my %classify = ();
  my %process_classify = ();
  my %version_count = ();
  foreach my $source (sort keys %{ $common_hash{$tool} }) {
    if ($source =~ /^(BE)|(FE)$/) {next;}
    my $toolname = $common_hash{$tool}{$source}{'TOOL'};
    my $toolversion = $common_hash{$tool}{$source}{'VERSION'};
    my $process = $common_hash{$tool}{$source}{'PROCESS'};
    $version_count{$toolversion}++;
    say qq(DEBUG VERSIONS $final $source $toolname $toolversion $process)  if $debug;
    if ($final eq 'BE') {
      if ($source =~ /\bUE_OVERRIDE\b/) {
        $classify{1}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{1}{$version_count{$toolversion}}{$toolversion} = $source;
      }
      elsif ($source =~ /\bHDK\w/) {
        $classify{2}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{2}{$version_count{$toolversion}}{$toolversion} = $source;
      } else {
        say qq(DEBUG ERROR UNKNOWN SOURCE $source $toolname $toolversion $process)  if $debug;
      }
    }
    elsif ($final eq 'FE') {
      if ($source =~ /\bLock\b/) {
        $classify{1}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{1}{$version_count{$toolversion}}{$toolversion} = $source;
      }
      elsif ($source =~ /\b(BASELINE|MAT)/) {
        $classify{2}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{2}{$version_count{$toolversion}}{$toolversion} = $source;

      } else {
        say qq(DEBUG ERROR UNKNOWN SOURCE $source $toolname $toolversion $process)  if $debug;
      }
    }
    elsif ($final eq 'FE/BE') {
      if ($source =~ /\bUE_OVERRIDE\b/) {
        $classify{1}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{1}{$version_count{$toolversion}}{$toolversion} = $source;
      }
      elsif ($source =~ /\bLock\b/) {
        $classify{2}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{2}{$version_count{$toolversion}}{$toolversion} = $source;
      }
      elsif ($source =~ /\b(BASELINE|MAT)/) {
        $classify{3}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{3}{$version_count{$toolversion}}{$toolversion} = $source;
      }
      elsif ($source =~ /\bHDK\w/) {
        $classify{4}{$version_count{$toolversion}}{$toolversion} = $source;
        $process_classify{$process}{4}{$version_count{$toolversion}}{$toolversion} = $source;
      } else {
        say qq(DEBUG ERROR UNKNOWN SOURCE $source $toolname $toolversion $process)  if $debug;
      }
    }
  }

  if ($debug) {
    if ($earmark_string =~ /\@process/) {
      foreach my $process (sort keys %process_classify) {
        foreach my $rank (sort numerically keys %{ $process_classify{$process} }) {
          foreach my $count (reverse sort numerically keys %{ $process_classify{$process}{$rank} }) {
            foreach my $version (keys %{ $process_classify{$process}{$rank}{$count} }) {
              say qq(DEBUG CLASSIFIED PROCESS BUCKET $tool $process_classify{$process}{$rank}{$count}{$version} $version $process $rank $count);
            }
          }
        }
      } 
    } else {
      foreach my $rank (sort numerically keys %classify) {
        foreach my $count (reverse sort numerically keys %{ $classify{$rank} }) {
          foreach my $version (keys %{ $classify{$rank}{$count} }) {
            say qq(DEBUG CLASSIFIED BUCKET $tool $classify{$rank}{$count}{$version} $version $rank $count);
          }
        }
      }
    }
  }

  my $final_version;
  my $final_source;
  my %final_process_version = ();
  my %final_process_source = ();
  if ($earmark_string =~ /\@process/) {
    foreach my $process (sort keys %process_classify) {
    OUTER_VERSION_PROCESS:
      foreach my $rank (sort numerically keys %{ $process_classify{$process} }) {
        foreach my $count (reverse sort numerically keys %{ $process_classify{$process}{$rank} }) {
          foreach my $version (keys %{ $process_classify{$process}{$rank}{$count} }) {
            $final_process_version{$process} = $version;
            $final_process_source{$process} = $process_classify{$process}{$rank}{$count}{$version};
            say qq(DEBUG CLASSIFIED PROCESS TARGET $tool $process_classify{$process}{$rank}{$count}{$version} $version $process $rank $count) if $debug;
            last OUTER_VERSION_PROCESS;
          }
        }
      }
    } 
  } else {
    OUTER_VERSION:
    foreach my $rank (sort numerically keys %classify) {
      foreach my $count (reverse sort numerically keys %{ $classify{$rank} }) {
        foreach my $version (keys %{ $classify{$rank}{$count} }) {
          $final_version = $version;
          $final_source = $classify{$rank}{$count}{$version};
          say qq(DEBUG CLASSIFIED TARGET $tool $final_source $final_version $rank $count) if $debug;
          last OUTER_VERSION;
        }
      }
    }
  }

  if ($earmark_string =~ /\@process/) {
    unless (scalar %final_process_version) {
      die "Final version not set for tool with process earmark $tool\n";
    }
  } else {
    unless ($final_version) {
      die "Final version not set for tool $tool\n";
    }
  }


  # Stamp new attributes on the common array
  my $local_earmark;
  foreach my $source (sort keys %{ $common_hash{$tool} }) {
    $local_earmark = '';
    if ($source =~ /^(BE)|(FE)$/) {next;}
    $common_hash{$tool}{$source}{'TYPE'} = $final;
    $common_hash{$tool}{$source}{'MAT_RULE'} = $mat_rule;
    my $version = $common_hash{$tool}{$source}{'VERSION'};
    if ($earmark_string =~ /\@process/) {
      my $process = $common_hash{$tool}{$source}{'PROCESS'};
      $final_version = $final_process_version{$process};
      $final_source = $final_process_source{$process};
      say qq(DEBUG CLASSIFIED PROCESS SET $tool $source $process $version) if $debug;
    }
    if (($version eq $final_version) and ($source eq $final_source)) {
      say qq(DEBUG CLASSIFIED FINAL $tool $source $version) if $debug;
      if ($earmark_string) {
        $local_earmark = ' ';
      }
      $local_earmark .= q(@final)
    }
    elsif ($version eq $final_version) {
      say qq(DEBUG CLASSIFIED SKIP_OK $tool $source $version) if $debug;
    } else {
      say qq(DEBUG CLASSIFIED VERSION_DIFF $tool $source $version) if $debug;
      if ($earmark_string) {
        $local_earmark = ' ';
      }
      $local_earmark .= q(@version_diff)
    }

    $common_hash{$tool}{$source}{'EARMARKS'} = $earmark_string . $local_earmark;
  }
}


# Write out csv for Excel consumption
my $csvfile = "${tsa_version}.toolver.csv";
my $csvfile_h = IO::File->new;
$csvfile_h->open(">$csvfile") or die "Could not open csvfile for writing: $csvfile\n";
my @field_list = qw(TSA TOOL TYPE KIT SOURCE PROCESS VERSION MAT_RULE EARMARKS TSETUP_TOOLNAME HDK_RELEASE_NOTES);
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
      if ($field eq 'TSA') {
        push (@csv_values, $tsa_version);
      }
      elsif ($field eq 'HDK_RELEASE_NOTES') {
        if (exists $doc_hash{$tool}{'HDK_RELEASE_NOTES'}) {
          my $version = $common_hash{$tool}{$source}{'VERSION'};
          my $hdk_release_notes = $doc_hash{$tool}{'HDK_RELEASE_NOTES'};
          $hdk_release_notes =~ s/\&get_tool_ver(sion)?\(\)/$version/;
          $hdk_release_notes =~ s{(\w)\/\/}{$1\/};
          push (@csv_values, $hdk_release_notes);
        } else {
          push (@csv_values, '');
        }
      } else {
        push (@csv_values, $common_hash{$tool}{$source}{$field});
      }
    }
    my $csv_row = join(',', @csv_values);
    $csvfile_h->print("$csv_row\n");
    #say qq($csv_row);
  }
}


sub numerically {$a <=> $b;}

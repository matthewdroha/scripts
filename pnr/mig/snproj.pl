#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: snproj.pl,v 1.4 2005/05/13 14:36:42 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: snproj.pl,v 1.4 2005/05/13 14:36:42 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: snproj.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Runs devx on two input SNs and projects the possible Z/L changes from the source
sn to the target sn.

=cut

# Will redefine when we get a permanant UE friendly setup for 1266 and migration
BEGIN {
  if (defined $ENV{'MIG_OVR'}) {
    push @INC, $ENV{'MIG_OVR'};
  } else {
    push @INC, '/nfs/iil/disks/home10/mroha/pnr/mig', '/usr/users/home2/mroha/pnr/mig';
  }
}

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd 'abs_path';
use Cwd;
use DAStdLib;
use MigStdLib;
use PdsStdLib;
use File::Copy;

my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);

our $SITE = &GetSite();

# Get the script start time
my ($start_time, $start_date) = &GetDate();


my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME  -cell <cell name>
                   -sourcesn <sn file> -targetsn <sn file>
                   [-help] [-debug] [-verbose]

flag descriptions:

-cell             Cell name to operate on.

-fromsn           This is the "golden" SN you want to take the zed
                  values from. If not specified, the following is the
                  default SN area and naming:

                  /nfs/iil/proj/mpg/mpg46/work/sagantec_group/mroha/silver_netlists
                  <cell>_after.sn

-ontosn           This is the SN you want to project the zed values
                  on to. If not specified, the harvest sn from the release area
                  will be used

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: $EXE_NAME -fromsn fmmgend.silver.sn -targetsn fmmgend.lor2.sn

Files that result from this run:


EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_help, $opt_debug, $opt_verbose);
our ($opt_ontosn, $opt_fromsn, $opt_cell);
my $options_ok = &GetOptions("help",
			     "cell=s",
			     "ontosn=s",
			     "fromsn=s",
			     "debug",
			     "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help;

my @required_flag_list = ('-cell');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);



##### Main Program #####

our ($WORK_AREA_ROOT_DIR, $NIKE_NETLISTER);
my @env_list = ('WORK_AREA_ROOT_DIR', 'NIKE_NETLISTER');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}


my $cell_lc = lc($opt_cell);
our $WARD = $WORK_AREA_ROOT_DIR;
my $fromsn;
if ($opt_fromsn) {
  my ($name,$path,$suffix)  = fileparse($opt_fromsn);
  my $resolved_path = abs_path($path);
  $fromsn = "${resolved_path}/${name}";
  unless (-e $fromsn) {
    die "-F- $EXE_NAME: -fromsn argument does not exist: $opt_fromsn";
  }
}

my $ontosn;
if ($opt_ontosn) {
  my ($name,$path,$suffix)  = fileparse($opt_ontosn);
  my $resolved_path = abs_path($path);
  $ontosn = "${resolved_path}/${name}";
  unless (-e $ontosn) {
    die "-F- $EXE_NAME: -ontosn argument does not exist: $opt_ontosn";
  }
}


chdir $PDSSN or die "Could not change dirs to \$PDSSN\n";
my $work_dir = "${cell_lc}_${EXE_PREFIX}";
&CreateDirTrees($work_dir);
chdir $work_dir or die "Could not change work dir to $work_dir\n";

our ($BASEFILE, $MAINLOG);
$BASEFILE = "${cell_lc}.${EXE_PREFIX}";
$MAINLOG = LogFile->new("${BASEFILE}.log");
$MAINLOG->flowname($EXE_NAME);
$MAINLOG->verbose($opt_verbose);

my $machine_info = `uname -a`;
chomp $machine_info;
$MAINLOG->info("Script command: $EXE_NAME $COMMAND_LINE");
$MAINLOG->info("Script start date: $start_date");
$MAINLOG->info("Machine Type: $machine_info");


# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless -debug is used.
our @TMPFILES = ();

my $default_z_scalar = 0.65;
my $default_l_value = 0.04;
my $sanity_l_too_low = 0.03;
my $sanity_l_too_high = 0.06;
my $key_separator = '__';
my $txx_regexp = 'tm0|tm5|t00';
my $vxx_regexp = 'vm0|vm5|v00';


my $silver_area = "/nfs/iil/proj/mpg/mpg46/work/sagantec_group/mroha/silver_netlists";
my $silver_sn = "${cell_lc}_after.sn";
unless ($fromsn) {
  if (-e "${silver_area}/${silver_sn}") {
    $fromsn = "${silver_area}/${silver_sn}";
  } else {
    die $MAINLOG->fatalq("Could not find silver SN for $cell_lc: ${silver_area}/${silver_sn}");
  }
}

&ManipFile($MAINLOG, 'copy', '', "${fromsn}", basename($fromsn));

my $target_release = '';
unless ($ontosn) {
  my $release_area = "$mig_lookup{$SITE}{'release'}/idc";
  # See what has been released. If there is more than one release for a fub, take the latest one
  my %release_lookup;
  &GetMigReleaseStatus($MAINLOG, $release_area, \%release_lookup);
  
  if ((exists $release_lookup{$cell_lc}) and (scalar @{ $release_lookup{$cell_lc} })) {
    my @sorted_releases = sort @{ $release_lookup{$cell_lc} };
    $target_release = pop(@sorted_releases);
  } else {
    die $MAINLOG->fatalq("No releases found for cell: $cell_lc in release area $release_area");
  }

  $MAINLOG->infoq("Release selected: (${release_area}/${target_release})");
  
  my $release_sn_area = "${release_area}/${target_release}/sn";
  opendir (SNDIR, $release_sn_area) or die $MAINLOG->fatalq("Could not open dir for reading: $release_sn_area");
  my @files = grep /${cell_lc}\.sn\S+(harvest|nobonus)\S+${mig_input_process}/, readdir (SNDIR);
  if (scalar @files != 1) {
    die $MAINLOG->fatalq("More than one harvest SN file found during search");
  }
  my $sn_file = pop(@files);
  if (-e "${release_sn_area}/${sn_file}") {
    $ontosn = "${release_sn_area}/${sn_file}";
  } else {
    $MAINLOG->fatalq("Could not find release SN for $cell_lc: ${release_sn_area}/${sn_file}");
  }
}
&ManipFile($MAINLOG, 'copy', '', "${ontosn}", "${WORK_AREA_ROOT_DIR}/netlists/mkisp/".basename($ontosn));
&ManipFile($MAINLOG, 'symlink', "${WORK_AREA_ROOT_DIR}/netlists/mkisp/", basename($ontosn), "${cell_lc}.sn");

my $cell_netlist_dir = "${PDSSN}/${cell_lc}_snproj_sn_nike_netlister";
my $cell_netlist_sn = "${cell_netlist_dir}/${cell_lc}.sn";
my $rundirty = &RunNikeNetlister($MAINLOG, $cell_lc, 'sn', 'snsch', "-outd $cell_netlist_dir");
if ($rundirty) {
  die $MAINLOG->fatalq("Netlist run SN->SNSCH failed");
}


# Check if LNF is clean to source SN. If it is, then no projection is required
 
&ManipFile($MAINLOG, 'symlink', $PDSSN, "${PDSSN}/${work_dir}/".basename($fromsn), "${opt_cell}.sn");

my $issrel_cmd = "$mig_utils{$SITE}/issrel.pl -cell $cell_lc -format lnf -flows trcstd";
unless (&Tcsh($MAINLOG, "$issrel_cmd")) {
  die $MAINLOG->fatalq("ISSREL run returned non-zero exit status");
}
my $issrel_log = "${WORK_AREA_ROOT_DIR}/${cell_lc}.issrel.lnf.trcstd.log";
open (ISSREL, $issrel_log) or die $MAINLOG->fatalq("Could not open issrel log for reading: $issrel_log");
my %cmp_hash;
while (<ISSREL>) {
  chomp;
  $MAINLOG->infoq($_);
  if (/(Total(\s+\d+){9})/) {
    my @record = split(/\s+/, $1);
    shift(@record);
    foreach my $code (@CMP_RECORD_ORDER) {
      $cmp_hash{$code} = shift(@record);
    }
  }
}
close (ISSREL);

my $cmp_error_found = 0;
my @critical_errors = ('UNMATCH_LAY_NODES', 'UNMATCH_SCH_NODES', 'UNMATCH_LAY_DEVICES', 'UNMATCH_SCH_DEVICES', 'BULK', 'UPC');
foreach my $code (@critical_errors) {
  if (exists $cmp_hash{$code}) {
    if ($cmp_hash{$code} ne '0') {
      $MAINLOG->errorq("(${cell_lc}) CMP error detected: $code");
      $cmp_error_found = 1;
    }
  } else {
    die $MAINLOG->fatalq("Problem occurred with issrel run. Could not find CMP total table in log");
  }
}


my $sn_type = 'golden_sn';

my $golden_sn = "${cell_lc}.sn.${mig_output_process}";
if ($cmp_error_found) {
  $sn_type = 'projected';
  $MAINLOG->info("($cell_lc) Source SN is NOT CMP clean to LNF. Running projection flow");
} else {
  $MAINLOG->info("($cell_lc) Source SN is CMP CLEAN to LNF. Archiving source SN");
  &ManipFile($MAINLOG, 'copy', "${PDSSN}/${work_dir}", basename($fromsn), basename($golden_sn));
  goto ARCHIVE;
}



# Call first round of DEVX, SN<->SN
my $xref_file = "${cell_lc}.xref";
my $cmpall_file = "${cell_lc}.cmpall";
&DeleteFiles($xref_file);

my $parent_flow = $MAINLOG->flowname("DEVX-BeforeProj");
my $cmd = "${ICVS}/devx -sn $fromsn -ln $cell_netlist_sn -xrefzlonly $cell_lc";
my @stdout_and_err;
unless (&Pipe($MAINLOG, $cmd, '', \@stdout_and_err)) {
  die $MAINLOG->fatalq("Call to devx failed. See log file.");
}
my $before_resize_devx_total;
foreach my $line (@stdout_and_err) {
  if ($line =~ /^Total(\s+\d+){9}/) {
    $before_resize_devx_total = $line;
  }
}   


$MAINLOG->flowname($parent_flow);
my %zl_hash;
my %conflict_hash;
my $conflict_count = 0;
my %final_cell_map;
open (XREF, $xref_file) or die $MAINLOG->fatalq("Could not open xref file for reading: $xref_file");
while (<XREF>) {
  $_ = lc;
  my @record = split;
  my $z = $record[5];
  my $l = $record[6];
  my $z_to_project = $record[13];
  my $l_to_project = $record[14];
  my $stdcellmacro = '';
  if ($record[0] =~ /^(${txx_regexp})/) {
    my $tempmacro = $record[0];
    $tempmacro =~ s/^tm0/vm0/;
    $tempmacro =~ s/^tm5/vm5/;
    $tempmacro =~ s/^t00/v00/;
    $final_cell_map{$record[0]} = $tempmacro;
    my @instances = split(/\//, $record[8]);
    while (@instances) {
      my ($instance) = pop (@instances);
      if ($instance =~ /\{((${vxx_regexp})\w+)\}/) {
	$stdcellmacro = $1;
	last;
      }
    }
  }
  my $key1 = join($key_separator, $record[0], $record[1], $record[2], $record[3], $record[4]);
  my $key2 = join($key_separator, $record[0], $record[3], $record[2], $record[1], $record[4]);
  my $zl_to_project = "$z_to_project $l_to_project";
  my $nominal_z_value = $z * $default_z_scalar;
  
  foreach my $key ($key1, $key2) {
    $zl_hash{$key}{'Z'} = $z;
    $zl_hash{$key}{'ZL'} = "$z $l";
    $zl_hash{$key}{'DEFAULT'} = "$nominal_z_value $default_l_value";
    $zl_hash{$key}{'VALUES'}{$zl_to_project} = 1;
    if ($stdcellmacro) {
      $zl_hash{$key}{'MACROS'}{$stdcellmacro} = $zl_to_project;
      $zl_hash{$key}{'MACROCOUNT'}{$stdcellmacro} += 1;
    }
  }
}
close (XREF);

if ($opt_debug) {
  foreach my $macro (sort keys %final_cell_map) {
    $MAINLOG->infod("STDCELL: ($macro) is mapped by name to ($final_cell_map{$macro})");
  }
}


# Smash the SD key combinations into a single key for processing
my %keys_to_remove;
foreach my $key (keys %zl_hash) {
  if (exists $keys_to_remove{$key}) {
    next;
  }
  my @key_fields = split(/${key_separator}/, $key);
  my $sd_swap_key = join($key_separator, $key_fields[0], $key_fields[3], $key_fields[2], $key_fields[1], $key_fields[4]);
  $keys_to_remove{$sd_swap_key} = 1;
}

foreach my $key (keys %keys_to_remove) {
  delete $zl_hash{$key};
}



# Resolve device mismatches. If you can, map cell by name. Otherwise pick scaling value that is closest to nominal
# without going below it. Otherwise you get nominal scaling.
my %remap_master;
foreach my $key (keys %zl_hash) {
  my ($macro) = split(/${key_separator}/, $key);
  my $txx_family;
  if ($macro =~ /^(${txx_regexp})bin\d\d\S\S/) {
    $txx_family = substr($macro, 0, -4);
  } else {
    $txx_family = substr($macro, 0, -2);
  }
  # If conflict exists, resolve in this order:
    # (1) If a txx cell, choose the highest occurance of a vxx device in the same family (different power class OK). 
    #     Sizing ECO recovery. Custom cells not considered here.
    # (2) If not a txx cell, pick the lowest matching z value that does not go below nominal scaling
    # (3) Nominally scale the device

  # If device is mapped to more than one Z/L value
  if (scalar keys %{ $zl_hash{$key}{'VALUES'} } > 1) {
    # If it is a txx/tm5 cell and is mapped to vxx/vm5 cells
    if (($key =~ /^(${txx_regexp})/) and (exists $zl_hash{$key}{'MACROCOUNT'})) {
      my $match_count = 0;
      my $match_cell = '';
      my $z;
      my $l;
      my $z_scale;
      my @sizing_choices = ();
      # Find the greatest number of cell instances that occur within the cell family and use its Z/L
      foreach my $cell (sort keys %{ $zl_hash{$key}{'MACROCOUNT'} }) {
	push (@sizing_choices, "(${cell}=$zl_hash{$key}{'MACROCOUNT'}{$cell})");
	my $vxx_family;
	if ($cell =~ /^(${vxx_regexp})bin\d\d\S\S/) {
	  $vxx_family = substr($cell, 0, -4);
	} else {
	  $vxx_family = substr($cell, 0, -2);
	}
	$vxx_family =~ s/^vm0/tm0/;
	$vxx_family =~ s/^vm5/tm5/;
	$vxx_family =~ s/^v00/t00/;
	if (($txx_family eq $vxx_family) and ($zl_hash{$key}{'MACROCOUNT'}{$cell} > $match_count)) {
	  $zl_hash{$key}{'PROJECTED'} = $zl_hash{$key}{'MACROS'}{$cell};
	  ($z, $l) = split (/\s+/, $zl_hash{$key}{'PROJECTED'});
	  $z_scale = sprintf("%.2f", $z/$zl_hash{$key}{'Z'});
	  $match_count = $zl_hash{$key}{'MACROCOUNT'}{$cell};
	  $match_cell = $cell;
	}
      }
      # If you don't find a power class match, there is some other ECO that may or may not be equivalent
      if ($match_cell) {
	$remap_master{$macro}{$match_cell} = 1;
	$MAINLOG->infoq("Conflict cell counts for key:($key) ". join(' ', @sizing_choices));
	$MAINLOG->infoq("Conflict for key:($key) Match:(${macro})->(${match_cell}) Prev:($zl_hash{$key}{'ZL'}) Final:($zl_hash{$key}{'PROJECTED'}) ZScale:($z_scale)");
	next;
      }
    }
    # For a case where matching can not be done by name. Pick size with scalar on conservative side
    my ($target_z) = split(/\s+/, $zl_hash{$key}{'DEFAULT'});
    my @z_list = ();
    foreach my $zl_pair (keys %{ $zl_hash{$key}{'VALUES'} }) {
      my ($z) = split(/\s+/, $zl_pair);
      push (@z_list, $z);
    }
    @z_list = sort {$a <=> $b} @z_list;
    my $z_string = join (' ', @z_list);
    foreach my $value (@z_list) {
      if ($value > $target_z) {
	$target_z = $value;
	last;
      }
    }
    $zl_hash{$key}{'PROJECTED'} = "$target_z $default_l_value";
    my $z_scale = sprintf("%.2f", $target_z/$zl_hash{$key}{'Z'});
    $MAINLOG->infoq("Conflict for key:($key) Nominal:($zl_hash{$key}{'DEFAULT'}) Final:($zl_hash{$key}{'PROJECTED'}) ZScale:($z_scale) ZVals:($z_string) ");
  } else {
    # All direct maps
    my ($value) = keys %{ $zl_hash{$key}{'VALUES'} };
    $zl_hash{$key}{'PROJECTED'} = $value;  
    my $map_cell = $macro;
    if (($key =~ /^(${txx_regexp})/) and (exists $zl_hash{$key}{'MACROCOUNT'})) {
      foreach my $cell (sort keys %{ $zl_hash{$key}{'MACROCOUNT'} }) {
	my $vxx_family;
	if ($cell =~ /^(${vxx_regexp})bin\d\d\S\S/) {
	  $vxx_family = substr($cell, 0, -4);
	} else {
	  $vxx_family = substr($cell, 0, -2);
	}
	$vxx_family =~ s/^vm0/tm0/;
	$vxx_family =~ s/^vm5/tm5/;
	$vxx_family =~ s/^v00/t00/;
	if ($txx_family eq $vxx_family) {
	  $remap_master{$macro}{$cell} = 1;
	  $map_cell = $cell;
	  last;
	}
      }
    }
    my ($z, $l) = split (/\s+/, $zl_hash{$key}{'PROJECTED'});
    my $z_scale = sprintf("%.2f", $z/$zl_hash{$key}{'Z'});
    $MAINLOG->infoq("Direct map for key:($key) Match:(${macro})->(${map_cell}) Prev:($zl_hash{$key}{'ZL'}) Final:($value) ZScale:($z_scale)");
  }
}

# From original code, checks that different SD node combinations got the same scaling. But now should not happen ever since
# dup keys are assigned together and one is deleted. Will keep this around for paranoia though
my %checked_hash;
foreach my $key (keys %zl_hash) {
  my @record = split(/${key_separator}/, $key);
  my $temp = $record[1];
  $record[1] = $record[3];
  $record[3] = $temp;
  my $altkey = join(${key_separator}, @record);
  if (exists $zl_hash{$altkey}) {
    if ($zl_hash{$key}{'PROJECTED'} ne $zl_hash{$altkey}{'PROJECTED'}) {
      die $MAINLOG->fatalq("Device with same SD nodes had different scaling: $key");
    }
  }
}


# Verify that all remaps occur to only one cell
foreach my $sourcecell (sort keys %remap_master) {
  my ($targetcell) = keys %{ $remap_master{$sourcecell} };
  my $txx_match_name = $targetcell;
  $txx_match_name =~ s/^vm0/tm0/;
  $txx_match_name =~ s/^vm5/tm5/;
  $txx_match_name =~ s/^v00/t00/;
  my $vxx_match_name = $sourcecell;
  $vxx_match_name =~ s/^tm0/vm0/;
  $vxx_match_name =~ s/^tm5/vm5/;
  $vxx_match_name =~ s/^t00/v00/;
  if (scalar keys %{ $remap_master{$sourcecell} } > 1) {
    $MAINLOG->warn("Master $sourcecell mapped to multiple cells: " . join(' ', keys %{ $remap_master{$sourcecell} }));
    if (exists $remap_master{$sourcecell}{$vxx_match_name}) {
      $targetcell = $vxx_match_name;
    }
  }
  unless ($sourcecell eq $txx_match_name) {
    $MAINLOG->infoq("Sizing ECO will be applied in projected SN: (${sourcecell}) => (${targetcell})  *****");
    $final_cell_map{$sourcecell} = $targetcell;
  }
}


my $zl_file = "${opt_cell}.zl";
open (ZL, ">$zl_file") or die $MAINLOG->fatalq("Could not open zlfile for writing: $zl_file");
foreach my $key (sort keys %zl_hash) {
  my ($z, $l) = split (/\s+/, $zl_hash{$key}{'PROJECTED'});
  if (($l < $sanity_l_too_low) or ($l > $sanity_l_too_high)) {
    $MAINLOG->warnq("$opt_cell: L value not in expected range ($l). Setting to default L ($default_l_value)  Key: $key");
    $l = $default_l_value;
  }
  print ZL "$key $z $l\n";
}
close (ZL);



my $cafe_sn = "${cell_lc}.sn.postcafe";
$parent_flow = $MAINLOG->flowname("CAFE-snproj");
$cmd = "~mroha/pnr/mig/snproj.tcl $cell_lc $cell_netlist_sn $zl_file $cafe_sn";
unless (&Pipe($MAINLOG, $cmd, '', \@stdout_and_err)) {
  die $MAINLOG->fatalq("Call to snproj.tcl failed. See log file.");
}
$MAINLOG->flowname($parent_flow);


my $cellrename_sn = "${cell_lc}.sn.cellrename.${mig_output_process}";
open (CAFESN, $cafe_sn) or die $MAINLOG->fatalq("Could not open CAFE generated SN for reading: $cafe_sn");
open (CELLSN, ">$cellrename_sn") or die $MAINLOG->fatalq("Could not open cell rename SN for writing: $cellrename_sn");
my %vxx_cell_added_by_eco;
while (<CAFESN>) {
  if (/^\s*\@\S+\s+(\S+)/) {
    my $macro = lc($1);
    if (exists $final_cell_map{$macro}) {
      s/(\s+)${macro}(\s+)/${1}$final_cell_map{$macro}${2}/g;
    }
  }
  if (/^\s*\.macro\s+(\S+)/i) {
    my $macro = lc($1);
    if (exists $final_cell_map{$macro}) {
      my $vxx_cell = my $txx_match_name = $final_cell_map{$macro};
      $txx_match_name =~ s/^vm0/tm0/;
      $txx_match_name =~ s/^vm5/tm5/;
      $txx_match_name =~ s/^v00/t00/;

      my $sub_macro = 0;
      # If the name is just directly mapped from txx to vxx, just do the substitution
      if ($macro eq $txx_match_name) {
	$sub_macro = 1;
      } else {
        # If there is an ECO, do the substitutions only if the target cell is not already
        # direct mapped and has not been added by a previous ECO	
	if (exists $final_cell_map{$txx_match_name}) {
	  if ($final_cell_map{$txx_match_name} ne $vxx_cell) {
	    $sub_macro = 1;
	  }
	} else {
	  unless (exists $vxx_cell_added_by_eco{$vxx_cell}) {
	    $sub_macro = 1;
	    $vxx_cell_added_by_eco{$vxx_cell} = 1;
	  }
	}
      }

      if ($sub_macro) {
	s/(\s+)${macro}(\s+)/${1}$final_cell_map{$macro}${2}/g;
      } else {
	$MAINLOG->warnq("Macro:($macro) mapping to ($final_cell_map{$txx_match_name}) causes previous definition conflict. Not substituting macro name");
      }
    }
  }
  print CELLSN $_;
}
close (CAFESN);
close (CELLSN);

$parent_flow = $MAINLOG->flowname("CAFE-snclean");
my $projected_sn = "${cell_lc}.sn.projected.${mig_output_process}";
$cmd = "~mroha/pnr/mig/snheal.tcl $cell_lc $cellrename_sn $projected_sn";
unless (&Pipe($MAINLOG, $cmd, '', \@stdout_and_err)) {
  die $MAINLOG->fatalq("Call to snheal.tcl failed. See log file.");
}
$MAINLOG->flowname($parent_flow);


&ManipFile($MAINLOG, 'move', '', $xref_file, "${xref_file}.orig");
&ManipFile($MAINLOG, 'move', '', $cmpall_file, "${cmpall_file}.orig");


$parent_flow = $MAINLOG->flowname("DEVX-AfterProj");
$cmd = "${ICVS}/devx -sn $fromsn -ln $projected_sn -xrefzlonly $opt_cell";
unless (&Pipe($MAINLOG, $cmd, '', \@stdout_and_err)) {
  die $MAINLOG->fatalq("Call to devx failed. See log file.");
}
$parent_flow = $MAINLOG->flowname($parent_flow);

my $after_resize_devx_total;
foreach my $line (@stdout_and_err) {
  if ($line =~ /^Total(\s+\d+){9}/) {
    $after_resize_devx_total = $line;
  }
}

$MAINLOG->info("($opt_cell) DEVX Before Resize: $before_resize_devx_total");
$MAINLOG->info("($opt_cell) DEVX After Resize : $after_resize_devx_total");
&ManipFile($MAINLOG, 'symlink', $PDSSN, "${work_dir}/${projected_sn}", "${opt_cell}.sn");

unless (&Tcsh($MAINLOG, "$issrel_cmd")) {
  die $MAINLOG->fatalq("ISSREL run returned non-zero exit status");
}
open (ISSREL, $issrel_log) or die $MAINLOG->fatalq("Could not open issrel log for reading: $issrel_log");
%cmp_hash = ();
while (<ISSREL>) {
  chomp;
  $MAINLOG->infoq($_);
  if (/(Total(\s+\d+){9})/) {
    my @record = split(/\s+/, $1);
    shift(@record);
    foreach my $code (@CMP_RECORD_ORDER) {
      $cmp_hash{$code} = shift(@record);
    }
  }
}
close (ISSREL);

$cmp_error_found = 0;
foreach my $code (@critical_errors) {
  if (exists $cmp_hash{$code}) {
    if ($cmp_hash{$code} ne '0') {
      $MAINLOG->errorq("(${cell_lc}) CMP error detected: $code");
      $cmp_error_found = 1;
    }
  } else {
    die $MAINLOG->fatalq("Problem occurred with issrel run. Could not find CMP total table in log");
  }
}

if ($cmp_error_found) {
  die $MAINLOG->fatalq("(${cell_lc}) SN vs LAY CMP errors found after projection");
} 


ARCHIVE:

chdir $PDSSN or die $MAINLOG->fatalq("Could not change dir back to \$PDSSN");

if ($target_release) {
  &CreateDirTrees("${target_release}/sn", "${target_release}/logs");
  my $release_sn;
  if ($sn_type eq 'projected') {
    $release_sn = $projected_sn;
  } else {
    $release_sn = $golden_sn;
  }
  &ManipFile($MAINLOG, 'copy', $PDSSN, "${work_dir}/${release_sn}", "${PDSSN}/${target_release}/sn/${release_sn}");
  $MAINLOG->infoq("(${cell_lc}) SNType:(${sn_type})  Release directory created: $target_release");
}

$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");
$MAINLOG->close;

copy("${PDSSN}/${work_dir}/${BASEFILE}.log", "${PDSSN}/${target_release}/logs/${BASEFILE}.log");


########## Begin subroutine definitions ##########

sub RunNikeNetlister {

  my $loghandle = shift;
  my $cell = shift;
  my $inputformat = shift;
  my $outputformat = shift;
  my $other_args = join(' ', @_);
  my $outnetlist;
  my $outnetlistlog;
  my $summary_found = 0;
  my $fatal_count;
  my $error_count;
  my $warning_count;
  my $run_is_dirty = 0;
  
  my $parent_flow = $loghandle->flowname;
  $loghandle->flowname('RunNikeNetlister');

  # Remove previous netlist (future: key off of input format);
  my $outputformat_ucf = ucfirst($outputformat);

  my $netlist_dir;
  my $sn_dir;
  if ($other_args =~ /\-outd (\S+)/) {
    $netlist_dir = $1;
    $sn_dir = $1;
  } else {
    $netlist_dir = "$WARD/netlists";
    $sn_dir = "$WARD/netlists/cvssch";
  }
 
  $outnetlistlog = "${netlist_dir}/${cell}__${inputformat}_to_${outputformat_ucf}__nike_netlister.log";
  $outnetlist = "${sn_dir}/${cell}.sn";
  &DeleteFiles($outnetlist, $outnetlistlog);

  # Nike netlister returns non-zero status if there are non-fatal issues with netlisting, as well as any process issues (like no disk space or wrong switches).
  # Since I don't know how to tell the difference, just check for the log file)
  unless (&Tcsh($loghandle, "$NIKE_NETLISTER -cell $cell -inf $inputformat -remp none -outf $outputformat $other_args >& /dev/null")) {
    $loghandle->warn('NIKE netlister call returned non-zero status.');
  }

  # Confirm there were no errors in the log file
  open (OUTNETLISTLOG, $outnetlistlog) or die $loghandle->fatalq("Could not open $outnetlistlog for reading");
  while (<OUTNETLISTLOG>) {
    if (/Fatals:\s+(\d+)\s+Errors:\s+(\d+)\s+Warnings:\s+(\d+)/) {
      $fatal_count = $1;
      $error_count = $2;
      $warning_count = $3;
      $summary_found = 1;
      chomp;
      $loghandle->infoq($_);
      last;
    }
  }
  close (OUTNETLISTLOG);

  if ($summary_found) {
    if (($fatal_count ne '0') or ($error_count ne '0')) {
      $loghandle->warnp("Fatals/errors occured during nike_netlister run.",
               "See $outnetlistlog");
      $run_is_dirty = 1;
    }
    if ($warning_count ne '0') {
      $loghandle->warnp("Warnings occured during nike_netlister run.",
           "See $outnetlistlog");
    }
  } else {
    die $loghandle->fatalq("Nike netlister log was found, but no summary was contained in file",
             "See $outnetlistlog");
  }
  # Confirm output netlist was generated, die otherwise

  $loghandle->flowname($parent_flow);
  return $run_is_dirty;
}

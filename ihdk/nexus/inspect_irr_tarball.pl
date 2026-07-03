#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w
#
# $Id: inspect_irr_tarball.pl,v 1.1 2016/06/10 22:17:48 mroha Exp $


=pod

=head1 COPYRIGHT

$Id: inspect_irr_tarball.pl,v 1.1 2016/06/10 22:17:48 mroha Exp $

(C) Copyright Intel Corporation, 2016
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: inspect_irr_tarball.pl
Project: ihdk
Original Author: Matthew Roha

=cut

=head1 DESCRIPTION

audit_irr_tarball.pl compares the manifest of an IP tarball from Intel Reuse Repository vs the files expected in the drop (source: MIG DART snapshot flow)

This script is asserting the following and checking it
  - All files in the snapshot manifest "match" (count, name, gcksum) against actual contents of tarball
  - All fatal, errors, and warnings during data pull are valid (human inspection)
  - All snapshot raw waivers are extracted and reviewed (human inspection)

=cut



BEGIN {
  use IO::Dir
  my %homedir;
  my %cpandir;
  my $homeproject = "ihdk";
  my $perlver = "5.14.1";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  $cpandir{'fm'} = "$homedir{'fm'}/cpan/${perlver}";
  # Patch for non-eclogin people
  if (defined $ENV{'EC_SITE'}) {
    if (-d "$homedir{$ENV{'EC_SITE'}}/override") {
      push @INC, "$ENV{'HOME'}/override";
    }
    if (-d "$cpandir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.88/lib") {
      push @INC, "$cpandir{$ENV{'EC_SITE'}}/Excel-Writer-XLSX-0.88/lib";
    }
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $code_dir_h = IO::Dir->new;
    $code_dir_h->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $code_dir_h->read();
    foreach my $item (@dirs) {
      if (-d "${code_dir}/${item}") {
        push @INC, "${code_dir}/${item}";
      }
    }
  } else {
    print "Environment var EC_SITE is not defined. Please make your environment eclogin compliant\n";
    exit;
  }
}

use strict;
use warnings;
use English;
use Getopt::Long;
use Time::Local;
use IO::File;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Path;
use File::Basename;
use File::Temp;
use Env;
use Cwd 'abs_path';
use DAStd;
use Logfile;
use Excel::Writer::XLSX;


my $code_dir = GetCodeDir('ihdk');
my $exe_name;
my $exe_prefix;
($exe_name, $exe_prefix) = GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = GetDate();

 # Get the site
our $site = GetSite();

# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");

usage:  $exe_name --snapdir <DART snapshot archive directory>
                  --targz <IRR compressed tarball>
                  [--run-name <logfile prefix>]
                  [--env 'VAR=VALUE']
                  [--help] [--verbose] [--debug]

flag descriptions:

--snapdir           DART snapshot archive directory path (including archive name)

--tarball           IRR .tar.gz IP release tarball

--run-name          Optional.  String label for output files only. Default is the script name only.

--env               Optional. Set env var at start of execution. Can provide more than
                    one --env flag.  Format is VAR=VALUE

--debug             Run flow in debug mode. Temporary files are not deleted and
                    additional data is placed in log file.

--verbose           Will add status messages to STDOUT.

f--help              This usage message will appear. 

example: $exe_name --snapdir /p/coeenv/cents/projects/coe73/archive_root/block/c73p1klnp10lfamilyew/snapshot/XDB_C73P1_PROD_MILESTONE_1_12_C73P1KLNP10LFAMILYEW --tarball /p/coeenv/cents/projects/coe73/archive_root/block/c73p1klnp10lfamilyew/irr_upload/XDB_C73P1_PROD_MILESTONE_1_12_C73P1KLNP10LFAMILYEW/c73p1klnp10lfamilyew_PROD.tar.gz --run-name kg_prod_1_12

Files that result from this run:

\$HOME/${exe_prefix}.log
\$HOME/${exe_prefix}.manifest_inspection.csv
\$HOME/${exe_prefix}.log_inspection.csv
\$HOME/${exe_prefix}.wvrin_inspection.csv

EOD

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_snapdir, $opt_tarball, $opt_run_name);
our (@opt_env, $opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
		            "snapdir=s",
			    "tarball=s",
			    "run-name=s", => \$opt_run_name,
			    "env=s@",
			    "debug",
			    "verbose");

# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}

Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help;
my @required_flag_list = ('--snapdir','--tarball');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);


# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your shell session:", "\$$env_var is not defined.";
  }
}


# Variables to start log file
our ($basefile, $log);

if ($opt_run_name) {
  $basefile = "${opt_run_name}.${exe_prefix}";
} else { 
  $basefile = "${exe_prefix}";
}
$log = Logfile->new("${basefile}.log");
$log->flowname($exe_name);
$log->verbose($opt_verbose);
$log->debug($opt_debug);
my $machine_info = `uname -a`;
chomp $machine_info;
$log->info("Script command: $exe_name $command_line");
$log->info("Script start date: $start_date");
$log->info("System info: $machine_info");


# Global temporary files list. Any file or directort added to this list
# will be deleted after execution is complete, unless --debug is used.
our @tmplist = ();


# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $log->infoq("--env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $log->fatalq("Invalid value for switch --env: $setting");
    }
  }
}


# Intialize stage number for log file
my $stage = 0;

# Begin Main Program

=head1 PROGRAM FLOW

=head2 Inputs

- DART snapshot archive directory containing the snapshot run that was used to generate the IRR tarball.
  - File input SNAPARCH/noble/logs/<block>.snapshot.log.gz
  - File input SNAPARCH/c73p1klnp10lfamilyew.snapshot.manifest.gz
  - File input SNAPARCH/noble/logs/<block>.c73p1klnp10lfamilyew.snapshot.detail.log.gz

=head2 Flow

- Stage 1: Quick Rejection: Validate input directories/files & extract block name
- Stage 2: Manifest vs tarball
  - Manifest file extract and store
  - Tarball file re-build manifest and store (assume a clever cheater)
  - Diff hashed manifiests and report results.  Look for contents in file 1 not in file 2, contents in file 2 not in file 1, and property differences where content matches.
- Stage 3: Fatals, errors, warnings during snapshot
  - In snapshot log file, for each noa/archive data section pull
  - Extract fatals/errors/warning markers and load

- Stage 4: Snapshot wvrin review
  - In wvrin db, dump contents to text using sqlite
  - Extract waivers and load

=cut


# Stage 1: Quick Rejection: Validate input directories/files,extract block name
$stage++;  
$log->newline;
$log->info("***** Stage $stage *****", "***** Quick Rejection Test*****", "***** Validate input directories/files and extract block name*****\n");

unless (-d $opt_snapdir) {
  die $log->fatalq("Directory specified by --snapdir does not exist: $opt_snapdir");
}

my $targetdir_h = IO::Dir->new;
$targetdir_h->open($opt_snapdir) or die "Could not open directory for reading: $opt_snapdir";


my $block;
my $snapshot_manifest_ext = '.snapshot.manifest.gz';
my $quotemeta_snapshot_manifest_ext = quotemeta($snapshot_manifest_ext);
my @manifest_list = grep (/^\S+${quotemeta_snapshot_manifest_ext}$/, $targetdir_h->read());
my $snapshot_manifest;
if (scalar @manifest_list) {
  $block = basename(pop @manifest_list, $snapshot_manifest_ext); 
  $snapshot_manifest = "${opt_snapdir}/${block}${snapshot_manifest_ext}";
  $log->info("Raw snapshot manifest file->($snapshot_manifest)");
} else {
  die $log->fatalq("$snapshot_manifest_ext file not found: $opt_snapdir")
}
$snapshot_manifest = abs_path($snapshot_manifest);
$log->info("Resolved snapshot manifest file->($snapshot_manifest)"); 
$log->info("Block name extracted->($block)");

if (-f $opt_tarball) {
  $log->info("Raw tarball file path->(${opt_tarball})");
} else {
  die $log->fatalq("IRR tarball file not found->($opt_tarball)")
}
my $irr_tarball = abs_path($opt_tarball);
$log->info("Resolved tarball file path->(${irr_tarball})");


# Stage 2: Manifest vs tarball
$stage++;  
$log->newline;
$log->info("***** Stage $stage *****", "***** Manifest vs Tarball*****\n");
$log->info("Target manifest file->($snapshot_manifest)");
$log->info("Target tarball file->($irr_tarball)");

# Extract and store manifest table
my $snapshot_manifest_h = IO::File->new;
$snapshot_manifest_h->open($snapshot_manifest) or die "Could not open file for reading: $snapshot_manifest";
my $snapshot_manifest_hgz = new IO::Uncompress::Gunzip $snapshot_manifest_h;

my %manifest;
my $filecount = 0;
while (<$snapshot_manifest_hgz>) {
  if (/RELEASE/) {
    if (/^\s*(RELEASE\S+)\s+(\d+)\s+(\d+)\s+/) {
      my $filename = $1;
      my $filemtime = $2;
      my $filesize = $3;
      my @time_list = localtime($filemtime);
      my ($filem_second, $filem_minute, $filem_hour, $filem_mday, $filem_month, $filem_year) = localtime($filemtime);

      $filem_second = 0;  #quick hack for 10nm, sles11 is missing minutes for some IP releases
      $filemtime = timelocal($filem_second, $filem_minute, $filem_hour, $filem_mday, $filem_month, $filem_year);

      $filem_year += 1900;
      $filem_month += 1;
      my $filem_formatdate = sprintf("%d-%02d-%02d %02d:%02d:%02d", $filem_year,$filem_month,$filem_mday,$filem_hour,$filem_minute,$filem_second);
      $filecount++;
      $manifest{$filename}{'SNAPSHOT'}{'FULLNAME'} = $filename;
      $manifest{$filename}{'SNAPSHOT'}{'ISDIR'} = 0;
      $manifest{$filename}{'SNAPSHOT'}{'COUNT'} += 1;
      $manifest{$filename}{'SNAPSHOT'}{'MTIME'} = $filemtime;
      $manifest{$filename}{'SNAPSHOT'}{'FILESIZE'} = $filesize;
      $manifest{$filename}{'SNAPSHOT'}{'MDATESTRING'} = $filem_formatdate;
      my ($bucket, $subbucket, $basefile);
      $bucket = 'NO_BUCKET';
      $subbucket = 'NO_SUBBUCKET';
      $basefile = 'NO_VALUE';
      my @record = split('/', $filename);
      shift @record;
      if ((scalar @record >= 1) and ($filename !~ /\/$/)) {
	$basefile = pop @record;
      } else {
	$basefile = $filename;
      }
      if (scalar @record >= 2) {
	$bucket = shift @record;
	$subbucket = shift @record;
      }
      elsif (scalar @record == 1) {
	$bucket = shift @record;
      }
      $manifest{$filename}{'SNAPSHOT'}{'BUCKET'} = $bucket;
      $manifest{$filename}{'SNAPSHOT'}{'SUBBUCKET'} = $subbucket;
      $manifest{$filename}{'SNAPSHOT'}{'BASEFILE'} = $basefile;
    } else {
      die $log->fatalq("Manifest file matched a RELEASE on a line that was missing the file size and modified date: $_");
    }
  }
}
$log->info("\nNumber of files in snapshot manifest->(${filecount})\n");


# Rebuild manifest from tarball file and store (assume a clever cheat hacked the manifest in IRR)
my @irr_tarball_tar_output;
my $list_tar_contents_cmd = "/bin/tar --list --verbose --file=${irr_tarball}";
$log->info("Launching tar process to list irr_tarball contents: ${list_tar_contents_cmd}");
unless (Pipe($log, $list_tar_contents_cmd, '', \@irr_tarball_tar_output)) {
  foreach my $line (@irr_tarball_tar_output) {
    $log->infoe($line);
  }
  die $log->fatalq("Error while executing tar --list process");
} 
$log->info("Tar list process completed normally");

if ($opt_debug) {
  foreach my $line (@irr_tarball_tar_output) {
    $log->infod($line);
  }
}

# Format number with up to 8 leading zeroes
#       $result = sprintf("%08d", $number);
$filecount = 0;
foreach my $tar_result (@irr_tarball_tar_output) {
  $log->infod("INSIDE: $tar_result");
  if ($tar_result =~ /^\s*(\S+)\s+\S+\s+(\d+)\s(\d{4})\-(\d{2})\-(\d{2})\s(\d{2})\:(\d{2})\S*\s(\S+)\s*$/) {
    $log->infod("INSIDE INSIDE: $tar_result");
    my $fileperm = $1;
    my $filesize = $2;
    my $modyear = $3;
    my $modmonth = $4;
    my $modmday = $5;
    my $modhour = $6;
    my $modminute = $7;
    my $modsecond = 0;
    my $filename = $8;
    my $filemtime = timelocal($modsecond, $modminute, $modhour, $modmday, ($modmonth-1), $modyear);
    my $filem_datestring = sprintf("%d-%02d-%02d %02d:%02d:%02d", $modyear,$modmonth,$modmday,$modhour,$modminute,$modsecond);
    if ($filename =~ /^\.\//) {
      $filename =~ s/^\.\//RELEASE\//;
    } else {
      $filename = "RELEASE/" . $filename;    }
    $manifest{$filename}{'TARBALL'}{'FULLNAME'} = $filename;
    if ($fileperm =~ /^d/) {
      $manifest{$filename}{'TARBALL'}{'ISDIR'} = 1;
    } else {
      $manifest{$filename}{'TARBALL'}{'ISDIR'} = 0;
      $filecount++;
    }
    $manifest{$filename}{'TARBALL'}{'COUNT'} += 1;
    $manifest{$filename}{'TARBALL'}{'MTIME'} = $filemtime;
    $manifest{$filename}{'TARBALL'}{'FILESIZE'} = $filesize;
    $manifest{$filename}{'TARBALL'}{'MDATESTRING'} = $filem_datestring;
    my ($bucket, $subbucket, $basefile);
    $bucket = 'NO_BUCKET';
    $subbucket = 'NO_SUBBUCKET';
    $basefile = 'NO_VALUE';
    my @record = split('/', $filename);
    shift @record;
    if ((scalar @record >= 1) and ($filename !~ /\/$/)) {
      $basefile = pop @record;
    } else {
      $basefile = $filename;
    }
    if (scalar @record >= 2) {
      $bucket = shift @record;
      $subbucket = shift @record;
    }
    elsif (scalar @record == 1) {
      $bucket = shift @record;
    }
    $manifest{$filename}{'TARBALL'}{'BUCKET'} = $bucket;
    $manifest{$filename}{'TARBALL'}{'SUBBUCKET'} = $subbucket;
    $manifest{$filename}{'TARBALL'}{'BASEFILE'} = $basefile;
   }
}
$log->info("\nNumber of files (not dirs) in snapshot IRR tarball->(${filecount})\n");


# Check if there are any empty directories in tarball

=head1 RESULT CODES

EMPTY_DIRECTORY_IN_TARBALL - IRR tarball contains empty directory
FILE_MISSING_IN_TARBALL    - File in snapshot manifest, missing in IRR tarball
FILE_MISSING_IN_SNAPSHOT   - File in IRR tarball, missing in snapshot manifest
DATESTAMP_MISMATCH         - File exists in snapshot and tarball, but date last modified is different
FILESIZE_MISMATCH          - File exists in snapshot and tarball, but date last modified is different
CLEAN                      - All checks clean, files match

=cut

my $EMPTY_DIR_IN_TARBALL = 'EMPTY_DIRECTORY_IN_TARBALL';
my $FILE_MISSING_IN_TARBALL = 'FILE_MISSING_IN_TARBALL';
my $FILE_MISSING_IN_SNAPSHOT = 'FILE_MISSING_IN_SNAPSHOT';
my $LAST_MODIFIED_DATE_MISMATCH = 'LAST_MODIFIED_DATE_MISMATCH';
my $FILESIZE_MISMATCH = 'FILESIZE_MISMATCH';
my $CLEAN = 'CLEAN';

foreach my $file (keys %manifest) {
  my @status = ();
  
  # Test if there are any empty directories in tarball
  # For each directory in tarball,  compare against beginning of all non directory paths
  my $isdir = 0;
  my $dirmatch = 0;
  if (exists $manifest{$file}{'TARBALL'}) {
    if ($manifest{$file}{'TARBALL'}{'ISDIR'}) {
      $isdir = 1;
      # $log->infod("Found Tarball Dir: $file");
      foreach my $regularfile (keys %manifest) {
	if ($file eq $regularfile) {next}; # don't check against yourself
	if (exists $manifest{$regularfile}{'TARBALL'}) {
	  # $log->infod("Check file: $regularfile");
	  if ($regularfile =~ /^\Q${file}/) {
	    $log->infod("Found Populated Directory: $file $regularfile");
	    $dirmatch = 1;
	    last;
	  }
	}
      }
    }
  }
  if ($isdir) {
    $log->infod("Found Directory: $file");
  }
  if ($isdir and not $dirmatch) {
    $log->infod("Found Empty Directory: $file");
    push @status, $EMPTY_DIR_IN_TARBALL;
  }
  if (exists $manifest{$file}{'SNAPSHOT'} and not exists $manifest{$file}{'TARBALL'}) {
    push @status, $FILE_MISSING_IN_TARBALL;
  }
  if (exists $manifest{$file}{'TARBALL'}) {
    # Check files (not dirs) from tarball.  Have already identified empty dirs
    if (not $manifest{$file}{'TARBALL'}{'ISDIR'} and not exists $manifest{$file}{'SNAPSHOT'}) {
      push @status, $FILE_MISSING_IN_SNAPSHOT;
    }
  }
  if (exists $manifest{$file}{'SNAPSHOT'} and exists $manifest{$file}{'TARBALL'}) {
    if ($manifest{$file}{'SNAPSHOT'}{'FILESIZE'} ne $manifest{$file}{'TARBALL'}{'FILESIZE'}) {
      push @status, $FILESIZE_MISMATCH;
    }
    if ($manifest{$file}{'SNAPSHOT'}{'MTIME'} ne $manifest{$file}{'TARBALL'}{'MTIME'}) {
      $log->infod("DATE MISMATCH: snapshot=$manifest{$file}{'SNAPSHOT'}{'MTIME'} tarball=$manifest{$file}{'TARBALL'}{'MTIME'}");
      push @status, $LAST_MODIFIED_DATE_MISMATCH;
    }
  }
  if (scalar @status) {
    $manifest{$file}{'INSPECTION_RESULT'} = join(':', @status);
  } else {
    $manifest{$file}{'INSPECTION_RESULT'} = $CLEAN;
  }
}

# Write output files
$stage++;
$log->newline;
$log->info("***** Stage $stage: Write .csv report files *****");
my @csv_fields = ('BASEFILE', 'FILE OR DIR', 'BUCKET', 'SUBBUCKET', 'INSPECTION RESULT', 'SNAPSHOT MANIFEST LAST MODIFIED DATE', 'IRR TARBALL LAST MODIFIED DATE', 'SNAPSHOT MANIFEST FILESIZE', 'IRR TARBALL FILESIZE', 'FULL FILE NAME');

my $csvout = "${basefile}.report.csv";
my $csvout_h = IO::File->new;
$csvout_h->open (">$csvout") or die $log->fatalq("Could not open report file for write: $csvout");
my $datarow = join(',', @csv_fields);
$csvout_h->print("$datarow\n");
foreach my $file (sort keys %manifest) {
  my @csvrow = ();
  my $writerecord = 1;
  # Don't write out directories that are not empty
  if (exists $manifest{$file}{'TARBALL'}) {
    if ($manifest{$file}{'TARBALL'}{'ISDIR'} and ($manifest{$file}{'INSPECTION_RESULT'} eq $CLEAN)) {
      $log->infod("Skipping this directory: $file");
      $writerecord = 0;
    }
  }
  if ($writerecord) {
    if (exists $manifest{$file}{'SNAPSHOT'}) {
      push @csvrow, $manifest{$file}{'SNAPSHOT'}{'BASEFILE'};
      if ($manifest{$file}{'SNAPSHOT'}{'ISDIR'}) {
	push @csvrow, 'DIR';
      } else {
	push @csvrow, 'FILE';
      }
      push @csvrow, $manifest{$file}{'SNAPSHOT'}{'BUCKET'};
      push @csvrow, $manifest{$file}{'SNAPSHOT'}{'SUBBUCKET'};
      push @csvrow, $manifest{$file}{'INSPECTION_RESULT'};
      push @csvrow, $manifest{$file}{'SNAPSHOT'}{'MDATESTRING'};
      if (exists $manifest{$file}{'TARBALL'}) {
	push @csvrow, $manifest{$file}{'TARBALL'}{'MDATESTRING'};
      } else {
	push @csvrow, '';
      }
      push @csvrow, $manifest{$file}{'SNAPSHOT'}{'FILESIZE'};
      if (exists $manifest{$file}{'TARBALL'}) {
	push @csvrow, $manifest{$file}{'TARBALL'}{'FILESIZE'};
      } else {
	push @csvrow, '';
      }
    }
    elsif (exists $manifest{$file}{'TARBALL'}) {
      push @csvrow, $manifest{$file}{'TARBALL'}{'BASEFILE'};
      if ($manifest{$file}{'TARBALL'}{'ISDIR'}) {
	push @csvrow, 'DIR';
      } else {
	push @csvrow, 'FILE';
      }
      push @csvrow, $manifest{$file}{'TARBALL'}{'BUCKET'};
      push @csvrow, $manifest{$file}{'TARBALL'}{'SUBBUCKET'};
      push @csvrow, $manifest{$file}{'INSPECTION_RESULT'};
      if (exists $manifest{$file}{'SNAPSHOT'}) {
	push @csvrow, $manifest{$file}{'SNAPSHOT'}{'MDATESTRING'};
      } else {
	push @csvrow, '';
      }
      push @csvrow, $manifest{$file}{'TARBALL'}{'MDATESTRING'};
      if (exists $manifest{$file}{'SNAPSHOT'}) {
	push @csvrow, $manifest{$file}{'SNAPSHOT'}{'FILESIZE'};
      } else {
	push @csvrow, '';
      }
      push @csvrow, $manifest{$file}{'TARBALL'}{'FILESIZE'};
    }
    push @csvrow, $file;
    my $datarow = join(',', @csvrow);
    $csvout_h->print("$datarow\n");
  }
}
$csvout_h->close;

# ManipFile($log, 'copy', $HOME, $csv_report, '.');

DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$log->newline;
$log->info("Script completion date: $stop_date");
$log->info("$exe_name run complete");




##### Start subroutine definitions #####

sub numerically {my $a <=> my $b;}

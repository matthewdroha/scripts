# $Id: DAStdLib.pm,v 1.12 2007/01/17 20:15:07 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: DAStdLib.pm,v 1.12 2007/01/17 20:15:07 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: DAStd.pm
Packages: DAStd, LogFile object
Project: Penryn
Original Author: Matthew Roha

Functional Description: Standard subroutines for logging, debug, file
                        manipulation, and other utilities.

=cut

package DAStdLib;

use strict;
use warnings;
use English;
use File::Copy;
use File::Path;
use File::Basename;
use IO::File;
use Cwd;
use Env;

BEGIN {
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(&GetExeName &GetDate &DeleteFiles &DeleteDirTrees &CreateDirTrees &ManipFile &GetDate &Tcsh &Pipe &PollForFile &CheckForMissingFlags &Usage &Round &GetSite &ReadEnvironmentFile &CaptureEnvironment &SetEnvironment &ClearEnvironment &RcsCo &CopyFilesToDir &ConvertMonthStringToInt &ConvertElapsedTimeToSeconds);
}

# Set up exception handling
$SIG{'INT'}  = 'DAStdLib::ExceptionHandler';
$SIG{'TERM'} = 'DAStdLib::ExceptionHandler';
$SIG{'QUIT'} = 'DAStdLib::ExceptionHandler';

# Set stdout autoflush

autoflush STDOUT 1;

########## Begin subroutine definitions ##########

# Exception hander
sub ExceptionHandler {
  die "Signal trapped. Exiting...\n";
}


sub GetDate {
  my $time;
  my $date;

  $time = time();
  $date = "(".scalar localtime($time).")";

  return ($time, $date);
}


sub GetExeName {
  my $exe_name = shift;
  my $base_exe_name;

  $exe_name = basename($exe_name);
  ($base_exe_name) = split(/\./, $exe_name);

  return ($exe_name, $base_exe_name);
}


# Deletes every file in the provided list, if it exists
sub DeleteFiles {

  my @files_list = @_;
  my $file;
  
  foreach $file (@files_list) {
    if ((-f $file) or (-l $file)) {
      unlink ($file);
    }
  }
}


sub DeleteDirTrees {

  my @targetdirs = @_;
  my $dir;

  foreach $dir (@targetdirs) {
    if (-d $dir) {
      rmtree($dir, 0, 1);
      if (-d $dir) {
	return 0;
      }
    }
  }
  return 1;
}


# Creates specified directory tree
sub CreateDirTrees {

  my @targetdirs = @_;
  my $dir;

  foreach $dir (@targetdirs) {
    unless (-d $dir) {
      mkpath($dir, 0, 0755);
      unless (-d $dir) {
	return 1;
      }
    }
  }
  return 0;
}


sub ManipFile {

  my $loghandle = shift;
  my $mode = shift;
  my $context_dir = shift;
  my $sourcefile = shift;
  my $destfile = shift;
  my $ok;
  my %cmd_hash;
  my $command;

  my $parent_dir = cwd; 
  if (-d $context_dir) {
    chdir ($context_dir) or die $loghandle->fatalq("Could not change context to dir: $context_dir");
  }

  if ((-f $destfile) or (-l $destfile)) {
    unlink($destfile);
  } 
  if ($mode eq 'copy') {
    $ok = copy($sourcefile, $destfile);
  }
  elsif ($mode eq 'symlink') {
    $ok = symlink($sourcefile, $destfile);
  }
  elsif ($mode eq 'move') {
    $ok = move($sourcefile, $destfile);
  } else {
    my $fatal_message = "Invalid mode passed to procedure ManipFile: $mode";
    if (ref($loghandle) eq 'LogFile') {
      die $loghandle->fatalq($fatal_message);
    } else {
      die "$fatal_message\n";
    }
  }
  unless ($ok) {
    if (ref($loghandle) eq 'LogFile') {
      die $loghandle->fatalq("Could not run $mode on files:",
			     "Context Dir: $context_dir",
			     "From: $sourcefile",
			     "To: $destfile");
    } else {
      die "Could not run $mode on sourcefile: $sourcefile to destfile: $destfile";
    }
  }
  chdir ($parent_dir) or die $loghandle->fatalq("Could not change context back to parent dir: $parent_dir");
}


sub Tcsh {

  my $loghandle = shift;
  my $cmd = shift;
  my $exit_value;
  my $signal_num;
  my $dumped_core;
  my $tcsh_cmd = "/bin/tcsh -fc";
  
  my $parent_flow = $loghandle->flowname('Tcsh');

  my $process_mode;
  if ($cmd =~ /\&\s*$/) {
    $process_mode = 'background';
  } else {
    $process_mode = 'foreground';
  }

  $loghandle->infoq("Starting $process_mode process: $tcsh_cmd \'$cmd\'");

  my $status = system("$tcsh_cmd \"$cmd\"");
  if ($status) {
    $exit_value = $? >> 8;
    $signal_num = $? & 127;
    $dumped_core = $? & 128;
    $loghandle->errorq("Tcsh call returned non-zero exit status. Exit: $exit_value  Signal: $signal_num  Core: $dumped_core");
  }
  $loghandle->flowname($parent_flow);
  if ($status) {
    return 0;
  } else {
    return 1;
  }
}

sub Pipe {

  my $loghandle = shift;
  my $cmd = shift;
  my $logre = shift;
  my $stdout_and_err_ref = shift;
  my $exit_value;
  my $signal_num;
  my $dumped_core;
  
  
  
  @{ $stdout_and_err_ref } = ();

  if ((!(defined($logre))) or ($logre eq '')) {
    $logre = '\S';
  }
  $loghandle->infoq("Opening pipe to process: \'$cmd\'");
  open (PIPE, "$cmd 2>&1 |") or die $loghandle->fatalq("Could not open pipe for command:", $cmd);
  while (<PIPE>) {
    chomp;
    if (/$logre/) {
      $loghandle->infoq($_);
      push (@{ $stdout_and_err_ref }, $_)
    }
  }
  close (PIPE);
  
  $exit_value = $? >> 8;
  $signal_num = $? & 127;
  $dumped_core = $? & 128;
  if ($exit_value) {
    $loghandle->errorq("Pipe call returned non-zero exit status. Exit: $exit_value  Signal: $signal_num  Core: $dumped_core");
    return 0;
  } else {
    return 1;
  }
}


# Polls for the existance of the given file once every POLL_INTERVAL seconds
sub PollForFile {
  my $flag_file = shift; 
  my $POLL_INTERVAL = 5;
  
  while (!(-e $flag_file)) {
    sleep $POLL_INTERVAL;
  }
}



# Does a closer check of the command line flags. Will check that
# flags required for the script execution are present, and will also check
# that a flag is not listed twice.
# For cases where one flag from a list of flags is required, separate by ":"
sub CheckForMissingFlags {

  my $argv_list_ref = shift;
  my $required_flags_list_ref = shift;
  my %argv_hash;
  my $flag;
  my @flags;
  my $required_flag_found;
  my $flag_spec;
  my $listflag;

  map { $argv_hash{$_} = 1 } @{ $argv_list_ref };
  foreach $flag_spec (@{ $required_flags_list_ref }) {
    $required_flag_found = 0;
    @flags = split(/:/, $flag_spec);
    foreach $flag (@flags) {
      if (exists $argv_hash{$flag}) { 
	if ($required_flag_found) {
	  print STDOUT "Only one flag from $flag_spec can be specified.";
	  print STDOUT "Use -help to list input flags.\n";
	  die "\n";
	} else {
	  $required_flag_found = 1;
	}
      }
    }
    unless ($required_flag_found) {
      die "Required flag(s) are missing. Use -help to list input flags.\n";
    }
  }
}



# Will print usage list that is provided. Replaces usage in inc.ph, got
# tired of having to worry whether or not the .ph file is in the
# current project.
sub Usage {

  my $error = shift;
  my @usagelist = @_;
  my $line;

  print "$error";
  print "\n";
  for $line (@usagelist) {
    print $line;
  }
  die "\n";
}


# Will round a floating point number to the closest integer.
sub Round {

   my $input_float = shift;
   my $output_integer;
   my $rounding_factor;

   if ($input_float < 0) {
      $rounding_factor = -.5;
   } else {
      $rounding_factor = .5;
   }

   $output_integer = int($input_float + $rounding_factor);
   return $output_integer;
}



sub GetSite {

  if (-d '/nfs/iil') {
    return 'iil';
  }
  elsif (-d '/nfs/fm') {
    return 'fm';
  }
  elsif (-d '/nfs/sc/') {
    return 'sc';
  }
  elsif (-d '/nfs/cr/') {
    return 'cr';
  }
  elsif (-d '/nfs/ltdn') {
    return 'ra';
  } 
  elsif (-d' /nfs/pdx') {
    return 'pdx';
  } else {
    die "GetSite: Could not detect Intel site. Not in iil, fm, sc, pdx, cr, ra";
  }
}


sub ReadEnvironmentFile {

  my $loghandle = shift;
  my $envfile = shift;
  my $env_table_ref = shift;
  
  my $envfh = new IO::File;
  my $parent_flow = $loghandle->flowname("ReadEnvironmentFile");
  $loghandle->infoq("Reading environment settings from: $envfile");
  $envfh->open($envfile) or die $loghandle->fatalq("Could not open $envfile for reading");
  
  my %env_table;
  while (<$envfh>) {
    chomp;
    if (/^\s*\#/) {
      next;
    }
    if (/^\s*(\S+)=(.+)/) {
      $$env_table_ref{$1} = $2;
    }
  }
  $envfh->close;

  $loghandle->flowname($parent_flow);
}


sub CaptureEnvironment {
  
  my $loghandle = shift;
  my $env_table_ref = shift;

  foreach my $var (keys %ENV) {
    $$env_table_ref{$var} = $ENV{$var};
  }
}


sub SetEnvironment {

  my $loghandle = shift;
  my $env_table_ref = shift;
  my $force_set = shift;
  my $log = shift;

  my $parent_flow = $loghandle->flowname("SetEnvironment");

  my $setvar;
  foreach my $var (sort keys %{ $env_table_ref }) {
    $setvar = 0;
    if (defined $ENV{$var}) {
      if ($force_set) {
	$setvar = 1;
      }
    } else {
      $setvar = 1;
    }

    if ($setvar) {
      $ENV{$var} = $$env_table_ref{$var};
      if ($log) {
	$loghandle->infoq("\$$var = $ENV{$var}");
      }
    } else {
      if ($log) {
	$loghandle->infoq("\$$var = $ENV{$var}        ***** Already set in env. File value not used. *****");
      }
    }
  }
  $loghandle->flowname($parent_flow);
}


sub ClearEnvironment {

  my $loghandle = shift;
  my $env_table_ref = shift;

  my $parent_flow = $loghandle->flowname("ClearEnvironment");

  if (ref($env_table_ref) eq "HASH") {
    foreach my $var (keys %{ $env_table_ref }) {
      delete $ENV{$var};
    }
  } else {
    foreach my $var (keys %ENV) {
      delete $ENV{$var}; 
    }
  }
  $loghandle->flowname($parent_flow);
}  



sub RcsCo {

  my $loghandle = shift;
  my $rcs_target_area = shift;
  my $rcs_area = shift;
  my $log = shift;

  my $parent_flow = $loghandle->flowname("RcsCo");
  my $parent_cwd = cwd;
  chdir ($rcs_target_area) or die $loghandle->fatalq("Could not change work directory to $rcs_target_area");
  opendir (TARGET, $rcs_target_area) or die $loghandle->fatalq("Could not open directory: $rcs_target_area");
  &DeleteFiles(readdir(TARGET));
  closedir (TARGET);
  &ManipFile($loghandle, 'symlink', '', $rcs_area, "${rcs_target_area}/RCS");
  
  my $co_cmd = 'co RCS/*';
  open (CO, "$co_cmd 2>&1 |") or die $loghandle->fatalq("Could not start co process:", $co_cmd);
  while (<CO>) {
    chomp;
    $loghandle->infoq($_) if $log;
  }
  close (CO);
  chdir($parent_cwd) or die $loghandle->fatalq("Could not change work directory back to $parent_cwd");
  $loghandle->flowname($parent_flow);
}


sub CopyFilesToDir {
  
  my $loghandle = shift;
  my $infile_regexp = shift;
  my $source_dir = shift;
  my $target_dir = shift;
  
  my $sre;
  my $tre;
  if ((scalar @_) == 2) {
    ($sre, $tre) = @_;
  }

  my $parent_flow = $loghandle->flowname('CopyFilesToDir');
  
  unless ($infile_regexp) {
    $infile_regexp = '.+';
  }

  unless (-d $source_dir) {
    die $loghandle->fatalq("Source dir specified is not a directory: $source_dir");
  }

  unless (-d $target_dir) {
    die $loghandle->fatalq("Target dir specified is not a directory: $target_dir");
  }
    
  opendir (SOURCEDIR, $source_dir) or die $loghandle->fatalq("Could not open dir for reading: $source_dir");
  my @files = grep /$infile_regexp/, readdir (SOURCEDIR);
  close (SOURCEDIR);

  my @return_files;
  foreach my $file (@files) {
    if (-f "${source_dir}/${file}") {
      my $target_file = $file;
      if (($sre) and ($tre)) {
	$target_file =~ s/$sre/$tre/;
      }
      &ManipFile($loghandle, 'copy', '', "${source_dir}/${file}", "${target_dir}/${target_file}");
      push (@return_files, $file);
    }
  }
  $loghandle->flowname($parent_flow);
  return @return_files;
}


sub ConvertElapsedTimeToSeconds {

  my $days = shift;
  my $hours = shift;
  my $minutes = shift;
  my $seconds = shift;

  my $elapsed_time = int($days*86400);
  $elapsed_time += int($hours*3600);
  $elapsed_time += int($minutes*60);
  $elapsed_time += int($seconds);

  return $elapsed_time;
}



sub ConvertTopMemToKBytes {

  my $value = shift;
  my $units = shift;
  my %units_map;

  $units_map{'Gigs'} = 1000000;
  $units_map{'Megs'} = 1000;
  $units_map{'K'} = 1;

  return ($value * $units_map{$units});
}


sub ConvertEpochSecondsToElapsedTime {

  my $elapsed_seconds = shift;
  my $remainder = $elapsed_seconds;

  my $days = int($remainder / 86400);
  $remainder = int($remainder % 86400);
  my $hours = int($remainder / 3600);
  $remainder = int($remainder % 3600);
  my $minutes = int($remainder / 60);
  my $seconds = int($remainder % 60);
  
  return ($days, $hours, $minutes, $seconds);
}


sub ConvertMonthStringToInt {

  my $month_string = shift;
  my %MONTH;

  $month_string = lc($month_string);

  $MONTH{'jan'} = 0;
  $MONTH{'feb'} = 1;
  $MONTH{'mar'} = 2;
  $MONTH{'apr'} = 3;
  $MONTH{'may'} = 4;
  $MONTH{'jun'} = 5;  
  $MONTH{'jul'} = 6;  
  $MONTH{'aug'} = 7;
  $MONTH{'sep'} = 8;
  $MONTH{'oct'} = 9;
  $MONTH{'nov'} = 10;
  $MONTH{'dec'} = 11;

  if (exists ($MONTH{$month_string})) {
    return $MONTH{$month_string}
  } else {
    die "ConvertMonthStringToInt: Input month not matched\n";
  }
}



package LogFile;

use IO::File;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $filename;
  my $filehandle;
  if (@_) {
    $filename = shift;
    $filehandle = new IO::File;
    $filehandle->open(">$filename") or die "Could not open $filename for writing\n";
  }
  $filehandle->autoflush(1);
  my $self = {
    FILEHANDLE   => $filehandle,
    FILENAME     => $filename,
    MODE         => undef,
    LOGONLY      => undef,
    FORCESTDOUT  => undef,
    DEBUG_MODE   => undef,
    VERBOSE      => undef,
    SPACER       => '',
    DEBUG_STRING => '[DEBUG]',
    FLOW_NAME    => undef,
    INFO_STRING  => '-I-',
    WARN_STRING  => '-W-',
    ERROR_STRING => '-E-',
    FATAL_STRING => '-F-',
  };
  $self->{DEBUG_SPACER} = length($self->{DEBUG_STRING});
  bless ($self, $class);
  return $self;
}


sub close {
  my $self = shift;
  close($self->{FILEHANDLE});
}


sub flowname {
  my $self = shift;
  my $current_flow = $self->{FLOW_NAME};
  if (@_) {
    $self->{FLOW_NAME} = shift;
  }
  my $length = length($self->{FLOW_NAME});
  $self->{SPACER} = " " x 5 . " " x $length;
  return $current_flow;
}


sub filename {
  my $self = shift;
  return $self->{FILENAME};
}


sub write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  my $header;
  my $logstring;
  
  $self->{MODE} = $mode;
  for (my $i = 0; $i <= $#message; $i++) {
    if ($i == 0) {
      if ($self->{DEBUG_MODE}) {
	$header = "$self->{DEBUG_STRING}";
      } else {
        $header = '';
      }
      $header .= "$self->{MODE} $self->{FLOW_NAME}: ";
    } else {
      if ($self->{DEBUG_MODE}) {
	$header = " " x $self->{DEBUG_SPACER};
      } else {
	$header = '';
      }
      $header .= "$self->{SPACER} ";
    }
    $logstring .= "${header}$message[$i]\n";
  }

  $self->{FILEHANDLE}->print($logstring);
  if ($self->{FORCESTDOUT} or (!$self->{LOGONLY} and $self->{VERBOSE})) {
    print STDOUT $logstring;
  }
  return $logstring;
}

sub newline {
  my $self = shift;
  my $count = shift;
  if ((defined $count) and ($count =~ /(\d+)/)) {
    $count = $1;
  } else {
    $count = 1;
  }
  my $string = "\n" x $count;
  $self->{FILEHANDLE}->print($string);
  return $string;
}
  

sub verbose {
  my $self = shift;
  if (@_) {
    $self->{VERBOSE} = shift;
  }
  return $self->{VERBOSE};
}

sub normal_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 0;
  $self->{LOGONLY} = 0;
  $self->write_to_log($mode, @message);
}


sub only_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 0;
  $self->{LOGONLY} = 1;
  $self->write_to_log($mode, @message);
}


sub stdout_and_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 1;
  $self->{LOGONLY} = 0;
  $self->write_to_log($mode, @message);
}


sub debug_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
 
  $self->{DEBUG_MODE} = 1;
  $self->{FORCESTDOUT} = 0;
  $self->{LOGONLY} = 1;
  $self->write_to_log($mode, @message);
  $self->{DEBUG_MODE} = 0;
}


sub info {
  my $self = shift;
  my @message = @_;
  $self->normal_write_to_log($self->{INFO_STRING}, @message);
}

sub infoq {
  my $self = shift;
  my @message = @_;
  $self->only_write_to_log($self->{INFO_STRING}, @message);
}

sub infop {
  my $self = shift;
  my @message = @_;
  $self->stdout_and_write_to_log($self->{INFO_STRING}, @message);
}

sub infod {
  my $self = shift;
  my @message = @_;
  $self->debug_write_to_log($self->{INFO_STRING}, @message);
}


sub warn {
  my $self = shift;
  my @message = @_;
  $self->normal_write_to_log($self->{WARN_STRING}, @message);
}

sub warnq {
  my $self = shift;
  my @message = @_;
  $self->only_write_to_log($self->{WARN_STRING}, @message);
}

sub warnp {
  my $self = shift;
  my @message = @_;
  $self->stdout_and_write_to_log($self->{WARN_STRING}, @message);
}

sub warnd {
  my $self = shift;
  my @message = @_;
  $self->debug_write_to_log($self->{WARN_STRING}, @message);
}

sub error {
  my $self = shift;
  my @message = @_;
  $self->normal_write_to_log($self->{ERROR_STRING}, @message);
}

sub errorq {
  my $self = shift;
  my @message = @_;
  $self->only_write_to_log($self->{ERROR_STRING}, @message);
}

sub errorp {
  my $self = shift;
  my @message = @_;
  $self->stdout_and_write_to_log($self->{ERROR_STRING}, @message);
}

sub errord {
  my $self = shift;
  my @message = @_;
  $self->debug_write_to_log($self->{ERROR_STRING}, @message);
}

sub fatal {
  my $self = shift;
  my @message = @_;
  $self->normal_write_to_log($self->{FATAL_STRING}, @message);
}

sub fatalq {
  my $self = shift;
  my @message = @_;
  $self->only_write_to_log($self->{FATAL_STRING}, @message);
}

sub fatalp {
  my $self = shift;
  my @message = @_;
  $self->stdout_and_write_to_log($self->{FATAL_STRING}, @message);
}

sub fatald {
  my $self = shift;
  my @message = @_;
  $self->debug_write_to_log($self->{FATAL_STRING}, @message);
}

1;

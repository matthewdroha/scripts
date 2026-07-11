#!/usr/intel/pkgs/perl/5.26.1/bin/perl

# check_stdcell_verilog.pl
# (C) Copyright Intel Corporation, 2019, Matthew Roha, matthew.d.roha@intel.com
#
# Documentation after __END__
#

use v5.26.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Copy;
use Time::Local;
use IO::File;
use IO::Dir;
use Cwd;
use Env;
use YAML::XS 'LoadFile';
use Data::Dumper;


# Get script name
my ($exe_name, $exe_prefix) = get_exe_name($0);

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die qq(-W- $exe_name: No command line parameters. Use --help to list input flags.\n);
}

# Get command line options. &GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_testrules);
our ($opt_run_name, @opt_env, $opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "run-name=s",  => \$opt_run_name,
                            "testrules=s", => \$opt_testrules,
                            "verbose");
# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
    die qq(-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n);
}

# Run help
if ($opt_help) {
  pod2usage( { -message => q(-I- $exe_name: Help flag specified. Printing usage information.),
  -exitval => 0,
  -sections => qw(SYNOPSIS)} );
}


# More options checks 
my @required_flag_list = ('--testrules');
my @argv_snapshot = @mailargv;
check_for_missing_opt_flags(\@argv_snapshot, \@required_flag_list);


# Get the script start time
our ($start_time, $start_date) = get_date();


# Variables for output file naming and global logfile
our ($basefile, $log);
if ($opt_run_name) {
  $basefile = "${opt_run_name}.${exe_prefix}";
} else {
  $basefile = "${exe_prefix}";
}

# Import environment variables
our ($HOME);
my @env_list = ('HOME');
foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your shell session:", "\$$env_var is not defined."
  }
}

########################
# Run main
main();



sub main {

  $log = Logfile->new("${basefile}.log");
  $log->flowname($exe_name);
  $log->verbose($opt_verbose);
  $log->debug($opt_debug);

  my $machine_info = `hostname --long`;
  chomp $machine_info;
  $log->info("Command: $exe_name $command_line");
  $log->info("Start date: $start_date");
  $log->info("Machine: $machine_info");


  # Get any command line env vars
  if (@opt_env) {
    foreach my $setting (@opt_env) {
      if ($setting =~ /^\s*(\S+)\=(.+)$/) {
        my $envvar = $1;
        my $value = $2;
        chomp $value;
        $ENV{$envvar} = $value;
        $log->info("--env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
      } else {
        die $log->fatal_l("Invalid value for switch --env: $setting");
      }
    }
  }

  # Read testrules 
  my $testrules_yaml;
  read_testrules($opt_testrules, \$testrules_yaml);

  # Read tests in existing test directory
  my($filename, $path, $suffix) = fileparse($opt_testrules);
  my %available_tests;
  find_available_tests($path, \%available_tests);

  # Create a sourcefile to remove unwanted tests
  my $targetfile = qq(${opt_testrules}.clean.source);
  write_rm_sourcefile($targetfile, $testrules_yaml, \%available_tests);

  # Finish
  my ($finish_time, $finish_date) = get_date();
  my $elapsed_time = $finish_time - $start_time;
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime($elapsed_time);
  $log->info("Finish date: $finish_date");
  my $elapsed_time_string = sprintf("%2d days, %2d hours, %2d minutes, %2d seconds", $yday, $hour, $min, $sec);
  $log->info("Elapsed time: $elapsed_time_string");
  $log->info("$exe_name run complete");
}



# subs

sub read_testrules {
  my $testrules = shift;
  my $testrules_yaml_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  $$testrules_yaml_ref = LoadFile($testrules) or die $log->fatal_l("Could not open yaml file for reading: $testrules");

  $log->flowname($parent_flow);
  return;
}


sub find_available_tests {
  my $targetdir = shift;
  my $available_tests_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my $targetdirh = new IO::Dir;
  $targetdirh->open($targetdir) or die $log->fatal_l("Could not open directory for reading: $targetdir");
  my @files = grep /\.t$/, $targetdirh->read;

  foreach my $file (@files) {
    #my $fullfile = qq(${targetdir}/${file});
    $$available_tests_ref{$file} = 1;
  }

  $log->flowname($parent_flow);
  return;
}


sub write_rm_sourcefile  {
  my $targetfile = shift;
  my $testrules_yaml_ref = shift;
  my $available_tests_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);


  my $targetfileh = new IO::File;
  $targetfileh->open(">$targetfile") or die "-E- Could not open $targetfile for writing";
  $targetfileh->autoflush(1);
  print $targetfileh qq(# Produced by $exe_name\n);

  my $seq_array = $testrules_yaml_ref->{seq};
  my %testrules_tests;
  foreach my $hash_ref (@$seq_array) {
    foreach my $seq_key (keys %{ $hash_ref }) {
      foreach my $test (@{ $$hash_ref{$seq_key} }) {
        $test =~ s/t\///;
        $testrules_tests{$test} = 1;
      }
    }
  }
  
  foreach my $test (sort keys %{ $available_tests_ref }) {
    unless(exists $testrules_tests{$test}) {
      print $targetfileh qq(rm $test\n);
    }
  }
  
  $targetfileh->close;

  $log->flowname($parent_flow);
  return;
}



sub check_for_missing_opt_flags {
  my $argv_list_ref = shift;
  my $required_flags_list_ref = shift;
  my %argv_hash;
  my @flags;
  my $required_flag_found;
  my $flag_spec;
  my $listflag;

  map { $argv_hash{$_} = 1 } @{ $argv_list_ref };
  foreach $flag_spec (@{ $required_flags_list_ref }) {
    $required_flag_found = 0;
    @flags = split(/:/, $flag_spec);
    foreach my $flag (@flags) {
      if (exists $argv_hash{$flag}) {
        if ($required_flag_found) {
          print STDOUT "Only one flag from $flag_spec can be specified.";
          print STDOUT "Use --help to list input flags.\n";
          print STDOUT "\n";
          exit;
        } else {
          $required_flag_found = 1;
        }
      }
    }
    unless ($required_flag_found) {
      print STDOUT "Required flag(s) are missing. Use --help to list input flags.\n";
      exit;
    }
  }
}


sub get_exe_name {
  my $exe_name = shift;
  my $base_exe_name;

  $exe_name = basename($exe_name);
  ($base_exe_name) = split(/\./, $exe_name);

  return ($exe_name, $base_exe_name);
}


sub read_file_to_list {
  my $infile = shift;
  my $output_list_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my $infilefh = new IO::File;
  $infilefh->open($infile) or die $log->fatal_l("Could not open file for reading: $infile");
  my $item_count = 0;
  while (<$infilefh>) {
    if (/^\s*\#/) {
      $log->warn("Skipping commented line $. of input file $infile");
      next;
    }
    my @record = split;
    foreach my $item (@record) {
      push (@{ $output_list_ref }, $item);
      $item_count++;
    }
  }
  $log->info("$item_count items read from file->($infile)");
  $infilefh->close;

  $log->flowname($parent_flow);
}


sub get_date {
  my $time;
  my $date;

  $time = time();
  $date = "(".scalar localtime($time).")";

  return ($time, $date);
}


sub operate_on_file {
  my $logh = shift;
  my $mode = shift;
  my $sourcefile = shift;
  my $destfile = shift;
  my $context_dir;
  if (@_) {
    $context_dir = shift;
  } else {
    $context_dir = cwd;
  }
  my $ok;
  my %cmd_hash;
  my $command;

  my $parent_dir = cwd;

  if (-d $context_dir) {
    $ok = chdir $context_dir;
    unless ($ok) {
      my $fatal_message = qq(Could not change context to dir: $context_dir);
      if (ref($logh) eq 'Logfile') {
        die $logh->fatal_l($fatal_message);
      } else {
        die "$fatal_message\n";
      }
    }
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
    my $fatal_message = qq(Invalid mode passed to procedure ManipFile: $mode);
    if (ref($logh) eq 'Logfile') {
      die $log->fatal_l($fatal_message);
    } else {
      die "$fatal_message\n";
    }
  }
  unless ($ok) {
    if (ref($logh) eq 'Logfile') {
      die $logh->fatal_l("Could not run $mode on files:",
          "Context Dir: $context_dir",
          "From: $sourcefile",
          "To: $destfile");
    } else {
      die qq(Could not run $mode on sourcefile: $sourcefile to destfile: $destfile);
    }
  }
  chdir ($parent_dir) or die $logh->fatal_l("Could not change context back to parent dir: $parent_dir");
}


sub pipe {
  my $logh = shift;
  my $cmd = shift;
  my $logre = shift;
  my $stdout_and_err_ref = shift;
  my $writetolog = shift;
  my $exit_value;
  my $signal_num;
  my $dumped_core;

  @{ $stdout_and_err_ref } = ();

  if ((!(defined($logre))) or ($logre eq '')) {
    $logre = '\S';
  }
  $logh->info_l("Opening pipe to process: \'$cmd\'") if $writetolog;
  open (PIPE, "$cmd 2>&1 |") or die $logh->fatal_l("Could not open pipe for command:", $cmd);
  while (<PIPE>) {
    chomp;
    if (/$logre/) {
      $logh->info_l($_) if $writetolog;
      push (@{ $stdout_and_err_ref }, $_)
    }
  }
  close (PIPE);

  $exit_value = $? >> 8;
  $signal_num = $? & 127;
  $dumped_core = $? & 128;
  if ($exit_value) {
    $logh->error_l("Pipe call returned non-zero exit status. Exit: $exit_value  Signal: $signal_num Core: $dumped_core");
    return 0;
  } else {
    return 1;
  }
}


########################
# Package Logfile
# 4 severity types: Info, Warning, Error, Fatal.  The last is for issues that should stop execution
#
# For each severity type,  there are 3 modes for writing output
# Default     (example: $log->info)    Writes to log file and stdout if verbose active
# Log only    (example: $log->info_l)  Writes to log file only, never stdout.
# Stdout only (example: $log->info_s)  Writes to stdout only, regardless of verbose, never logfile
#
# In addition,  there is debug mode if --debug is activated that supports the above modes.
# (examples:  $log->infod, $log->info_ld, $log->info_sd)

{
  package Logfile;

  use strict;
  use warnings;
  use English;
  use IO::File;
  use Carp;

  sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $filename;
    my $filehandle;
    if (scalar @_ == 1) {
      $filename = shift;
      $filehandle = new IO::File;
      $filehandle->open(">$filename") or die "-E- Could not open $filename for writing";
      $filehandle->autoflush(1);
    } else {
      $filename = q(NONE);
      $filehandle = undef;
    }
    my $self = {
      FILEHANDLE   => $filehandle,
      FILENAME     => $filename,
      WRITELOG     => undef,
      WRITESTDOUT  => undef,
      WRITEDEBUG   => undef, 
      DEBUG        => undef,
      VERBOSE      => undef,
      SEVERITY     => q(),
      SPACER       => q(),
      FLOW_NAME    => q(),
      DEBUG_STRING => q([DEBUG]),
      INFO_STRING  => q(-I-),
      WARN_STRING  => q(-W-),
      ERROR_STRING => q(-E-),
      FATAL_STRING => q(-F-),
    };
    $self->{DEBUG_SPACER} = length($self->{DEBUG_STRING});
    bless ($self, $class);
    return $self;
  }

  sub close {
    my $self = shift;
    $self->{FILEHANDLE}->close if defined $self->{FILEHANDLE};
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

  sub write_message {
    my $self = shift;
    my @message = @_;
    my $header;
    my $logstring;

    for (my $i = 0; $i <= $#message; $i++) {
      if ($i == 0) {
        if ($self->{WRITEDEBUG}) {
          $header = qq($self->{DEBUG_STRING});
        } else {
          $header = q(); 
        }
        $header .= qq($self->{SEVERITY} $self->{FLOW_NAME}: );
      } else {
        if ($self->{WRITEDEBUG}) {
          $header = " " x $self->{DEBUG_SPACER};
        } else {
          $header = q();
        }
        $header .= qq($self->{SPACER} );
      }
      $logstring .= qq(${header}$message[$i]\n);
    }

    # if a debug message but not in debug mode
    if ($self->{WRITEDEBUG} and not $self->{DEBUG}) {
      $self->{WRITELOG} = 0;
      $self->{WRITESTDOUT} = 0;
    }

    if ((defined $self->{FILEHANDLE}) and $self->{WRITELOG}) {
      $self->{FILEHANDLE}->print($logstring);
    }
    print STDOUT $logstring if $self->{WRITESTDOUT};

    $self->{WRITELOG} = 0;
    $self->{WRITESTDOUT} = 0;
    $self->{WRITEDEBUG} = 0;

    return $logstring;   # for die and croak calls
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
    if ((defined $self->{FILEHANDLE}) and $self->{WRITELOG}) {
      $self->{FILEHANDLE}->print($string);
    }
    print STDOUT $string if $self->{WRITESTDOUT};
    return $string;
  }

  sub verbose {
    my $self = shift;
    if (@_) {
      $self->{VERBOSE} = shift;
    }
    return $self->{VERBOSE};
  }


  sub debug {
    my $self = shift;
    if (@_) {
      $self->{DEBUG} = shift;
    }
    return $self->{DEBUG};
  }


  sub write_to_log_and_stdout {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    $self->{WRITESTDOUT} = $self->{VERBOSE};
    $self->write_message(@message);
  }


  sub write_to_log_only {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    $self->write_message(@message);
  }


  sub write_to_stdout_only {
    my $self = shift;
    my @message = @_;
    $self->{WRITESTDOUT} = 1;
    $self->write_message(@message);
  }

  sub info {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->write_to_log_and_stdout(@message);
  }


  sub info_l {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->write_to_log_only(@message);
  }


  sub info_s {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->write_to_stdout_only(@message);
  }

  sub info_d {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_and_stdout(@message);
  }


  sub info_ld {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_only(@message);
  }


  sub info_sd {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_stdout_only(@message);
  }


  sub warn {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->write_to_log_and_stdout(@message);
  }


  sub warn_l {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->write_to_log_only(@message);
  }


  sub warn_s {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->write_to_stdout_only(@message);
  }


  sub warn_d {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_and_stdout(@message);
  }


  sub warn_ld {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_only(@message);
  }


  sub warn_sd {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_stdout_only(@message);
  }


  sub error {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->write_to_log_and_stdout(@message);
  }


  sub error_l {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->write_to_log_only(@message);
  }


  sub error_s {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->write_to_stdout_only(@message);
  }


  sub error_d {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_and_stdout(@message);
  }


  sub error_ld {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_only(@message);
  }


  sub error_sd {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_stdout_only(@message);
  }


  sub fatal {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->write_to_log_and_stdout(@message);
  }


  sub fatal_l {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->write_to_log_only(@message);
  }


  sub fatal_s {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->write_to_stdout_only(@message);
  }


  sub fatal_d {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_and_stdout(@message);
  }


  sub fatal_ld {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_log_only(@message);
  }


  sub fatal_sd {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->{WRITEDEBUG} = 1;
    $self->write_to_stdout_only(@message);
  }


  sub self_test {
    my $self = shift;
    $self->info("info: Will write to log.  Will write to STDOUT if verbose");
    $self->info_l("info_l: Will only write to log. Will never write to STDOUT");
    $self->info_s("info_s: Will never write to log. Will always write to STDOUT");
    $self->info_d("info_d: Debug. Will write to log.  Will write to STDOUT if verbose");
    $self->info_ld("info_ld: Debug. Will only write to log. Will never write to STDOUT");
    $self->info_sd("info_sd: Debug. Will never write to log. Will always write to STDOUT");
    $self->warn("warn: Will write to log.  Will write to STDOUT if verbose");
    $self->warn_l("warn_l: Will only write to log. Will never write to STDOUT");
    $self->warn_s("warn_s: Will never write to log. Will always write to STDOUT");
    $self->warn_d("warn_d: Debug. Will write to log.  Will write to STDOUT if verbose");
    $self->warn_ld("warn_ld: Debug. Will only write to log. Will never write to STDOUT");
    $self->warn_sd("warn_sd: Debug. Will never write to log. Will always write to STDOUT");
    $self->error("error: Will write to log.  Will write to STDOUT if verbose");
    $self->error_l("error_l: Will only write to log. Will never write to STDOUT");
    $self->error_s("error_s: Will never write to log. Will always write to STDOUT");
    $self->error_d("error_d: Debug. Will write to log.  Will write to STDOUT if verbose");
    $self->error_ld("error_ld: Debug. Will only write to log. Will never write to STDOUT");
    $self->error_sd("error_sd: Debug. Will never write to log. Will always write to STDOUT");
    $self->fatal("fatal: Will write to log.  Will write to STDOUT if verbose");
    $self->fatal_l("fatal_l: Will only write to log. Will never write to STDOUT");
    $self->fatal_s("fatal_s: Will never write to log. Will always write to STDOUT");
    $self->fatal_d("fatal_d: Debug. Will write to log.  Will write to STDOUT if verbose");
    $self->fatal_ld("fatal_ld: Debug. Will only write to log. Will never write to STDOUT");
    $self->fatal_sd("fatal_sd: Debug. Will never write to log. Will always write to STDOUT");
  }

} # End Package Logfile



__END__




=pod

=head1 COPYRIGHT

(C) Copyright Intel Corporation, 2019
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: check_stdcell_verilog.pl

=cut

=head1 DESCRIPTION

B<prune_t.pl> For Perl prove setup.  Reads in prove testrules.yml file and creates source file that will prune away tests that are not present in testrules.  Useful when building up a new testlist from a template.

=cut

# Prepare the usage string.

=head1 SYNOPSIS

=over 25

=item prune_t.pl

 --testrules <testrules.yml file>
 [--run-name <unique run name>]
 [--env 'VAR=VALUE'] 
 [--debug][--verbose] [--help]

=back

flag descriptions:

=over 20

=item B<--testrules>

Prove testrules.yml file that contains only the desired tests

Optional. Check all sites for existence of stdcell .v files.

=item B<--run-name>

Optional. Will append given run name to output files to avoid clobbering runs in same area.

=item B<--env>

Optional. Set env var at start of execution. Can provide more than one --env flag.  Format is VAR=VALUE

=item B<--debug>

Optional. Run flow in debug mode. Temporary files are not deleted and additional data is placed in log file.

=item B<--verbose>

Optional. Will add status messages to STDOUT.

=item B<--help>

This usage message will appear.

=item B<example:>

  prune_t.pl --testrules testrules.yml



=back

=cut

#!/usr/intel/pkgs/perl/5.40.1/bin/perl

# fixclocks.pl
# (C) Copyright Intel Corporation, 2026, Matthew Roha, matthew.d.roha@intel.com
#
# Documentation after __END__
#

use v5.40.1;
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
use Env;
use Carp;
use IPC::Open3;
use File::Path qw(make_path);
use Cwd qw(getcwd abs_path);

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
our ($opt_module, $opt_tag, $opt_simplesdc, $opt_clock_collateral_dir);
our ($opt_run_name, @opt_env, $opt_help, $opt_debug, $opt_verbose, $opt_quiet);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "module=s" => \$opt_module,
                            "tag=s" => \$opt_tag,
                            "simple-sdc=s" => \$opt_simplesdc,
                            "clock-collateral-dir=s" => \$opt_clock_collateral_dir,
                            "run-name=s" => \$opt_run_name,
                            "env=s@" => \@opt_env,
                            "debug=i" => \$opt_debug,
                            "quiet!" => \$opt_quiet,
                            "verbose!" => \$opt_verbose);
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
my @required_flag_list = ('--module', '--simple-sdc:--clock-collateral-dir');
my @argv_snapshot = @mailargv;
check_for_missing_opt_flags(\@argv_snapshot, \@required_flag_list);

unless (-d $opt_clock_collateral_dir) {
  die qq(-E- clock_collateral_dir does not exist: $opt_clock_collateral_dir);
}


# Get the script start time
our $start_time = time;

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
# Run main if not calling as package
main() if not caller();


sub main {

$log = Logfile->new("${basefile}.log");
$log->flowname($exe_name);
$log->verbose($opt_verbose);
$log->quiet($opt_quiet);
$log->debug($opt_debug);

my $machine_info = `hostname --long`;
chomp $machine_info;
$log->info("Command: $exe_name $command_line");
$log->info("Start date: $start_time");
$log->info("Machine: $machine_info");
$log->info("CWD: " . getcwd());

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


my $sdcfile = qq(${opt_clock_collateral_dir}/${opt_module}_clocks.tcl);
if (not -f $sdcfile) {
  die qq(-E- sdcfile does not exist: $sdcfile\n);
}

my @outfilelist;

# Add source call to clock params file on line 1 of new file
my $paramsfile;

my @paramsfile_candidates = (
  qq(${opt_clock_collateral_dir}/${opt_module}_clock_params_func.nom.TT_100.tttt.tcl),
  qq(${opt_clock_collateral_dir}/${opt_module}_clock_params_func.min_high.TM_100.tttt.tcl)
);

my $found_paramsfile = 0;
foreach my $file (@paramsfile_candidates) {
  if (-e $file) {
    $log->info("Clock params file exists: $file");
    $paramsfile = $file;
    $found_paramsfile = 1;
    last;
  }
}

if (not $found_paramsfile) {
  my $paramsfile_list = join(", ", @paramsfile_candidates);
  die qq(-E- Clock params file does not exist. Candidates: $paramsfile_list\n);
}

push(@outfilelist, qq(# mroha: Added by ${exe_name}\n));
push(@outfilelist, qq(# mroha: Source SDC is: ${sdcfile}\n));
push(@outfilelist, qq(# mroha: Read in place ${paramsfile}\n));
$log->info("Start read of clock params file: $paramsfile");
my $paramsfileh = IO::File->new;
$paramsfileh->open($paramsfile) or die "-E- Could not open params file for reading: $paramsfile\n";
while (<$paramsfileh>) {
  push(@outfilelist, $_);
}
$paramsfileh->close;
push(@outfilelist, qq(# mroha: Finish read in place of $paramsfile\n));
$log->info("Finish read of clock params file: $paramsfile");
push(@outfilelist, qq(set create_clock_executed_count 0\n));
push(@outfilelist, qq(set create_generated_clock_executed_count 0\n\n));

# COR is setting some new ivars
push(@outfilelist, qq(set ivar(design_name) $opt_module\n));
push(@outfilelist, qq(set ivar(clock_collateral_dir) $opt_clock_collateral_dir\n));
push(@outfilelist, qq(set ivar(build_dir) ) . getcwd() . qq(\n));

# Add code here to generate a the directory tree "release/latest" under in the current working directory then create a symlink named "clock_collateral" that points to $opt_clock_collateral_dir.  Overwrite if it already exists.
my $release_latest_dir = "release/latest";
my $clock_collateral_symlink = qq(${release_latest_dir}/clock_collateral);
make_path($release_latest_dir);
if (-l $clock_collateral_symlink || -e $clock_collateral_symlink) {
  unlink $clock_collateral_symlink or die "-E- Could not remove existing symlink: $clock_collateral_symlink\n";
}
symlink($opt_clock_collateral_dir, $clock_collateral_symlink) or die "-E- Could not create symlink: $clock_collateral_symlink -> $opt_clock_collateral_dir\n";


# Process input file. Output lines exist in @outfilelist
my $sdcfileh = IO::File->new;
$sdcfileh->open($sdcfile) or die "-F- Could not open constraints file for reading: $sdcfile\n";

my $replace_string_before = q[\$ivar\(build_dir\)\/release\/latest\/clock_collateral];

my $create_clock_detected_count = 0;
my $create_generated_clock_detected_count = 0;
my $create_clock_processed_count = 0;
my $create_generated_clock_processed_count = 0;
$log->info("Start processing SDC file: $sdcfile");
while (<$sdcfileh>) {
  my $skip = 0;
  if (/ivar/) {
    $log->info_d(2, "Found ivar in line: $_");
  }
  # Replace backend Cheetah work area with central clock collateral areas
  #if (/$replace_string_before/) {
  #  s/$replace_string_before/${opt_clock_collateral_dir}/;
  #  $log->info_d(2, "Replaced with: ${opt_clock_collateral_dir} in line: $_");
  # }
  # Add pwr_shell support
  if (/\$::synopsys_program_name == "pt_shell"/) {
    s/\$::synopsys_program_name == "pt_shell"/\( \$::synopsys_program_name == "pt_shell" || \$::synopsys_program_name == "pwr_shell" \)/;
  }
  # Add rtl_shell support
  elsif (/\$::synopsys_program_name == "icc2_shell"/) {
    s/\$::synopsys_program_name == "icc2_shell"/\$::synopsys_program_name == "icc2_shell" || \$::synopsys_program_name == "rtl_shell"/;
  }
  # Guard create_clock calls.  Run command only if one or more source objects exist after black boxing
  elsif (/^\s*create_clock\s+/) {
    my $original_command = $_;
    $create_clock_detected_count++;
    $skip = 1;
    my $source_object_collection_name;
    my @create_clock_modified_command = ();
    my $name;
    # create_clock -name idvclk -add -period $periodCache(idvclk) -waveform $waveCache(idvclk) [append_to_collection clkSourceCache_pins(idvclk) $clkSourceCache(idvclk)]
    if (/\-name\s+(\S+)/) {
      $name = $1;
    }
    if (/(\[append_to_collection.+\])\s*$/) {
      $source_object_collection_name = $1;
      my $tempstring = $source_object_collection_name =~ s/\[|\]|\$//rg; 
      my @record = split(/\s+/, $tempstring);
      my $pincollection = $record[1];
      my $portcollection = $record[2];
      my $source_object_collection_name_quotemeta = quotemeta($source_object_collection_name);
      my $pincommand = $original_command =~ s/${source_object_collection_name_quotemeta}/\$${pincollection}/rg;
      my $portcommand = $original_command =~ s/${source_object_collection_name_quotemeta}/\$${portcollection}/rg;
      @create_clock_modified_command = (
        qq(\n# Added by ${exe_name}\n),
        qq(set pincount [sizeof_collection \$$pincollection]\n),
        qq(puts "fixclocks.pl: Collection size for $pincollection: \$pincount"\n),
        qq(set portcount [sizeof_collection \$$portcollection]\n),
        qq(puts "fixclocks.pl: Collection size for $portcollection: \$portcount"\n),
        qq(if { (\$pincount > 0) && (\$portcount > 0) } {\n),
        qq(  puts "fixclocks.pl: Both pin and port collection exist. Use original create_clock command"\n),
        qq(  $_),
        qq(  incr create_clock_executed_count\n),
        qq(} elseif {\$pincount > 0} {\n),
        qq(  puts "fixclocks.pl: Only pin collection exists. Use only pins for create_clock source objects"\n),
        qq(  $pincommand),
        qq(  incr create_clock_executed_count\n),
        qq(} elseif {\$portcount > 0} {\n),
        qq(  puts "fixclocks.pl: Only port collection exists. Use only ports for create_clock source objects"\n),
        qq(  $portcommand),
        qq(  incr create_clock_executed_count\n),
        qq(} else {\n),
        qq(   puts "fixclocks.pl: No valid pin or port source objects"\n),
        qq(   puts "fixclocks.pl: Skipped create_clock for clock: $name"\n),
        qq(}\n\n)
      );
    }
    # write virtual clocks without any processing
    elsif (/\s+\-waveform\s+(\S+|\{.+\})\s*$/) {
      push(@outfilelist, qq(puts "${exe_name}: No guard wrap added for clock: $name"\n));
      push(@outfilelist, $_);
      next;
    }
    # process common case
    elsif (/\s+(\$\S+)\s*$/) {
      $source_object_collection_name = $1;
      my $source_object_collection_name_reduced = $source_object_collection_name =~ s/\$//rg;
      @create_clock_modified_command = (
        qq(\n# Added by ${exe_name}\n),
        qq(set source_object_count [sizeof_collection ${source_object_collection_name}]\n),
        qq(if {\$source_object_count > 0} {\n),
        qq(  puts "${exe_name}: Source object count for ${source_object_collection_name_reduced}: \$source_object_count"\n),
        qq(  incr create_clock_executed_count\n),
        qq(  $_),
        qq(  puts "${exe_name}: Executed create_clock for clock: $name"\n),
        qq(} else {\n),
        qq(  puts "${exe_name}: ${source_object_collection_name_reduced} contains no valid objects"\n),
        qq(  puts "${exe_name}: Skipped create_clock for clock: $name"\n),
        qq(}\n\n)
      );
    }
    die qq(create_clock source object format not handled. Enhancement required. See SDC file, line $.\n) unless $source_object_collection_name;
    push(@outfilelist, @create_clock_modified_command);
    $create_clock_processed_count++;
  }
  # Guard create_generated_clock calls.  Run command only if one or more source objects exist after black boxing
  elsif (/^\s*create_generated_clock\s+/) {
    $create_generated_clock_detected_count++;
    $skip = 1;
    my $master_clock;
    my $master_clock_source;
    my $source_object_collection_name;
    my $name;
    # create_generated_clock -name visa_serstb_croclk -add -master_clock croclk -source $clkMasterSourceCache(visa_serstb_croclk) -divide_by $factorCache_div(visa_serstb_croclk) $clkSourceCache(visa_serstb_croclk)
    if (/\-name\s+(\S+)/) {
      $name = $1;
    }
    if (/\-master_clock\s+(\S+)/) {
      $master_clock = $1;
    }
    if (/\-source\s+(\S+)/) {
      $master_clock_source = $1;
    }
    if (/\s+(\$\S+)\s*$/) {
      $source_object_collection_name = $1;
    }

    die qq(create_generated_clock call format is not handled. Enhancement required. See SDC file, line $.\n) unless ($master_clock and $master_clock_source and $source_object_collection_name);

    my $master_clock_source_reduced = $master_clock_source =~ s/\$//rg;
    my $source_object_collection_name_reduced = $source_object_collection_name =~ s/\$//rg;

    my @create_generated_clock_modified_command = (
      qq(\n# Added by ${exe_name}\n),
      qq(set clock_exists [sizeof_collection [get_clocks $master_clock]]\n),
      qq(if { [info exists ${master_clock_source_reduced}] } {\n),
      qq(  set master_clock_source_object_count [sizeof_collection ${master_clock_source}]\n),
      qq(}\n),
      qq(set source_object_count [sizeof_collection ${source_object_collection_name}]\n),
      qq(if { ( \$clock_exists > 0 ) && ( [info exists ${master_clock_source_reduced}] ) && ( \$master_clock_source_object_count > 0 ) && ( \$source_object_count > 0 ) } {\n),
      qq(  puts "${exe_name}: Source object count for ${master_clock_source_reduced}: \$master_clock_source_object_count"\n),
      qq(  puts "${exe_name}: Source object count for ${source_object_collection_name_reduced}: \$source_object_count"\n),
      qq(  incr create_generated_clock_executed_count\n),
      qq(  $_),
      qq(  puts "${exe_name}: Executed create_generated_clock for clock: $name"\n),
      qq(} else {\n),
      qq(  puts "${exe_name}: generated_clock master clock or source object list contains no valid objects"\n),
      qq(  puts "${exe_name}: Skipped create_generated_clock for clock: $name"\n),
      qq(}\n\n)
    );
    push(@outfilelist, @create_generated_clock_modified_command);
    $create_generated_clock_processed_count++;

  }
  push(@outfilelist, $_) unless $skip;
}
$sdcfileh->close;


# mroha:  Removed check_timing calls. Report doesn't provide details on which generated clock source objects are causing a TCK-004
my @footer =(
  #  qq(\n\n),
  #  # Warning: The generated clock 'lcpclk' has no path from master clock 'tclk'. Mode:'default'. (TCK-004)
  #  # The same clock can appear in warnings multiple times
  #  qq(\n# Added by ${exe_name}\n),
  #  qq(### ${exe_name} Run check_timing to scan and resolve TCK-004 issues before running rtl_opt\n),
  #  qq(redirect -variable check_output {check_timing -include {generated_clock}}\n),
  #  qq(set warninglist [regexp -all -line -inline {Warning: The generated clock '(.+)' has no path.+TCK-004} \$check_output]\n),
  #  qq(set removeGeneratedClockCount 0\n),
  #  qq(foreach line \$warninglist {\n),
  #  qq(  if  {![regexp {Warning:} \$line] }  {\n),
  #  qq(    if {![info exists alreadyRemoved(\$line)]} {\n),
  #  qq(      remove_generated_clock \$line\n),
  #  qq(      incr removeGeneratedClockCount\n),
  #  qq(      set alreadyRemoved(\$line) 1\n),
  #  qq(    }\n),
  #  qq(  }\n),
  #  qq(}\n\n),
  #
  #  # mroha: There are many better ways to do this, dirty code reuse for now
  #  qq(### ${exe_name} Run second round check_timing to scan for orphaned generated clocks and resolve TCK-004 issues before running rtl_opt\n),
  #  qq(redirect -variable check_output {check_timing -include {generated_clock}}\n),
  #  qq(set warninglist [regexp -all -line -inline {Warning: The generated clock '(.+)' has no path.+TCK-004} \$check_output]\n),
  #  qq(foreach line \$warninglist {\n),
  #  qq(  if  {![regexp {Warning:} \$line] }  {\n),
  #  qq(    if {![info exists alreadyRemovedRound2(\$line)]} {\n),
  #  qq(      remove_generated_clock \$line\n),
  #  qq(      incr removeGeneratedClockCount\n),
  #  qq(      set alreadyRemovedRound2(\$line) 1\n),
  #  qq(    }\n),
  #  qq(  }\n),
  #  qq(}\n),

  # Final Summary
  qq(\n\n),
  qq(# Added by ${exe_name}\n),
  qq(### ${exe_name} Summary\n),
  qq(puts "create_clock calls detected in original SDC           : $create_clock_detected_count"\n),
  qq(puts "create_clock calls guard wrapped in new SDC           : $create_clock_processed_count"\n),
  qq(puts "create_generated_clock calls detected in original SDC : $create_generated_clock_detected_count"\n),
  qq(puts "create_generated_clock calls guard wrapped in new SDC : $create_generated_clock_processed_count"\n),
  qq(puts "create_clock calls executed                           : \$create_clock_executed_count"\n),
  qq(puts "create_generated_clock calls executed                 : \$create_generated_clock_executed_count"\n),
  #  qq(puts "remove_generated_clock calls executed                 : \$removeGeneratedClockCount"\n),
);


push(@outfilelist, @footer);

#my $basefilename = basename($sdcfile);
my $outfile;
if ($opt_tag) {
  $outfile = qq(${opt_module}_clocks_${opt_tag}.tcl.fixclocks);
} else {
  $outfile = qq(${opt_module}_clocks.tcl.fixclocks);
}
my $outfileh = IO::File->new;
$outfileh->open(">$outfile") or die qq(-E- Could not open outfile for writing: $outfile\n);
foreach my $line (@outfilelist) {
  print $outfileh $line;
}
$outfileh->close;

$log->info("create_clock calls detected in original SDC           : $create_clock_detected_count");
$log->info("create_clock calls guard wrapped in new SDC           : $create_clock_processed_count");
$log->info("create_generated_clock calls detected in original SDC : $create_generated_clock_detected_count");
$log->info("create_generated_clock calls guard wrapped in new SDC : $create_generated_clock_processed_count");
$log->info("SDC file written successfully: $outfile");
$log->close;

}  # end main 



# Subs

sub numerically {$a <=> $b;}


sub get_exe_name {
  my $exe_name = shift;
  my $base_exe_name;

  $exe_name = basename($exe_name);
  ($base_exe_name) = split(/\./, $exe_name);

  return ($exe_name, $base_exe_name);
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


sub read_file_to_list {
  my $infile = shift;
  my $output_list_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my $infilefh = IO::File->new;
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
    $context_dir = getcwd();
  }
  my $ok;
  my %cmd_hash;
  my $command;

  my $parent_dir = getcwd();

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


sub Pipe {
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
  my $pipeh = FileHandle->new;
  $pipeh->open("$cmd 2>&1 |") or die $logh->fatal_l("Could not open pipe for command:", $cmd);
  while (<$pipeh>) {
    chomp;
    if (/$logre/) {
      $logh->info_l($_) if $writetolog;
      push (@{ $stdout_and_err_ref }, $_)
    }
  }
  $pipeh->close;

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
# 4 severity types: info, warn, error, fatal.  fatal is for issues that stop flow execution
#
# For info, warn, and error types,  there are 2 modes for writing output to STDOUT.  Logfile records everything.
# Default     (example: $log->info)    Writes to stdout if verbose active. Quiet will suppress stdout.
# Force       (example: $log->info_f)  Writes to stdout regardless of verbose. Quiet will suppress stdout.
#
# Fatal will always write to stdout and stop flow execution.
#
# In addition,  there is debug mode if --debug <integer> is activated that supports the above modes.
# Example:  $log->info_d(2, "This is a level 2 debug message. Will be printed in logfile for --debug 2 or higher")

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
      $filehandle = IO::File->new;
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
      QUIET        => undef,
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

    if ((defined $self->{FILEHANDLE}) and $self->{WRITELOG}) {
      $self->{FILEHANDLE}->print($logstring);
    }
    if ($self->{WRITESTDOUT}) {
      print STDOUT $logstring;
    }

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

  sub quiet {
    my $self = shift;
    if (@_) {
      $self->{QUIET} = shift;
    }
    return $self->{QUIET};
  }

  sub write_to_log_and_verbose_stdout {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    if ($self->{QUIET}) {
      $self->{WRITESTDOUT} = 0;
    } else {
      $self->{WRITESTDOUT} = $self->{VERBOSE};
    }
    $self->write_message(@message);
  }

  sub write_to_log_and_stdout {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    if ($self->{QUIET}) {
      $self->{WRITESTDOUT} = 0;
    } else {
      $self->{WRITESTDOUT} = 1;
    }
    $self->write_message(@message);
  }

  sub write_to_log_and_force_stdout {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    $self->{WRITESTDOUT} = 1;
    $self->write_message(@message);
  }

  sub write_to_log_only {
    my $self = shift;
    my @message = @_;
    $self->{WRITELOG} = 1;
    $self->write_message(@message);
  }

  # Info message. Writes to log file and stdout if verbose active. Will not write to stdout if quiet active.
  sub info {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->write_to_log_and_verbose_stdout(@message);
  }

  # Info but forces stdout even without verbose flag. Will not write to stdout if quiet active.
  sub info_f {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    $self->write_to_log_and_stdout(@message);
  }

  # Info debug message. Writes to log only.  First argument is debug level.
  sub info_d {
    my $self = shift;
    my $debug_level = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{INFO_STRING};
    if ((defined $self->{DEBUG}) and ($debug_level <= $self->{DEBUG})) {
      $self->{WRITEDEBUG} = 1;
      $self->write_to_log_only(@message);
    }
  }

  # Warn message. Writes to log file and stdout if verbose active. Will not write to stdout if quiet active.
  sub warn {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->write_to_log_and_verbose_stdout(@message);
  }

  # Warn but forces stdout even without verbose flag. Will not write to stdout if quiet active.
  sub warn_f {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    $self->write_to_log_and_stdout(@message);
  }

  # Warn debug message. Writes to log only.  First argument is debug level.
  sub warn_d {
    my $self = shift;
    my $debug_level = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{WARN_STRING};
    if ((defined $self->{DEBUG}) and ($debug_level <= $self->{DEBUG})) {
      $self->{WRITEDEBUG} = 1;
      $self->write_to_log_only(@message);
    }
  }

  # Error message. Writes to log file and stdout if verbose active. Will not write to stdout if quiet active.
  sub error {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->write_to_log_and_verbose_stdout(@message);
  }

  # Error but forces stdout even without verbose flag. Will not write to stdout if quiet active.
  sub error_f {
    my $self = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    $self->write_to_log_and_stdout(@message);
  }

  # Error debug message. Writes to log only.  First argument is debug level.
  sub error_d {
    my $self = shift;
    my $debug_level = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{ERROR_STRING};
    if ((defined $self->{DEBUG}) and ($debug_level <= $self->{DEBUG})) {
      $self->{WRITEDEBUG} = 1;
      $self->write_to_log_only(@message);
    }
  }

  # Fatal but forces stdout even without verbose flag. Will write even if quiet active.
  sub fatal {
    my $self = shift;
    my @message = @_; 
    $self->{SEVERITY} = $self->{FATAL_STRING};
    $self->write_to_log_and_force_stdout(@message);
  }

  # Fatal debug message. Writes to log only.  First argument is debug level.
  sub fatal_d {
    my $self = shift;
    my $debug_level = shift;
    my @message = @_;
    $self->{SEVERITY} = $self->{FATAL_STRING};
    if ((defined $self->{DEBUG}) and ($debug_level <= $self->{DEBUG})) {
      $self->{WRITEDEBUG} = 1;
      $self->write_to_log_only(@message);
    }
  }

  sub self_test {
    my $self = shift;
    $self->info("info: Logfile:Yes STDOUT Verbose:Yes STDOUT Quiet:No");
    $self->warn("warn: Logfile:Yes STDOUT Verbose:Yes STDOUT Quiet:No");
    $self->error("error: Logfile:Yes STDOUT Verbose:Yes STDOUT Quiet:No");
    $self->fatal("fatal: Logfile:Yes STDOUT regardless of verbose or quiet settings");
    $self->info_f("info_f: Logfile:Yes STDOUT regardless of verbose. Quiet: No");
    $self->warn_f("warn_f: Logfile:Yes STDOUT regardless of verbose. Quiet: No");
    $self->error_f("error_f: Logfile:Yes STDOUT regardless of verbose. Quiet: No");
    $self->info_d(1,"info_d: DEBUG LEVEL 1 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->warn_d(1,"warn_d: DEBUG LEVEL 1 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->error_d(1,"error_d: DEBUG LEVEL 1 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->fatal_d(1,"fatal_d: DEBUG LEVEL 1 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->info_d(2,"info_d: DEBUG LEVEL 2 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->warn_d(2,"warn_d: DEBUG LEVEL 2 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->error_d(2,"error_d: DEBUG LEVEL 2 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->fatal_d(2,"fatal_d: DEBUG LEVEL 2 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->info_d(3,"info_d: DEBUG LEVEL 3 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->warn_d(3,"warn_d: DEBUG LEVEL 3 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->error_d(3,"error_d: DEBUG LEVEL 3 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
    $self->fatal_d(3,"fatal_d: DEBUG LEVEL 3 Logfile:Yes STDOUT Verbose:No STDOUT Quiet:No");
  }

} # End Package Logfile






__END__

=pod

=head1 COPYRIGHT

(C) Copyright Intel Corporation, 2026
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: fixclocks.pl

=cut

=head1 DESCRIPTION

B<fixclocks.pl>Reads MCSS or hand authored .tcl/.sdc clock collateral and places guard code around create_clock and create_generated_calls to verify at least one source object exists before executing.  PPRTL has been inconsistent in handling these cases.

=cut

# Prepare the usage string.

=head1 SYNOPSIS

=over 25

=item fixclocks.pl

 --module <rtl top module name>
 --simple-sdc <input sdc> or --clock_collateral_dir <clock_collateral release area>
 [--run-name <name for this run>]
 [--tag <arbitrary tag name>]
 [--env 'VAR=VALUE'] 
 [--debug <debug level>][--verbose][--quiet][--help]

=back

flag descriptions:

=over 20

=item B<--module>

String input. RTL top module name of the design.

=item B<--simple-sdc>

String input. Must use this option or --clock_collateral_dir. Path to hand written SDC file.

=item B<--clock-collateral-dir>

String input. Must use this option or --simple-sdc. Directory containing clock collateral release area.  Generation format of SDC expected to be from MCSS flow.

=item B<--tag>

Optional. String input. If provided,  output tcl file will be named: <module>_clocks_<tag>.tcl.fixclocks).

=item B<--env>

Optional. String input. Set env var at start of execution. Can provide more than one --env flag.  Value format is --env VAR=VALUE

=item B<--debug>

Optional. Integer input. Run flow in debug mode. Temporary files are not deleted and additional data is placed in log file only.  Stdout not impacted.

=item B<--verbose>

Optional. No argument. Add info/warnings to STDOUT. If used with --quiet, --quiet takes precedence.

=item B<--quiet>

Optional. No argument. Write message to STDOUT only if fatal occurs. If used with --verbose, --quiet takes precedence.

=item B<--help>

Optional. No argument. This usage message will appear.

=back
=item B<example:>

Run fixclocks.pl on hand written SDC.  Extra verbosity

  fixclocks.pl --module pars3m --simple-sdc pars3m.sdc --verbose


Run fixclocks.pl on MCSS generated clock collateral. No stdout messages except for fatals.

  fixclocks.pl --quiet --debug 2 --module acc --clock_collateral_dir  /nfs/site/disks/dmr2_arc_proj_archive/arc/acc/clock_collateral/CORIOH1A0_H2B_0P5_WW23A


Run fixclocks.pl on hand written SDC with a tagname and all debug level messages with level 2 or less.

  fixclocks.pl --module pars3m --simple-sdc pars3m.sdc --tag test


Select the correct archive area using this command
  find -L /nfs/site/disks/dmr2_arc_proj_archive/arc/acc -name "*_clocks.tcl" -printf '%TY-%Tm-%TdT%TT %p\n' | sort | tail -10

=cut

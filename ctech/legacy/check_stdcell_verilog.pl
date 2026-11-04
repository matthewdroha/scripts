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
use Carp;
use IPC::Open3;
use Excel::Writer::XLSX;


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
our ($opt_verilog_file_list, $opt_ctech_dir_list, $opt_udp, $opt_check_sites);
our ($opt_run_name, @opt_env, $opt_help, $opt_debug, $opt_verbose);
Getopt::Long::Configure("prefix_pattern=(--)");
my $options_ok = GetOptions("help",
                            "run-name=s", => \$opt_run_name,
                            "verilog-file-list=s" => \$opt_verilog_file_list,
                            "ctech-dir-list=s" => \$opt_ctech_dir_list,
                            "udp",
                            "check-sites" => \$opt_check_sites,
                            "env=s@",
                            "debug",
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
my @required_flag_list = ('--verilog-file-list');
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

  # Get verilog file list
  my @verilog_files;
  read_file_to_list($opt_verilog_file_list, \@verilog_files);

  # If udp is specified,  remap to use udp verilog
  if ($opt_udp) {
    set_verilogs_to_udp(\@verilog_files);
  }

  # Validate verilog file list
  quick_check_verilog_files(\@verilog_files); 

  # If specified, get ctech dir list
  my (@ctech_dirs, %v_ctech_data);
  if ($opt_ctech_dir_list) {
    read_file_to_list($opt_ctech_dir_list, \@ctech_dirs);
    # If specified, validate ctech dir list
    load_ctech_sv_files(\@ctech_dirs, \%v_ctech_data);
  }

  # Load verilog files. Track file ordering
  my (%v_cell_data, %v_file_data);
  load_verilog_files(\@verilog_files, \%v_cell_data, \%v_file_data);

  # Test verilog files for redefinition
  my (@error_data);
  test_for_module_redefinitions(\%v_cell_data, \@error_data);

  # Test that primitives have no instances
  #test_for_instances_in_primitive_definitions();

  # Test verilog files for unresolvable modules
  test_for_unresolvable_stdcell_references(\%v_cell_data, \%v_file_data);

  # If specified, test ctech modules
  # Only test capturing error data in xlsx
  test_for_unresolvable_ctech_references(\%v_cell_data, \%v_ctech_data, \@error_data) if scalar %v_ctech_data;

  # If specified, test that verilog files exist at all sites
  if ($opt_check_sites) {
    test_for_verilog_missing_at_sites(\@verilog_files);
  }

  # Write spreadsheet showing dependencies between libraries and ctech modules and libraries
  write_xlsx(\%v_cell_data, \%v_file_data, \%v_ctech_data, \@error_data);

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

sub test_for_verilog_missing_at_sites {
  my $verilog_files_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my %servers;
  $servers{fm}   = q(fmci61915.fm.intel.com);
  $servers{sc}   = q(sccj001007.sc.intel.com);
  $servers{png}  = q(pglc80317a.png.intel.com);
  $servers{iind} = q(iind-login.iind.intel.com);
  $servers{pdx}  = q(plxcjh047.pdx.intel.com);
  $servers{iil}  = q(icsl2173.iil.intel.com);

  foreach my $site (sort keys %servers) {
    $log->info("Checking .v existence site->($site)");
    my $ssh_cmd = qq(/usr/bin/ssh $servers{$site});
    #my (*SSH_IN, *SSH_OUT, *SSH_ERR);
    my $pid = open3(*SSH_IN, *SSH_OUT, 0, $ssh_cmd);
    $log->info_d($ssh_cmd);
    foreach my $infile (@{ $verilog_files_ref }) {
      my $filetest_cmd = qq(/usr/bin/wc $infile);
      $log->info_d($filetest_cmd);
      print SSH_IN qq(${filetest_cmd}\n);
      #foreach my $line (@outlines) {
      #  $log->info_d($line);
      #}
    }
    close(SSH_IN);
    my @outlines = <SSH_OUT>;
    close(SSH_OUT);
    foreach my $outline (@outlines) {
      $log->info_d("SSH_OUT $outline");
      if ($outline =~ /No such file or directory/) {
        $log->error("Missing .v found during site check site->($site) file->($outline)");
      }
    }
    waitpid($pid, 0);
    if ($?) {
      $log->info_d("ssh exited with wait status of $?");
    }
  }
  $log->flowname($parent_flow);
  return;
}


sub set_verilogs_to_udp {
  my $verilog_files_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my @udp_patterns = qw(primitives_pwr_udp_fbn primitives_pwr_udp pwr_primitive_udp core_pwr_udp_fbn core_udp core_pwr_udp);
  # another possibility is d04_pwr_nn_core_udp.v, skip for now

  foreach my $infile (@{ $verilog_files_ref }) {
    my($filename, $path, $suffix) = fileparse($infile);

    foreach my $pattern (@udp_patterns) {
      my $tempname = $filename;
      $tempname =~ s/((primitive(s?)_verilog)|core)\.v$/${pattern}.v/;
      my $fullpath = qq(${path}/${tempname});
      if (-f $fullpath) {
        $log->info("Remapping .v file to udp version before->(${infile}) after->(${fullpath})");
        $infile = $fullpath;
      }
    }
  }
  $log->flowname($parent_flow);
  return;
}


sub quick_check_verilog_files {
  my $verilog_files_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  foreach my $infile (@{ $verilog_files_ref }) {
    my $basefilename = basename($infile); 
    my $infileh = new IO::File;
    $infileh->open($infile) or die $log->fatal_l("Could not open file for reading: $infile");
    my $definition_count = 0;
    while (<$infileh>) {
      if (/^\s*(module|\`define|primitive)\s+\S+\s*\(/) {
        $definition_count++;
      }
    }
    $infileh->close;
    $log->info("File->(${basefilename}) Definitions->(${definition_count}) Fullpath->(${infile})");
  }

  $log->flowname($parent_flow);
  return;
}


sub load_ctech_sv_files {
  my $ctech_dirs_ref = shift;
  my $v_ctech_data_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  if (scalar @{ $ctech_dirs_ref }) {
    my $dirnum = 1;
    foreach my $indir (@{ $ctech_dirs_ref }) {
      my $module_count = 0;
      my $indirh = new IO::Dir;
      $indirh->open($indir) or die $log->fatal_l("Could not open directory for reading: $indir");
      my @files = grep /\.sv$/, $indirh->read;

      foreach my $file (@files) {
        my $sv_file = qq(${indir}/${file});
        my $sv_fileh = new IO::File;
        $sv_fileh->open($sv_file) or die $log->fatal_l("Could not open sv file for reading: $sv_file");
        my $ctech_module = q();
        my $in_module_block;
        while (<$sv_fileh>) {
          if (/^\s*\/\//) { next };
          if (/^\s*module\s+(\S+)/) {
            $in_module_block = 1;
            $ctech_module = $1;
            $ctech_module =~ s/\(//;
            $ctech_module .= qq(.dir${dirnum});
            $$v_ctech_data_ref{$ctech_module}{'DIR'} = $indir;
          }
          elsif (/endmodule/) {
            $in_module_block = 0;
            my $instance_master_count;
            if (exists $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'}) {
              $instance_master_count = scalar keys %{ $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'} };
            } else {
              $instance_master_count = 0;
            }
            $log->info_d("Ctech module loaded: module->($ctech_module) instance_master_count->($instance_master_count)");
            $module_count++;
            $ctech_module = q();
          }
          elsif (($in_module_block) and (/^\s*(\S+)\s+\S+(\s*\[\S+\])?\s*\(/)) {
            my $instance_master = $1;
            $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'}{$instance_master}++;
          }
        }
      }
      $log->info("Ctech modules found count->($module_count) dir->($dirnum) dir->($indir)");
      $dirnum++;
    }
  } else {
    $log->warn("No ctech directories were provided in ctech_dirs list.");
  }

  $log->flowname($parent_flow);
  return;
}


sub load_verilog_files {
  my $verilog_files_ref = shift;
  my $v_cell_data_ref = shift;
  my $v_file_data_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my $infile_number = 0;
  foreach my $infile (@{ $verilog_files_ref }) {
    my $basefilename = basename($infile); 
    my $infileh = new IO::File;
    $infileh->open($infile) or die $log->fatal_l("Could not open file for reading: $infile");
    my $in_module_block = 0;
    my ($cell, $type);
    while (<$infileh>) {
      if (/^\s*(module|\`define|primitive)\s+(\S+)\s*\(/) {
        $in_module_block = 1;
        $type = $1;
        $cell = $2;
        if (exists $$v_file_data_ref{$basefilename}{$cell}) {
          next;
        }
        push @{ $$v_cell_data_ref{$cell} }, $basefilename;
        $$v_file_data_ref{$basefilename}{$cell}{'CELLNAME'} = $cell;
        $$v_file_data_ref{$basefilename}{$cell}{'TYPE'} = $type;
        $$v_file_data_ref{$basefilename}{$cell}{'FULLPATHFILE'} = $infile;
        $log->info_d("Found cell: file->($basefilename) cell->($cell) type->($type)");
      }
      elsif (/endmodule|endprimitive/) {
        $in_module_block = 0;
      }
      elsif (($in_module_block) and ($type eq 'module')) {
        if (/^\s*\`(\S+)\(/) {
          my $instance_master = $1;
          $$v_file_data_ref{$basefilename}{$cell}{'INSTANCEMASTERS'}{$instance_master} = 1;
          $log->info_d("Found primitive instance parent->($cell) instance->($instance_master)");
        }
      }
    }
    $infileh->close;
  }
  $log->flowname($parent_flow);
  return;
}


sub test_for_module_redefinitions {
  my $v_cell_data_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);

  my $error_count = 0;
  foreach my $cell (sort keys %{ $v_cell_data_ref }) {
    if (scalar @{ $$v_cell_data_ref{$cell} } > 1) {
      my $v_files = join (';', @{ $$v_cell_data_ref{$cell} });
      $log->error("Cell has multiple definitions: cell->($cell) v_files->($v_files)");
      $error_count++;
    }
  }

  $log->info("Test results: test->(test_for_redefinitions) errors->($error_count)");
  $log->flowname($parent_flow);
  return;
}


sub test_for_unresolvable_stdcell_references {
 my $v_cell_data_ref = shift;
 my $v_file_data_ref = shift;

 my $subname = (caller(0))[3];
 my $parent_flow = $log->flowname($subname);

 my $error_count = 0;
 foreach my $file (keys %{ $v_file_data_ref }) {
   foreach my $cell (sort keys %{ $$v_file_data_ref{$file} }) {
     if (exists $$v_file_data_ref{$file}{$cell}{'INSTANCEMASTERS'}) {
       foreach my $instance_master (keys %{ $$v_file_data_ref{$file}{$cell}{'INSTANCEMASTERS'} }) {
         unless (exists $$v_cell_data_ref{$instance_master}) {
           $log->error("Unresolvable cell instance: file->($file) parent->($cell) child->($instance_master)");
           $error_count++;
         }
       }
     }
   }
 }
 $log->info("Test results: test->(test_for_unresolvable_stdcell_references) errors->($error_count)");
 $log->flowname($parent_flow);
 return;
}

sub test_for_unresolvable_ctech_references {
 my $v_cell_data_ref = shift;
 my $v_ctech_data_ref = shift;
 my $error_data_ref = shift;

 my $subname = (caller(0))[3];
 my $parent_flow = $log->flowname($subname);

 my $error_count = 0;
 my $ctech_dir;
 foreach my $ctech_module (sort keys %{ $v_ctech_data_ref }) {
   next unless exists $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'};
   $ctech_dir = $$v_ctech_data_ref{$ctech_module}{'DIR'};
   foreach my $instance_master (keys %{ $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'} }) {
     unless (exists $$v_cell_data_ref{$instance_master}) {
       if ($instance_master =~ /^ctech_lib/) { next };  # mapped ctech
       $log->error("Unresolvable ctech instance master: ctech_module->($ctech_module) instance_master->($instance_master) dir->($ctech_dir)");
       push @{ $error_data_ref }, join(',', $subname, $ctech_module, $instance_master, $ctech_dir);
       $error_count++;
     }
   }
 }
 push @{ $error_data_ref }, join(',', $subname, 'No Errors', '', '') unless ($error_count);

 $log->info("Test results: test->(test_for_unresolvable_ctech_references) errors->($error_count)");
 $log->flowname($parent_flow);
 return;
}



sub write_xlsx {
  my $v_cell_data_ref = shift;
  my $v_file_data_ref = shift;
  my $v_ctech_data_ref = shift;
  my $error_data_ref = shift;

  my $subname = (caller(0))[3];
  my $parent_flow = $log->flowname($subname);
  my $xlsx_file = qq(${basefile}.xlsx);

  my $workbook = Excel::Writer::XLSX->new($xlsx_file);
  $log->info("Excel workbook created: $xlsx_file");


  # stdcell worksheet
  my @dataset;
  my %vfilepath;
  foreach my $file (sort keys %{ $v_file_data_ref }) {
    foreach my $cell (sort keys %{ $$v_file_data_ref{$file} }) {
      my $fullpathfile = $$v_file_data_ref{$file}{$cell}{'FULLPATHFILE'}; 
      $vfilepath{$file} = $fullpathfile;
      if (exists $$v_file_data_ref{$file}{$cell}{'INSTANCEMASTERS'}) {
        foreach my $instance_master (sort keys %{ $$v_file_data_ref{$file}{$cell}{'INSTANCEMASTERS'} }) {
          my $v_files;
          if (exists $$v_cell_data_ref{$instance_master}) {
            $v_files = join (';', @{ $$v_cell_data_ref{$instance_master} });
          } else {
            # can't find home library for cell instance
            $v_files = q(MISSING);
          }
          push @dataset, join(',', $cell, $file, $instance_master, $v_files, $fullpathfile);
        }
      # cell definition has no dependencies
      } else {
        push @dataset, join(',', $cell, $file, 'CONTAINS_NO_INSTANCES', 'CONTAINS_NO_INSTANCES', $fullpathfile);
      }
    }
  }
  my $cellsheet = $workbook->add_worksheet('stdcells');
  my $rownum = 1;
  my $colnum = 0;
  foreach my $datarow (@dataset) {
    $colnum = 0;
    my @rowvalues = split(/,/, $datarow);
    foreach my $celldata (@rowvalues) {
      $cellsheet->write_string($rownum, $colnum, $celldata);
      $colnum++;
    }
    $rownum++;
  }
  $cellsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'parent cell' },
                            { header => 'parent library' },
                            { header => 'instance master' },
                            { header => 'instance master library' },
                            { header => 'fullpathfile'},
                          ]
                        }
  );
  my $logstring = sprintf("Data written to xlsx: worksheet->(%s) rowcount->(%s)", $cellsheet->get_name, $rownum-1);
  $log->info($logstring);


  # ctech worksheet
  @dataset = ();
  my %reflibs_reduced;
  foreach my $ctech_module (sort keys %{ $v_ctech_data_ref }) {
    my $ctech_dir = $$v_ctech_data_ref{$ctech_module}{'DIR'};
    my $v_files;
    if (exists $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'}) {
      foreach my $instance_master (sort keys %{ $$v_ctech_data_ref{$ctech_module}{'INSTANCEMASTERS'} }) {
        if (exists $$v_cell_data_ref{$instance_master}) {
          $v_files = join (';', @{ $$v_cell_data_ref{$instance_master} });
          foreach my $v_file (@{ $$v_cell_data_ref{$instance_master} }) {
            $reflibs_reduced{$v_file} = 1;
          }
        }
        elsif ($instance_master =~ /^ctech_lib/) {
          $v_files = q(CTECH_MAP);
        } else {
          # can't find home library for cell instance
          $v_files = q(MISSING);
        }
        push @dataset, join(',', $ctech_module, $instance_master, $v_files, $ctech_dir);
      }
    } else {
       push @dataset, join(',', $ctech_module, 'CONTAINS_NO_INSTANCES', 'CONTAINS_NO_INSTANCES', 'CONTAINS_NO_INSTANCES');
    }
  }
  my $ctechsheet = $workbook->add_worksheet('ctech');
  $rownum = 1;
  $colnum = 0;
  foreach my $datarow (@dataset) {
    $colnum = 0;
    my @rowvalues = split(/,/, $datarow);
    foreach my $celldata (@rowvalues) {
      $ctechsheet->write_string($rownum, $colnum, $celldata);
      $colnum++;
    }
    $rownum++;
  }
  $ctechsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'ctech module' },
                            { header => 'instance master' },
                            { header => 'instance master library' },
                            { header => 'ctech dir' },
                          ]
                        }
  );
  $logstring = sprintf("Data written to xlsx: worksheet->(%s) rowcount->(%s)", $ctechsheet->get_name, $rownum-1);
  $log->info($logstring);


  # referenced libraries worksheet
  @dataset = ();
  foreach my $v_file (sort keys %reflibs_reduced) {
    push @dataset, join(',', $v_file, $vfilepath{$v_file});
  }
  my $referencedlibsheet = $workbook->add_worksheet('referenced libraries');
  $rownum = 1;
  $colnum = 0;
  foreach my $datarow (@dataset) {
    $colnum = 0;
    my @rowvalues = split(/,/, $datarow);
    foreach my $celldata (@rowvalues) {
      $referencedlibsheet->write_string($rownum, $colnum, $celldata);
      $colnum++;
    }
    $rownum++;
  }
  $referencedlibsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'library' },
                            { header => 'fullpath' },
                          ]
                        }
  );
  $logstring = sprintf("Data written to xlsx: worksheet->(%s) rowcount->(%s)", $referencedlibsheet->get_name, $rownum-1);
  $log->info($logstring);


  # error worksheet
  my $errorsheet = $workbook->add_worksheet('error');
  my $actual_errors = 0;
  $rownum = 1;
  $colnum = 0;
  foreach my $datarow (@{ $error_data_ref }) {
    $colnum = 0;
    if ($datarow !~ /No Errors/) {
      $actual_errors++;
    }
    my @rowvalues = split(/,/, $datarow);
    foreach my $celldata (@rowvalues) {
      $errorsheet->write_string($rownum, $colnum, $celldata);
      $colnum++;
    }
    $rownum++;
  }
  $errorsheet->add_table(0, 0, $rownum-1, $colnum-1,
                        {
                          columns => [
                            { header => 'test' },
                            { header => 'ctech module' },
                            { header => 'instance master' },
                            { header => 'ctech dir' },
                          ]
                        }
  );
  $logstring = sprintf("Data written to xlsx: worksheet->(%s) rowcount->(%s) errorcount->(%s)", $errorsheet->get_name, $rownum-1, $actual_errors);
  $log->info($logstring);

  $cellsheet->activate;
  $workbook->close;
  FileOp($log, 'copy', $xlsx_file, qq(${HOME}/${xlsx_file}));
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


sub FileOp {
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
# 4 severity types: Info, Warning, Error, Fatal.  The last is for issues that should stop flow execution
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

B<check_stdcell_verilog.pl> Reads an ordered list of .v files and checks that all cell references are resolvable in the order called. An optional list of directories containing ctech .sv files can be provided also.

=cut

# Prepare the usage string.

=head1 SYNOPSIS

=over 25

=item check_stdcell_verilog.pl

 --verilog-file-list <file containing full paths to .v files seperated by whitespace>
 [--ctech-dir-list] <file containing paths containing ctech .sv files>
 [--udp] [--check-sites] [--run-name]
 [--env 'VAR=VALUE'] 
 [--debug][--verbose] [--help]

=back

flag descriptions:

=over 20

=item B<--verilog-file-list>

File containing full paths to .v files seperated by whitespace.

=item B<--ctech-dir-list>

File containing paths containing ctech .sv files.

=item B<--udp>

Optional. Use udp versions of the verilogs.

=item B<--check-sites>

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

  check_stdcell_verilog.pl --verilog-file-list p1274d13.ec0pp60.list 
  check_stdcell_verilog.pl --verilog-file-list p1274d13.ec0pp60.list --ctech-dir-list p1274d13.ctech.ec0pp60.list
  check_stdcell_verilog.pl --verilog-file-list p1274d13.ec0pp60.list --ctech-dir-list p1274d13.ctech.ec0pp60.list --udp --check-sites -verbose --run-name p1274d13.ec0pp60


Example contents of p1274d13.ec0pp60.list

  /p/hdk/cad/stdcells/ec0pp60/19ww06.5_ec0pp60_n.1.all/v/primitives/ec0pp60_primitives_verilog.v
  /p/hdk/cad/stdcells/ec0pp60/19ww06.5_ec0pp60_n.1.all/v/bn/ec0pp60_bn_core.v
  /p/hdk/cad/stdcells/ec0pp60/19ww06.5_ec0pp60_n.1.all/v/cn/ec0pp60_cn_core.v
  /p/hdk/cad/stdcells/ec0pp60hs/19ww06.5_ec0pp60hs_n.1.all/v/primitives/ec0pp60hs_primitives_verilog.v
  /p/hdk/cad/stdcells/ec0pp60hs/19ww06.5_ec0pp60hs_n.1.all/v/bn/ec0pp60hs_bn_core.v
  /p/hdk/cad/stdcells/ec0pp60hs/19ww06.5_ec0pp60hs_n.1.all/v/cn/ec0pp60hs_cn_core.v


Example contents of p1274d13.ctech.ec0pp60.list

  /nfs/fm/disks/w.mroha.102/c3v19ww09a_hdk157_sip_sbx/source/p1274/ec0pp60/cn
  /nfs/fm/disks/w.mroha.102/ctech_exp_c3v19ww09a_hdk157_p1274d13_sip_sbx/source/p1274/ec0pp60/cn
  /nfs/fm/disks/w.mroha.102/c3v19ww09a_hdk157_sip_sbx/source/p1274/ec0pp60/bn
  /nfs/fm/disks/w.mroha.102/ctech_exp_c3v19ww09a_hdk157_p1274d13_sip_sbx/source/p1274/ec0pp60/bn


=back

=cut

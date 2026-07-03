#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# $Id: mkfeed.pl,v 1.4 2006/11/10 21:49:29 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: mkfeed.pl,v 1.4 2006/11/10 21:49:29 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: mkfeed.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Reads whitespace separated fields from STDIN and generates a feeder file for nbfeed

=cut

BEGIN {
  our %mig_utils;
  $mig_utils{'iil'} = "/nfs/iil/disks/home10/mroha/pnr/mig";
  $mig_utils{'fm'} = "/usr/users/home2/mroha/pnr/mig";
  push @INC, values %mig_utils;
}
our %mig_utils;

use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';

use DAStdLib;


# Extract script name
my $EXE_NAME;
my $EXE_PREFIX;
($EXE_NAME, $EXE_PREFIX) = &GetExeName($0);


# Get the script start time
my ($start_time, $start_date) = &GetDate();

# Set defaults
my $maxjobs_default = 50;
my $maxwait_default = 6;
my $pool_default = 'MPG_IALcs';
my $qslot_default = 500;


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $EXE_NAME -cmd \"cmd\" -task <nbfeed task name>
                  [-P <nbq pool>] [-Q <nbq qslot>]
                  [-C <nbq class>] [-work <work directory>]
                  [-maxwait <max num waiting jobs>]
                  [-maxjobs <max num wait+run jobs>]
                  [-serial <num source files>]
                  [-help] [-debug] [-verbose]

flag descriptions:

-P                NBQ pool name. Default is $pool_default.

-Q                NBQ slot name. Default is $qslot_default.

-task             Arbitrary task name for feeder job

-cmd              Single quoted command line. In the command line, {0}, {1}, etc
                  will be replaced with field0, field1, etc from STDIN, whitespace separated

-maxwait          Maximum number of jobs in wait queue. Default is $maxwait_default.

-maxjobs          Maximum number of jobs in wait queue. Default is $maxjobs_default.

-work             Work area where nbfeed logs will be written. Default is \$PWD.

-C                NBQ class name. If not specified environment default is used.

-serial           Instead of feeder file, split the commands across the argument number
                  of source-able command files.

-debug            This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

-verbose          Will add status messages to STDOUT.

-help             This usage message will appear. 


example: cat infile | $EXE_NAME -P linux_exp -Q 5 -task pshift -cmd "fullpath/runfub.pl -cell {0} -process {1}"

Contents of infile:

cell1 1264


Files that result from this run:

<task>.feed

EOD


my $options_ok = 1;

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "-E- $EXE_NAME: No command line parameters. Use -help to list input flags.\n";
}


# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
our ($opt_debug, $opt_verbose, $opt_help);
our ($opt_P, $opt_Q, $opt_C, $opt_task, $opt_cmd, $opt_work, $opt_maxwait, $opt_maxjobs, $opt_serial);
$options_ok = &GetOptions("help",
			  "debug",
			  "verbose",
			  "P=s",
			  "Q=i",
			  "C=s",
			  "task=s",
			  "work=s",
			  "maxwait=i",
			  "maxjobs=i",
			  "serial=i",
			  "cmd=s");


# Check options
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $EXE_NAME: One or more command line parameters incorrect. Use -help switch.\n";
}

&Usage("\n-I- $EXE_NAME: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('-task', '-cmd');
my @argv_snapshot = @MAILARGV;
&CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);



##### Main Program #####

# Capture initial environment variables
our ($HOME);
my @env_list = ('HOME');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    &Env::import($env_var);
  } else {
    die "-F- $EXE_NAME: Something is wrong with your UE session:", "\$$env_var is not defined.";
  }
}



our ($BASEFILE, $MAINLOG, $CWD);
$CWD = cwd;
$BASEFILE = ${EXE_PREFIX};
$MAINLOG = LogFile->new("${CWD}/${BASEFILE}.log");
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



my $workdir;
if ($opt_work) {
  $workdir = abs_path($opt_work);
} else {
  $workdir = $CWD;
}
$workdir =~ s/^\/a//;

if ($opt_debug) {};

unless (defined $opt_P) {
  $opt_P = $pool_default;
}

unless (defined $opt_Q) {
  $opt_Q = $qslot_default;
}

unless (defined $opt_maxwait) {
  $opt_maxwait = $maxwait_default;
}

unless (defined $opt_maxjobs) {
  $opt_maxjobs = $maxjobs_default;
}

my $nbcmd = 'nbq';
if ($opt_C) {
  $nbcmd .= " -C $opt_C";
}


my @records;
while (<>) {
  chomp;
  push (@records, $_);
}


my @command_list;
if (scalar @records) {
  foreach my $line (@records) {
    my $command = $opt_cmd;
    my @values = split(/\s+/, $line);
    for (my $i=0; $i<=$#values; $i++) {
      $command =~ s/\{${i}\}/$values[$i]/g;
    }
    push @command_list, $command;
  }
} else {
  push @command_list, $opt_cmd;
}

if ((defined $opt_serial) and ($opt_serial =~ /^\d+$/)) {
  $MAINLOG->info("-serial $opt_serial option detected. $opt_serial source files will be created");
  my $commands_per_file = int ((scalar @command_list)/$opt_serial);
  my $commands_mod = int ((scalar @command_list)%$opt_serial);
  my $file_number = 0;
  while (scalar @command_list) {
    my $command_count = $commands_per_file;
    if ($commands_mod) {
      $command_count++;
      $commands_mod--;
    }
    my $outfile = "${opt_task}.sourcefile${file_number}";
    open (OUTFILE, ">$outfile") or die $MAINLOG->fatalq("Could not open file for writing: $outfile");
    my $orig_command_count = $command_count;
    while ($command_count) {
      print OUTFILE shift(@command_list),"\n";
      $command_count--;
    }
    close (OUTFILE);
    $MAINLOG->infop("Source file generated with $orig_command_count commands: $outfile"); 
    $file_number++;
  }
} else {
  my $feedfile = "${opt_task}.feed";
  
  open (FEEDFILE, ">$feedfile") or die $MAINLOG->fatalq("Could not open file for writing: $feedfile");
  select FEEDFILE;
  
  print "# $EXE_NAME autogenerated feeder file for nbfeed\n";
  print "conf\n{\n";
  print "submit-frequency 60\n";
  print "update-frequency 60\n";
  print "max-waiting $opt_maxwait\n";
  print "}\n\n";
  
  print "task $opt_task\n{\n";
  print "pool $opt_P\n";
  print "qslot $opt_Q\n";
  print "work-area $workdir\n";
  print "}\n\n";
  
  print "jobs\n{\n";
  foreach my $command (@command_list) {
    print "$nbcmd $command\n";
  }
  print "}\n";
  
  select (STDOUT);
  close (FEEDFILE);
  $MAINLOG->infop("To launch feeder job: nbfeed --feeder-file $feedfile --feeder-name $opt_task");
}

$MAINLOG->newline;
&DeleteFiles(@TMPFILES) unless $opt_debug;
my ($stop_time, $stop_date) = &GetDate();
$MAINLOG->info("Script completion date: $stop_date");
$MAINLOG->info("$EXE_NAME run complete");

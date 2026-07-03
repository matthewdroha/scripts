#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: mkfeed.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: mkfeed.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: mkfeed.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: 

Reads newline separated fields from STDIN and generates a feeder file for nbfeeder

=cut

BEGIN {
  use IO::Dir;
  my $homeproject = 'ivb';
  my %homedir;
  $homedir{'iil'} = "/nfs/iil/disks/home10/mroha";
  $homedir{'sc'} = "/nfs/user/home/mroha";
  $homedir{'fm'} = "/usr/users/home2/mroha";
  if (defined $ENV{'EC_SITE'}) {
    my $code_dir = "$homedir{$ENV{'EC_SITE'}}/${homeproject}";
    my $dir = IO::Dir->new;
    $dir->open($code_dir) or die "Code directory could not be opened: $code_dir";
    my @dirs = grep /\w+/, $dir->read();
    if (-d "$ENV{'HOME'}/ovrd") {
      push @INC, "$ENV{'HOME'}/ovrd";
    }
    foreach my $item (@dirs) {
      if (-d "${code_dir}/${item}") {
        push @INC, "${code_dir}/${item}";
      }
    }
  } else {
    die "Environment var EC_SITE is not defined. Please make your environment eclogin compl
iant\n";
  }
}


use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use IO::File;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Cwd 'abs_path';
use DAStd;
use Logfile;
use Netbatch;


my $code_dir = GetCodeDir('ivb');
my $exe_name;
my $exe_prefix;
($exe_name, $exe_prefix) = GetExeName($0);

# Get the script start time
my ($start_time, $start_date) = GetDate();

# Get the site
our $site = GetSite();


# Defaults (included in --help)
# Set defaults
my $maxjobs_default = 50;
my $maxwait_default = 6;
my $queue_default = 'Express_MPG_IALcs';
my $class_default = 'SUSE_64';
my $qslot_default = 500;


# Prepare the usage string.
my @usage;
push(@usage,<<"EOD");
usage:  $exe_name --cmd \"cmd\" --task <nbfeeder base task name>
                  [--queue <nb queue or pool>] [--qslot <nb qslot>]
                  [--class <nb class>] [--work <work directory>]
                  [--maxwait <max num waiting jobs>]
                  [--maxjobs <max num wait+run jobs>]
                  [--serial <num source files>]
                  [--multitask <num tasks>]
                  [--help] [--debug] [--verbose] [--env]

flag descriptions:

--cmd             Single quoted command line. In the command line, {0}, {1}, etc
                  will be replaced with field0, field1, etc from STDIN, whitespace separated

--task            Netbatch task name

--queue           Netbatch queue name. Default is $queue_default

--qslot           Netbatch qslot. Default is $qslot_default

--class           Netbatch class. Default is $class_default

--maxwait         Maximum number of jobs in wait queue. Default is $maxwait_default.

--maxjobs         Maximum number of jobs in wait queue. Default is $maxjobs_default.

--work            Work area where nbfeed logs will be written. Default is \$PWD.

--serial          Instead of feeder file, split the commands across the <number>
                  of source-able command files.

--multitask       Break task file into <number> set of tasks (will enable use
                  of multiple queues)

--debug           This switch is available for debugging purposes.
		  -debug will preserve all temporary files.

--verbose         Will add status messages to STDOUT.

--env             Set or reset environment variable during execution
                  --env MYSITE=FM

--help            This usage message will appear. 


example: cat infile | $exe_name -P linux_exp -Q 5 -task pshift -cmd "fullpath/runfub.pl -cell {0} -process {1}"

Contents of infile:

cell1 1264


Files that result from this run:

<task>.feed

EOD


# Parse command line parameters, check if input files exist, etc...
unless (scalar @ARGV) {
  die "-E- $exe_name: No command line parameters. Use --help to list input flags.\n";
}
# Get command line options. GetOptions returns $opt_<option>
our ($command_line, @mailargv);
@mailargv = @ARGV;  # Will be used to check for required command line parameters
$command_line = join (" ", @mailargv);
our ($opt_debug, $opt_verbose, $opt_help, @opt_env);
our ($opt_cmd, $opt_task, $opt_queue, $opt_qslot, $opt_class, $opt_maxwait, $opt_maxjobs, $opt_work);
our ($opt_serial, $opt_multitask);
my $options_ok = GetOptions("help",
			    "debug",
			    "verbose",
			    "cmd=s",
			    "task=s",
			    "queue=s",
			    "qslot=i",
			    "class=s",,
			    "maxwait=i",
			    "maxjobs=i",
			    "work=s",
			    "serial=i",
			    "multitask=i",
			    "env=s@");


# Check options 
if ((!($options_ok)) || (@ARGV != 0)) {
  die "-F- $exe_name: One or more command line parameters incorrect. Use --help switch.\n";
}
Usage("\n-I- $exe_name: Help flag specified. Printing usage information.\n",@usage) if $opt_help; 

my @required_flag_list = ('--task', '--cmd');
my @argv_snapshot = @mailargv;
CheckForMissingFlags(\@argv_snapshot, \@required_flag_list);



##### Main Program #####
# Capture initial environment variables
our ($HOME, $USER);
my @env_list = ('HOME', 'USER');

foreach my $env_var (@env_list) {
  if (exists $ENV{$env_var}) {
    Env::import($env_var);
  } else {
    die "-F- $exe_name: Something is wrong with your UE session:", "\$$env_var is not defined
ed.";
  }
}


our ($basefile, $logfh);
$basefile = "${exe_prefix}";
$logfh = Logfile->new("${basefile}.log");
$logfh->flowname($exe_name);
$logfh->verbose($opt_verbose);
$logfh->debug($opt_debug);

my $machine_info = `uname -a`;
chomp $machine_info;
$logfh->info("Script command: $exe_name $command_line");
$logfh->info("Script start date: $start_date");
$logfh->info("Machine Type: $machine_info");

# Global temporary files list. Any file added to this list will be deleted after
# execution is complete, unless --debug is used.
our @tmplist = ();

# Set any command line env vars
if (@opt_env) {
  foreach my $setting (@opt_env) {
    if ($setting =~ /^\s*(\S+)\=(.+)$/) {
      my $envvar = $1;
      my $value = $2;
      chomp $value;
      $ENV{$envvar} = $value;
      $logfh->infoq("-env detected. ENV VAR set: \$$envvar = $ENV{$envvar}");
    } else {
      die $logfh->fatalq("Invalid value for switch -env: $setting");
    }
  }
}


my $workdir;
if ($opt_work) {
  $workdir = abs_path($opt_work);
} else {
  $workdir = cwd();
}
$workdir =~ s/^\/a//;

unless (defined $opt_queue) {
  $opt_queue = $queue_default;
}
unless (defined $opt_qslot) {
  $opt_qslot = $qslot_default;
}
unless (defined $opt_maxwait) {
  $opt_maxwait = $maxwait_default;
}
unless (defined $opt_maxjobs) {
  $opt_maxjobs = $maxjobs_default;
}
unless (defined $opt_class) {
  $opt_class = $class_default;
}


my $nbcmd = 'nbjob run';

my @records;
while (<>) {
  chomp;
  push (@records, $_);
}


my @job_list;
if (scalar @records) {
  foreach my $line (@records) {
    my $job = $opt_cmd;
    my @values = split(/\s+/, $line);
    for (my $i=0; $i<=$#values; $i++) {
      $job =~ s/\{${i}\}/$values[$i]/g;
    }
    push @job_list, $job;
  }
} else {
  push @job_list, $opt_cmd;
}

my @working_job_list = @job_list;
if ((defined $opt_serial) and ($opt_serial > 0)) {
  $logfh->info("--serial $opt_serial option detected. $opt_serial source files will be created");
  my $jobs_per_file = int ((scalar @job_list)/$opt_serial);
  my $jobs_mod = int ((scalar @job_list)%$opt_serial);
  my $file_number = 0;
  while (scalar @working_job_list) {
    my $job_count = $jobs_per_file;
    if ($jobs_mod) {
      $job_count++;
      $jobs_mod--;
    }
    my $sourcefile = "${opt_task}.sourcefile${file_number}";
    my $sourcefilefh = IO::File->new;
    $sourcefilefh->open(">$sourcefile") or die $logfh->fatalq("Could not open file for writing: $sourcefile");
    my $orig_job_count = $job_count;
    while ($job_count) {
      $sourcefilefh->printf("%s\n", shift(@working_job_list));
      $job_count--;
    }
    $sourcefilefh->close;
    $logfh->infop("Source file generated with $orig_job_count commands: $sourcefile"); 
    $file_number++;
  }
} 


my $nbmgr = Netbatch->new($logfh, $opt_task);
my $persistency_dir = "${workdir}/persistency";
DeleteDirTrees($persistency_dir);

@working_job_list = @job_list;
if ((defined $opt_multitask) and ($opt_multitask > 0)) {
  $logfh->info("--multitask $opt_multitask option detected. The taskfile will be sectioned into $opt_multitask tasks.");
  my $jobs_per_task = int ((scalar @job_list)/$opt_multitask);
  my $jobs_mod = int ((scalar @job_list)%$opt_multitask);
  my $task_number = 0;
  while (scalar @working_job_list) {
    my $job_count = $jobs_per_task;
    if ($jobs_mod) {
      $job_count++;
      $jobs_mod--;
    }
    my $taskname = "${opt_task}${task_number}";
    while ($job_count) {
      $nbmgr->addjobtotask($taskname, shift(@working_job_list));
      $job_count--;
    }
    $nbmgr->taskworkarea($taskname, $persistency_dir);
    $nbmgr->tasknbqueue($taskname, $opt_queue);
    $nbmgr->tasknbqslot($taskname, $opt_qslot);
    $nbmgr->tasknbclass($taskname, $opt_class);
    $nbmgr->taskonjobfinish($taskname, "NBErr:Requeue(2)");
    $nbmgr->taskhunglimits($taskname, "10m:20m");
    $nbmgr->taskmaxwaiting($taskname, $opt_maxwait);
    $nbmgr->taskmaxjobs($taskname, $opt_maxjobs);
    $task_number++;
  }
} else {
  my $taskname = $opt_task;
  foreach my $job (@job_list) {
    $nbmgr->addjobtotask($taskname, $job);
  }
  $nbmgr->taskworkarea($taskname, $persistency_dir);
  $nbmgr->tasknbqueue($taskname, $opt_queue);
  $nbmgr->tasknbqslot($taskname, $opt_qslot);
  $nbmgr->tasknbclass($taskname, $opt_class);
  $nbmgr->taskonjobfinish($taskname, "NBErr:Requeue(2)");
  $nbmgr->taskhunglimits($taskname, "10m:20m");
  $nbmgr->taskmaxwaiting($taskname, $opt_maxwait);
  $nbmgr->taskmaxjobs($taskname, $opt_maxjobs);
}

my $taskfile = "${opt_task}.taskfile";
$nbmgr->writetaskfile($taskfile);
$logfh->infop("To launch feeder job: nbfeeder start --task $taskfile --terminate-on-finish --block --work-area $workdir");

$logfh->newline;
DeleteFilesAndDirTrees(@tmplist) unless $opt_debug;
my ($stop_time, $stop_date) = GetDate();
$logfh->info("Script completion date: $stop_date");
$logfh->info("$exe_name run complete");

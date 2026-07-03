# $Id: Netbatch.pm,v 1.1 2014/09/11 08:26:52 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: Netbatch.pm,v 1.1 2014/09/11 08:26:52 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: Netbatch.pm
Packages: Netbatch objects
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: Object for managing interface to 7.3.2 compatable
                        netbatch commands
=cut


package Netbatch;

use strict;
use warnings;
use English;
use IO::File;
use Cwd;
use Carp;
use Switch;
use DAStd;

our $default_taskfile = getcwd() . '/feeder.file';
our $nbpath = '/usr/intel/pkgs/netbatch/7.3.2_0200_04';

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $logfh;
  my $name;
  if ((@_) and (scalar(@_) == 2)) {
    $logfh = shift;
    $name = shift;
  } else {
    croak "-E- Netbatch.pm: Two arguments required for new netbatch object (Logfile object, netbatch name)\n";
  }
  my $self = {
    LOGHANDLE      => $logfh,
    NAME           => $name,
    WORKAREA       => undef,
    NBCLASS        => undef,
    NBQUEUE        => undef,
    NBQSLOT        => undef,
    MAXJOBS        => undef,
    MAXWAITING     => undef,
    TASKREFRESH    => undef,
    TASKS          => undef,
    TASKFILE       => undef,
    UPDATEFREQ     => undef,
    TERMONFINISH   => 1,
    BLOCK          => 1,
  };

  bless ($self, $class);
  return $self;
}


sub workarea {
  my $self = shift;
  if (@_) {
    $self->{WORKAREA} = shift;
  }
  return $self->{WORKAREA};
}


sub nbclass {
  my $self = shift;
  if (@_) {
    $self->{NBCLASS} = shift;
  }
  return $self->{NBCLASS};
}


sub nbqueue {
  my $self = shift;
  if (@_) {
    $self->{NBQUEUE} = shift;
  }
  return $self->{NBQUEUE};
}


sub nbqslot {
  my $self = shift;
  if (@_) {
    $self->{NBQSLOT} = shift;
  }
  return $self->{NBQSLOT};
}


sub maxwaiting {
  my $self = shift;
  if (@_) {
    $self->{MAXWAITING} = shift;
  }
  return $self->{MAXWAITING};
}


sub maxjobs {
  my $self = shift;
  if (@_) {
    $self->{MAXJOBS} = shift;
  }
  return $self->{MAXJOBS};
}


sub taskrefresh {
  my $self = shift;
  if (@_) {
    $self->{TASKREFRESH} = shift;
  }
  return $self->{TASKREFRESH};
}


sub taskfile {
  my $self = shift;
  if (@_) {
    $self->{TASKFILE} = shift;
  }
  return $self->{TASKFILE};
}


sub block_on {
  my $self = shift;
  $self->{BLOCK} = 1;
}


sub block_off {
  my $self = shift;
  $self->{BLOCK} = 0;
}


sub terminate_on_finish_on {
  my $self = shift;
  $self->{TERMONFINISH} = 1;
}


sub terminate_on_finish_off {
  my $self = shift;
  $self->{TERMONFINISH} = 0;
}


sub addjobtotask {
  my $self = shift;
  my $taskname;
  my $job;
  if (@_) {
    $taskname = shift;
    $job = shift;
    if (not((defined $self->{TASKS}) and (defined $self->{TASKS}{$taskname}))) {
      $self->{TASKS}{$taskname} = NetbatchTask->new($self->{LOGHANDLE}, $taskname);
    }
    $self->{TASKS}{$taskname}->addjob($job);
  }
}


sub _settaskvar {
  my $self = shift;
  my $taskname = shift;
  my $varname = shift;
  my $value = shift;
  if (exists $self->{TASKS}{$taskname}) {
    switch ($varname) {
      case 'WORKAREA'    {$self->{TASKS}{$taskname}->workarea($value)}
      case 'NBCLASS'     {$self->{TASKS}{$taskname}->nbclass($value)}
      case 'NBQUEUE'     {$self->{TASKS}{$taskname}->nbqueue($value)}
      case 'NBQSLOT'     {$self->{TASKS}{$taskname}->nbqslot($value)}
      case 'DEPENDSON'   {$self->{TASKS}{$taskname}->dependson($value)}
      case 'UPDATEFREQ'  {$self->{TASKS}{$taskname}->updatefreq($value)}
      case 'MAXWAITING'  {$self->{TASKS}{$taskname}->maxwaiting($value)}
      case 'MAXJOBS'     {$self->{TASKS}{$taskname}->maxjobs($value)}
      case 'ONJOBFINISH' {$self->{TASKS}{$taskname}->onjobfinish($value)}
      case 'HUNGLIMITS'  {$self->{TASKS}{$taskname}->hunglimits($value)}
      case 'EXECLIMITS'  {$self->{TASKS}{$taskname}->execlimits($value)}
      else               {return undef}
    }
  } else {
    return undef;
  }
}


sub _gettaskvar {
  my $self = shift;
  my $taskname = shift;
  my $varname = shift;
  if (exists $self->{TASKS}{$taskname}) {
    switch ($varname) {
      case 'WORKAREA'    {return $self->{TASKS}{$taskname}->workarea}
      case 'NBCLASS'     {return $self->{TASKS}{$taskname}->nbclass}
      case 'NBQUEUE'     {return $self->{TASKS}{$taskname}->nbqueue}
      case 'NBQSLOT'     {return $self->{TASKS}{$taskname}->nbqslot}
      case 'DEPENDSON'   {return $self->{TASKS}{$taskname}->dependson}
      case 'UPDATEFREQ'  {return $self->{TASKS}{$taskname}->updatefreq}
      case 'MAXWAITING'  {return $self->{TASKS}{$taskname}->maxwaiting}
      case 'MAXJOBS'     {return $self->{TASKS}{$taskname}->maxjobs}
      case 'ONJOBFINISH' {return $self->{TASKS}{$taskname}->onjobfinish}
      case 'HUNGLIMITS'  {return $self->{TASKS}{$taskname}->hunglimits}
      case 'EXECLIMITS'  {return $self->{TASKS}{$taskname}->execlimits}
      else               {return undef}
    }
  } else {
    return undef;
  }
}


sub taskworkarea {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'WORKAREA');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskworkarea = shift;
    return $self->_settaskvar($taskname, 'WORKAREA', $taskworkarea);
  }
}


sub tasknbclass {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'NBCLASS');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $tasknbclass = shift;
    return $self->_settaskvar($taskname, 'NBCLASS', $tasknbclass);
  }
}


sub tasknbqueue {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'NBQUEUE');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $tasknbqueue = shift;
    return $self->_settaskvar($taskname, 'NBQUEUE', $tasknbqueue);
  }
}


sub tasknbqslot {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'NBQSLOT');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $tasknbqslot = shift;
    return $self->_settaskvar($taskname, 'NBQSLOT', $tasknbqslot);
  }
}


sub taskdependson {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'DEPENDSON');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskdependson = shift;
    return $self->_settaskvar($taskname, 'DEPENDSON', $taskdependson);
  }
}


sub taskupdatefreq {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'UPDATEFREQ');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskupdatefreq = shift;
    return $self->_settaskvar($taskname, 'UPDATEFREQ', $taskupdatefreq);
  }
}


sub taskmaxwaiting {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'MAXWAITING');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskmaxwaiting = shift;
    return $self->_settaskvar($taskname, 'MAXWAITING', $taskmaxwaiting);
  }
}


sub taskmaxjobs {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'MAXJOBS');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskmaxjobs = shift;
    return $self->_settaskvar($taskname, 'MAXJOBS', $taskmaxjobs);
  }
}


sub taskonjobfinish {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'ONJOBFINISH');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskonjobfinish = shift;
    return $self->_settaskvar($taskname, 'ONJOBFINISH', $taskonjobfinish);
  }
}


sub taskhunglimits {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'HUNGLIMITS');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskhunglimits = shift;
    return $self->_settaskvar($taskname, 'HUNGLIMITS', $taskhunglimits);
  }
}


sub taskexeclimits {
  my $self = shift;
  if (scalar @_ == 1) {
    my $taskname = shift;
    return $self->_gettaskvar($taskname, 'EXECLIMITS');
  }
  elsif (scalar @_ == 2) {
    my $taskname = shift;
    my $taskexeclimits = shift;
    return $self->_settaskvar($taskname, 'EXECLIMITS', $taskexeclimits);
  }
}


sub writetaskfile {
  my $self = shift;
  if (@_) {
    $self->{TASKFILE} = shift;
  }
  unless (defined $self->{TASKFILE}) {
    $self->{TASKFILE} = $default_taskfile;
    $self->{LOGHANDLE}->warn("nbfeeder task file name not defined, setting to default name->($self->{TASKFILE})");
  }
  my $taskfilefh = new IO::File;
  $taskfilefh->open(">$self->{TASKFILE}") or croak $self->{LOGHANDLE}->fatalq("Could not open file for writing: $self->{TASKFILE}");
  foreach my $task (sort keys %{ $self->{TASKS} }) {
    $taskfilefh->printf("%s\n\n", $self->{TASKS}{$task}->getfeederstring);
  }
  $taskfilefh->close;
}


sub nbfeederstart {
  my $self = shift;
  if (@_) {
    $self->{TASKFILE} = shift;
  }
  $self->writetaskfile;
  my @return_string;
  my $feedercmd;
  $feedercmd = "${nbpath}/bin/nbfeeder start --task $self->{TASKFILE}";
  $feedercmd .= " --terminate-on-finish" if $self->{TERMONFINISH};
  $feedercmd .= " --block" if $self->{BLOCK};
  $feedercmd .= " --work-area $self->{WORKAREA}" if defined $self->{WORKAREA};
  $feedercmd .= " --queue $self->{NBQUEUE}" if defined $self->{NBQUEUE};
  $feedercmd .= " --qslot $self->{NBQSLOT}" if defined $self->{NBQSLOT};
  $feedercmd .= " --max-jobs $self->{MAXJOBS}" if defined $self->{MAXJOBS};
  $feedercmd .= " --max-waiting $self->{MAXWAITING}" if defined $self->{MAXWAITING};
  $feedercmd .= " --task-refresh-interval $self->{TASKREFRESH}" if defined $self->{TASKREFRESH};
  $feedercmd .= " --update-frequency $self->{UPDATEFREQ}" if defined $self->{UPDATEFREQ};
  Pipe($self->{LOGHANDLE}, $feedercmd, '', \@return_string, 0);
  foreach my $line (@return_string) {
    $self->{LOGHANDLE}->infod($line);
  }
}



package NetbatchTask;

use strict;
use warnings;
use English;
use Carp;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $name;
  my $logfh;
  if ((@_) and (scalar(@_) == 2)) {
    $logfh = shift;
    $name = shift;
  } else {
    croak "-E- Netbatch.pm: Two arguments required for new netbatch task object (Logfile object, taskname)\n";
  }
  my $self = {
    LOGHANDLE      => $logfh,
    NAME           => $name,
    WORKAREA       => undef,
    NBCLASS        => undef,
    NBQUEUE        => undef,
    NBQSLOT        => undef,
    DEPENDSON      => undef,
    JOBLIST        => undef,
    UPDATEFREQ     => undef,
    MAXWAITING     => undef,
    MAXJOBS        => undef,
    ONJOBFINISH    => undef,
    HUNGLIMITS     => undef,
    EXECLIMITS     => undef,
  };
  bless ($self, $class);
  return $self;
}


sub addjob {
  my $self = shift;
  my $newjob = shift;
  push @{ $self->{JOBLIST} }, $newjob;
}


sub printjobs {
  my $self = shift;
  foreach my $job (@{ $self->{JOBLIST} }) {
    $self->{LOGHANDLE}->infod("JOB: $job");
  }
}


sub workarea {
  my $self = shift;
  if (@_) {
    $self->{WORKAREA} = shift;
  }
  return $self->{WORKAREA};
}


sub nbclass {
  my $self = shift;
  if (@_) {
    $self->{NBCLASS} = shift;
  }
  return $self->{NBCLASS};
}


sub nbqueue {
  my $self = shift;
  if (@_) {
    $self->{NBQUEUE} = shift;
  }
  return $self->{NBQUEUE};
}


sub nbqslot {
  my $self = shift;
  if (@_) {
    $self->{NBQSLOT} = shift;
  }
  return $self->{NBQSLOT};
}


sub dependson {
  my $self = shift;
  if (@_) {
    $self->{DEPENDSON} = shift;
  }
  return $self->{DEPENDSON};
}


sub updatefreq {
  my $self = shift;
  if (@_) {
    $self->{UPDATEFREQ} = shift;
  }
  return $self->{UPDATEFREQ};
}


sub maxwaiting {
  my $self = shift;
  if (@_) {
    $self->{MAXWAITING} = shift;
  }
  return $self->{MAXWAITING};
}


sub maxjobs {
  my $self = shift;
  if (@_) {
    $self->{MAXJOBS} = shift;
  }
  return $self->{MAXJOBS};
}


sub onjobfinish {
  my $self = shift;
  if (@_) {
    $self->{ONJOBFINISH} = shift;
  }
  return $self->{ONJOBFINISH};
}


sub hunglimits {
  my $self = shift;
  if (@_) {
    $self->{HUNGLIMITS} = shift;
  }
  return $self->{HUNGLIMITS};
}


sub execlimits {
  my $self = shift;
  if (@_) {
    $self->{EXECLIMITS} = shift;
  }
  return $self->{EXECLIMITS};
}
 

sub getfeederstring {
  my $self = shift;
  my $feederstring;
  $feederstring = "Task $self->{NAME} {\n";
  $feederstring .= "  WorkArea $self->{WORKAREA}\n" if defined $self->{WORKAREA};
  if (defined $self->{NBCLASS} or defined $self->{ONJOBFINISH}) {
    $feederstring .= "  SubmissionArgs";
    $feederstring .= " --class $self->{NBCLASS}" if defined $self->{NBCLASS};
    $feederstring .= " --on-job-finish $self->{ONJOBFINISH}" if defined $self->{ONJOBFINISH};
    $feederstring .= " --hung-limits $self->{HUNGLIMITS}" if defined $self->{HUNGLIMITS};
    $feederstring .= " --exec-limits $self->{EXECLIMITS}" if defined $self->{EXECLIMITS};
    $feederstring .= "\n";
  }
  $feederstring .= "  DependsOn $self->{DEPENDSON}\n" if defined $self->{DEPENDSON};
  if (defined $self->{NBQUEUE}) {
    $feederstring .= "  Queue $self->{NBQUEUE} {\n";
    $feederstring .= "    Qslot $self->{NBQSLOT}\n" if defined $self->{NBQSLOT} ;
    $feederstring .= "    UpdateFrequency $self->{UPDATEFREQ}\n" if defined $self->{UPDATEFREQ};
    $feederstring .= "    MaxWaiting $self->{MAXWAITING}\n" if defined $self->{MAXWAITING};
    $feederstring .= "    MaxJobs $self->{MAXJOBS}\n" if defined $self->{MAXJOBS};
    $feederstring .= "  }\n";
  }
  $feederstring .= "  jobs {\n";
  foreach my $job (@{ $self->{JOBLIST} }) {
    $feederstring .= "    nbjob run $job\n";
  }
  $feederstring .= "  }\n";
  $feederstring .= "}\n";
  return $feederstring
}


1;

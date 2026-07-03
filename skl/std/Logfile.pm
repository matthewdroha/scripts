# $Id: Logfile.pm,v 1.1 2010/01/08 19:57:36 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: Logfile.pm,v 1.1 2010/01/08 19:57:36 mroha Exp $

(C) Copyright Intel Corporation, 2008
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: Logfile.pm
Packages: LogFile objects
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: Object for managing standard logfile interface
      
=cut


package Logfile;

use strict;
use warnings;
use English;
use Carp;
use IO::File;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $filename;
  my $filehandle;
  if (scalar @_ == 1) {
    $filename = shift;
    $filehandle = new IO::File;
    $filehandle->open(">$filename") or croak "-E- Could not open $filename for writing";
  } else {
    croak "-E- Logfile.pm: Filename required for new Logfile object";
  }	
  $filehandle->autoflush(1);
  my $self = {
    FILEHANDLE   => $filehandle,
    FILENAME     => $filename,
    MODE         => undef,
    LOGONLY      => undef,
    FORCESTDOUT  => undef,
    DEBUG        => undef,
    VERBOSE      => undef,
    SPACER       => '',
    DEBUG_STRING => '[DEBUG]',
    FLOW_NAME    => '',
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
  $self->{FILEHANDLE}->close;
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
  my $write_debug = shift;
  my @message = @_;
  my $header;
  my $logstring;
  
  $self->{MODE} = $mode;
  for (my $i = 0; $i <= $#message; $i++) {
    if ($i == 0) {
      if (($write_debug) and ($self->{DEBUG})) {
	$header = "$self->{DEBUG_STRING}";
      } else {
        $header = '';
      }
      $header .= "$self->{MODE} $self->{FLOW_NAME}: ";
    } else {
      if (($write_debug) and ($self->{DEBUG})) {
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


sub debug {
  my $self = shift;
  if (@_) {
    $self->{DEBUG} = shift;
  }
  return $self->{DEBUG};
}


sub normal_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 0;
  $self->{LOGONLY} = 0;
  $self->write_to_log($mode, 0, @message);
}


sub only_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 0;
  $self->{LOGONLY} = 1;
  $self->write_to_log($mode, 0, @message);
}


sub stdout_and_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
  $self->{FORCESTDOUT} = 1;
  $self->{LOGONLY} = 0;
  $self->write_to_log($mode, 0, @message);
}


sub debug_write_to_log {
  my $self = shift;
  my $mode = shift;
  my @message = @_;
 
  if ($self->{DEBUG}) {
    $self->{FORCESTDOUT} = 0;
    $self->{LOGONLY} = 1;
    $self->write_to_log($mode, 1, @message);
  }
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

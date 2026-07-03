#!/usr/intel/pkgs/perl/5.8.2/bin/perl -w
#
#$Id: feedfails.pl,v 1.1 2006/11/10 21:51:55 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: feedfails.pl,v 1.1 2006/11/10 21:51:55 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: feedfails.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Accepts nbfeed status file in STDIN. Single argument is field in status file as input.
It outputs the value of the given field for all lines that do
not contain  FINISHED_EXECUTED-DONE  0
=cut


use strict;
use warnings;
use English;
use File::Path;
use File::Basename;
use Getopt::Long;
use Time::Local;
use Env;
use Cwd;
use Time::Local;

my $target_field = shift;

if ($target_field) {
  if ($target_field !~ /^\d+$/) {
    die "-E- Input field needs to be an integer. Argument value was->($target_field)\n";
  }
} else {
  die "-E- No field argument given as input\n";
}

my @value_list;
while (<>) {
  if (/^\d+\s+/) {
    unless (/\s+FINISHED_EXECUTED-DONE\s+0\s+/) {
      my @record = split;
      if (exists $record[$target_field]) {
	my $value = $record[$target_field];
	push (@value_list, $value);
      } else {
	die "Field ($target_field) did not contain a value in line $. : $_";
      }
    }
  }
}

foreach my $value (@value_list) {
  print "$value\n";
}

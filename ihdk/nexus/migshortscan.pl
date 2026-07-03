#!/usr/intel/pkgs/perl/5.20.1-threads/bin/perl
#
# $Id: threadcfg.pl,v 1.3 2016/06/16 04:38:02 mroha Exp $


=pod

=head1 COPYRIGHT

$Id: threadcfg.pl,v 1.3 2016/06/16 04:38:02 mroha Exp $

(C) Copyright Intel Corporation, 2016
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: migshortscan.pl
Project: ihdk
Original Author: Matthew Roha

=cut


=head1 DESCRIPTION

Test of Thread::Queue

=cut


use v5.20.1;
use strict;
use warnings;
no warnings qw(experimental::smartmatch);
use English;


my @configs = (
'mig74p0latest',
'mig74p1latest',
'mig74p2latest',
'mig74p3latest',
'mig74p6latest',
'mig74p7latest',
'mig75p3latest',
'mig74p0alpa0prod',
'mig74p0cnl1c0prod ',
'mig74p1cnl4a0prod',
'mig74p2icl3a0polo',
'mig74p2icl3a0prod',
'mig74p2knha0prod',
'mig74p3ausa0prod',
'mig74p3icl1a0polo',
'mig74p3icl1a0prod',
);


my $config_count = scalar @configs;
my $count = 0;
my $netbatch = 1;

$ENV{'NB_WASH_ENABLED'} = '1';
$ENV{'NB_WASH_GROUPS'} = q(soc,coe73lay,coeenv,hdk10nm,hdk10nmproc,hdk22nmproc);

say qq(Perl version: $^V);
foreach my $config (@configs) {
  $count++;
  my $commandline = qq(\$HOME/ihdk/nexus/getTCver.pl --config $config --debug --verbose --skipheader --skipcadscan);
  given (fork) {
    when (undef) { die "couldn't fork: $!" }
    when (0) {
      if ($netbatch) {
        $commandline = "nbq -P fm_express -C SLES11 -Q /HIP/HSIO/CKT/CLIENT $commandline";
      }
      say qq(Executing $count of $config_count-> $commandline);
      exec $commandline;
    } default {
      my $pid = $_;
      #say qq(Before waitpid command: $pid);
      # waitpid $pid, 0;
      #say 'After waitpid command';
    }
  }
  sleep 10;
}

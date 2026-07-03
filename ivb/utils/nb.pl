#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use IO::File;
use lib "/usr/users/home2/mroha/ivb/std";
use DAStd;
use Logfile;
use Netbatch;


my $logfh = new Logfile("nb.log");
$logfh->info("Starting new netbatch object");
$logfh->debug(1);
my $nbMgr = new Netbatch($logfh, "tester");
$nbMgr->addjobtotask("A", "sleep 100");
$nbMgr->addjobtotask("A", "sleep 101");
$nbMgr->addjobtotask("B", "sleep 102");
$nbMgr->taskworkarea("A", $ENV{'HOME'});
$nbMgr->taskworkarea("B", $ENV{'HOME'});
$nbMgr->taskonjobfinish("B", "NBErr:Requeue(1)");
$nbMgr->tasknbclass("A", 'pnr_to');
$nbMgr->tasknbclass("B", 'pnr_to');
$nbMgr->workarea($ENV{'HOME'});
$nbMgr->block_on;
$nbMgr->terminate_on_finish_on;
$nbMgr->nbqueue("MPG_IALcs");
$nbMgr->nbqslot("500");
$nbMgr->taskrefresh("30");

my $test = 0;
$test++;
$test += 0.1;
$test++;
my $stuff = sprintf($test);
print "$stuff\n";
#$nbMgr->nbfeederstart;

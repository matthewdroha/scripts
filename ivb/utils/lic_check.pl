#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w
#
# $Id: lic_check.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: lic_check.pl,v 1.1 2010/01/08 19:57:39 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: ivbot.pl
Project: Ivy Bridge
Original Author: Matthew Roha

Functional Description: 

Grabs ot sources and builds an ot file

=cut


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


my $new_ot_file = "/usr/users/home2/mroha/ivb.ot";
my $new_ot_filefh = IO::File->new;
$new_ot_filefh->open(">$new_ot_file") or die "Could not open file for writing

if (-e /p/mpg/proc/common2/proj_tools/genesys/overrides/ivb/developer)

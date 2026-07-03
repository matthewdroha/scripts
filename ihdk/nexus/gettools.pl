#!/usr/intel/pkgs/perl/5.14.1/bin/perl -w
#
# $Id: gettools.pl,v 1.1 2016/06/01 18:30:14 mroha Exp $


=pod

=head1 COPYRIGHT

$Id: gettools.pl,v 1.1 2016/06/01 18:30:14 mroha Exp $

(C) Copyright Intel Corporation, 2016
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: gettools.pl
Project: ihdk
Original Author: Matthew Roha

=cut

use strict;
use warnings;
use English;

# Example line
# abb                       p12ww06.5 # wibaxter 2014/09/04 11:03:45

my %tool_versions;
while (<>) {
  if (/^\s*(\S+)\s+(\S+)\s+\#/) {
    my $tool = $1;
    my $version = $2;
    $tool_versions{$tool} = $version;
  }
}

print "tool,version\n";
foreach my $tool (sort keys %tool_versions) {
  print "${tool},$tool_versions{$tool}\n";
}

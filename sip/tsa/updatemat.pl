#!/usr/intel/pkgs/perl/5.14.1/bin/perl

use strict;
use warnings;
use English;
use YAML::XS qw(LoadFile);
use Data::Dumper;
use IO::File;

my ($arrayref) = LoadFile("/p/hdk/rtl/proj_tools/toolfiles/mat/1.4/latest/mat_versions.yaml");
foreach my $tool (@{ $arrayref } ) {
  my $name = $tool->{'tool'} or die "-E- Tool name not defined\n";
  my $versions = $tool->{'versions'} or die "-E- Tool versions not defined\n";
}
#print Dumper($string, $arrayref, $hashref);

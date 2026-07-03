#!/usr/intel/pkgs/perl/5.6.1/bin/perl
#use lib '/nfs/site/proj/vt/tools/hsd/api/2.0.19/lib';
use lib '/nfs/site/proj/vt/tools/hsd/api/release/lib';
# Where RELEASE is the version. Version 1.5.15 or later is 
# required for 64-bit support.
use HSDFocus;

my $id = shift;
my $field = "status";

print "Working on ID->(${id})\n";

my $gfocus = new HSDFocus("md", "hsd_mmg_physical_design") or
    die "failed to init - " .
    HSDFocus::getLastErrMsg() . "\n";


$gfocus->loadRec($id) or
   die "Failed to loadRec - " . $gfocus->getLastErrMsg() . "\n";


my $current_value = $gfocus->getVal($field);

print "ID->($id) FIELD->(${field}) VALUE->(${current_value})\n";

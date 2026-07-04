#!/usr/intel/pkgs/perl/5.6.1/bin/perl
use lib '/nfs/site/proj/vt/tools/hsd/api/2.0.19/lib';
# Where RELEASE is the version. Version 1.5.15 or later is 
# required for 64-bit support.
use strict;
use HSDFocus;

my $id = shift;
#my $layout_module = shift;
my $field1 = "project";
my $field2 = "layout_module";

print "Working on ID->(${id})\n";

my $gfocus = new HSDFocus("md", "hsd_mmg_physical_design") or
    die "failed to init - " .
    HSDFocus::getLastErrMsg() . "\n";


$gfocus->loadRec($id) or
   die "Failed to loadRec - " . $gfocus->getLastErrMsg() . "\n";


my $previous_field1_value = $gfocus->getVal($field1);
my $previous_field2_value = $gfocus->getVal($field2);

my $new_field1_value = "PNR";
my $new_field2_value =  $previous_field2_value;
$new_field2_value =~ s/pnrg\./pnr\./;


$gfocus->setVal($field1, $new_field1_value);
$gfocus->setVal($field2, $new_field2_value);
$gfocus->updateRec() or
   die "failed to updateDB - " .
   $gfocus->getLastErrMsg() . "\n";

my $postupdate_value1 = $gfocus->getVal($field1);
my $postupdate_value2 = $gfocus->getVal($field2);
print "Update:ID->($id) FIELD1->(${field1}) (${previous_field1_value}->${postupdate_value1}) FIELD2->(${field2}) (${previous_field2_value}->${postupdate_value2})\n";

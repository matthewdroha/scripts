#!/usr/intel/pkgs/perl/5.14.1/bin/perl
use lib '/nfs/site/proj/vt/tools/hsd/api/2.0.71/lib';
# Where RELEASE is the version. Version 1.5.15 or later is 
# required for 64-bit support.
use HSDFocus;

my $id = shift;
my $field = "ip_module";

print "Working on ID->(${id})\n";

my $gfocus = new HSDFocus("md", "hsd_seg_ip") or
  die "failed to init - " .
  HSDFocus::getLastErrMsg() . "\n";


$gfocus->loadRec($id) or
  die "Failed to loadRec - " . $gfocus->getLastErrMsg() . "\n";


my $previous_value = $gfocus->getVal($field);
my $new_value = "CNL.PCIE.PI.ip741pcipi_top";

$gfocus->setVal($field, $value);
$gfocus->updateRec() or
   die "failed to updateDB - " .
   $gfocus->getLastErrMsg() . "\n";

$new_value = $gfocus->getVal($field);
print "Update:ID->($id) FIELD->(${field}) (${previous_value}->${new_value})\n";

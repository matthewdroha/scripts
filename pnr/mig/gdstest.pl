#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w

use strict;
use GDS2;

my $fileName1 = $ARGV[0];
my $fileName2 = $ARGV[1];
my $current_record;
my $record;
my @record_list;
my $text_found = 0;
my $boundary_found = 0;
my $keeptext = 0;
my $throw_away_properties = 0;
my $layer;

my %target_layer_hash;

$target_layer_hash{'1'} = 'NDIFF';
$target_layer_hash{'8'} = 'PDIFF';

my $gds2InFile = new GDS2(-fileName => $fileName1);
my $gds2OutFile = new GDS2(-fileName => ">$fileName2");

while ($current_record = $gds2InFile -> readGds2Record) {
  # If the record is of type TEXT, then set a flag to indicate that we want
  # to save the remaining records. If the layer for the TEXT ends up being
  # ndiff or pdiff, then we will make a note to keep this text.
  # Continue until ENDEL and reset search. If we said to keep the text,
  # then print all the records
  # including current one. Otherwise clear out the record list and skip
  # current record.
  
  # If the record is of type BOUNDARY, then set a flag to indicate we are
  # in a boundary element and need to look further (still write record)
  # If the layer for the BOUNDARY ends up being ndiff or pdiff, then make
  # another note that we will want to throw away this boundary element's
  # properties (still write record)
  # If all flags set and we find PROPATTR or PROPVALUE, skip it
    # May want to make sure that PROPATTR and PROPVALUE are the only two
    # records before the ENDEL to solidify understanding of the format

  if ($gds2InFile -> isText) {
    $text_found = 1;
  }

  if ($gds2InFile -> isBoundary) {
    $boundary_found = 1;
  }

  if ($text_found and $boundary_found) {
    die "Assert Error: In text and boundary loops; should not happen\n";
  }
  # Text processing loop kept seperate from boundary processing to keep it simple
  elsif ($text_found) {
    push (@record_list, $current_record);
    $layer = $gds2InFile->returnLayer;
    if (exists $target_layer_hash{$layer}) {
	$keeptext = 1;
    }
    if ($gds2InFile -> isEndel) {
      if ($keeptext) {
	foreach $record (@record_list) {
	  $gds2OutFile -> printRecord(-data=>$record);
	}
	$gds2OutFile -> printRecord(-data=>$current_record); # don't forget endel
      }
      @record_list = ();
      $text_found = 0;
      $keeptext = 0;
    }
  }
  elsif ($boundary_found) {
    $layer = $gds2InFile->returnLayer;
    if (exists $target_layer_hash{$layer}) {
	$throw_away_properties = 1;
    }
    # Skip writing properties section for ndiff and pdiff
    if (($gds2InFile->isPropattr) or ($gds2InFile->isPropvalue)) {
      if ($throw_away_properties) {
	next;
      }
    }
    if ($gds2InFile -> isEndel) {
      $boundary_found = 0;
      $throw_away_properties = 0;
    }
    $gds2OutFile -> printRecord(-data=>$current_record); 
  } else {
    $gds2OutFile -> printRecord(-data=>$current_record);
  }
}


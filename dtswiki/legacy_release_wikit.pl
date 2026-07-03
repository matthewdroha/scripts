#!/usr/intel/pkgs/perl/5.14.1-threads/bin/perl


use v5.14.1;
use strict;
use warnings;
use English;
use IO::File;


my $txt = pop @ARGV;
my $txt_h;
if ($txt) {
  system("/usr/intel/bin/dos2unix $txt");
  $txt_h = IO::File->new;
  $txt_h->open($txt) or die "Could not open .txt file for reading\n";
} else {
  die "No .txt file provided\n";
}


my @rows;

while (<$txt_h>) {
  push @rows, $_;
}
$txt_h->close;

# Write out csv for Excel consumption
my $wikifile = "${txt}.wiki";
my $wikifile_h = IO::File->new;
$wikifile_h->open(">$wikifile") or die "Could not open wikifile for writing: $wikifile\n";

$wikifile_h->print(qq({| class="wikitable"\n));
my $firstrow = 1;
my $release_notes_fieldnum = 0;
foreach my $rowdata (@rows) {
  my @record = split (/\t/, $rowdata);
  my $previousvalue = '';
  my $currentvalue = '';
  my $fieldnum = 1;
  my @lifo = ();
  my $last_column;
  foreach my $fieldvalue (@record) {
    #say qq(FIELDNUM $fieldnum);
    chomp $fieldvalue;
    if ($firstrow) {
      if ($fieldnum <= 2) {
        $wikifile_h->print(qq(! $fieldvalue\n));
      }
      elsif ($fieldvalue =~ /HDK_RELEASE_NOTES/) {
        #say qq(DETECTED $fieldnum);
        $release_notes_fieldnum = $fieldnum;
        $last_column = qq(! $fieldvalue\n);
      } else {
        push @lifo, qq(! $fieldvalue\n);
      }
    }
    elsif ($fieldnum <= 2) {
      #say qq(FIELDNUM $fieldnum $release_notes_fieldnum);
      $wikifile_h->print(qq(| $fieldvalue\n));
    }
    elsif ($fieldnum == $release_notes_fieldnum) {
      #say qq(RELEASE NOTES VALUE $fieldvalue);
      $last_column = qq(| $fieldvalue\n);
    } else {
      $currentvalue = $fieldvalue;
      unless ($previousvalue) {
        $previousvalue = $fieldvalue;
        #say qq(EQUAL $previousvalue);
      }
      if ($currentvalue eq $previousvalue) {
        push @lifo, qq(| $fieldvalue\n);
        #say qq(| $fieldvalue);
      } else {
        #say qq(NOT EQUAL $currentvalue $previousvalue);
        my $formatted_value = q(| style="background:#ffe699;") . qq(| $fieldvalue\n);
        push @lifo, $formatted_value;
        #say $formatted_value;
      }
      $previousvalue = $currentvalue;
    }
    $fieldnum++;
  }
  foreach my $reversed_value (reverse @lifo) {
    $wikifile_h->print(qq($reversed_value));
  }
  if ($release_notes_fieldnum) {
    $wikifile_h->print(qq($last_column));
  }
  $firstrow = 0;
  $wikifile_h->print(qq(|-\n));
}
$wikifile_h->print(q(|}));

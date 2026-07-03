#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use IO::File;


# Open and hash the fubs.list file
my $fubsfile = "/usr/users/home2/mroha/snb_fubs.list";
my $fubsfilefh = IO::File->new;
$fubsfilefh->open($fubsfile) or die "Could not open file for reading: $fubsfile\n";
my %fub_hash;
while (<$fubsfilefh>) {
  my @record = split;
  my $module = $record[0];
  my $fub = $record[3];
  my $type = $record[4];
  if (($fub) and ($type) and ($fub !~ /dbtry|fublaytry|rlscore/)){
    $fub_hash{$fub}{FUBNAME} = $fub;
    $fub_hash{$fub}{MODULE} = $module;
    $fub_hash{$fub}{TYPE} = $type;
    $fub_hash{$fub}{DBB} = $fub;
    $fub_hash{$fub}{TAG} = "latest";
  }
}


# Open and hash the fubdbb.txt
my $dbbfile = "/usr/users/home2/mroha/fubdbb.txt";
#my $dbbfile = "/usr/users/home12/agoel4/fubdbb.txt";
my $dbbfilefh = IO::File->new;
$dbbfilefh->open($dbbfile) or die "Could not open file for reading: $dbbfile\n";
while (<$dbbfilefh>) {
  my @record = split;
  my $fub = $record[0];
  my $dbb = $record[1];
  my $tag = $record[2];
  if ($fub and $dbb) {
    unless (exists $fub_hash{$fub}) {
      die "Error: Fub->(${fub}) in DBB file does not exists in fubfile\n";
    }
    $fub_hash{$fub}{DBB} = $dbb;
    $fub_hash{$fub}{TAG} = $tag;
  }
}


# For each fub in the fubs.list file
foreach my $fub (sort keys %fub_hash) {
  # If the fub is repeater or rls or has a tag  not_ready , skip it
  #if (($fub_hash{$fub}{TYPE} eq "rls") or ($fub_hash{$fub}{TYPE} eq "repeater")) {
  #  next;
  #}
  if ($fub_hash{$fub}{TYPE} =~ /rls|repeater/) {next}
  if ($fub_hash{$fub}{TAG} eq "not_ready" ){next}
  foreach my $subkey ('FUBNAME', 'MODULE', 'DBB', 'TAG') {        
    print "$fub_hash{$fub}{$subkey}  ";
  }
  print "\n";
}

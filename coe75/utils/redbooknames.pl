#!/usr/intel/pkgs/perl/5.12.2/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Pipe;

my $sprintf_spec = '%-35s %10s %10s %8s %30s %20s %20s %20s';
my @wwid_list = ();
my @out_records = ();
my $familyname;
my $firstname;
my $middleinitial;
my $wwid;
my $exportcountrycode;
my $exportcountrygroup;
my $glgroupcode;
my $glgroupdesc;

while (<>) {
  my @names = split(/\;/, $_);
  foreach my $name (@names) {
    if ($name =~ /\<(\S+)\>/) {
      my $email = $1;
      my $infopipe = IO::Pipe->new;
      $infopipe->reader("/usr/intel/bin/phonebook -c WWID $email");
      while (<$infopipe>) {
	if (/WWID/) {
	  next;
	}
	my @record = split(/\|/, $_);
	push @wwid_list, &trim($record[0]);
      }
      $infopipe->close;
    }
  }
}

if (@wwid_list) {
  my $csvrecord = join(',','Lname','Fname','WWID','IDSID','ExportCountryCode','ExportCountryGroup',
		       'GLGroupCode','GLGroupDesc');
  print "$csvrecord\n";
  foreach my $record (@wwid_list) {
    my %cdishash;
    my $cdispipe = IO::Pipe->new;
    $cdispipe->reader("/usr/intel/bin/cdislookup -w $record");
    while (<$cdispipe>) {
      if (/^\s*(\S+)\s*\=\s+(.+)$/) {
	$cdishash{$1} = &trim($2);
      }
    }
    $cdispipe->close;
    my $middleinitial;
    if (exists $cdishash{'MI'}) {
      $middleinitial = " $cdishash{'MI'}";
    } else {
      $middleinitial = '';
    }
    my $firstplusmiddle = &trim("$cdishash{'Fname'}${middleinitial}");
    my $csvrecord = join(',',
		      $cdishash{'Lname'},
		      $firstplusmiddle,
		      $cdishash{'WWID'},
		      $cdishash{'IDSID'},
		      $cdishash{'ExportCountryCo'},
		      $cdishash{'ExportCountryGr'},
		      $cdishash{'GLGroupCode'},
		      $cdishash{'GLGroupDesc'});
    print "$csvrecord\n";
  }
} else {
  print "No records found\n";
}


sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

#!/usr/intel/pkgs/perl/5.40.1/bin/perl

# kajson.pl
# (C) Copyright Intel Corporation, 2025, Matthew Roha, matthew.d.roha@intel.com
#

use v5.40.1;
use strict;
use warnings;
use English;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Copy;
use File::Find;
use Time::Local;
use IO::File;
use IO::Dir;
use Cwd;
use Env;
use Carp;
use JSON;
use Data::Dumper;
use Text::CSV_XS;
use Date::Calc qw(Week_of_Year);
use Intel::CDISLookup;


my @file_list;
find ( sub {
  return unless -f;       #Must be a file
  return unless /\.json$/;  #Must end with `.pl` suffix
  push @file_list, $File::Find::name;
}, '/nfs/site/disks/mroha_wa_01/copilot_feedback_pilot');

my %found;

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
my $usercsv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
my $kah;
open $kah, ">:encoding(utf8)", "ka.csv" or die "ka.csv: $!";
my @header = ('site', 'system', 'record_type',
              'tool', 'user', 'timestamp', 'txtdatetime', 'yearww',
              'feedback_rating', 'feedback_reason', 'feedback_comment', 'file');
                   
$csv->say ($kah, $_) for \@header;


my @csvrecord;
my @usercsvrecord;
my %users;
my $filecount = scalar @file_list;

my $cdis = Intel::CDISLookup->new;

foreach my $file (@file_list) {
  @csvrecord = ();
  # say qq($file);
  unless (-s $file) {next}
  #if (exists $found{system} and exists $found{feedback}) {
  #  say qq(Exiting);
  #  exit 1;
  #}
  my @record = split(/\//,$file);
  my $site = $record[6];
  my $system = $record[7];
  #if ($system eq "wa") {next}
  my $record_type = $record[8];
  my $tool = $record[9];
  #say qq($site $system $record_type $tool);
  #if (exists $found{$record_type}) {
  #  say qq(Skipping);
  #  next;
  #}

  my $json_text = do {
   open(my $jsonh, "<:encoding(UTF-8)", $file)
      or die("Can't open \"$file\": $!\n");
   local $/;
   <$jsonh>
  };

  my $json = JSON->new;
  my $data = $json->decode($json_text);
  #unless (length($data)) {next}
  #print Dumper($data);
  #for ( @{$data->{data}} ) {
  #  print $_->{name}."\n";
  #}
  $found{$record_type} = 1;
  
  unless ($$data{metadata}{system_timestamp}) {
    $$data{metadata}{system_timestamp} = 1;
  }
  my $user = $$data{metadata}{system_user_name};
  my $txtdatetime = generate_txt_datetime($$data{metadata}{system_timestamp});
  my $yearww = generate_yearww($$data{metadata}{system_timestamp});
  push(@csvrecord,
       $site,
       $system,
       $record_type,
       $tool,
       $user,
       $$data{metadata}{system_timestamp},
       $txtdatetime,
       $yearww);

  my $feedback_rating = '';
  my $feedback_reason = '';
  my $feedback_comment = '';
  if ($record_type eq "feedback") {
    $feedback_rating = $$data{metadata}{feedback_rating};
    $feedback_reason = $$data{metadata}{feedback_reason};
    $feedback_comment = $$data{metadata}{feedback_comment};
  }
  $feedback_reason =~ s/\n/ /g if $feedback_reason;
  $feedback_comment =~ s/\n/ /g if $feedback_comment;
  push(@csvrecord, $feedback_rating, $feedback_reason, $feedback_comment,$file);

  $csv->say ($kah, $_) for \@csvrecord;
 
  unless ($user) {next}
  if (exists $users{$user}) {
    if ($users{$user} gt $yearww) {
      $users{$user} = $yearww;
    }
  } else {
    $users{$user} = $yearww;
  }
}

close $kah;



my $userkah;
open $userkah, ">:encoding(utf8)", "userka.csv" or die "userka.csv: $!";
@header = ('user', 'first_ww_ran', 'IDSID', 'Region', 'SiteCode',
           'GLCostCenterDes', 'GLDivisionDesc', 'GLGroupDesc',
           'GLSuperGroupDes', 'OrgUnitDescr' );
$usercsv->say ($userkah, $_) for \@header;


foreach my $user (sort keys %users) {
  @usercsvrecord = ();
  my $count = $cdis->query( mode=>L_IDSID, key=>${user});
  foreach my $result (($cdis->results())) {
    push(@usercsvrecord,
        $user, $users{$user}, $result->{IDSID},
        $result->{Region}, $result->{SiteCode}, $result->{GLCostCenterDesc},
        $result->{GLDivisionDesc}, $result->{GLGroupDesc}, $result->{GLSuperGroupDesc},
        $result->{OrgUnitDescr});
    $usercsv->say ($userkah, $_) for \@usercsvrecord;
  }
}

close $userkah;

say qq(File count: $filecount);



sub generate_txt_datetime {
  my $ltime = shift;

  my ($sec, $min, $hour, $mday, $mon, $year) = localtime($ltime);
  $year += 1900;
  $mon += 1;
  $mon = sprintf("%02d", $mon);
  $mday = sprintf("%02d", $mday);

  return qq($year-$mon-$mday $hour:$min:$sec);
}

sub generate_yearww {
  my $ltime = shift;

  my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($ltime);
  $year += 1900;
  $mon += 1;
  
  my ($week, $wwyear) = Week_of_Year($year, $mon, $mday);
  if ($wday == 0) {
    $week += 1;
  }
  $week = sprintf("%02d", $week);

  return qq(${wwyear}ww${week});
}
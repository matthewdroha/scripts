#!/usr/intel/pkgs/perl/5.12.2/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;
use Carp;

my $cvsschdir = cwd();
my $cvsschdirfh = IO::Dir->new;
$cvsschdirfh->open($cvsschdir) or die "Could not open directory for reading: $cvsschdir\n";
my @files = grep /\S+\.sn$/, $cvsschdirfh->read;
$cvsschdirfh->close;
unless (@files) {
  print "No snsch .sn files found in current directory\n";
  exit;
}
my $csvfile = "$ENV{'HOME'}/sncells.csv";
my $csvfilefh = new IO::File;
$csvfilefh->open(">$csvfile") or croak "-E- Could not open $csvfile for writing\n";
print $csvfilefh "top_block,cell,cvv_version,library,library_tag,cvv_path,last_checkin_user,last_checkin_date\n";
foreach my $file (@files) {
  my $targetfh = IO::File->new;
  $targetfh->open($file);
  my $block;
  ($block) = split (/\.sn/, $file);
  my $cell;
  my $cvv_path;
  my $cvv_version;
  my $library;
  my $library_tag;
  my $checkin_date;
  my $checkin_user;
  my %cell_hash = ();
  while (<$targetfh>) {
    if (/^\$\s+\#\s+Cell\s+:\s+(\S+)\s*$/) {
      $cell = $1;
    }
    if (/^\$\s+\#\s+Cell\s+Data\s+:\s+(\S+)\s+version:\s+(\S+)\s+.+$/) {
      $cvv_path = $1;
      $cvv_version = $2;
      my @path_list = reverse split(/\//, $cvv_path);
      $library = $path_list[2];
      $library_tag = $path_list[3];
      if (1) {
	$checkin_date = 'test';
	$checkin_user = 'test';
      } elsif (exists $cell_hash{$cell}) {
	$checkin_date = $cell_hash{$cell}{'checkin_date'};
	$checkin_user = $cell_hash{$cell}{'checkin_user'};
      } else {
	my $dsscquery = "$ENV{SYNC_DIR}/bin/dssc report history -last 1 $cvv_path";
	my $dsscqueryfh = new IO::File;
	$dsscqueryfh->open("$dsscquery |") or die "Could not open DSSC query:", $dsscquery;
	while (<$dsscqueryfh>) {
	  if (/^\s*Date:\s+(.+)$/) {
	    my $date_string = $1;
	    my @record = split(/\s+/, $date_string);
	    my $day_of_week_name = $record[0];
	    my $month_name = $record[1];
	    my $mday = $record[2];
	    my $time = $record[3];
	    my $year = $record[5];
	    my $month = ConvertMonthStringToInt($month_name) + 1;
	    $checkin_date = "${year}-${month}-${mday} $time";
	    $cell_hash{$cell}{'checkin_date'} = $checkin_date;
	    }
	  if (/^\s*Author:\s+(\S+)$/) {
	    $checkin_user = $1;
	    $cell_hash{$cell}{'checkin_user'} = $checkin_user;
	    last;
	  }
	}
	$dsscqueryfh->close;
      }
      my $csvline = join(',',$block,$cell,$cvv_version,$library,$library_tag,$cvv_path,$checkin_user,$checkin_date);
      print $csvfilefh "$csvline\n";
    }
  }
  $targetfh->close;
}


sub ConvertMonthStringToInt {

  my $month_string = shift;
  my %MONTH;

  $month_string = lc($month_string);

  $MONTH{'jan'} = 0;
  $MONTH{'feb'} = 1;
  $MONTH{'mar'} = 2;
  $MONTH{'apr'} = 3;
  $MONTH{'may'} = 4;
  $MONTH{'jun'} = 5;
  $MONTH{'jul'} = 6;
  $MONTH{'aug'} = 7;
  $MONTH{'sep'} = 8;
  $MONTH{'oct'} = 9;
  $MONTH{'nov'} = 10;
  $MONTH{'dec'} = 11;

  if (exists ($MONTH{$month_string})) {
    return $MONTH{$month_string}
  } else {
    die "ConvertMonthStringToInt: Input month not matched\n";
  }
}


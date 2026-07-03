#!/usr/intel/bin/perl

open (PRIORITYLIST, $ARGV[0]) or die;
if (-d $ARGV[1]) {
  $premigdir = $ARGV[1];
} else {
  die;
} 

while (<PRIORITYLIST>) {
  ($fub) = split;
  $fub = lc($fub);
  $priority_hash{$fub} = 1;
}

opendir (PREMIGDIR, $premigdir) or die;
my @premiglog_list = grep {/premig.log$/} readdir(PREMIGDIR);
closedir (PREMIGDIR);

my $file;
my $cell;
my @cell_list;
my $fullfilepath;

foreach $file (@premiglog_list) {
  my $cell = $file;
  $cell =~ s/\.premig\.log//;
  $fullfilepath = "${premigdir}/${file}";
  open (PREMIGLOG, $fullfilepath) or die;
  while (<PREMIGLOG>) {
    if (/(\d+)\s+total layout devices/) {
      $devcount{$cell} = $1;
    }
    if (/run CLEAN for model: \((\S+)\)/) {
      $datasource{$cell} = $1;
    }
  }
  close (PREMIGLOG);
}


foreach $cell (sort keys %priority_hash) {
  if ($devcount{$cell}) {
    unless ($datasource{$cell}) {
      $datasource{$cell} = 'lor2';
    }
    print "FCL priority cell CLEAN in Merom: cell-> $cell  source-> $datasource{$cell}  devcount-> $devcount{$cell}\n";
  } else {
    print "FCL priority cell DIRTY in Merom: cell-> $cell\n";
  }
}

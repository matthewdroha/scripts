#!/usr/intel/pkgs/perl/5.8.5/bin/perl -w

use Cwd 'abs_path';

my @record;
my $cshrc_path;
my $idsid;
my @have_eclogin;
my $do_not_have_eclogin;

while (<>) {
  ($idsid) = split;
  $cshrc_path = `cd ~${idsid};pwd`;
  chomp $cshrc_path;
  $cshrc_path = "${cshrc_path}/.cshrc.${idsid}";
  print "$cshrc_path\n";
  if (-f $cshrc_path) {
    push @have_eclogin, $idsid;
  } else {
    push @do_not_have_eclogin, $idsid
  }
}

print "### Update eclogin project:  eclogin -p ivb  ###\n";
foreach my $user (@have_eclogin) {
  print "$user\n";
}

print "\n\n### Need to convert to eclogin ###\n";
foreach my $user (@do_not_have_eclogin) {
  print "$user\n";
}

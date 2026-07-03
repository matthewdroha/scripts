#!/usr/bin/perl -w
use strict;


die "\nPLEASE ENTER THREE ARGUMENTS: LIBRARY TAG MODEL\n\n" unless scalar(@ARGV) == 3;
my ($lib,$tag,$model) = @ARGV;

&test_commandline;
my $fub_name = &get_fubname;
&test_lib($lib);
&test_model($lib,$model);
&test_tag($lib,$tag,$model,$fub_name);
&run_release2model($lib,$tag,$model);

sub test_commandline {
    print "\nCommand line syntax should read:  ../release2model_mod.pl library tag model\n\n";
    print "You have input the following arguments:\n\n";
    print "Library:  $lib\nTag:      $tag\nModel:    $model\n\n";
    print "Continue? (y/n)";
    chomp(my $response = <STDIN>);
    until ($response =~ /^yes$|^y$|^no$|^n$/i) {
        print "Continue? (y/n)";
        chomp($response = <STDIN>);
    }
    exit if ($response =~ /no|n/i);
}

sub get_fubname {
    my $DBB = $ENV{DBB};
    if ($DBB =~ /[:]+/) {
        print "\n\$DBB contains more than one library name. ($DBB) \n";
        print "Please enter fub name:\n";
        chomp(my $in = <STDIN>);
        $in =~ s/(\w+)/\L$1/i;
        $in;
    }
    else {
        $DBB;
    }
}

sub test_lib {
    my $l = shift;
    unless ($l =~ "\_$ENV{PROJECT}\_") {
        print "\nLIBRARY SPECIFIED DOES NOT EXIST IN ENVIRONMENT\n\n";
        exit;
    }
}

sub test_model {
    my $l = shift;
    $l =~ s/.*_(\w+)_.*/$1/;
    my $m = shift;
    unless (-e "$ENV{DA_PROJECTS}/$ENV{PROJECT}/$l.$m.cfg") {
        print "\nMODEL SPECIFIED DOES NOT EXIST FOR THIS PROJECT\n\n";
        exit;
    }
}

sub test_tag {
    my $l = shift;
    $l =~ s/.*_(\w+)_.*/$1/;
    my $t = shift;
    my $m = shift;
    my $f = shift;
    $m =~ ".*_(.+)_.*";
    my $lib_type = $1;
    unless (-e "$ENV{DB_ROOT}/$l/$f\_$l/$lib_type/$t") {
        print "\nTAG SPECIFIED DOES NOT EXIST FOR THIS LIBRARY\n\n";
        exit;
    }
}

sub run_release2model {
    my $l = shift;
    my $t = shift;
    my $m = shift;
    chomp(my @output = `$ENV{PROJ_SKILL}/gallery/bin/release2model.tcl -lib $l -tag $t -model $m`);
    print "\n";
    print "$_\n" foreach @output;
    print "\n\n";
}

#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# INTEL CONFIDENTIAL
#
# $Id: pienotext.pl,v 1.1 2004/09/12 02:38:08 mroha Exp $
#


BEGIN {
    my $scriptpath = $0;
    if ($scriptpath =~ /^(\S+\/)/) {
        $scriptpath = $1;
    }else{
        $scriptpath = "./";
    }
    
    unshift @INC , "$scriptpath";    
}

# load packages.
use strict;
use English; 
use Getopt::Long;
use File::Basename;
use Env ;
use Cwd ;

# setup exception handling.
$SIG{'INT'}  = \&exceptionhandler;
$SIG{'TERM'} = \&exceptionhandler;

# declare variables used in the main script
my (@usage, $optokay, $opthelp, $optstream, $optblock,
    $scriptname, $exitgood, $exitbad);

# extract the name of this script. 
$scriptname = basename($0);

# auto flush STDOUT and STDERR
$| = 1;

my ($idstring) ;
print "-------------------------------------------------------------------\n";
$idstring = '$Id: pienotext.pl,v 1.1 2004/09/12 02:38:08 mroha Exp $' ;
print "VERSION:  $idstring\n";
print "-------------------------------------------------------------------\n";

# Usage of the script
@usage =("${scriptname} -stream <stmfile> -block <block> [-help]\n",
         "   -stream = <stmfile>",
         "   -block = <block>",
         "   -help = usage options\n"
         );

# set default options and global variables here.
$exitgood = 0;
$exitbad  = 1; 

# Get command line options, variables should start with $opt<switch>
$optokay = &GetOptions('help' =>   \$opthelp,
                       'stream=s' => \$optstream,
                       'block=s' => \$optblock
                       );

# Check parameters 
if (($optokay != 1) || ($opthelp) || !($optblock) || !($optstream)) {
    &usage();
    exit($exitbad);
}

# ---------------------
# Validate assumptions:
# --------------------- 

unless (-e $optstream) {
    &mydie("-e- error:  \"$optstream\" doesn't exist.\n");
}
unless (defined $ENV{'PROCESS_NAME'}) {
    &mydie("-e- error:  PROCESS environment variable not set.\n");
}

# ---------------------------------------
# All assumptions valid after this point.
# Begin main execution of script. 
# --------------------------------------- 
print "----------------\n";
print "Setup Started...\n";
print "----------------\n";
my ($piedir,$pieprocess,$piemain,$piestruct,$pierunset,$pieroot) ;
$pieroot = "$ENV{'WORK_AREA_ROOT_DIR'}/pie/pienotext_$optblock/" ;
if (-e $pieroot) { &mydie ("-e- error:  \"$pieroot\" file exists.  Please clean up previous version (this folder) before running again.\n");}
system("mkdir -p $pieroot") && &mydie("-e- error:  couldn't setup directory \"$pieroot\"\n");
$optstream = &fwd($optstream);
$pieprocess = $ENV{'PROCESS_NAME'}; unless (defined $pieprocess) {&mydie("-e- error: process wasn't defined\n");}
$piedir = $ENV{'PIE_DIR'};     unless (-e $piedir)     {&mydie("-e- error: pie not setup correctly\n");}
$piemain = "$piedir/bin/Piemain" ;  unless(-e $piemain) {&mydie("-e- error: pie executable missing\n");}
my ($pierunsetdir) ;
if(defined $ENV{'PIE_RUNSET_DIR'}) {
    print "-i- info:  overriding pie runsets with PIE_RUNSET_DIR\n";
    $pierunsetdir = $ENV{'PIE_RUNSET_DIR'};
} else {
    $pierunsetdir = "$piedir/runsets/" ;
}
$piestruct = "$pierunsetdir/$pieprocess/pie${pieprocess}.struct" ; unless (-e $piestruct) {&mydie("-e- error: piestruct missing\n");}
$pierunset = "$pierunsetdir/$pieprocess/pie${pieprocess}.vc" ; unless (-e $pierunset) {&mydie("-e- error: pierunset missing\n");}

my($gdsin,$hercules);
$gdsin = `which gdsin` ; chomp($gdsin) ;
$hercules = `which hercules` ; chomp($hercules);
unless(-e $gdsin) { &mydie("-e- error:  couldn't find gdsin...\n");}
unless(-e $hercules) { &mydie("-e- error:  couldn't find hercules...\n");}

print "---------------------------\n";
print "  Running modified pie flow\n";
print "---------------------------\n";
chdir $pieroot ;
my $modpiefile = "$optblock.modpie";
open (OUT, ">$modpiefile") || &mydie("-e- error: couldn't open \"$modpiefile\" for write.\n");

print OUT "#!/bin/tcsh -ef\n";
print OUT "gdsin $optstream $optblock.db -g ./ -fs .1 .1 .1 .1 -ea r -ma r -nl -tp | tee $optblock.gdsin.log\n";
print OUT "setenv PIE_BETTER_VIA_EV YES  \n";
print OUT "setenv PIE_BETTER_STRAP_EV YES  \n";
print OUT "setenv PIE_SKINNY_STRAP_EV NO \n";
print OUT "setenv PIE_PROPAGATE_PRT_EV NO \n";
print OUT "setenv PIE_KEEP_RESID_EV NO \n";
print OUT "setenv PIE_BLACKBOX_LIST_EV NO \n";
print OUT "hercules -b $optblock -f LTL -i $optblock.db -O LTL -o ${optblock}_pie.db -p $pieroot $pierunset | tee $optblock.hercules.log\n";
print OUT "$piemain -ltldb ${optblock}_pie.db -topcell $optblock -netfile $optblock.net -skipannotations -depth 999 -doports -dozones -portdepth 999 -structfile $piestruct -writelnf -wirejun 0 -netprefix syn -cellboundaryhack -instancenamehack -process p1266 -nonmanhattan -maxDevSDWidth 0.13 -propagatevccvss | tee $optblock.pie.log\n";
close OUT;
system ("chmod 755 $modpiefile");
system("./$modpiefile")  && &mydie("-e- error: failure running modpiefile\n");

print "--------------------------------------\n";
print "$scriptname completed successfully...\n";
print "Have a nice day.  Please drive through.\n";
exit($exitgood); 


# ----------------------
# Subroutines
# ----------------------

#>
sub usage {
    print "Usage: @usage\n";
    exit($exitbad);
} 

#> Exception handling.
sub exceptionhandler {
    print "-F- FATAL: Exception occured!  Exiting....\n";
    exit($exitbad);
}

sub mydie {
    my $message = shift;
    print "$message";
    exit ($exitbad);
}

sub fwd {
    my ($path) = shift;
    
    my ($dir,$curwd,$base) ;
    
    $dir = dirname ($path) ;
    $base = basename ($path) ;

    $curwd = cwd() ;
    chdir $dir || die ("-e- error:  can't change dir to \"$dir\"\n");
    $dir = cwd() ;
    chdir $curwd || die ("-e- error:  can't change dir to \"$curwd\"\n");

    return "$dir/$base";
}


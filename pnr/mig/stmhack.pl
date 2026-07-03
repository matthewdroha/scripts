#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#
# INTEL CONFIDENTIAL
#
# $Id: stmhack.pl,v 1.1 2004/09/12 02:38:09 mroha Exp $
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
use Dabasics ;
use stm ;

# setup exception handling.
$SIG{'INT'}  = \&exceptionhandler;
$SIG{'TERM'} = \&exceptionhandler;

# declare variables used in the main script
my (@usage, $optokay, $opthelp, $optstm,
    $scriptname, $exitgood, $exitbad);

# extract the name of this script. 
$scriptname = basename($0);

# auto flush STDOUT and STDERR
$| = 1;

my ($idstring) ;
print "-------------------------------------------------------------------\n";
$idstring = '$Id: stmhack.pl,v 1.1 2004/09/12 02:38:09 mroha Exp $' ;
print "VERSION:  $idstring\n";
print "-------------------------------------------------------------------\n";

# Usage of the script
@usage =("${scriptname} -stm <stm> [-help]\n",
         "   -help = usage options\n"
         );

# set default options and global variables here.
$exitgood = 0;
$exitbad  = 1; 

# Get command line options, variables should start with $opt<switch>
$optokay = &GetOptions('stm=s' => \$optstm,
                       'help' =>   \$opthelp
                       );

# Check parameters 
if (($optokay != 1) || ($opthelp) || !($optstm)) {
    &usage();
    exit($exitbad);
}

# ---------------------
# Validate assumptions:
# --------------------- 

# ---------------------------------------
# All assumptions valid after this point.
# Begin main execution of script. 
# --------------------------------------- 

my($stm) ;

$stm = 'stm'->new($optstm) ;

#$stm->glance() ;

$stm->readascii($optstm) ;
$stm->writegds("$optstm.gds");

print "--------------------------------------\n";
print "$scriptname completed successfully...\n";
print "Have fun storming the castle!\n";
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

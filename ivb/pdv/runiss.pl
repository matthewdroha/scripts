#!/usr/intel/bin/perl
#
# INTEL CONFIDENTIAL
#
#> $Id: runiss.pl,v 1.1 2010/01/08 19:57:20 mroha Exp $
#>
#> Sean Nguyen
#> Oct 2003
#>
#> This is a wrapper script for _pdsbuilder.pl.  It is used
#> for submitting PDS (Physical Design System) jobs.
#>
#>

# load packages.
use strict;
use English; 
use Getopt::Long;
use File::Basename;

# declare variables used in the main script
my (@usage, $ret, $opthelp, $optfile, $optmail, 
    $scriptname, $exitgood, $exitbad, $optcellfile,
    $optflowfile,@optflows,@optcells,
    $PdsCmd, $optlocal, $optformat, $optsavewd,
    $runMode, $format, $saveDir,$optltlinpath, $optskipcvsin,$optsnname,
    $ltlInPath,$skipCvsIn,$snName,$incremental,$optlibspec,$opttail,
    $autoTail,$mailUser,$foreGround,
    $optfg,$optexplode,$opttopcheck,$optnocmp,$optonecell,
    $explodeFile,$topCheck,$noCmp,$oneCell,
    $optnetbatcher, $optnetbatcharg,
    );

# auto flush STDOUT and STDERR
$| = 1;

# extract the nae of this script. 
$scriptname = basename($0);

# setup exception handling.
$SIG{'INT'}  = \&exceptionhandler;
$SIG{'TERM'} = \&exceptionhandler;


# SUSE32 platform is not supported 
my $cadroot = $ENV{'CAD_ROOT'};
my $cadrootbase = basename($cadroot);
if ($cadrootbase =~ m/i386_linux26/i) {
    print "-E- gpds: The SUSE32 platform ($cadrootbase) is not supported, please use the SUSE64 platform.\n"; 
    exit (1);
}


# Usage of the script
@usage =("${scriptname} [-help] -cell cellName -flow flowName\n",
         "   -help        = usage options\n",
         "   -mail        = mail results\n",
         "   -cell        = cellname (can be repeated)\n",
         "   -cellfile    = file containing list of cells\n",
         "   -flow        = flow to run (can be repeated)\n",
         "   -flowfile    = file containing list of flows\n",
         "   -format      = data format\n",
         "   -local       = run job locally\n",
         "   -savewd      = save work dir\n",
         "   -snname      = sn file\n",
         "   -skipcvsin   = skip running input\n",
         "   -ltlinpath   = LTL input path\n",
         "   -libspec     = input LTL library name\n",
         "   -onecell     = run input on top-level cell only\n",
         "   -tail        = autotail\n",
         "   -fg          = run job in foreground\n",
         "   -explode     = explode file\n",
         "   -nocmp       = do not run cmp\n",
         "   -topcheck    = set topcheck to yes\n",
         "   -netbatcher  = netbatcher\n",
         "   -netbatcharg = netbatch arguments\n",
         );

# set default options and global variables here.
$exitgood = 0;
$exitbad  = 1; 

$PdsCmd = '$PDSPATH/_pdsbuilder -ecn ECNOFF -trcpin top -outtype apl -calcres no -batch1 HIDE -skewtype TTTT -tooltype iss -autohmsprt no -smshopt relax -dvssmshfile none -ltloutpath none -groupdir none -chkptdir none -batch2 HIDE -batch3 HIDE -crosscap none -make_sn false ';

$runMode = 'batch';       # default is to submit job to netbatch
$format = 'LNF';          # default format is alflay
$saveDir = 'no';
$skipCvsIn = 'no';
$ltlInPath = 'none';
$snName = 'DEFAULT';      # default is to use local netlist file
$incremental = 'no';
$autoTail = 'no';
$mailUser = 'no';
$foreGround = 'no';
$explodeFile = 'DEFAULT';
$topCheck = 'nocheck';    # default is to run cmp without topcheck
$noCmp = 'cmp';           # default is to run cmp
$oneCell = 'no';          # default is to run in hierarchy mode

# Get command line options, variables should start with $opt<switch>
$ret = &GetOptions('help',        \$opthelp,
                   'local',       \$optlocal,
                   'cellfile=s',  \$optcellfile,
                   'flowfile=s',  \$optflowfile,
                   'flow=s@',     \@optflows,
                   'cell=s@',     \@optcells,
                   'format=s',    \$optformat,
                   'savewd',      \$optsavewd,
                   'ltlinpath=s', \$optltlinpath,
                   'skipcvsin',   \$optskipcvsin,
                   'snname=s',    \$optsnname,
                   'libspec=s',   \$optlibspec,
                   'tail',        \$opttail,
                   'mail',        \$optmail,
                   'fg',          \$optfg,
                   'explode=s',   \$optexplode,
                   'nocmp',       \$optnocmp,
                   'topcheck',    \$opttopcheck,
                   'onecell',     \$optonecell,
                   'netbatcher=s',  \$optnetbatcher,
                   'netbatcharg=s', \$optnetbatcharg,
                   ); 

# Check parameters 
if (($ret != 1) || ($opthelp) || (! $optcellfile && ! @optcells) || (! $optflowfile && ! @optflows) ) {
    &usage();
    exit($exitbad);
}

# ---------------------
# Validate assumptions:
# --------------------- 

if ($optflowfile && ! -e $optflowfile) {
    print "$scriptname: -E- Could not find file: $optflowfile.\n"; 
    exit($exitbad); 
}

if ($optcellfile && ! -e $optcellfile) {
    print "$scriptname: -E- Could not find file: $optcellfile.\n"; 
    exit($exitbad); 
}

if ($optsnname && ! -e $optsnname) {
    print "$scriptname: -E- Could not find file: $optsnname.\n";
    exit($exitbad);
}

if ($optexplode && ! -e $optexplode) {
    print "$scriptname: -E- Could not find file: $optexplode.\n";
    exit($exitbad);
}

if ($optskipcvsin && ! $optltlinpath)
{
    print "$scriptname: -E- Need to specify ltl path if skipping input.\n";
    exit($exitbad);
}

if ($optltlinpath && ! -d $optltlinpath) {
    print "$scriptname: -E- Could not find dir: $optltlinpath.\n";
    exit($exitbad);
}

# ---------------------------------------
# All assumptions valid after this point.
# Begin main execution of script. 
# --------------------------------------- 


#########################################################
#
# Process Arguments
#
#########################################################

# set explode file
#
if ($optexplode)
{
    $explodeFile = $optexplode;
}

$PdsCmd .= "-explode $explodeFile ";

# set option for running cmp
#
if ($optnocmp)
{
    $noCmp = 'no';
}

$PdsCmd .= "-verifytool $noCmp ";

# set option for running cmp with topcheck on
#
if ($opttopcheck)
{
    $topCheck = 'check';
}

$PdsCmd .= "-topframe $topCheck ";

# set option for mailing
#
if ($optmail)
{
    $mailUser = 'yes';
}

$PdsCmd .= "-mailuser $mailUser ";

# set option for autotail to show run progress
# 
if ($opttail)
{
    $autoTail = 'yes';
}

$PdsCmd .= "-autotail $autoTail ";

# set run mode and save run dir option
#
if ($optlocal)
{
    $runMode = 'local';

    # save workdir only when running local
    #
    if ($optsavewd)
    {
        $saveDir = 'yes';
    }

    # run job in foreground when running local
    #
    if ($optfg)
    {
        $foreGround = 'yes';
    }
}

$PdsCmd .= "-runmode $runMode -saveworkdir $saveDir -fg $foreGround ";

# set input format
#
if ($optformat)
{
    if ($optformat =~ /^(alf|cdba|icf|lnf)$/i)
    {
        $format = uc($optformat);
    }
    elsif ($optformat =~ /^(stm|gds)$/i)
    {
        $format = lc($optformat);
    }
    else
    {
        print "$scriptname: -E- Unknown format: $optformat\n";
        exit($exitbad);
    }
}

$PdsCmd .= "-inputtype $format ";

# LTL input path
#
if ($optltlinpath)
{
    $ltlInPath = $optltlinpath;
    
    # increment must be set to yes when using external LTL input path
    #
    $incremental = 'yes';
}

$PdsCmd .= "-ltlinpath $ltlInPath -incremental $incremental ";
    
# skip running input
#
if ($optskipcvsin)
{
    $skipCvsIn = 'yes';
}
# run input on top-level cell only
#
elsif ($optonecell)
{
    $oneCell = 'yes';
}

$PdsCmd .= "-skipcvsin $skipCvsIn -onecell $oneCell ";

# Netlist file
#
if ($optsnname)
{
    $snName = $optsnname;
}

$PdsCmd .= "-snname $snName ";


#########################################################
#
# Prepare List of Cells and Flows
#
#########################################################

my (@flows,@cells);

@flows = ();
@cells = ();

# get list of cell from file
#
if ($optcellfile)
{
    @cells = GetFileList($optcellfile)
}

# merge with list of cells from argument
#
if (@optcells)
{
    @cells = (@cells, @optcells)
}

if (! @cells)
{
    print "$scriptname: -E- No cell specified to run.\n";
    exit($exitbad);
}

# get list of flows from file
#
if ($optflowfile)
{
    @flows = GetFileList($optflowfile);
}

# merge with list of flows from argument
#
if (@optflows)
{
    @flows = (@flows, @optflows);
}

if (! @flows)
{
    print "$scriptname: -E- No flow specified to run.\n";
    exit($exitbad);
}

#########################################################
#
# Execute ISS Runs
#
#########################################################

my ($cell, $curGateDir, $curFullDie);


if ($optnetbatcher)
{
    $ENV{PDSBATCHER} = $optnetbatcher;
}

if ($optnetbatcharg)
{
    $ENV{PDSBATCHLINE} = $optnetbatcharg;
}

$curGateDir = $ENV{GATE_DIRECTION};
$curFullDie = $ENV{FULL_DIE};

foreach $cell (@cells)
{
    my ($cmd, $libSpec, $flow);


    # default libspec name is based on cell name
    #
    $libSpec = $cell;

    if ($optlibspec)
    {
        $libSpec = $optlibspec;
    }
    
    $cmd = "$PdsCmd -laytopcell $cell -libspec $libSpec ";

    foreach $flow (@flows)
    {
        my ($runCmd);

        $runCmd = "$cmd -mode $flow";
        &runcmd($runCmd);
    }
    
    # restore env variable
    #
    $ENV{GATE_DIRECTION} = $curGateDir;
    $ENV{FULL_DIE} = $curFullDie;
}


exit($exitgood); 


# ----------------------
# Subroutines
# ----------------------

sub GetFileList
{
    my ($file) = @_;
    my ($line,@flownames);

    open(FLOW,$file) || die "-E- Could not open file $file";

    while ($line = <FLOW>)
    {
        $line =~ s/^\s*//;
        $line =~ s/\s*$//;

        if ($line =~ /^\w+/)
        {
            push(@flownames, $line);
        }
    }

    close(FLOW);

    return (@flownames);
}

#>
sub usage {
    print "\nSubmit PDS jobs.\n\n";
    print "Usage: @usage\n";
    exit($exitbad);
} 


#>
sub rmfile {
  my @filenames = @_;
  my $ret = &runcmd("rm -f @filenames 2> /dev/null");
  return $ret;
}


#>
sub mvfile {
  my $old = shift(@_);
  my $new = shift(@_);
  my $ret = &runcmd("mv -f $old $new 2> /dev/null");
  return $ret;
}


#>
sub mymkdir {
    my $dir =  shift(@_);
    my $force = shift(@_); 
    
    if (-d $dir && $force) {
        print "-W- directory already exists: ${dir}\n";
    }
    else {
        &runcmd("mkdir $dir");
    } 
}

#> Executes a Unix command - does not die upon error.
sub runcmd {
    my @cmd = @_;
    print "Running: @cmd\n";
    system(@cmd);
    # Get  status from system
    my $ret = $? >> 8; 

    if ($ret) {  
        print "-E- command completed with error code $ret.\n"; 
        exit(1); 
    }
    return ($ret);
}

#> Assertion handling 
sub assert {
    my $test = shift(@_); 
    my $msg  = shift(@_);
    
    if ($test == 0) {
        print "$msg\n";
        &exceptionhandler();
    }
}


#> Exception handling.
sub exceptionhandler {
    print "-F- FATAL: Exception occured!  Exiting....\n";
    exit($exitbad);
}

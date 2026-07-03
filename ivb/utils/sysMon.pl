#!/usr/intel/bin/perl 
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:DProf
#!/usr/intel/pkgs/perl/5.6.1/bin/perl -d:ptkdb
# for profiling:  /usr/intel/pkgs/perl/5.6.1/bin/dprofpp tmon.out

use strict;
#use warnings;
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Filename: sysMon.pl                        Project: WSM
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# (C) Copyright Intel Corporation, 2008
# Licensed material -- Program property of Intel Corporation
# All Rights Reserved
#
# This program is the property of Intel Corporation and is furnished
# pursuant to a written license agreement. It may not be used, reproduced,
# or disclosed to others except in accordance with the terms and conditions
# of that agreement.
#
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# Original Author: Mike Farabee
#
# Project: WSM
#
# Functional description:
#       
# Written by Mike Farabee  8/12/2008
#
# Revision History:
#
# Arguments:
#
#
# Called by: None
#
# Calls to: None
#
#
# Environment Assumptions: None
#
#
# Side effects:
#
#
# Problems:
#
# Known bugs:  None
#
# Enhancements: Nothing needed
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#
# RCS Information:
#
#   $Author: mroha $
#   $Source: /mpg/gwa/mroha/cvsroot/ivb/utils/sysMon.pl,v $
#     $Date: 2010/01/08 19:55:11 $
# $Revision: 1.2 $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
use Tk;
use Tk::LabFrame;
use Tk::Tree;
use Tk::ItemStyle;


#######################################################
#                  GLOBALS
#######################################################
my $VERSION = '$Revision: 1.2 $';
$VERSION =~ s/\$//g;
my $scriptName = $0;
$scriptName=~ s/.*\///g;
local $main::DEBUG=""; 
my %allWindows=();
my $HELPINFO;;
my $appName="/genesys ev_engine";
my $TOP;
#my $SWAPIN=0;
#my $SWAPOUT=0;
my %STATFILE=();
my %VMSTATFILE=();
my %MEMFILE=();
my %LOADAVERAGE=();
my %TMPDISK=();
my %PREVIOUS=();
my $UNITS="kb";
#######################################################
#                  Help Message       
#######################################################

my $help_message = <<HERE
	SYNTAX: $scriptName [-h][-v] [-a application] infile\n

       -h Help message. Also displayed, if no argument exist
		  on command line.
	   -v prints version # of program.
	   -a application name
		  default: /genesys ev_engine
HERE
;
$help_message =~ s/\t/    /g; # Replace tabs with 4 spaces

$HELPINFO = <<HERE

Description: This utility will help monitor system and process resources.

Host:     Displays the current host machine
Display:  Shows the setting of the environment variable DISPLAY. This can be useful when
          running Genesys or Genie because system performance and be impacted if the DISPLAY
	      is set to the host. It is best to set this to the VNC server.

          The display will turn red if the display variable in not set to the VNC server. This is
          found by comparing the DISPLAY variable to all *.pid files in the \$USER/.vnc directory.
          If a .pid file does not exist that matches the DISPLAY variable, this it is assumed that 
          the user is indirectly connecting to the VNC server through multiple ssh commands. This 
          can cause slowness.

          If this variable is changed after this utility is started, executing the refresh 
          will not update it. It will be necessary to restart this program to see the change.

Zombie:   Aides the user by identifying possible ZOMBIE processes running on the machine.
          Zombie processes are processes that the parent process has lost contact with the child.
          Usually this means that the child has ended, but the parent did not clean up the process
          table after the child ended. Since a Zombie is a child process that has ended, the memory
          should have been reclaimed by the system and there should be no CPU being used. Zombies
          therefore should not be eating up system resources, therefore are not a great concern.

		  The Zombie process is identified by using the ps command.
		  ps axo pid,user,stat,cmd | awk '\$3~/Z/ {print}'|wc -l

          Sometimes the only way to kill a Zombie is to kill the parent process. But it sometimes 
          is possible to use the following command:
          kill -9 <PID>

          A great Zombie movie (comedy) is "Shaun of the Dead", well worth watching after a hard day
          killing zombies at work.

Orphans:  Orphan processes are processes where the parent process has ended, but the child is still 
          running. Orphan processes do consume resourses.

          When the parrent ends, the child is still running and consuming resources. When the 
          parent dies the "init" process takes over as the parent.  A possible orphan can be defined by 
          a parent process ID (PPID) of "1". Not all processes with a parent of "1" are orphans.

Processor information:
          The number of CPU's is derived from looking at the results from the '/proc/cpuinfo' file.
          CPU count can be decieving because of Hyper-threading. If a HT machine is present the 
          system thinks there are additional processors. If the "cpuinfo" file has fields for
          "physical id" and "core id", it is possible to determine how many processors really exist.
          The "physical id" will show in ID number for each CPU chip and the "core id" will show the
          ID number for each CPU core on each chip. By finding the uniqie values for these ID, the number
          of CPU's can be determined.
          
          If this command does not return zero:
          egrep 'core id|physical id' /proc/cpuinfo |sort -u

          else use this:
          egrep 'processor' /proc/cpuinfo |wc -l
         

          There are multiple ways of finding the load average for the CPU. When looking at the load
          average, the 3 numbers represent the load average for 1 minute, 5 minutes and 15 minutes
          respectively. The load average represents the average number of CPU's running in the given time.
          The system is considered heavily loaded if there are more than 2 running jobs per CPU. Short 
          increases in the 1 minute average are perfectly acceptable. It can also be useful to look at
          the trend of 5 and 15 minute load averages. If these averages are decreasing, that implies
          that the CPU was hevialy loaded previously, but is now less stressed. If these numbers are growing,
          this could be a warning that compute intensive processes are continuing to run on this machine.
          Short increases in the 1 minute average are perfectly acceptable.

          uptime
          cat /proc/loadavg

          The 'iowait' and 'idle' percentages represent the amount of time the system is waiting for
          IO (possibly swapping to disk) and the amount of time the CPU was idle. The iowait 
          percentage should be very low and the idle should be very high otherwise slowness can occur.
          This information is extracted from the /proc/stat file. This file contains the count in 'jiffys'
          (1/100 sec) since boot. An easier way to see this information is to run one of the following.

          top
          iostat 1 2
          mpstat 1 1

Tmp Disk: This identifies the local tmp disk on the machine. It will display the size of 
          the disk as well as the amount used. The information about the tmp disk is gathered
		  by:
		  df -k /tmp

Memory:   This shows the total memory available in the host system, the amount used and 
          the percent free. When looking at the amount of free memory is is important not 
          to just look at "free", but to look at free+buffers+cached. This is because the
          system does not want to waste unused memory, when there are ways to take advantage of it.
          The system uses free memory to "cache" information that was requested from disk. Once it
          reads information from disk is keeps it in memory just in case something requests the data
          again. Since memory access if much faster than disk access, this can really speed up
          processing. If memory is needed for another application, then the system releases 
          some of this cached data and assign the memory to the requesting application. 
          
          The command(s) used:
		  free -k
          cat /proc/meminfo

Application:
          This allows the user to enter an application name. The utility will then search
		  the results of the ps command and display memory information about all instances
		  of that application found.
		  PID: Process ID
		  PPID: Parent Process ID
		  RSZ: Resident memory size (Amount of RAM the application is using)
		  VSZ: Virtual memory size (Amount of total memory the application needs RAM+DISK)

          An application can exist in RAM (Resident memory) or in RAM and disk (Virtual memory). If
          the application can execute only in RAM then if can run very fast. If the application
          requires more memory than what is available it has 2 choices:
           1) The system can reduce the disk cache and give that memory to the application.
           2) Page out some of the memory information to disk of the least used memory for
              that application. Since the CPU can only work on data that is in RAM, it will
              need to "page" or "swap" data from the DISK to RAM (resident memory). 
              Since not all of the data usually needs to by worked on all at once, this usually 
              does not cause a noticeable slow down to the user.  When the application needs to 
              constantly grab the data from disk (constantly swapping data from RAM to DISK and
              DISK to RAM), this is when the system can slow down.

		  The command used is:
          ps -eo pid,ppid,user,\%mem,rss,size,vsz,cmd | grep <appName> 

          If there is more that one process running of the same name and it is necessary to 
          locate the specific window, there are a few things that can be tried. These suggestions
          may be more helpful for some types of applications than others.

          1) Check the date or compare start date to other processes of same name
               ps up <PID>
               ps auxw | grep -i -E "PID|<process name>" 
          2) To find the directory the process way started from: 
             ls -l /proc/<PID>/cwd  
          3) To find the full command used to start the process:
             cat /proc/<PID>/cmd  
          4) Perform the previous commands on the Parent process
             ls -l /proc/<PPID>/cwd  
             cat /proc/<PPID>/cmd  

Disk Information:
		  This displays information about all disks being used. By default the users 
		  home disk will be displayed. If the user has the \$PROJECT environment variable
		  set, this utility will search the \$HOME/work_area/\$PROJECT area and locate all
		  work block disks being used and display information about them also. Where
		  possible, buttons called "usage" and "today" will also be available to display the
		  .usage and today files that exists at the top of each disk.

		  The disk information is gathered by:
		  df <path>



Warning: There are a lot of chances for this script to not work correctly. It relies on 
gathering information from the report of Unix commands. Different versions of Unix may have
slightly different versions of the output.

HERE
;
$HELPINFO =~ s/\t/    /g; # Replace tabs with 4 spaces

# Prints hash, array ,hash of hash, or any combination. Optional 2nd arg is the name of the hash
# usage example: printAny(\%data,"data");
#                printAny(\@data,"data");
sub printAny {
	my ($data,$dataname)=@_;
	my ($key,$index)=(undef) x 2;
	if(ref $data eq "ARRAY"){
		if($dataname eq "" && ref $data eq "ARRAY"){
			$dataname="ARRAY";
		}
		for($index=0;$index<=$#{@$data};++$index){
			if(ref $$data[$index] eq "HASH"){
				&printAny(\%{$$data[$index]},"$dataname\[$index\]");
			}elsif(ref $$data[$index] eq "ARRAY"){
				&printAny(\@{$$data[$index]},"$dataname\[$index\]");
			}else{
	 			print STDERR "$dataname\[$index\]=$$data[$index]\n";
			}
		}
	}
	if(ref $data eq "HASH"){
		if($dataname eq "" && ref $data eq "HASH"){
			$dataname="HASH";
		}
		foreach $key (keys %$data){
			if(ref $$data{$key} eq "HASH"){
				&printAny(\%{$$data{$key}},"$dataname\{$key\}");
			}elsif(ref $$data{$key} eq "ARRAY"){
				&printAny(\@{$$data{$key}},"$dataname\{$key\}");
			}else{
			 print STDERR "$dataname\{$key\}=$$data{$key}\n";
			}
   	 	}
    }
}


=pod
The following is for Debug
=cut


# can salt the dPrint statements throughout the code and turn them
# on and off with changing the values in the $main::DEBUG Variable
# The first argument can be a key word to specify when the print happens
# If this key is undef , it will always print when debug is on
# usage: dPrint("key","Data to %s","print");
my $deBugOn = sub  {
	my ($level,$string,@args) =@_;
	my($pkg,$file,$line)=caller();
	if(!defined $level || $main::DEBUG eq $level){
		printf(STDERR "-DEBUG- line $line: $string\n",@args);
	}
};
my $deBugOff = sub {};
if(!defined $main::DEBUG || $main::DEBUG eq "") {*dPrint=$deBugOff;} else {*dPrint= $deBugOn;}



sub numerically {$a <=> $b;}
sub reverse_numerically {$b <=> $a;}
############################################################################
############################################################################
#                        generic subroutines
############################################################################
############################################################################

###################################################
#            commaNumber
# Description: This takes a number and converts it to a string
# With commas for easier readability
###################################################
sub commaNumber () {
	my($number)=@_;
	my ($index,$final,$truncated,$remainder)=(undef)x4;
	my @digits=();
    if($UNITS eq "mb"){
        $truncated= int($number/1000);
        $remainder=sprintf("%0.1f",(($number/1000.0)-$truncated));
        $remainder=~s/^[0-9]+\./\./;
    }elsif($UNITS eq "gb"){
        $truncated= int($number/1000000);
        $remainder=sprintf("%0.2f",(($number/1000000.0)-$truncated));
        $remainder=~s/^[0-9]+\./\./;
    }else{
        $truncated= $number;
        $remainder="";
    }
	@digits=split("",sprintf("%d",$truncated));
	for($index=$#digits;$index>=0;--$index){
		if($index >=0 && $index!=$#digits && ($#digits-$index)%3==0){
			$final=",".$final;
		}
		$final=$digits[$index].$final;
	}
	return $final.$remainder;
}

###################################################
#            getColor
# Description: Takes one or more triplets (3 values)
# (value to be tested , color, Condition to test)
# and returns the color specified or black.
# multiple triplets can be specified on teh same line.
###################################################
sub getColor{
    my @colorTrip=@_;
    my ($index,$color,$tmp)=(undef)x3;
    $color="black";
    $index=0;
    while(($index+2)<=$#colorTrip){
        $tmp= "$colorTrip[$index] $colorTrip[$index+1]";
        if((eval $tmp)){
            $color=$colorTrip[$index+2]
        }
        $index +=3;
    }
    return($color);
}

###################################################
#            CREATE MENU
###################################################
sub createMenu(){
    my($title,$commands)=@_;
    my ($count,$cindex)=(undef) x 2;
    my ($title_button,$title_menu,$cascade_menu,$cascade)=(undef) x 4;

    $title_button = $allWindows{MENUBAR}->Menubutton(-text => $title);
    $title_menu = $title_button->Menu(-tearoff=>'0');
    $title_button->pack( -anchor => 'nw', -side => 'left');
    $title_button->configure(-menu => $title_menu);
    $count=0;
    while($count<=$#{@$commands}){
        if(exists $$commands[$count]{CASCADE}){
            $cascade= $title_menu->cascade(-label =>$$commands[$count]{CASCADE});
            $cascade_menu = $title_menu->Menu(-tearoff=>'0');
            $cascade->configure(-menu => $cascade_menu);
        }elsif(exists $$commands[$count]{ADD}){
            $title_menu->add('command', -label =>$$commands[$count]{ADD} ,
                -command => eval($$commands[$count]{COMMAND}) );
        }
        if(exists $$commands[$count]{CASCADE_ADD}){
            $cindex=0;
            while($cindex<=$#{$$commands[$count]{CASCADE_ADD}}){
                $cascade_menu->add('command', -label =>$$commands[$count]{CASCADE_ADD}[$cindex] ,
                    -command => eval($$commands[$count]{CASCADE_COMMAND}[$cindex]) );
                ++$cindex;
            }
        }
        ++$count;
    }
}


###################################################
#            collapseFrame
###################################################
sub collapseFrame{
    my ($labelFrame,$frame)=@_;
    my ($packName)=(undef)x1;
    $packName=$frame."Pack";
    if($allWindows{$packName} == 0){
        $allWindows{$frame}->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'false');
        $allWindows{$labelFrame}->Subwidget("label")->packForget();
        $allWindows{$packName}=1;
    }else{
        $allWindows{$labelFrame}->Subwidget("label")->pack();
        $allWindows{$frame}->packForget();
        $allWindows{$packName}=0;
    }
}











############################################################################
############################################################################
#                        Data collection subroutines
############################################################################
############################################################################

###################################################
#            readMemory
###################################################
sub readMemory {
    my ($data,$line)=(undef)x2;
	my @lines=();
	my @cols=();
        $data=`free -k`;
        @lines=split('\n',$data);
        foreach $line (@lines){
          if($line =~ /^Mem:/){
            @cols=split(' ',$line);
            $MEMFILE{totalMem}=$cols[1];
            $MEMFILE{free} = $cols[3];
            $MEMFILE{buffers} = $cols[5];
            $MEMFILE{cached} = $cols[6];
          }
        }
}

###################################################
#            readLoadAvg
# Description: Read /proc/loadavg file and stores info in hash
###################################################
sub readLoadAvg{
    my ($oneMin,$fiveMin,$fifteenMin,$rest)=(undef)x4;
    if(-e "/proc/loadavg"){
        ($oneMin,$fiveMin,$fifteenMin,$rest)=split(' ',`cat /proc/loadavg`);
        $LOADAVERAGE{oneMin}=$oneMin;
        $LOADAVERAGE{fiveMin}=$fiveMin;
        $LOADAVERAGE{fifteenMin}=$fifteenMin;
    }
}

###################################################
#            readTmpDisk
###################################################
sub readTmpDisk{
    my ($data,$index)=(undef)x2;
	my @lines=();
	my @header=();
	my @cols=();
	$data=`df -k /tmp`;
	@lines=split('\n',$data);
	if ($#lines==1){
		@header=split(' ',$lines[0]);
		@cols=split(' ',$lines[1]);
		for($index=0;$index<=$#cols;++$index){
			$TMPDISK{$header[$index]}=$cols[$index];
		}
	}
}

###################################################
#            readVmstat
# Description: Read /proc/vmstat file and stores info in hash
###################################################
sub readVmstat{
my ($key,$value)=(undef)x2;
    if(-e "/proc/vmstat"){
        open(FILE, "/proc/vmstat")|| die "Can't open: /proc/vmstat";
        while(<FILE>) {
            chomp;
            ($key,$value)=split(' ');
                $VMSTATFILE{$key}=$value;
        }
        close FILE;
    }
    if(!exists $PREVIOUS{pswpin}){
        $PREVIOUS{pswpin}=$VMSTATFILE{pswpin};
        $PREVIOUS{pswpout}=$VMSTATFILE{pswpout};
    }
}
###################################################
#            readStat
# Description: Read /proc/stat file and stores info in hash
###################################################
sub readStat{
    my ($cpu,$user,$nice,$system,$idle,$iowait,$irq,$rest,$total)=(undef)x9;
    if(-e "/proc/stat"){
        open(FILE, "/proc/stat")|| die "Can't open: /proc/stat";
        while(<FILE>) {
            chomp;
            if(/^cpu\s+/){
                ($cpu,$user,$nice,$system,$idle,$iowait,$irq,$rest)=split(' ',$_,8);
            }elsif(/^procs_running\s+([0-9]+)/){
                $STATFILE{"running"}=$1;
            }elsif(/^procs_blocked\s+([0-9]+)/){
                $STATFILE{"blocked"}=$1;
            }
        }
        close FILE;
        if(!exists $STATFILE{user}){
            $STATFILE{"deltaUser"}=0;
            $STATFILE{"deltaNice"}=0;
            $STATFILE{"deltaSystem"}=0;
            $STATFILE{"deltaIdle"}=0;
            $STATFILE{"deltaIowait"}=0;
            $STATFILE{"deltaIrq"}=0;
        }else{
            $STATFILE{"deltaUser"}=$user-$STATFILE{"user"};
            $STATFILE{"deltaNice"}=$nice-$STATFILE{"nice"};
            $STATFILE{"deltaSystem"}=$system-$STATFILE{"system"};
            $STATFILE{"deltaIdle"}=$idle-$STATFILE{"idle"};
            $STATFILE{"deltaIowait"}=$iowait-$STATFILE{"iowait"};
            $STATFILE{"deltaIrq"}=$irq-$STATFILE{"irq"};

            $total=$STATFILE{"deltaUser"}+$STATFILE{"deltaNice"}+$STATFILE{"deltaSystem"}+$STATFILE{"deltaIdle"}+$STATFILE{"deltaIowait"};

            # convert to percent
            $STATFILE{"deltaUser"}=sprintf("%4.2f",($STATFILE{"deltaUser"}/$total)*100);
            $STATFILE{"deltaNice"}=sprintf("%4.2f",($STATFILE{"deltaNice"}/$total)*100);
            $STATFILE{"deltaSystem"}=sprintf("%4.2f",($STATFILE{"deltaSystem"}/$total)*100);
            $STATFILE{"deltaIdle"}=sprintf("%4.2f",($STATFILE{"deltaIdle"}/$total)*100);
            $STATFILE{"deltaIowait"}=sprintf("%4.2f",($STATFILE{"deltaIowait"}/$total)*100);
            $STATFILE{"deltaIrq"}=sprintf("%4.2f",($STATFILE{"deltaIrq"}/$total)*100);
        }
        # Update last stored values
        $STATFILE{"user"}=$user;
        $STATFILE{"nice"}=$nice;
        $STATFILE{"system"}=$system;
        $STATFILE{"idle"}=$idle;
        $STATFILE{"iowait"}=$iowait;
        $STATFILE{"irq"}=$irq;
     }
#     printf("U %d,N %d,S %d,ID %d,IO %d,IRQ %d\n",$STATFILE{"deltaUser"},$STATFILE{"deltaNice"},$STATFILE{"deltaSystem"},$STATFILE{"deltaIdle"},$STATFILE{"deltaIowait"},$STATFILE{"deltaIrq"});

}

###################################################
#            calculateCpuNumber
# To calculate the real CPU count, it is necessary to do the following:
# Look in /proc/cpuinfo file
# for each "processor" 
# Locate "core id" and "physical id" fields
# remove from count any processors that have the same "physical and core id pair.
# 
###################################################
sub calculateCpuNumber {
	my ($count,$item,$pnumber)=(undef)x3;
    my %cpuinfo=();
    my %tmp=();
    my @data=();

    $count=0;
    if(-e "/proc/cpuinfo"){
        open(FILE, "/proc/cpuinfo")|| die "Can't open: /proc/cpuinfo";
        while(<FILE>) {
            chomp;
            @data=split(':');
            $data[0]=~s/^\s+//;
            $data[1]=~s/^\s+//;
            $data[0]=~s/\s+$//;
            $data[1]=~s/\s+$//;
            if($data[0] =~ "processor"){
                $pnumber = $data[1];
            }
            $cpuinfo{$pnumber}{$data[0]}=$data[1];
    #        printf("->%s<->%s<-\n",$data[0],$data[1]);
        }
        close FILE;

        foreach $pnumber (keys %cpuinfo){
            if(exists $cpuinfo{$pnumber}{"core id"} && exists $cpuinfo{$pnumber}{"physical id"}){
                    $tmp{"$cpuinfo{$pnumber}{'physical id'} $cpuinfo{$pnumber}{'core id'}"}=1;
            }else{
                ++$count
            }

        }
        foreach $item (keys %tmp){
            ++$count;
        }
    }
	return($count);
}




############################################################################
############################################################################
#                        Create GUI subroutines
############################################################################
############################################################################
sub createTopFrames{
    $allWindows{EnvironmentFrame} = $allWindows{MAINFRAME}->LabFrame(-labelside=>'acrosstop',-label=> "Environment")
        ->pack(-expand => 'true',-fill => 'x',-pady=>0,-anchor =>"n",-side=>'top');
    $allWindows{ProcessorInfoFrame} = $allWindows{MAINFRAME}->LabFrame(-labelside=>'acrosstop',-label=> "CPU Info")
        ->pack(-expand => 'true',-fill => 'x',-pady=>0,-anchor =>"n",-side=>'top');
    $allWindows{ApplicationFrame} = $allWindows{MAINFRAME}->LabFrame(-labelside=>'acrosstop',-label=> "Application")
        ->pack(-expand => 'true',-fill => 'x',-pady=>0,-anchor =>"n",-side=>'top');
    $allWindows{DiskFrame} = $allWindows{MAINFRAME}->LabFrame(-labelside=>'acrosstop',-label=> "Disks")
        ->pack(-expand => 'true',-fill => 'x',-pady=>0,-anchor =>"n",-side=>'top');
}


###################################################
#            createZombie
###################################################
sub createZombie{
my ($frame,$label,$allFrame)=(undef)x3;

    $allFrame = $allWindows{EnvironmentFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'true');
    $label = $allFrame->Label(-text => "Zombie Processes (All)")->pack(-side => 'left');
    $allWindows{zombieAll} = $allFrame->Label(-text => "",-relief => 'sunken',-anchor => 'w')
        ->pack(-side => 'left',-expand=>'true',-fill =>'x');

    $label = $allFrame->Label(-text => "Zombie Processes ($ENV{USER})")
        ->pack(-side => 'left');
    $allWindows{zombieUser} = $allFrame->Label(-text =>"" ,-relief => 'sunken',-anchor => 'w')
        ->pack( -side => 'left',-expand=>'true',-fill => 'x');
}



###################################################
#            createDisplay
###################################################
sub createDisplay{
    my ($frame,$label)=(undef)x2;
    $frame = $allWindows{EnvironmentFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'true');

    $label = $frame->Label(-text => "Host")->pack(-side => 'left');
    $allWindows{DisplayHost} = $frame->Label(-text => "$ENV{HOST}",-relief => 'sunken',-anchor => 'w')
        ->pack(-side => 'left',-expand=>'true',-fill =>'x');

    $label = $frame->Label(-text => "Host IP")->pack(-side => 'left');
    $allWindows{DisplayHostIP} = $frame->Label(-text => "$ENV{HOST}",-relief => 'sunken',-anchor => 'w')
        ->pack(-side => 'left',-expand=>'true',-fill =>'x');

    $label = $frame->Label(-text => "Display")
        ->pack(-side => 'left');
    $allWindows{DisplayDisplay} = $frame->Label(-text => "$ENV{DISPLAY}",-relief => 'sunken',-anchor => 'w')
        ->pack(-side => 'left',-expand=>'true',,-fill =>'x');
}



###################################################
#            createMemSize
###################################################
sub createMemSize{
    my ($tmpFrame,$label,$labelTotal,$labelUsed,$labelFree)=(undef)x5;
        $tmpFrame = $allWindows{ProcessorInfoFrame}->Frame(-bd =>'0')
            ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'false');
        $label = $tmpFrame->Label(-text => "Memory")
            ->pack(-side => 'left');
        $labelTotal = $tmpFrame->Label(-text => "Total: total $UNITS",-relief => 'sunken')
            ->pack(-side => 'left',-expand=>'false',-fill =>'x');
        $labelUsed = $tmpFrame->Label(-text => "Used: used $UNITS",-relief => 'sunken')
            ->pack(-side => 'left',-expand=>'false',-fill =>'x');
        $labelFree = $tmpFrame->Label(-text => "Total Free: $UNITS",-relief => 'sunken')
            ->pack(-side => 'left',-expand=>'true',-fill =>'x');
        $allWindows{MemTotal}=$labelTotal;
        $allWindows{MemUsed}=$labelUsed;
        $allWindows{MemFree}=$labelFree;
}


###################################################
#            createCpuStats
# Description: Creates initial cpu stats
###################################################
sub createCpuStats{
	my ($frame,$label,$string,$data,$count)=(undef)x5;

    $count=&calculateCpuNumber();
    $frame = $allWindows{ProcessorInfoFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'true');
    $label = $frame->Label(-text => "# of CPU's:")->pack(-side => 'left');
    $string=sprintf(" %d ",$count);
    $label = $frame->Label(-text => $string,-relief =>'sunken')
        ->pack(-side => 'left');

    # Create running, waiting and swap line
    $label = $frame->Label(-text => "  Running",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuRun} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  Waiting",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuWait} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  Swap In",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuSwapIn} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  Swap Out",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuSwapOut} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');

    #Create CPU usage line
    $frame = $allWindows{ProcessorInfoFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'true');
    $label = $frame->Label(-text => "User",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuUserP} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  System",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuSystemP} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  Nice",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuNiceP} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  Idle",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuIdleP} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "  IO Wait",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorInfoCpuIOwaitP} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');

    # Create load average line
    $frame = $allWindows{ProcessorInfoFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'true');
    $label = $frame->Label(-text => "Load Ave/CPU:   1Min: ",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorLoadAve1} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "     5Min:",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorLoadAve5} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
    $label = $frame->Label(-text => "    15Min:",-relief =>'flat')
        ->pack(-side => 'left',-expand=>'false');
    $allWindows{ProcessorLoadAve15} = $frame->Label(-text => "",-relief =>'sunken')
        ->pack(-side => 'left',-expand=>'false');
}

###################################################
#            createApplication
###################################################
sub createApplication{
    my ($tmpFrame,$label)=(undef)x2;

    $tmpFrame = $allWindows{ApplicationFrame}->Frame(-bd =>'0')
        ->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'true');
    $tmpFrame->Label(-text => "Search:")->pack(-side => 'left');
    # Width of entry box used to force the frame to be the correct size
    $label=$tmpFrame->Entry(-relief => 'sunken', -bd => '1', -width => '90',
        -textvariable =>\$appName)->pack(-side => 'left',,-expand=>'false',-fill =>'x');
    $label->bind('<Return>' => sub{\&refreshValues(undef)});

    $allWindows{ApplicationTree}=$allWindows{ApplicationFrame}->
        Scrolled('HList',-columns=>9,-header=>1,-scrollbars=>'osoe',-height=>5)->pack(-side=>'top',-expand=>'true',-fill=>'both');

    #pid,ppid,user,\%mem,\%cpu,rss,size,vsz,start_time,cmd 
    $allWindows{ApplicationTree}->headerCreate(0,-text=>" APPLICATION ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(1,-text=>"    USER    ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(2,-text=>"  PID  ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(3,-text=>"  PPID  ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(4,-text=>"    \%MEM   ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(5,-text=>"    \%CPU   ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(6,-text=>"   RSZ ($UNITS)   ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(7,-text=>"   VSZ ($UNITS)   ",-style=>$allWindows{STYLE}{center});
    $allWindows{ApplicationTree}->headerCreate(8,-text=>"    START   ",-style=>$allWindows{STYLE}{center});

}
###################################################
#            createTmpDiskUsage
###################################################
sub createTmpDiskUsage{
my ($tmpFrame,$label)=(undef)x2;

    $tmpFrame = $allWindows{DiskFrame}->Frame(-bd =>'0')->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'false');
    $label = $tmpFrame->Label(-text => "Tmp Disk")
        ->pack(-side => 'left');
    $allWindows{tmpDiskUsed} = $tmpFrame->Label(-text => "Used: ?$UNITS",-relief => 'sunken')
        ->pack(-side => 'left',-expand=>'false',-fill =>'x');
    $allWindows{tmpDiskAvail} = $tmpFrame->Label(-text => "Available: ?$UNITS",-relief => 'sunken')
        ->pack(-side => 'left',-expand=>'false',-fill =>'x');
    $allWindows{tmpDiskPer} = $tmpFrame->Label(-text => "Percent: ?",-relief => 'sunken')
        ->pack(-side => 'left',-expand=>'true',-fill =>'x');
#    $tmpFrame->pack(-anchor =>"n",-side=>'top',-fill =>'x',-expand=>'false');
}
###################################################
#            createTop10
###################################################
sub createTop10 {
    my ($lbscrollx,$lbscrolly,$textframe,$textframe_folder)=(undef) x 4;
    my ($label,$tmp)=(undef)x2;

    $allWindows{top10FramePack}=1;
    $label = $allWindows{MAINFRAME}->Checkbutton(-text=> 'Top 10');
    $tmp = "sub{\&collapseFrame(\"top10MainFrame\",\"top10Frame\")}";
    $label->configure(-command =>eval($tmp));
    $label->toggle();
    $allWindows{top10MainFrame} = $allWindows{MAINFRAME}->Labelframe(-labelwidget=>$label,-labelanchor=>"nw")
            ->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'false');
    # remove iritating extra label that is created by labelframe
    $allWindows{top10MainFrame}->Subwidget("label")->packForget();



    $allWindows{top10Frame}=$allWindows{top10MainFrame}->Frame(-relief => 'raised',-bd =>'2')
       ->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'false');

    $lbscrollx = $allWindows{top10Frame}->Scrollbar(-activerelief => 'flat', -orient => 'horiz');
    $lbscrollx->pack(-side => 'bottom', -fill => 'x');

    $textframe_folder = $allWindows{top10Frame}->Frame->
        pack(-fill =>"both",-expand =>"true",-anchor =>"nw",-side=>'top');
    $textframe = $textframe_folder->Frame->pack(-side => 'top',-fill =>"both",-expand =>"true");

    $lbscrolly = $textframe->Scrollbar(-activerelief => 'flat', -orient => 'vert');
    $lbscrolly->pack(-side => 'right', -fill => 'y');

    $allWindows{top10textBox}=$textframe->Text(-width =>20, -height =>27, wrap=>"none")->
        pack(-side => 'left',-fill =>"both",-expand =>"true");

    $lbscrollx->configure(-command => ['xview',$allWindows{top10textBox}]);
    $lbscrolly->configure(-command => ['yview',$allWindows{top10textBox}]);

    $allWindows{top10textBox}->configure(-xscrollcommand => ['set',$lbscrollx]);
    $allWindows{top10textBox}->configure(-yscrollcommand => ['set',$lbscrolly]);

}

############################################################################
############################################################################
#                        Update GUI subroutines
############################################################################
############################################################################

###################################################
#            updateMemSize
###################################################
sub updateMemSize{
    my ($freeMem,$total,$used,$freeTotal,$color)=(undef)x5;

    $total = &commaNumber($MEMFILE{totalMem});
    $freeMem=$MEMFILE{free}+$MEMFILE{buffers}+$MEMFILE{cached};
    $used = &commaNumber($MEMFILE{totalMem}-$freeMem);
    $freeTotal=&commaNumber($freeMem);
    $allWindows{MemTotal}->configure(-text => "Total: $total $UNITS");
    $allWindows{MemUsed}->configure(-text => "Used: $used $UNITS");

    $color=&getColor(($freeMem/$MEMFILE{totalMem}),"<0.10","red");
    $allWindows{MemFree}->configure(-text => "Total Free: $freeTotal $UNITS", -fg=>$color);
}

###################################################
#            updateCpuStats
# Description: Updates cpu stats
###################################################
sub updateCpuStats{
	my ($si,$so,$color,$count)=(undef)x4;
    my ($one,$five,$fifteen)=(undef)x3;

    $count=&calculateCpuNumber();

    $allWindows{ProcessorInfoCpuUserP}->configure(-text => $STATFILE{"deltaUser"}."%");
    $allWindows{ProcessorInfoCpuNiceP}->configure(-text => $STATFILE{"deltaNice"}."%");
    $allWindows{ProcessorInfoCpuSystemP}->configure(-text => $STATFILE{"deltaSystem"}."%");

    $color=&getColor($STATFILE{"deltaIdle"},"<70.0","red");
    $allWindows{ProcessorInfoCpuIdleP}->configure(-text => $STATFILE{"deltaIdle"}."%", -fg=>$color);

    $color=&getColor($STATFILE{"deltaIowait"},">10.0","red");
    $allWindows{ProcessorInfoCpuIOwaitP}->configure(-text => $STATFILE{"deltaIowait"}."%", -fg=>$color);

    $si=$VMSTATFILE{pswpin}-$PREVIOUS{pswpin};
    $so=$VMSTATFILE{pswpout}-$PREVIOUS{pswpout};
    $PREVIOUS{swapinDelta}=$si;
    $PREVIOUS{swapoutDelta}=$so;
    $PREVIOUS{pswpin}=$VMSTATFILE{pswpin};
    $PREVIOUS{pswpout}=$VMSTATFILE{pswpout};
    $allWindows{ProcessorInfoCpuRun}->configure(-text => $STATFILE{"running"});
    $allWindows{ProcessorInfoCpuWait}->configure(-text => $STATFILE{"blocked"});
    $color=&getColor( $si,"<200","orange",
                    $si,"<50","black",
                    $si,">=200","red");
    $allWindows{ProcessorInfoCpuSwapIn}->configure(-text => $si, -fg=>$color);
    $color=&getColor($so,"<200","orange",
                    $so,"<50","black",
                    $so,">=200","red");
    $allWindows{ProcessorInfoCpuSwapOut}->configure(-text => $so, -fg=>$color);


    $one=$LOADAVERAGE{oneMin}/$count;
    $color=&getColor($one,">=2","red");
    $allWindows{ProcessorLoadAve1}->configure(-text => $one, -fg=>$color);

    $five=$LOADAVERAGE{fiveMin}/$count;
    $color=&getColor($five,">1.5","orange",$five,">=2","red");
    $allWindows{ProcessorLoadAve5}->configure(-text => $five, -fg=>$color);

    $fifteen=$LOADAVERAGE{fifteenMin}/$count;
    $color=&getColor($fifteen,">=1.0","orange",$fifteen,">=2","red");
    $allWindows{ProcessorLoadAve15}->configure(-text => $fifteen, -fg=>$color);
}

###################################################
#            updateDisplayBox
###################################################
sub updateDisplayBox {
    my ($printData)=@_;
    my ($frame,$label,$hostFrame,$displayFrame)=(undef) x 4;
    my ($file,$found,$display,$ip,$displayDisplay,$displayHost)=(undef) x 6;
    my @data=();
    my @allFiles=();

    # Check if display variable is set to a VNC session or if it is redirected.
    $display = $ENV{DISPLAY};
    $display =~ s/\.[0-9]+$//; # strip off any .# at the end of the display

    $displayHost=$display;
    $displayHost =~ s/\:.+$//;

    # Check if display is using a IP instead of hostname
    if($displayHost =~ /^[0-9:.]+$/){
        $displayDisplay = $display;
        $displayDisplay =~ s/^.+:/:/;

        $ip=`host $displayHost`;
        @data=split(' ',$ip);
        $data[$#data]=~s/\.$//; # remove "." at end of line
        $display = $data[$#data] . $displayDisplay;
    }
    $display =~ s/\..+:/:/; # strip of any system path info

    $found=0;
    opendir(DIR, "$ENV{HOME}/.vnc");
    my @allFiles = grep /pid/, readdir DIR;
    close(DIR);
    foreach $file (@allFiles){
        $file =~ s/\.pid//;
        $file =~ s/\.[0-9]+$//; # strip off any .# at the end 
        if($file eq $display ){
            $found=1;
        }
    }



   
   # get host IP address
   $ip=`host $ENV{HOSTNAME}`;
   @data=split(' ',$ip);
   $ip=$data[$#data];
   $allWindows{DisplayHostIP}->configure(-text => $ip);


    

    if(defined $printData){
       printf ($printData "%s\n",`date`);
       printf ($printData "HOST and DISPLAY\n");
       printf ($printData "---------------------------------------\n");
       printf ($printData "Host: %s\n",$ENV{HOST});
       printf ($printData "DISPLAY: %s\n",$ENV{DISPLAY});
       if($found==1){
            printf ($printData "A VNC server was found that is associated with DISPLAY variable setting\n");
       }else{
            printf ($printData "Could not find a VNC server associated with DISPLAY variable setting\n");
       }
       printf ($printData "\n\n");
        
    }else{
        $allWindows{DisplayHost}->configure(-text => $ENV{HOST});
        if($found ==1){
            $allWindows{DisplayDisplay}->configure(-text => $ENV{DISPLAY});
        }else{
            $allWindows{DisplayDisplay}->configure(-text => $ENV{DISPLAY}, -fg=> "red");
        }
    }
}


###################################################
#            updateTmpDiskUsage
###################################################
sub updateTmpDiskUsage{
    my ($valueU,$valueA,$valueP,$color)=(undef) x 4;

    $color=&getColor(($TMPDISK{Used}/($TMPDISK{Available}+$TMPDISK{Used})),"> 0.90)","red");
	$valueU=&commaNumber($TMPDISK{Used});
	$valueA=&commaNumber($TMPDISK{Available});
	$valueP=$TMPDISK{'Use%'};
    $allWindows{tmpDiskUsed}->configure(-text => "Used: $valueU $UNITS");
    $allWindows{tmpDiskAvail}->configure(-text => "Available: $valueA $UNITS");
    $allWindows{tmpDiskPer}->configure(-text => "Used: $valueP",-fg=> $color);
}



###################################################
#            getProcessorInfo
# The readStat must be called before calling this routine
###################################################
sub getProcessorInfo{
    my ($printData)=@_;
    my ($count)=(undef)x1;

    $count=&calculateCpuNumber();
    if(defined $printData){
       printf ($printData "CPU and Memory\n");
       printf ($printData "---------------------------------------\n");
       printf($printData "# of CPU's: %d\n",$count);
       printf($printData "Load Ave: 1Min: %4.2f       5Min: %4.2f       15Min: %4.2f\n",
            $LOADAVERAGE{oneMin},
            $LOADAVERAGE{fiveMin},
            $LOADAVERAGE{fifteenMin});
       printf($printData "vmstat Running:%d   Waiting:%d   Swap In:%d   Swap Out:%d\n",$STATFILE{"running"},$STATFILE{"blocked"},$PREVIOUS{"swapinDelta"},$PREVIOUS{"swapoutDelta"});
       printf($printData "User: %d\%    Nice: %d\%    System: %d\%    Idle: %d\%    IOWait: %d\%\n",
                $STATFILE{"deltaUser"},$STATFILE{"deltaNice"},$STATFILE{"deltaSystem"},
                $STATFILE{"deltaIdle"},$STATFILE{"deltaIowait"});
    }else{
        &updateCpuStats();
    }
}



###################################################
#            getZombie
###################################################
sub  getZombie{
    my ($printData)=@_;
    my ($frame,$label,$allFrame,$userFrame,$allCnt,$userCnt)=(undef) x 6;
    my ($tmp) x 1;
	# ps axo pid,user,stat | awk '$3~/Z/ {print}'
	$allCnt = `ps axo pid,user,stat | awk '\$3~/Z/ {print}'|wc -l`;
	chomp($allCnt);
	# ps axo pid,user,stat | awk '$3~/Z/ && $USER {print}'
	$userCnt = `ps axo pid,user,stat | awk '\$3~/Z/ {print}'|grep $ENV{USER}|wc -l`;
	chomp($userCnt);
    if(defined $printData){
        printf ($printData "Zombie Processes (All): %d\n",$allCnt);
        printf ($printData "PID   User   Status       Cmd\n");
        printf ($printData "---------------------------------------\n");
        if($allCnt >0){
            $tmp=`ps axo pid,user,stat,cmd | awk '\$3~/Z/ {print}'`;
            printf($printData "%s\n",$tmp);
        }
        printf($printData "\n");
        printf($printData "Zombie Processes (%s): %d\n",$ENV{USER},$userCnt);
        printf ($printData "PID   User   Status       Cmd\n");
        printf ($printData "---------------------------------------\n");
        if($userCnt >0){
            $tmp=`ps axo pid,user,stat,cmd | awk '\$3~/Z/ {print}'`;
            printf($printData "%s",$tmp);
        }
        printf($printData "\n");
    }else{
        $allWindows{zombieAll}->configure(-text => $allCnt);
        $allWindows{zombieUser}->configure(-text => $userCnt);
    }
}


###################################################
#            getMemSize
###################################################
sub getMemSize{
    my ($printData)=@_;
    my ($total,$used,$free,$freeMem,$freeTotal)=(undef) x 5;

    $total = &commaNumber($MEMFILE{totalMem});
    $freeMem=$MEMFILE{free}+$MEMFILE{buffers}+$MEMFILE{cached};
    $used = &commaNumber($MEMFILE{totalMem}-$freeMem);
    $freeTotal=&commaNumber($freeMem);
    if(defined $printData){
        printf($printData "Memory: Total: %s %s Used: %s %s Total Free: %s %s\n",$total,$UNITS,$used,$UNITS,$freeTotal,$UNITS);
        printf($printData "\n");
    }else{
        &updateMemSize();
    }
}




###################################################
#            getAppMemSize
###################################################
sub getAppMemSize{
    my ($printData)=@_;
    my ($label,$tmpFrame,$total,$used,$free,$data,$child)=(undef) x 7;
    my ($line,$user,$pid,$ppid,$percent,$cpu,$rss,$vsz,$index,$app,$start)=(undef) x 11;
    my ($rColor,$vColor,$rstyle,$vstyle)=(undef)x4;
	my %lines=();
	my @cols=();


    # loop through all apps and find them through the PS command
    foreach $app (split(' ',$appName)){
	    $data=`ps -eo pid,ppid,user,\%mem,\%cpu,rss,size,vsz,start_time,cmd | grep \"$app\" |fgrep -v grep`;
	    @{$lines{$app}}=split('\n',$data);
    }
    if(defined $printData){
        printf($printData "APPLICATION\n");
        printf($printData "-----------------------------------\n");
        foreach $app (keys %lines){
            foreach $line (@{$lines{$app}}){
                @cols=split(' ',$line);
                $pid = $cols[0];
                $ppid = $cols[1];
                $user = $cols[2];
                $percent = $cols[3];
                $cpu = $cols[4];
                $rss = &commaNumber($cols[5]);
                $vsz = &commaNumber($cols[7]);
                $start = $cols[8];
                printf($printData "%s  User:%s  PID:%d PPID:%d  Cpu:%4.2f\%  \%Mem:%4.2f\%  RSZ:%s%s  VSZ:%s%s Start:%s\n",
                $app,$user,$pid,$ppid,$cpu,$percent,$rss,$UNITS,$vsz,$UNITS,$start);
            } 
        } 
        printf($printData "\n");
    }else{
        $allWindows{ApplicationTree}->delete('all');
	    $index=0;
        foreach $app (keys %lines){
           foreach $line (@{$lines{$app}}){
                @cols=split(' ',$line);
                $pid = $cols[0];
                $ppid = $cols[1];
                $user = $cols[2];
                $percent = $cols[3];
                $cpu = $cols[4];
                $rss = &commaNumber($cols[5]);
                $vsz = &commaNumber($cols[7]);
                $start = $cols[8];

                $rColor=&getColor(($cols[5]/$MEMFILE{totalMem}),">0.7","red");
                if($rColor eq "red"){
                    $rstyle= $allWindows{STYLE}{red};
                }else{
                    $rstyle= $allWindows{STYLE}{black};
                }
                $vColor=&getColor(($cols[7]/$MEMFILE{totalMem}),">1.0","red");
                if($vColor eq "red"){
                    $vstyle= $allWindows{STYLE}{red};
                }else{
                    $vstyle= $allWindows{STYLE}{black};
                }

                $allWindows{ApplicationTree}->add($index);
                $allWindows{ApplicationTree}->itemCreate($index,0,-text=>$app,-style=>$allWindows{STYLE}{left});
                $allWindows{ApplicationTree}->itemCreate($index,1,-text=>$user,-style=>$allWindows{STYLE}{left});
                $allWindows{ApplicationTree}->itemCreate($index,2,-text=>$pid,-style=>$allWindows{STYLE}{right});
                $allWindows{ApplicationTree}->itemCreate($index,3,-text=>$ppid,-style=>$allWindows{STYLE}{right});
                $allWindows{ApplicationTree}->itemCreate($index,4,-text=>$cpu,-style=>$allWindows{STYLE}{right});
                $allWindows{ApplicationTree}->itemCreate($index,5,-text=>$percent,-style=>$allWindows{STYLE}{right});
                $allWindows{ApplicationTree}->itemCreate($index,6,-text=>$rss, -style=>$rstyle);
                $allWindows{ApplicationTree}->itemCreate($index,7,-text=>$vsz, -style=>$vstyle);
                $allWindows{ApplicationTree}->itemCreate($index,8,-text=>$start,-style=>$allWindows{STYLE}{right});

              ++$index;
           }
        }
#        if($index >5){
#          $index=5;   
#        }
#        $allWindows{ApplicationTree}->configure(-height=>$index);
    }
}

###################################################
#            getTop10
###################################################
sub getTop10{
    my ($printData)=@_;
    my ($line,$user,$pid,$percent,$cpu,$rss,$vsz,$index,$item,$string,$data)=(undef) x 11;
	my @cols=();
	my @lines=();
    my %memHash=();
    my %cpuHash=();

    if($allWindows{"top10FramePack"} == 1 || defined $printData){
        $data=`ps -eo pid,user,\%mem,\%cpu,cmd`;
        @lines=split('\n',$data);
        for($index=1;$index<=$#lines;++$index){
            @cols=split(' ',$lines[$index]);
            $user = $cols[1];
            $pid = $cols[0];
            $percent = $cols[2];
            $cpu = $cols[3];
            push(@{$memHash{$percent}},sprintf("%5.2f%%  %6d  %10s %s",$percent,$pid,$user,$cols[4]));
       #     push(@{$cpuHash{$cpu}},sprintf("%5.2f%%  %6d  %10s %s",$cpu,$pid,$user,$cols[4]));
        }

        $data=`top -n 1 -b`;
        @lines=split('\n',$data);
        $index=0;
        foreach $line (@lines){
            if($index>0){
                @cols=split(' ',$line);
                $user = $cols[1];
                $pid = $cols[0];
                $cpu = $cols[8];

                if($user ne "root" || $cpu > 0.0){
                    push(@{$cpuHash{$cpu}},sprintf("%5.2f%%  %6d  %10s %s",$cpu,$pid,$user,$cols[11]));
                }
            }
            if($line =~ /^\s*PID\s+USER/){
                $index=1;
            }
        }

        $index=1;
        $string = "Top 10 Memory Users\n";
        $string .= "    %      PID      USER        CMD\n";
        $string .= "--------------------------------------------------\n";
        foreach $percent (sort reverse_numerically keys %memHash){
            foreach $item (@{$memHash{$percent}}){
                if($index<=10){
                $string .= $item . "\n";
                }
                ++$index
            }
        }


        $index=1;
        $string .= "\n";
        $string .= "Top 10 CPU Users\n";
        $string .= "    %      PID      USER        CMD\n";
        $string .= "--------------------------------------------------\n";
        foreach $percent (sort reverse_numerically keys %cpuHash){
            foreach $item (@{$cpuHash{$percent}}){
                if($index<=10){
                $string .= $item . "\n";
                }
                ++$index
            }
        }
        if(defined $printData){
            printf($printData "%s\n",$string);
        }else{
            $allWindows{top10textBox}->delete("1.0","end");
            $allWindows{top10textBox}->insert("end", $string );
        }
    }
}



###################################################
#            getTmpDiskUsage
###################################################
sub getTmpDiskUsage {
    my ($printData)=@_;
    my ($valueU,$valueA,$valueP)=(undef) x 3;
    my ($tmpFrame,$label)=(undef)x2;

    if(!defined $printData){
        if(!exists $allWindows{tmpDiskUsed}){
        }
        &updateTmpDiskUsage();
    }else{
	    $valueU=&commaNumber($TMPDISK{Used});
    	$valueA=&commaNumber($TMPDISK{Available});
    	$valueP=$TMPDISK{'Use%'};
        printf($printData "Tmp Disk\n");
        printf($printData "-----------------------------------\n");
        printf($printData "Used:%s%s   Available:%s%s   Used:%s\n",$valueU,$UNITS,$valueA,$UNITS,$valueP);
        printf($printData "\n");
    }
}

###################################################
#            findTodayFile
###################################################
sub findTodayFile{
	my ($name)=@_;	
	my ($data,$system,$disk,$result)=(undef)x2;
	my @lines=();
	my @cols=();

	$result="";
	$data=`df -P $name`;
	@lines=split('\n',$data);
	@cols=split(' ',$lines[$#lines]);
	($system,$disk)=split(':',$cols[0]);
	if (-e "$cols[5]/.owner/diskcheck/today"){
		$result="$cols[5]/.owner/diskcheck/today";
	}elsif(-e "$disk/.owner/diskcheck/today"){
		$result="$disk/.owner/diskcheck/today";
	}elsif (-e "$disk/../.owner/diskcheck/today"){
		$result="$disk/../.owner/diskcheck/today";
	}else{
        $disk=~ s./vol/homedirs/./nfs/pdx/disks/.;
	    if(-e "$disk/.owner/diskcheck/today"){
		   $result="$disk/.owner/diskcheck/today";
	    }elsif (-e "$disk/../.owner/diskcheck/today"){
		    $result="$disk/../.owner/diskcheck/today";
        }
	}
	return($result);
}
###################################################
#            findUsageFile
###################################################
sub findUsageFile{
	my ($name)=@_;	
	my ($data,$system,$disk,$result)=(undef)x2;
	my @lines=();
	my @cols=();

	$result="";
	$data=`df -P $name`;
	@lines=split('\n',$data);
	@cols=split(' ',$lines[$#lines]);
	($system,$disk)=split(':',$cols[0]);
	if (-e "$cols[5]/.usage"){
		$result="$cols[5]/.usage";
	}elsif(-e "$disk/.usage"){
		$result="$disk/.usage";
	}elsif (-e "$disk/../.usage"){
		$result="$disk/../.usage";
	}else{
        $disk=~ s./vol/homedirs/./nfs/pdx/disks/.;
	    if(-e "$disk/.usage"){
		    $result="$disk/.usage";
	    }elsif (-e "$disk/../.usage"){
	    	$result="$disk/../.usage";
        }
	}
	return($result);
}

sub createAllDiskSize{
    my ($tmp,$label,$index,$tmpFrame)=(undef)x4;
    $allWindows{allDiskFramePack}=1;
    $label = $allWindows{DiskFrame}->Checkbutton(-text=> 'Work Disks');
    $tmp = "sub{\&collapseFrame(\"allDiskTopFrame\",\"allDiskFrame\")}";
    $label->configure(-command =>eval($tmp));
    $label->toggle();

    $allWindows{allDiskTopFrame} = $allWindows{DiskFrame}->Labelframe(-labelwidget=>$label,-labelanchor=>"nw",-padx=>1)
            ->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'true');
    # remove iritating extra label that is created by labelframe
    $allWindows{allDiskTopFrame}->Subwidget("label")->packForget();

    $allWindows{allDiskFrame} = $allWindows{allDiskTopFrame}->Frame()
            ->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'true');

    for($index=0;$index<100;++$index){
        $tmpFrame = $allWindows{allDiskFrame}->Frame(-bd =>'1',-relief=>"sunken");
        push(@{$allWindows{allDiskSubFrame}},$tmpFrame);
        $label = $tmpFrame->Label(-text => "Name: Disk:",-relief => 'flat');
        push(@{$allWindows{allDiskSubName}},$label);
        $label = $tmpFrame->Label(-text => "",-relief => 'flat');
        push(@{$allWindows{allDiskSubDisk}},$label);
        $label =$tmpFrame-> Button(-text => "Today");
        push(@{$allWindows{allDiskTodayButton}},$label);
        $label =$tmpFrame-> Button(-text => "Usage");
        push(@{$allWindows{allDiskUsageButton}},$label);
        $label = $tmpFrame->Label(-text => "",-relief => 'sunken');
        push(@{$allWindows{allDiskSubUsage}},$label);
    }
}

###################################################
#            getAllDiskSize
###################################################
sub getAllDiskSize{
    my ($printData)=@_;
    my ($label,$tmpFrame,$total,$used,$free,$data,$child,$path,$color)=(undef) x 9;
    my ($line,$usage,$percent,$disk,$index,$name,$dir,$subdir,$tmp)=(undef) x 9;
	my @dirs=();
	my @subdirs=();
	my @cols=();
	my @lines=();
	my %hash=();


    $data=`df $ENV{HOME}`;
    @lines=split('\n',$data);
    if($#lines==2){
       @cols=split(' ',$lines[2]);
       $hash{HOME}{usage}=$cols[3];
       $hash{HOME}{usage} =~  s/\%//;
       $hash{HOME}{disk}=$cols[4];
    }

  if(defined $ENV{PROJECT}){
	opendir MYDIR, "$ENV{HOME}/work_area/$ENV{PROJECT}";
	@dirs=readdir MYDIR;
	closedir MYDIR;
	foreach $dir (@dirs){
		if($dir ne "." && $dir ne ".."){
			opendir MYDIR, "$ENV{HOME}/work_area/$ENV{PROJECT}/$dir";
			@subdirs=readdir MYDIR;
			closedir MYDIR;
			foreach $subdir (@subdirs){
				if($subdir ne "." && $subdir ne ".." && -e "$ENV{HOME}/work_area/$ENV{PROJECT}/$dir/$subdir"){
					$data=`df $ENV{HOME}/work_area/$ENV{PROJECT}/$dir/$subdir`;
					@lines=split('\n',$data);
					if($#lines==2){
						@cols=split(' ',$lines[2]);
						$hash{$dir}{usage}=$cols[3];
                        $hash{$dir}{usage} =~ s/\%//;
						$hash{$dir}{disk}=$cols[4];
					}
				}
			}

		}
	}
  }

    if(!defined $printData){
       foreach $child (@{$allWindows{allDiskSubFrame}}){
           $child->packForget();
       }

        $index=0;
        foreach $dir (keys %hash){
            if($index<100){
                $allWindows{allDiskSubFrame}[$index]->pack(-anchor =>"n",-side=>'top',-fill =>'both',-expand=>'true');
                $allWindows{allDiskSubName}[$index]->configure(-text => "WorkBlock: $dir  Disk: $hash{$dir}{disk}");
                $allWindows{allDiskSubName}[$index]->pack(-side => 'left',-expand=>'false',-fill =>'x');
                #This is a blank area that fills the empty space
                $allWindows{allDiskSubDisk}[$index]->configure(-text => "");
                $allWindows{allDiskSubDisk}[$index]->pack(-side => 'left',-expand=>'true',-fill =>'x');

                $path=&findTodayFile($hash{$dir}{disk});
                $tmp = "sub{\&displayUsage(\"$path\",\"$path\")}";
                $allWindows{allDiskTodayButton}[$index]->configure(-command =>eval($tmp));
                $allWindows{allDiskTodayButton}[$index]->pack(-side => 'left',-expand=>'false',-fill =>'x');

                $path=&findUsageFile($hash{$dir}{disk});
                $tmp = "sub{\&displayUsage(\"$path\",\"$path\")}";
                $allWindows{allDiskUsageButton}[$index]->configure(-command =>eval($tmp));
                $allWindows{allDiskUsageButton}[$index]->pack(-side => 'left',-expand=>'false',-fill =>'x');

                
                $color = &getColor($hash{$dir}{"usage"},">90.0","orange",$hash{$dir}{"usage"},">95.0","red");
                $allWindows{allDiskSubUsage}[$index]->configure(-text => "$hash{$dir}{usage}\%",-relief => 'sunken', -fg=>$color);
                $allWindows{allDiskSubUsage}[$index]->pack(-side => 'left',-expand=>'false',-fill =>'x');
             }
             ++$index;
        }
    }else{
        printf($printData "Disk Usage\n");
        printf($printData "-----------------------------------\n");
        foreach $dir (keys %hash){
            printf($printData "WorkBlock:%s   Disk:%s   Used:%s%s\n",$dir,$hash{$dir}{disk},$hash{$dir}{usage},"%");
        }
        printf($printData "\n");
    }
}


###################################################
#            displayText
###################################################
sub displayText{
    my ($title,$string)=@_;
    my $help = $allWindows{TOP}->Toplevel;
    $help->configure(-title => $title);
    $help->geometry("+" . $allWindows{TOP}->rootx() . "+" . $allWindows{TOP}->rooty());
    my ($hframe,$ButtonFrame, $lbscrollx,$lbscrolly,$textbox,
        $textframe_folder,$textframe,$index,$line)=(undef)x9;
    my ($width,$height)=(0) x 2;
    my @tmp=();
    $hframe = $help->Frame;
    $hframe->pack(-fill =>'both' , -expand => 'true');


    @tmp=split('\n',$string);
    foreach $line (@tmp){
        if($width <length($line)){
            $width=length($line);
        }
    }
    $width += 3;
    $height = $string =~ s/\n/\n/g;
    if($height > 30){
        $height=30;
    }

    $ButtonFrame = $hframe->Frame->pack(-anchor =>"s",-fill =>"x",-side =>"bottom");

    $lbscrollx = $hframe->Scrollbar(-activerelief => 'flat', -orient => 'horiz');
    $lbscrollx->pack(-side => 'bottom', -fill => 'x');

    $textframe_folder = $hframe->Frame->
           pack(-fill =>"both",-expand =>"true",-anchor =>"nw",-side=>'top');
    $textframe = $textframe_folder->Frame->pack(-side => 'top',-fill =>"both",-expand =>"true");

    $lbscrolly = $textframe->Scrollbar(-activerelief => 'flat', -orient => 'vert');
    $lbscrolly->pack(-side => 'right', -fill => 'y');

    $textbox=$textframe->Text(-width =>$width, -height => $height)->
        pack(-side => 'left',-fill =>"both",-expand =>"true");

    $lbscrollx->configure(-command => ['xview',$textbox]);
    $lbscrolly->configure(-command => ['yview',$textbox]);

    $textbox->configure(-xscrollcommand => ['set',$lbscrollx]);
    $textbox->configure(-yscrollcommand => ['set',$lbscrolly]);

    $textbox->insert("end", $string );

    $ButtonFrame->Button(-text =>"Close",
            -command => sub{destroy $help})-> pack(-side =>"right");
    $help->waitWindow;
}
###################################################
#            displayUsage
###################################################
sub displayUsage{
    my ($title,$string)=@_;
    my $help = $allWindows{TOP}->Toplevel;
    $help->configure(-title => $title);
    $help->geometry("+" . $allWindows{TOP}->rootx() . "+" . $allWindows{TOP}->rooty());
    my ($hframe,$ButtonFrame, $lbscrollx,$lbscrolly,$textbox,
        $textframe_folder,$textframe,$index,$line,$usage)=(undef)x10;
    my ($width,$height)=(0) x 2;
    my @tmp=();
    $hframe = $help->Frame;
    $hframe->pack(-fill =>'both' , -expand => 'true');

	if(-e "$string"){
		$usage=`cat $string`;
	}else{
	$usage="Unable to locate .usage file\n"
	}

    @tmp=split('\n',$usage);
    foreach $line (@tmp){
        if($width <length($line)){
            $width=length($line);
        }
    }
    $width += 3;
    $height = $usage =~ s/\n/\n/g;
    if($height > 30){
        $height=30;
    }

    $ButtonFrame = $hframe->Frame->pack(-anchor =>"s",-fill =>"x",-side =>"bottom");

    $lbscrollx = $hframe->Scrollbar(-activerelief => 'flat', -orient => 'horiz');
    $lbscrollx->pack(-side => 'bottom', -fill => 'x');

    $textframe_folder = $hframe->Frame->
           pack(-fill =>"both",-expand =>"true",-anchor =>"nw",-side=>'top');
    $textframe = $textframe_folder->Frame->pack(-side => 'top',-fill =>"both",-expand =>"true");

    $lbscrolly = $textframe->Scrollbar(-activerelief => 'flat', -orient => 'vert');
    $lbscrolly->pack(-side => 'right', -fill => 'y');

    $textbox=$textframe->Text(-width =>$width, -height => $height)->
        pack(-side => 'left',-fill =>"both",-expand =>"true");

    $lbscrollx->configure(-command => ['xview',$textbox]);
    $lbscrolly->configure(-command => ['yview',$textbox]);

    $textbox->configure(-xscrollcommand => ['set',$lbscrollx]);
    $textbox->configure(-yscrollcommand => ['set',$lbscrolly]);

    $textbox->insert("end", $usage );

    $ButtonFrame->Button(-text =>"Close",
            -command => sub{destroy $help})-> pack(-side =>"right");
    $help->waitWindow;
}




###################################################
#            loopRefresh
# Description: sets up endless loop
###################################################
sub loopRefresh {
    my $index=0;
    &refreshValues(undef);
    $allWindows{TOP}->after(10000 => sub{\&loopRefresh(undef)});
}

###################################################
#            printValues
# Description: Prints all data by calling refreshyy
# Also need to call createDisplay because this data is not refreshed
###################################################
sub printValues () {
    
    my $fh = *STDOUT;
    &updateDisplayBox($fh);
    &refreshValues($fh);
}
###################################################
#            refreshValues
# Description: Calls all to level rotines to refresh data
###################################################
sub refreshValues () {
my ($printInfo)=@_;
    &readStat();
    &readMemory();
    &readVmstat();
    &readLoadAvg();
    &readTmpDisk();
	&getZombie($printInfo);
	&getProcessorInfo($printInfo);
	&getMemSize($printInfo);
	&getAppMemSize($printInfo);
	&getTmpDiskUsage($printInfo);
	&getAllDiskSize($printInfo);
    &getTop10($printInfo);
}








#######################################################
#######################################################
#                       MAIN
#######################################################
#######################################################

my @infiles=();
my ($infile)=("")x1;
my ($outfile,$MENUBAR,$MAINFRAME,$tmp)=(undef)x4;
my ($command)=(undef)x1;
my @File_Button=();


&dPrint(undef,"In DEBUG Mode:");  

print STDERR "IN $0: @ARGV\n";
#$ARGV[0]= "-help"  if $#ARGV <0; # displays help message id no args are defined
while ($ARGV[0]){
    if ($ARGV[0] =~ /^-h(.*)/){  #
        print STDERR "$help_message";
        exit 1;
    }elsif($ARGV[0] =~ /^-g(.*)/){ #
        $UNITS="gb";
    }elsif($ARGV[0] =~ /^-m(.*)/){ #
        $UNITS="mb";
    }elsif($ARGV[0] =~ /^-k(.*)/){ #
        $UNITS="kb";
    }elsif($ARGV[0] =~ /^-v(.*)/){ #
		print "$scriptName: $VERSION\n";
		exit;
    }elsif($ARGV[0] =~ /^-a(.*)/){ #
        shift;
        $appName= $ARGV[0];
    }else{
		push(@infiles,$ARGV[0]);
    }
    shift;
}

if (defined $outfile){
	open(OUTFILE, ">$outfile")|| die "Can't open:  $outfile";
	select(OUTFILE);
}

    $allWindows{TOP} = new MainWindow;

    # I need to do this because I can not get the quit function to work with a hash reference
    $TOP=$allWindows{TOP};

    $allWindows{TOP}->configure(-title => "$0 $VERSION");

    # Allows the user to resize the window in the Y direction.
    #$allWindows{TOP}->resizable('false','false');
    $allWindows{TOP}->resizable('true','true');
    $allWindows{TOP}->after(5000 => sub{\&loopRefresh()});

    # These are needed to set the HLIST box colors
    $allWindows{STYLE}{center}= $allWindows{TOP}->ItemStyle('text',-justify=>'center');
    $allWindows{STYLE}{left}= $allWindows{TOP}->ItemStyle('text',-justify=>'left');
    $allWindows{STYLE}{right}= $allWindows{TOP}->ItemStyle('text',-justify=>'right');
    $allWindows{STYLE}{red}= $allWindows{TOP}->ItemStyle('text',-fg=>"red",-justify=>'right');
    $allWindows{STYLE}{black}= $allWindows{TOP}->ItemStyle('text',-fg=>"black",-justify=>'right');
    $allWindows{STYLE}{orange}= $allWindows{TOP}->ItemStyle('text',-fg=>"orange",-justify=>'right');

    #--- Build top level frame ---
    $MENUBAR = $allWindows{TOP}->Frame(-relief => 'raised', -bd => '2');
	$MENUBAR->pack(-anchor => 'n', -fill => 'both',-side => 'top');
  	$MENUBAR->pack(-anchor => 'n', -fill => 'both',-side => 'top');
	$allWindows{MENUBAR}=$MENUBAR;

    $MAINFRAME = $allWindows{TOP}->Frame(-relief => 'raised', -bd => '2');
	$allWindows{MAINFRAME}=$MAINFRAME;
    $MAINFRAME->pack(-anchor => 'n', -fill => 'x',-side => 'top',-expand=>'true');

	
    $File_Button[0]{ADD}="Print";
	$command = "\'sub{&printValues()}\'";
    $File_Button[0]{COMMAND}=eval($command);
    $File_Button[1]{ADD}="Quit";
	$File_Button[1]{COMMAND}='sub{destroy $TOP}';
    &createMenu("File",\@File_Button);
    $MENUBAR->Button(-text =>"Help", -command => sub{&displayText("Help",$HELPINFO)})-> pack(-side =>"right");

    &createTopFrames();
    &createApplication();
    &createDisplay();
    &createZombie();
    &createCpuStats();
    &createMemSize();
    &createTmpDiskUsage();
    &createAllDiskSize();
    &createTop10();

	&updateDisplayBox(undef);
	&refreshValues(undef);
	MainLoop;


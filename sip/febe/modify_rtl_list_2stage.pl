#!/usr/bin/env /usr/intel/pkgs/perl/5.14.1/bin/perl
use strict ;
use File::chdir;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use IPC::Open3;

##This script converts 1 stage filelist into 2 stage filelist format, the script expects the rtl_list.tcl to be present under $WARD/collaterla/rtl/rtl_list.tcl

my ($CTECH_TYPE, $CTECH_VARIANT) = @ARGV;
unless ($CTECH_TYPE and $CTECH_VARIANT) {
  die "Arguments: rtl_list_2stage.tcl <ctech lib type> <ctech lib variant>\n"
}
my $twostagefile = "$ENV{WARD}/collateral/rtl/rtl_list_2stage.tcl";
my $in_ctech_glob = 0;
if(-e $twostagefile ) {
   open(my $fh,"<$twostagefile")or die "Unable to open the file :$!\n";
   while(<$fh>) {
     last if($_ =~ /Converted by 1 stage to 2stage rtl_converter/);
   }
} else {
   
   open FH, "<$ENV{WARD}/collateral/rtl/rtl_list.tcl" or die $!;
   my @file_contents = <FH>;
   close(FH);
   
   open(my $fh1,">$twostagefile") or die $!;
   #Prints the Header on the converted filelists 
   print $fh1 "\#\#Converted by 1 stage to 2stage rtl_converter\n";
   foreach(@file_contents) {
      $_ =~ s/VERILOG_CTECH_FILES_REM/VERILOG_CTECH_FILES_REM_1/g;
      $_ =~ s/VERILOG_CTECH_FILES_ADD/VERILOG_CTECH_FILES_ADD_1/g;
      $_ =~ s/VERILOG_SOURCE_FILES/VERILOG_SOURCE_FILES_1/g;
      $_ =~ s/VHDL_SOURCE_FILES/VHDL_SOURCE_FILES_1/g;
      $_ =~ s/search_path/G_RTL_SEARCH_PATH_1/g;
      $_ =~ s/lappend RTL_DEFINES/lappend RTL_DEFINES_1/g;
      if (/if \{\[info exist CTECH_TYPE\]\s+/) {
        $in_ctech_glob = 1;
        print $fh1 qq(set CTECH_TYPE $CTECH_TYPE\n);
        print $fh1 qq(set CTECH_VARIANT $CTECH_VARIANT\n\n);
      }
      elsif (/set VERILOG_CTECH_FILES_REM_1 \[ lsort/) {
        $in_ctech_glob = 0;
        $_ = "# $_"
      }
      $_ = "# $_" if $in_ctech_glob;
      print $fh1 $_;
      if ($in_ctech_glob and /concat \$VERILOG_CTECH_FILES_(ADD|REM)_1 (\[glob \/\{\S+\])\]\s*$/) {
        my $add_or_rem = $1;
        my $tcl_addrem = $2;
        $tcl_addrem =~ s/(\$CTECH_(TYPE|VARIANT))/$1/eeg;
        #print "$tcl_addrem\n";
        my $tclsh = qq(/usr/intel/bin/tclsh);
        my $pid = open3(*TCLSH_IN, *TCLSH_OUT, 0, $tclsh);
        print TCLSH_IN qq(puts $tcl_addrem\n);
        close(TCLSH_IN);
        my @outlines = <TCLSH_OUT>;
        close(TCLSH_OUT);
        foreach my $outline (@outlines) {
          if ($outline =~ /no files matched glob pattern/) {
            print $fh1 "\n# ERROR: No files matched ctech glob pattern with CTECH_TYPE=${CTECH_TYPE} CTECH_VARIANT=${CTECH_VARIANT}. Check settings and group permissions for library\n\n";
          } else {
            my @ctech_sv_list = split (/\s+/, $outline);
            foreach my $ctech_sv (sort @ctech_sv_list) {
              print $fh1 "lappend VERILOG_CTECH_FILES_${add_or_rem}_1 $ctech_sv\n";
            }
          }
        }
        waitpid($pid, 0);
        if ($?) {
          die "rtl_list_2stage.tcl tclsh exited with status of $?\n";
        }
      }
   }
   print $fh1 "global i_numips\n";
   print $fh1 "set i_numips 1\n";
   print $fh1 "set G_DISABLE_SUFFIX_LIB 1\n";
   my $cmd1 = 'sed -ie \' s/\(.*set.*RTL_DEFINES.*\)/set IP_MODULE_NAME_1 \"WORK\"\nset IP_INST_NAME_1 \"WORK\" \n\1/ig\''; 
   my $cmd2 = "$cmd1 $twostagefile";
   system($cmd2);
}



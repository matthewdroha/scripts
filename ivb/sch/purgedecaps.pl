#! /usr/intel/bin/perl5.85

############## Intel Corporation Confidential information. ############
#                                                                     #
#              Intel  confidential		                      #
#                                                                     #
# This listing is supplied under the terms of a  license  agreement   #
# with Intel Corporation and may not be copied nor disclosed except   #
# in accordance with the terms of the agreement.                      #
#                                                                     #
############## Intel Corporation Confidential information. ############

###############################################################################
#                         Intel Confidential
###############################################################################
# New Version of purgedecap
# Modified by Ofer Meiri (omeiri) MMG/Design May 2007
# New version iclude purging of dummy devices (SRC=DRN=GATE)
# And option to use skip-cell-device
#
#
###############################################################################
# RCS:
# $Author: mroha $
# $Header: /mpg/gwa/mroha/cvsroot/ivb/sch/purgedecaps.pl,v 1.1 2010/01/08 19:57:25 mroha Exp $
###############################################################################

##### Default setting
$DEBUG = 1;


print "***************************************\n",
      "* Running purgedecap to filter decap  *\n",
      "* and other passive elements          *\n",
      "***************************************\n";    
  

### Define cell with device type NOT to filter 
%SKIP_CELL = (
	#'template' => 'gnac decap dummy bjtdiode all'
);


### Define cells to filter all theirs devices
%BLACK_BOX = (
	#'template' => 'something'
);


### Define list of device to filter
%FILTER_DEVICE = (
	'DECAP' => [
		#'SRC GATE DRN DEV_TYPE',
		'VSS VCC VSS  N',
		'VSS VCC VSS  NLL',	
		'VCC VSS VCC  P',
		'VCC VSS VCC  PLL',	
		'VSS VCCP VSS N',
		'VSS VCCP VSS NLL',		
	],
	
	'DUMMY' => [
		#'SRC GATE DRN DEV',
		'VSS VSS VSS N',  
		'VSS VSS VSS NLL',
		'VCC VCC VCC P',
		'VCC VCC VCC PLL',
		'VCCP VCCP VCCP PAL',	
		'VCCA VCCA VCCA PAL',	
	],
	
	'GNAC'     => ['* VSS VSS NGATEDNAC'],	
	'BJTDIODE' => ['* * * BJTDIODE'],
);



### default options
$purge_decap    = "yes";
$purge_gnac     = "yes";
$purge_dummy    = "yes"; #purge dummy device
$purge_bjtdiode = "no";
$remove_empty   = "no";

#$power = "vcc";
#$ground = "vss";
$netlist = "";
$output_netlist = "";
$command_file = "";

### Get ARGV options
&usage("-E- Unspecified LN/SN file!\n") unless $ARGV[0];

for (my $i = 0;  $i < scalar @ARGV; $i++) {
	$_ = $ARGV[$i];
	my $val = $ARGV[++$i];
	if (/^-h/i) {
		&usage;
	} elsif (/^-debug/i) {
		$DEBUG = 1;
	} elsif (not $val) {
		&usage("-E- Missing value for the option: $_\n");	
	} elsif (/^-decap/i) {
		$purge_decap = lc $val;
	} elsif (/^-gnac/i) {
		$purge_gnac = lc $val;		
	} elsif (/^-dummy/i) {
		$purge_dummy = lc $val;		
	} elsif (/^-bjtdiode$/) {
		$purge_bjtdiode = lc $val;
	} elsif (/^-lnout/i) {
		$output_netlist = $val;
	} elsif (/^-ln/i) {			
		$netlist = $val;		
	} elsif (/^-cmdfile/i) {
 		$command_file = $val;	
	} elsif (/^-rmempty/i) {
		$remove_empty = $val;
	} 
	else {
		&usage("-E- Unknown option: $_\n");
	}	
}

### open debug file
if ($DEBUG) {
	$debug_file = "purgedecap.debug_info";
	if (open (DEBUG_FILE, ">$debug_file")) {
		print DEBUG_FILE "### Debug information for purge decap ###\n",
		                 "LN file: $netlist\n";
	} else {
		print "-E- can't open the debug file:$debug_file\n($!)\n";
		$DEBUG = 0; 
	} 
} 
### Check the user input
$err .= "";
$err .= "-E- Can't find the netlist file: $netlist\n" unless -r $netlist;
$err .= "-E- Can't find the command file: $command_file\n" if $command_file and not -r $command_file;
die "-E- purgedecap aborted! due to:\n$err\n" if $err;

        

### Load the command file
if ($command_file) {
	print "purgedecap: Using alternative command file: $command_file\n";
	require $command_file;
}
&prepare_filter_table(); #pre-processing of filter tables
    
my $info = << "END_INFO";
purgedecap options:
% Purging decap        = $purge_decap
% Purging gnac         = $purge_gnac
% Purging BJT diodes   = $purge_bjtdiode
% Purging empty cells  = $remove_empty
% Purging dummy device = $purge_dummy
END_INFO

print "$info\n";
print DEBUG_FILE "$info\n\n";

	
### set purge option
$purge_decap     = 0 unless $purge_decap    eq "yes";
$purge_gnac      = 0 unless $purge_gnac     eq "yes";
$purge_dummy     = 0 unless $purge_dummy    eq "yes";
$purge_bjtdiode  = 0 unless $purge_bjtdiode eq "yes";
$remove_empty    = 0 unless $remove_empty    eq "yes";


# Now for each netlist do the purging.
print "purgedecap: Start time: ", `/bin/date`;
print "-I- Reading netlist file: $netlist\n";

# No need to save the original anymore because the output file is of
# diffent name & we are not modifying the original (only reading).
if (not open (NETLIST, "<$netlist")) {
	print "\npurgedecaps.pl:\n -E- Cannot open $netlist for read\n $! \n";
	exit 1;
}

### output file    
my $purge_file = "${netlist}.purged";
my @file_path = split "/", $netlist;
$purge_file = "$file_path[$#file_path].purged" if  $file_path[$#file_path];
$purge_file = $output_netlist if $output_netlist; #use user output name

print "-I- Writing purging LN/SN file: $purge_file\n";
if (not open (NEWNETLIST, ">$purge_file")) {
	print "\npurgedecaps.pl:\n -E- Cannot open $purge_file for write\n $! \n";
	exit 1;
}

### print header 	  	
$date = scalar localtime ;
print NEWNETLIST "\$\$\$########################################################\n",
				 "\$\$\$#     Modified by purgedecaps.pl\n",
				 "\$\$\$#     On $date by $ENV{'USER'}\n",
				 "\$\$\$########################################################\n\n";

### Parase and filter the net-list file		
my $line = "";
my @line_buffer = ();
my $line_num = 0;
@output_netlist = ();
$CURRENT_MACRO = "";   #global variable for the current cell name
%CELL_DEV_COUNT = ();  #device/instances count for each cell

@debug_info = (); #for debug;

while (defined ($line = <NETLIST>)) {
	$line_num++;	
	if ($line =~ m/^\s*\+/ or (not scalar @line_buffer)) { #buffer continues line
		push (@line_buffer, $line);	
		next;
	} else {	
		&print_buffer(@line_buffer);
		@line_buffer = ($line);
	}
	
}#while file
&print_buffer(@line_buffer) if scalar @line_buffer; #print rest of lines (last line)
close NEWNETLIST;
close NETLIST;


$runtime = time - $^T;
$hours = int ($runtime / 3600);
$hours = "0${hours}" if $hours < 10;
$runtime = $runtime - ($hours * 3600);
$minutes = int ($runtime / 60);
$minutes = "0${minutes}" if $minutes < 10;
$seconds = $runtime - ($minutes * 60);
$seconds = "0${seconds}" if $seconds < 10;
print "purgedecap: Overall runtime: ${hours}:${minutes}:${seconds}\n";

close DEBUG_FILE if $DEBUG;
exit 0;



################### print_buffer #########################
#
# Print the lines in buffer unless line should be filtered
#
sub print_buffer
{
	my (@lines) = @_;	
	my $line = join " ", @lines;
	$line =~ s/\n|\+/ /g;	
	if(&filter_line(uc $line)) {
		print DEBUG_FILE "-D- Cell $CURRENT_MACRO purging: $line\n" if $DEBUG;	
		return;	
	}
	my @write_buffer = ();
	
	$CELL_DEV_COUNT{$CURRENT_MACRO}++ if $line =~ /^\@|^\w/i;		
	foreach my $l (@lines) {
		push @write_buffer, "$l";				
	}
	print NEWNETLIST @write_buffer;
}
	
############ filter_line #################
#
# Check if this line should be filter-out
# Base on the filtering mode
# Return TRUE/FALSE (1 or 0)
#	
sub filter_line 
{	
	my ($line) = @_;
	if ($line =~ /\.macro\s+(\S+)/i) {
		$CURRENT_MACRO = uc $1 if $1;
        return 0;
	} elsif ($line =~ /^\s*\$|^\s*$/i) { #skip comment or empty line
		return 0;
	}
	
	
	### Check devices filter
	if ($line =~ m/^[\w]\S*/) {		
		return 1 if $BLACK_BOX{$CURRENT_MACRO}; #filter all devices in this template
		return 0 if $SKIP_CELL{$CURRENT_MACRO}{'all'};
		
		$line =~ s/\(\d+\)//g;
		my ($dev_name, $src, $gate, $drn, $bulk, $dev_type, @others) = split /\s+/, $line;		
				
		### Filter gated_nac
		if ($purge_gnac and (not $SKIP_CELL{$CURRENT_MACRO}{'GNAC'})) {
			my @dev_list = @{$FILTER_{'GNAC'}};
			for(my $i =0; $i < @dev_list; $i++) {
				my ($s, $g, $d, $t) = @{$dev_list[$i]};
				return 1 if &match_devices($src, $gate, $drn, $dev_type, $s, $g, $d, $t);
				if ($dev_type eq $t) {
					print "-E- Found illegal use of Gated-Nac (gate != $g) in cell: $CURRENT_MACRO\n$line\n",
					return 0;
				}
			}
		}

		### Filter dummy devices
		if ($purge_dummy and not $SKIP_CELL{$CURRENT_MACRO}{'DUMMY'}) {
			my @dev_list = @{$FILTER_{'DUMMY'}};
			for(my $i =0; $i < @dev_list; $i++) {
				my ($s, $g, $d, $t) = @{$dev_list[$i]};
				return 1 if &match_devices($src, $gate, $drn, $dev_type, $s, $g, $d, $t);
			}
		} 
	
		### Filter decap
		if ($purge_decap and not $SKIP_CELL{$CURRENT_MACRO}{'DECAP'}) {				
			my @dev_list = @{$FILTER_{'DECAP'}};
			my $length = scalar @dev_list;	
			for(my $i =0; $i < @dev_list; $i++) {
				my ($s, $g, $d, $t) = @{$dev_list[$i]};
				return 1 if &match_devices($src, $gate, $drn, $dev_type, $s, $g, $d, $t);
			}
		}
		
		### Filter bjtdiode (analog device nor in SCH)
		# example: Q1 VSS BASEOUT EMITIN VSS Y80DDRDIODE2_PRIM 0.0000 0b0 
		if ($purge_bjtdiode and not $SKIP_CELL{$CURRENT_MACRO}{'BJTDIODE'}) {
			return 1 if $dev_name =~ m/^Q\d+/i;
		}
	}#DEvice filter
	### Filter instance call of empty cells
	elsif ($remove_empty =~ /yes/i and $line =~ m/^@\S*\s+(\S+)/) {
		my $cell_name = $1;		
		return 1 unless $CELL_DEV_COUNT{$cell_name};		
	}
	if ($line =~ m/^@\S*\s+(\S+)/) {
		return 1 if $BLACK_BOX{$CURRENT_MACRO};
	}
	return 0;
}



### match_device ###
# compare 2 devices
# return 1 if device are the same 
# else return 0
sub match_devices
{
	my ($src1, $gate1, $drn1, $type1, $src2, $gate2, $drn2, $type2) = @_;
	return 0 unless $type1 eq $type2;
	
	$gate1 = $gate2 if $gate2 eq "*";
	return 0 unless $gate1 eq $gate2;
		
	return 1 if $src2 eq "*" and $drn2 eq "*";
	
	if (($src1 eq $src2 and $drn1 eq $drn2) or 
		($src1 eq $drn2 and $drn1 eq $src2) or 
		($src2 eq "*" and ($src1 eq $drn2 or $drn1 eq $drn2)) or 
		($drn2 eq "*" and ($src1 eq $src2 or $drn1 eq $src2)) ){
		return 1;
	}	
}



########### prepare_filter_table #################
# Pre-process the %FILTER_DEVICE, %SKIP_CELL and %BLACK_BOX
# For faster use of match device 
# Make cell name device types in UC 
#
sub prepare_filter_table
{
	foreach my $type (keys %FILTER_DEVICE) {
		foreach my $item (@{$FILTER_DEVICE{$type}}) {
			my @dev = split /\s+/, uc $item;
			push (@{$FILTER_{$type}}, [@dev]);
		}
	}
	
	
	### pre-processing the %SKIP_CELL	
	### make cell name and device type in uc
	### convert device list to hash table
	my %skip_cell_tmp = %SKIP_CELL;
	%SKIP_CELL = ();
	foreach my $cell (keys %skip_cell_tmp) {
		my $uc_cell = uc $cell;
		my @types = split /\s+/, $skip_cell_tmp{$cell};
		foreach my $type (@types) {			
			my $dev = uc $type;
			$SKIP_CELL{$uc_cell}{$dev} = 'yes';	
		}
	}
	
	### make black-box cell name in uc
	my %black_box_tmp = %BLACK_BOX;
	%BLACK_BOX = ();
	foreach my $cell (keys %black_box_tmp) {
		my $uc_cell = uc $cell;
		$BLACK_BOX{$uc_cell} = $black_box_tmp{$cell};
	}
}






###################### Usage message ###########################
sub usage
{
	print "@_\n";
	print "Usage for: purgedecas\n",
	      "purgedecas.pl -ln ln/sn file  [-lnout output file]\n",
	      "              [-decap yes/no] [-ganc yes/no] [-dummy yes/no] [-bjtdiode yes/no]\n",
	      "              [-cmdfile command_file]",
	      "-ln           Name (path) for LN or SN file\n",
	      "-lnout        Name (path) for output file   (default: {input_netlist}.purged)\n",
	      "-decap        Purge decap                   (default: $purge_decap)\n",
	      "-gnac         Purge gated-nac               (default: $purge_gnac)\n",
	      "-dummy        Purge dummy device            (default: $purge_dummy)\n",
	      "-bjtdiode     Purge BJT diodes              (default: $purge_bjtdiode)\n",
	      "-rmempty      Remove empty cells witout devices or instances (default: $remove_empty)\n",
	      "-cmdfile      Perl file with the setting of skip-cell, black-box and device to filte",
	      "\n";
	exit 1;
}

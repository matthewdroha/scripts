#!/usr/intel/bin/perl

# mergestm.pl
#
# This script will read a directory of files and merge all of the ones
# with a '.stm' extension.

# Pre-reqs:

# Should be in a UE environment set up with Hercules/ISSTOOLS (like opus_lay)
# Recommend that the $local_disk_area is truely a local disk on a compute server


# Edit these lines for your site and cluster
$top_level_cell = $ARGV[0];
$local_disk_area = "/tmp_proj/$ENV{'USER'}";



$top_level_gds = "${top_level_cell}.stm";
$output_gds = "${top_level_cell}_merge.stm";

unless (-e $local_disk_area) {
  die "-E- Local disk $local_disk_area not found\n";
}

$gdsin_command = "gdsin -fs 1.50 2.00 5.00 10.00 -f -g $local_disk_area -ma a";
$gdsout_command = "gdsout -f -g $local_disk_area -lf \$PDS_ISS_OVRRD/Standard/p1266.map -w y -q n -r n -t '_' '_' '_' '_' $top_level_cell $output_gds '_'";


# List all .gds files in current directory
opendir(CURDIR, '.') or die;
@files = grep /\S+\.stm/, readdir(CURDIR);
closedir(CURDIR);

unless (-e $top_level_gds) {
  die "-E- $top_level_gds not found in current directory\n";
}


# Run gdsin on these files, with the top level file being first
system("$gdsin_command -ea r $top_level_gds $top_level_cell\n");
foreach $gdsfile (@files) {
  print "Processing $gdsfile...\n";
  if (($gdsfile ne $top_level_gds) and ($gdsfile ne $output_gds)) {
    system("$gdsin_command -ea m $gdsfile $top_level_cell\n");
  }
}

# Run gdsout on the resulting ltl library
# For some reason stdout is not
system($gdsout_command);

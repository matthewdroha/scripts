#!/usr/intel/pkgs/perl/5.6.1/bin/perl -w
#

# Disable command buffering 
$| = 1;


# Temporary until we get a central release area built
use strict;
use warnings;
use English;


my $num_cpus = shift;
my $site = shift;
my $fub = 'pbctrsn';

my $ov_area;
my $project;
my $setup;
my $migpl;
my $postmigpl;
my $reportmigpl;

unless ($num_cpus =~ /^\d+$/) {
  die "First argument is number of CPUs. Must be an integer\n";
}


if (($site) and ($site eq 'fm')) {
  $ov_area = '/extra1/mroha';
  $project = 'pnr';
  $setup = '/usr/users/home6/fdcda/pnr_new';
  $migpl = '/usr/users/home2/mroha/pnr/mig/mig.pl';
  $postmigpl = '/usr/users/home2/mroha/pnr/mig/postmig.pl';
  $reportmigpl = '/usr/users/home2/mroha/pnr/mig/reportmig.pl';
} else {
  $ov_area = '/nfs/iil/proj/mpg/mpg46/work/sagantec_group/mroha';
  $project = 'pnrmig';
  $setup = '/usr/local/bin/uesetup44';
  $migpl = '/nfs/iil/disks/home10/mroha/pnr/mig/mig.pl';
  $postmigpl = '/nfs/iil/disks/home10/mroha/pnr/mig/postmig.pl';
  $reportmigpl = '/nfs/iil/disks/home10/mroha/pnr/mig/reportmig.pl';
}

my $ue_setup = "$setup -p $project -hp $project -t opus_lay -pr 1266 -b none -m latest -ov $ov_area";
my @y_sweep_list = ('.70', '.72', '.74', '.76', '.78', '.80');
my @x_sweep_list = ('.69', '.71', '.73', '.77', '.80');


# Need to get all our machines into a private netbatch pool!
my $sweep_count = int((scalar @y_sweep_list) * (scalar @x_sweep_list));
my $num_cmds_per_file = int ($sweep_count/$num_cpus);
print "Number of sweep runs: $sweep_count\n";
print "Number of CPUS (runfiles): $num_cpus\n";
print "Number commands per file: $num_cmds_per_file\n";
if ($num_cmds_per_file < 1) {
  $num_cmds_per_file = 1;
}

my $x;
my $y;
my $mig_cmd;
my $postmig_cmd;
my $reportmig_cmd;
my $ue_cmd;
my $area_suffix;
my @mig_cmd_list;
my @postmig_cmd_list;
my @reportmig_cmd_list;
foreach $y (@y_sweep_list) {
  foreach $x (@x_sweep_list) {
    $area_suffix = "_x${x}_y${y}";
    print "$area_suffix\n";
    $area_suffix =~ s/\.//g;
    print "$area_suffix\n";
    my $ward = "${ov_area}/${fub}${area_suffix}";
    $mig_cmd = "$migpl -cell $fub -scale_x $x -scale_y $y -xmethod VTMIncremental";
    $postmig_cmd = "$postmigpl -cell $fub -migrundir $ward";
    $reportmig_cmd = "$reportmigpl -cell $fub -migrundir $ward -postmigrundir $ward -outcsv ${fub}${area_suffix}.csv -sumfilter 'nofillgate'";
    $ue_cmd = "${ue_setup} -n ${fub}${area_suffix} -cmd \"${mig_cmd}\"";
    print "$ue_cmd\n";
    push(@mig_cmd_list, $ue_cmd);
    $ue_cmd = "${ue_setup} -n ${fub}${area_suffix} -cmd \"${postmig_cmd}\"";
    push(@postmig_cmd_list, $ue_cmd);
    $ue_cmd = "${ue_setup} -n ${fub}${area_suffix} -cmd \"${reportmig_cmd}\"";
    push(@reportmig_cmd_list, $ue_cmd);
  }
}


my $file_number;
my %cmd_queue;
my $commands_remaining = scalar(@mig_cmd_list);
my $cmd_number = 0;
while ($commands_remaining) {
  for ($file_number=0; $file_number < $num_cpus; $file_number++) {
    print "Pushing command into queue: $file_number $cmd_number\n";
    $cmd_queue{'mig'}{$file_number}{$cmd_number} = pop(@mig_cmd_list);
    $cmd_queue{'postmig'}{$file_number}{$cmd_number} = pop(@postmig_cmd_list);
    $cmd_queue{'reportmig'}{$file_number}{$cmd_number} = pop(@reportmig_cmd_list);
    $commands_remaining = scalar(@mig_cmd_list);
    unless ($commands_remaining) {
      last;
    }
  }
  $cmd_number++;
}

my $flowtype;
foreach $flowtype (keys %cmd_queue) {
  foreach $file_number (sort keys %{ $cmd_queue{$flowtype} }) {
    my $runfile = "${flowtype}_runfile${file_number}";
    open (RUNFILE, ">$runfile") or die "-E- Could not open $runfile for writing\n";
    foreach $cmd_number (sort keys %{ $cmd_queue{$flowtype}{$file_number} }) {
      print RUNFILE "$cmd_queue{$flowtype}{$file_number}{$cmd_number}\n";
    }
    close (RUNFILE);
  }
}

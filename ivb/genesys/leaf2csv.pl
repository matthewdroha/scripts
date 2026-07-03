#!/usr/intel/pkgs/perl/5.8.7/bin/perl -w

use strict;
use warnings;
use English;
use Cwd;
use IO::Dir;
use IO::File;
use Env;

our ($HOME);
Env::import('HOME');


# Capture gallery information for fub (module,cluster,type)
my %gallery_hash;
my $fublist = "$HOME/fubs.list";
my $galleryfh = IO::File->new;
$galleryfh->open($fublist) or die "Could not open file for reading: $fublist\n";
while (<$galleryfh>) {
  $_ = lc;
  if (/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*(\S+)?/) {
    my $module = $1;
    my $cluster = $2;
    my $fub = $4;
    my $type = $5;
    $gallery_hash{$fub}{'FUB'} = $fub;
    $gallery_hash{$fub}{'MODULE'} = $module;
    $gallery_hash{$fub}{'CLUSTER'} = $cluster;
    if ($type) {
      $gallery_hash{$fub}{'TYPE'} = $type;
    }
  }
}
$galleryfh->close;


# Capture and store data from Genesys leaf cell extraction
my %fub_hash;
my %cell_hash;
my %modular_cell_hash;
my $currentdir = cwd();
my $currentdirfh = new IO::Dir;
$currentdirfh->open($currentdir) or die "Could not open directory for reading\n";
my @files = grep /\.rungenesys\.genesyslog/, $currentdirfh->read();
$currentdirfh->close();
foreach my $file (@files) {
  my $targetfh = new IO::File;
  $targetfh->open($file);
  #print "Opening target file->($file)\n";
  my $fub;
  my $cell;
  my $lib;
  my $instcount;
  my $llx;
  my $lly;
  my $width;
  my $height;
  my $devcount;
  my $dummydevcount;
  my $diffcount;
  while (<$targetfh>) {
    if (/getLeafCellMetricsFromHier: TopLevel->(\S+)\s+Cell->(\S+)\s+Lib->(\S+)\s+InstCount->(\S+)/) {
      $fub = $1;
      $cell = $2;
      $lib = $3;
      $instcount = $4;
      $fub_hash{$fub}{$cell}{'FUB'} = $fub;
      $fub_hash{$fub}{$cell}{'CELL'} = $cell;
      $fub_hash{$fub}{$cell}{'LIB'} = $lib;
      $fub_hash{$fub}{$cell}{'INSTCOUNT'} = $instcount;
    }
    elsif (/getCellMetrics: Cell->(\S+)\s+LowerLeft->(\S+):(\S+)\s+XWidth->(\S+)u\s+YHeight->(\S+)u\s+DevCount->(\S+)\s+DummyDevCount->(\S+)\s+DiffPlyCount->(\S+)/) {
      $cell = $1;
      $llx = $2;
      $lly = $3;
      $width = $4;
      $height = $5;
      $devcount = $6;
      $dummydevcount = $7;
      $diffcount = $8;
      $cell_hash{$cell}{'CELL'} = $cell;
      $cell_hash{$cell}{'LLX'} = $llx;
      $cell_hash{$cell}{'LLY'} = $lly;
      $cell_hash{$cell}{'WIDTH'} = $width;
      $cell_hash{$cell}{'HEIGHT'} = $height;
      $cell_hash{$cell}{'DEVCOUNT'} = $devcount;
      $cell_hash{$cell}{'DUMMYDEVCOUNT'} = $dummydevcount;
      $cell_hash{$cell}{'DIFFCOUNT'} = $diffcount;
    }
    elsif (/getLeafCellMetricsFromHier: TopLevel->(\S+)\s+Cell->(\S+)\s+ModularStandAloneInstCount->(\S+)/) {
      $fub = $1;
      $cell = $2;
      $instcount = $3;
      $modular_cell_hash{$fub}{$cell}{'FUB'} = $fub;
      $modular_cell_hash{$fub}{$cell}{'CELL'} = $cell;
      $modular_cell_hash{$fub}{$cell}{'INSTCOUNT'} = $instcount;
    }
  }
  $targetfh->close();
}


# Generate mutation info sheet for all fubs.  Also generate list of mutations that don't map to an original cell
# MODULE,CLUSTER,FUB,CELL,LIB,MUTATION,MUTATION_X,MUTATION_Y,ORIGINAL_CELL,ORIGINAL_X,ORIGINAL_Y
my @field_list_mutation = ('MODULE', 'CLUSTER', 'FUB', 'LIB', 'MUTATION', 'INSTCOUNT', 'MUTATION_X', 'MUTATION_Y', 'ORIGINAL', 'ORIGINAL_X', 'ORIGINAL_Y', 'SIZE_BUCKET');
my $mutation_csv = "$HOME/mutation.csv";
my $mutation_csvfh = IO::File->new;
$mutation_csvfh->open(">$mutation_csv") or die "-E- Could not open file for writing: $mutation_csv\n";
$mutation_csvfh->printf("%s\n", join(",", @field_list_mutation));
my %mutation_hash;
foreach my $fub (keys %fub_hash) {
  foreach my $cell (keys %{ $fub_hash{$fub} }) {
    if (exists $mutation_hash{$cell}) {
      next;
    }
    if ($cell =~ /^w\d+_?(\S+)$/) {
      my $original = $1;
      if ($original =~ /(\S+)_+\d+$/) {
	$original = $1;
      }
      $original =~ s/^_//;    # Bad mutation naming
      my $cell_x;
      my $cell_y;
      my $size_bucket;
      my %cell_delta;
      my @record = ();
      push (@record, $gallery_hash{$fub}{'MODULE'});
      push (@record, $gallery_hash{$fub}{'CLUSTER'});
      push (@record, $fub_hash{$fub}{$cell}{'FUB'});
      push (@record, $fub_hash{$fub}{$cell}{'LIB'});
      push (@record, $cell);
      push (@record, $fub_hash{$fub}{$cell}{'INSTCOUNT'});
      push (@record, $cell_hash{$cell}{'WIDTH'});
      push (@record, $cell_hash{$cell}{'HEIGHT'});
      push (@record, $original);
      if (exists $cell_hash{$original}) {
	foreach my $parameter ('WIDTH', 'HEIGHT') {
	  push (@record, $cell_hash{$original}{$parameter});
	}
	foreach my $parameter ('WIDTH', 'HEIGHT') {
	  if ($cell_hash{$cell}{$parameter} eq $cell_hash{$original}{$parameter}) {
	    $size_bucket = "${parameter}_SAME";
	  }
	  elsif ($cell_hash{$cell}{$parameter} < $cell_hash{$original}{$parameter}) {
	    $size_bucket = "${parameter}_SHRUNK";
	  } else {
	    $size_bucket = "${parameter}_GREW";
	  }
	  $cell_delta{$parameter} = $size_bucket;
	}
	my $temp = "$cell_delta{'WIDTH'} $cell_delta{'HEIGHT'}";
	$temp =~ s/WIDTH/X/;
	$temp =~ s/HEIGHT/Y/;
	push (@record, $temp);
      } else {
	push (@record, 'NOT_FOUND');
	push (@record, 'NOT_FOUND');
      }
      $mutation_csvfh->printf("%s\n", join(",", @record));
      $mutation_hash{$cell} = 1;
    }
  }
}
$mutation_csvfh->close;


# Calculate and generate the instance area percentages per fub for all fubs.
my @field_list_instarea = ('MODULE', 'CLUSTER', 'FUB', 'TYPE',  'MasterCount AI0', 'MasterCount Mutated AI0/AI3', 'MasterCount AI7/AN4', 'MasterCount Mutated AI7/AN4', 'MasterCount AI3 Not Inside AI0', 'MasterCount CLK Collateral', 'MasterCount AXX', 'MasterCount A80', 'MasterCount X10', 'MasterCount Custom Leaf', 'MasterCount IVB_DFM Collateral', 'MasterCount Other Decap/Gnac/Dummy', 'MasterCount Cell Contains Diffusion But No Devices', 'PercentArea AI0', 'PercentArea Mutated AI0/AI3', 'PercentArea AI7/AN4', 'PercentArea Mutated AI7/AN4', 'PercentArea AI3 Not Inside AI0', 'PercentArea CLK Collateral', 'PercentArea AXX', 'PercentArea A80', 'PercentArea X10', 'PercentArea Custom Leaf', 'PercentArea IVB_DFM Collateral', 'PercentArea Other Decap/Gnac/Dummy', 'PercentArea Cell Contains Diffusion But No Devices', 'InstArea Total', 'InstArea AI0', 'InstArea Mutated AI0/AI3', 'InstArea AI7/AN4', 'InstArea Mutated AI7/AN4', 'InstArea AI3 Not Inside AI0', 'InstArea CLK Collateral', 'InstArea AXX', 'InstArea A80', 'InstArea X10', 'InstArea Custom Leaf', 'InstArea IVB_DFM Collateral', 'InstArea Other Decap/Gnac/Dummy', 'InstArea Cell Contains Diffusion But No Devices');
my @field_list_leaf = ('MODULE', 'CLUSTER', 'FUB', 'CELL', 'LIB', 'CATEGORY', 'INSTCOUNT', 'WIDTH', 'HEIGHT', 'INSTAREA', 'DEVCOUNT', 'DIFFCOUNT');
my @detail_list = ('AI0', 'Mutated AI0', 'AI7/AN4', 'Mutated AI7/AN4', 'AI3 Not Inside AI0', 'CLK Collateral', 'AXX', 'A80', 'X10', 'Custom Leaf', 'IVB_DFM Collateral', 'Other Decap/Gnac/Dummy', 'Cell Contains Diffusion But No Devices');
my $fub_instarea_csv = "$HOME/fub_instarea.csv";
my $fub_leaf_csv = "$HOME/fub_leaf.csv";
my $fub_instarea_csvfh = IO::File->new;
my $fub_leaf_csvfh = IO::File->new;
$fub_instarea_csvfh->open(">$fub_instarea_csv") or die "-E- Could not open file for writing: $fub_instarea_csv\n";
$fub_leaf_csvfh->open(">$fub_leaf_csv") or die "-E- Could not open file for writing: $fub_leaf_csv\n";
$fub_instarea_csvfh->printf("%s\n", join(',', @field_list_instarea));
$fub_leaf_csvfh->printf("%s\n", join(',', @field_list_leaf));
foreach my $fub (sort keys %fub_hash) {
  my %report_hash;
  my @record = ();
  my $inst_area_total = 0;
  foreach my $field (@detail_list) {
    $report_hash{"InstArea $field"} = 0;
    $report_hash{"PercentArea $field"} = 0;
    $report_hash{"MasterCount $field"} = 0;
  }
  foreach my $cell (sort keys %{ $fub_hash{$fub} }) {
    my @leaf_record = ();
    my $lib = $fub_hash{$fub}{$cell}{'LIB'};
    my $detail;
    if ($cell =~ /^ai0/) {
      $detail = 'AI0';
    }
    elsif ($cell =~ /^w\d+ai(0|3)/) {
      $detail = 'Mutated AI0/AI3';
    }
    elsif ($cell =~ /^a(i7|n4)/) {
      $detail = 'AI7/AN4';
    }
    elsif ($cell =~ /^w\d+a(i7|n4)/) {
      $detail = 'Mutated AI7/AN4';
    }
    # Only count modular cells if they are used outside CLD cells
    elsif ($cell =~ /^ai3/) {
      if (exists $modular_cell_hash{$fub}{$cell}) {
	$detail = 'AI3 Not Inside AI0';
      }
    }
    elsif ($cell =~ /^(axx|a80|x10)/) {
      $detail = uc($1);
    } 
    elsif ($lib eq 'clk_cltr') {
      $detail = 'CLK Collateral';
    }
    elsif ($lib eq 'ivb_dfm') {
      $detail = 'IVB_DFM Collateral';
    }
    elsif (($cell_hash{$cell}{'DEVCOUNT'} > 0) and ($cell_hash{$cell}{'DEVCOUNT'} == $cell_hash{$cell}{'DUMMYDEVCOUNT'})) {
      $detail = 'Other Decap/Gnac/Dummy';
    } elsif ($cell_hash{$cell}{'DEVCOUNT'} > 0) {
      $detail = 'Custom Leaf';
    } else {
      $detail = 'Cell Contains Diffusion But No Devices';
    }
    if ($detail) {
      if ($detail eq 'AI3 Not Inside AI0') {
	$report_hash{"InstArea $detail"} += $modular_cell_hash{$fub}{$cell}{'INSTCOUNT'};# * $cell_hash{$cell}{'WIDTH'}; # * $cell_hash{$cell}{'HEIGHT'};
      } else {
	$report_hash{"InstArea $detail"} += $fub_hash{$fub}{$cell}{'INSTCOUNT'} * $cell_hash{$cell}{'WIDTH'} * $cell_hash{$cell}{'HEIGHT'}; 
      }
      push (@leaf_record, $gallery_hash{$fub}{'MODULE'});
      push (@leaf_record, $gallery_hash{$fub}{'CLUSTER'});
      push (@leaf_record, $fub);
      push (@leaf_record, $cell);
      push (@leaf_record, $fub_hash{$fub}{$cell}{'LIB'});
      push (@leaf_record, $detail);
      push (@leaf_record, $fub_hash{$fub}{$cell}{'INSTCOUNT'});
      push (@leaf_record, $cell_hash{$cell}{'WIDTH'});
      push (@leaf_record, $cell_hash{$cell}{'HEIGHT'});
      push (@leaf_record, $fub_hash{$fub}{$cell}{'INSTCOUNT'} * $cell_hash{$cell}{'WIDTH'} * $cell_hash{$cell}{'HEIGHT'});
      push (@leaf_record, $cell_hash{$cell}{'DEVCOUNT'});
      push (@leaf_record, $cell_hash{$cell}{'DIFFCOUNT'});
      $fub_leaf_csvfh->printf("%s\n", join(',', @leaf_record));
      $report_hash{"MasterCount $detail"}++;
      $inst_area_total += $fub_hash{$fub}{$cell}{'INSTCOUNT'} * $cell_hash{$cell}{'WIDTH'} * $cell_hash{$cell}{'HEIGHT'};
    } 
  }
 
  foreach my $detail (@detail_list) {
    $report_hash{"PercentArea $detail"} = ($report_hash{"InstArea $detail"}/$inst_area_total);
  }
  push (@record, $gallery_hash{$fub}{'MODULE'});
  push (@record, $gallery_hash{$fub}{'CLUSTER'});
  push (@record, $fub);
  push (@record, $gallery_hash{$fub}{'TYPE'});
  foreach my $detail (@detail_list) {
    push (@record, $report_hash{"MasterCount $detail"});
  }
  foreach my $detail (@detail_list) {
    push (@record, $report_hash{"PercentArea $detail"});
  }
  push (@record, $inst_area_total);
  foreach my $detail (@detail_list) {
    push (@record, $report_hash{"InstArea $detail"});
  }
  $fub_instarea_csvfh->printf("%s\n", join(',', @record));
}
$fub_instarea_csvfh->close;
$fub_leaf_csvfh->close;

# $Id: SagStd.pl,v 1.12 2005/10/17 13:50:48 mroha Exp $

=pod
=head1 COPYRIGHT

$Id: SagStd.pl,v 1.12 2005/10/17 13:50:48 mroha Exp $

(C) Copyright Intel Corporation, 2005
Licensed material -- Program property of Intel Corporation
All Rights Reserved

This program is the property of Intel Corporation and is furnished
pursuant to a written license agreement. It may not be used, reproduced,
or disclosed to others except in accordance with the terms and conditions
of that agreement.

Filename: SagStd.pl
Project: Penryn
Original Author: Matthew Roha

Functional Description: 

Sagperl based routines that can not be stored in other packages.

This package is coded to be dependent on the calling module for interface assertions
(like whether an input file exists). Internal checks will still be done.


=cut

use sagperllib;
use strict;
use warnings;
use English;
use Getopt::Long;

# Parse command line parameters, check if input files exist, etc...
if (@ARGV == 0) {
  die "No command line parameters. Use -help to list input flags.\n";
}

# Get command line options. &GetOptions returns $opt_<option>
our ($COMMAND_LINE, @MAILARGV);
@MAILARGV = @ARGV;  # Will be used to check for required command line parameters
$COMMAND_LINE = join (" ", @MAILARGV);
my $options_ok = &GetOptions('StripTextFromCif'           => \&StripTextFromCif,
			     'GeneratePortPropsInCif'     => \&GeneratePortPropsInCif,
			     'GeneratePortsInCif'         => \&GeneratePortsInCif,
			     'StripPolygonsFromCif'       => \&StripPolygonsFromCif,
			     'StripLayersFromCif'         => \&StripLayersFromCif,
			     'StripPwrPolygonsFromCif'    => \&StripPwrPolygonsFromCif,
			     'GenerateTextInCif'          => \&GenerateTextInCif,
			     'ConvertTextPropToGds126'    => \&ConvertTextPropToGds126,
			     'CopyKeepoutTextToMetalText' => \&CopyKeepoutTextToMetalText,
			     'StripSynPropsFromCif'       => \&StripSynPropsFromCif,
			     'ChangeLayerNamesInCif'      => \&ChangeLayerNamesInCif,
			     'AddViaPadPropsInCif'        => \&AddViaPadPropsInCif);


sub StripTextFromCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my %master_cell_table;

  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &StripTextFromCell($master_cell_table{$cellname});
  }
  sagSaveCif($cifhandle, $outcif);
}


sub StripPolygonsFromCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
	print "StripPolygonsFromCif: Layer to be processed: $layer\n";
      }
    }
  } else {
    print "StripPolygonsFromCif: All layers to be processed\n";
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &StripPolygonsFromCell($master_cell_table{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub StripPwrPolygonsFromCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
        print "StripPwrPolygonsFromCif: Layer to be processed:($layer)\n";
      }
    }
  } else {
    print "StripPwrPolygonsFromCif: All layers to be processed\n";
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &StripPwrPolygonsFromCell($master_cell_table{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub ChangeLayerNamesInCif  {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_pair_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  my %layer_pair_hash;
  if (scalar @layer_pair_list) {
    foreach my $layerpair (@layer_pair_list) {
      if ($layerpair =~ /(\S+):(\S+)/) {
	my $sourcelayer = $1;
	my $targetlayer = $2;
	$layer_pair_hash{$sourcelayer} = $targetlayer;
  	print "ChangeLayerNamesInCif: Change to be processed: ($sourcelayer) -> ($targetlayer)\n";	
      } else {
	die "ChangeLayerNamesInCif: Input layer pair list needs to be of form <srclayer>:<targetlayer>\n";
      }
    }
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &ChangeLayerNamesInCell($master_cell_table{$cellname}, \%layer_pair_hash);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub StripLayersFromCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
	print "StripLayersFromCif: Layer to be processed: $layer\n";
      }
    }
  } else {
    print "StripLayersFromCif: All layers to be processed\n";
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &StripLayersFromCell($master_cell_table{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub GeneratePortPropsInCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;

  my %master_cell_table;

  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
	print "GeneratePortPropsInCif: Layer to be processed: $layer\n";
      }
    }
  } else {
    print "GeneratePortPropsInCif: All layers to be processed\n";
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &GeneratePortPropsInCell($master_cell_table{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub GeneratePortsInCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
	print "GeneratePortsInCif: Layer to be processed: $layer\n";
      }
    }
  } else {
    print "GeneratePortsInCif: All layers to be processed\n";
  }
  
  my %cell_already_processed;
  my @ordered_cell_list;
  &GetHierarchyDepthFirst($cellhandle, \%cell_already_processed, \@ordered_cell_list);
  foreach my $cellname (@ordered_cell_list) {
    print "GeneratePortsInCif: Cell being processed->(${cellname})";
    &GeneratePortsInCell($cell_already_processed{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub GenerateTextInCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my @layer_list = @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  if (scalar @layer_list) {
    foreach my $layer (@layer_list) {
      if ($layer =~ /\w/) {
	print "GenerateTextInCif: Layer to be processed: $layer\n";
      }
    }
  } else {
    print "GenerateTextInCif: All layers to be processed\n";
  }
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
     &GenerateTextInCell($master_cell_table{$cellname}, \@layer_list);
  }
  sagSaveCif($cifhandle, $outcif);
}


sub CopyKeepoutTextToMetalText {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
     &CopyKeepoutTextToMetalTextInCell($master_cell_table{$cellname});
  }
  sagSaveCif($cifhandle, $outcif);
}



sub ConvertTextPropToGds126 {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
     &ConvertTextPropToGds126InCell($master_cell_table{$cellname});
  }
  sagSaveCif($cifhandle, $outcif);
}


sub StripSynPropsFromCif {

  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "Top Cell: $test\n";
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    &StripSynPropsInCell($master_cell_table{$cellname});
  }
  print "MadeIt\n";
  sagSaveCif($cifhandle, $outcif);
}



sub AddViaPadPropsInCif {
  my @arg_list = @ARGV;

  my $cell = shift @arg_list;
  my $incif = shift @arg_list;
  my $outcif = shift @arg_list;
  my %master_cell_table;
  
  my $cifhandle = sagLoadCif($incif);
  my $cellhandle;
  eval {$cellhandle = sagCell($cifhandle, $cell);};
  if ($@) {
    die "-F- AddViaPadPropsInCif: Could not open cell $cell in $incif\n";
  }
  my $test = sagCellName($cellhandle);
  print "-I- AddViaPadPropsInCif: Top Cell: $test\n";
  $master_cell_table{$cell} = $cellhandle;
  &GetHierarchy($cellhandle, \%master_cell_table);
  foreach my $cellname (sort keys %master_cell_table) {
    print "-I- AddViaPadPropsInCif: Working on cell: $cellname\n";
    &AddViaPadPropsInCell($master_cell_table{$cellname});
  }
  sagSaveCif($cifhandle, $outcif);
}



sub StripTextFromCell {

  my $cellhandle = shift;
  
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = sagLayerName($layer);
    if ($layername =~ /^(n|p)diff$/) {
      foreach my $text (sagTexts($layer)) {
	sagRemoveText($text);
      }
    } else {
      sagCalculateLayer($cellhandle, $layername, "selectshape(PATHS&POLYGONS,$layername)", 'S'); 
    }
  }
}



sub ConvertTextPropToGds126InCell {

  my $cellhandle = shift;
  
  foreach my $layer (sagLayers($cellhandle)) {
    foreach my $polygon (sagPolygons($layer)) {
      if (sagPropertyExists($polygon, "text")) {
	my @prop_value_list = sagPropertyValues($polygon, "text");
	if (sagPropertyExists($polygon, "gdsprop 126")) {
	  sagRemovePropertyPath($polygon, "gdsprop 126");
	}
	foreach my $propvalue (@prop_value_list) {
	  sagAddProperty($polygon, "gdsprop 126", $propvalue);
	}
	sagRemovePropertyPath($polygon, "text");
      }
    }
  }
}


sub StripSynPropsInCell {

  my $cellhandle = shift;
  
  foreach my $layer (sagLayers($cellhandle)) {
    foreach my $polygon (sagPolygons($layer)) {
      my @prop_value_list = sagPropertyValues($polygon, "gdsprop 126");
      if (scalar @prop_value_list > 1) {
	die "-F- StripSynPropsInCell: Found multivalue properties for prop 126 in CIF file\n";
      }
      elsif (scalar @prop_value_list == 1) {
	if (($prop_value_list[0] =~ /^\=syn\d+$/) or ($prop_value_list[0] =~ /^\s*$/)) {
	  sagRemovePropertyPath($polygon, "gdsprop 126");
	}
      }
    }
  }
}



sub CopyKeepoutTextToMetalTextInCell {

  my $cellhandle = shift;
  
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = sagLayerName($layer);
    if ($layername =~ /^(\S+)keepout$/) {
      my $targetlayer = sagAddLayer($cellhandle, $1);
      foreach my $kotext (sagTexts($layer)) {
	sagCopyText($targetlayer, $kotext);
      }
    }
  }
}


sub GenerateTextInCell {

  my $cellhandle = shift;
  my $layer_list_ref = shift;

  my %layer_hash;

  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = sagLayerName($layer);
    if (scalar keys %layer_hash) {
      unless ($layer_hash{$layername}) {
	next;
      }
    } 
    foreach my $polygon (sagPolygons($layer)) {
      if (sagPropertyExists($polygon, "gdsprop 126")) {
	my @prop_value_list = sagPropertyValues($polygon, "gdsprop 126");
	my @real_nets_list = ();
	if (scalar(@prop_value_list) > 1) {
	  foreach my $prop (@prop_value_list) {
	    if ($prop !~ /^\=syn\d+$/) {
	      push (@real_nets_list, $prop);
	    }
	  }
	  if (scalar @real_nets_list > 1) {
	    my $prop_string = join(':', @prop_value_list);
	    print "-W- GenerateTextInCell: Not generating text for multivalue property polygon. layer->(${layername}) gdsprop 126->(${prop_string})\n";
	    next;
	  }
	}
	my @coords = sagPolygonCoordinates($polygon);
	# If there is a real net, use it. Otherwise pop the first syn net off of the stack
	if (scalar @real_nets_list) {
	  sagAddText($layer, [$coords[0], $coords[1]], pop(@real_nets_list));
	} else {
	  sagAddText($layer, [$coords[0], $coords[1]], pop(@prop_value_list));
	}
      }
    }
  }
}


sub StripPolygonsFromCell {

  my $cellhandle = shift;
  my $layer_list_ref = shift;

  my %layer_hash;

  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    if (scalar keys %layer_hash) {
      unless ($layer_hash{sagLayerName($layer)}) {
	next;
      }
    }
    foreach my $polygon (sagPolygons($layer)) {
      sagRemovePolygon($polygon);
    } 
  }
}


sub ChangeLayerNamesInCell {

  my $cellhandle = shift;
  my $layer_pair_hash_ref = shift;

  foreach my $layername (keys %{ $layer_pair_hash_ref }) {
    my $layer;
    eval {$layer = sagLayer($cellhandle, $layername);}; 
    if ($layer) {
      sagCopyLayer($cellhandle, $layer, $$layer_pair_hash_ref{$layername});
      sagRemoveLayer($layer);
    }
  }
}
    

sub StripPwrPolygonsFromCell {

  my $cellhandle = shift;
  my $layer_list_ref = shift;

  my %layer_hash;

  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    if (scalar keys %layer_hash) {
      unless ($layer_hash{sagLayerName($layer)}) {
	next;
      }
    }
    PLYSEARCH: foreach my $polygon (sagPolygons($layer)) {
      if (sagPropertyExists($polygon, "gdsprop 126")) {
	my @prop_value_list = sagPropertyValues($polygon, "gdsprop 126");
	if (scalar @prop_value_list) {
	  foreach my $prop (@prop_value_list) {
	    if ($prop =~ /^(vcc|vss)$/i) {
	      sagRemovePolygon($polygon);
	      next PLYSEARCH;
	    }
	  }
	}
      }
    } 
  }
}



sub StripLayersFromCell {

  my $cellhandle = shift;
  my $layer_list_ref = shift;

  my %layer_hash;

  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    if (scalar keys %layer_hash) {
      unless ($layer_hash{sagLayerName($layer)}) {
	next;
      }
    }
    sagRemoveLayer($layer);
  }
}


sub GeneratePortPropsInCell {

  my $cellhandle = shift;
  my $layer_list_ref = shift;

  my %layer_hash;

  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = sagLayerName($layer);
    if (scalar keys %layer_hash) {
      unless ($layer_hash{$layername}) {
	next;
      }
    }
    my $layer_and_port_name = "${layername}_and_port";
    sagCalculateLayer($cellhandle, $layer_and_port_name, "${layername}&${layername}_portDrawing","S");
    my $layer_and_port;
    eval {$layer_and_port = sagLayer($cellhandle, $layer_and_port_name);};
    if ($layer_and_port) {
      foreach my $polygon (sagPolygons($layer_and_port)) {
	if (sagPropertyExists($polygon, "gdsprop 126")) {
	  sagRemovePropertyPath($polygon, "gdsprop 126");
	}
	my $new_layer_polygon = sagCopyPolygon($layer, $polygon);
	sagAddProperty($new_layer_polygon, "portObject", "YES");
      }
      sagRemoveLayer($layer_and_port);
    }
  }
}


sub GeneratePortsInCell {
  
  my $cellhandle = shift;
  my $layer_list_ref = shift;
  
  my %layer_hash; 
  
  foreach my $layer (@{ $layer_list_ref }) {
    if ($layer =~ /\w/) {
      $layer_hash{$layer} = 1;
    }
  }
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = sagLayerName($layer);
    if (scalar keys %layer_hash) {
      unless ($layer_hash{$layername}) {
	next;
      }
    }
    # Generate port layer for all metal tagged with port property
    my $portlayername = "${layername}_portDrawing";
    my $portlayer = sagAddLayer($cellhandle, $portlayername);
    foreach my $polygon (sagPolygons($layer)) {
      if (sagPropertyExists($polygon, "portObject YES")) {
	my $port_polygon = sagCopyPolygon($portlayer, $polygon);
      }
    }
    # Flatten port layer through the hierarchy
    sagFlatLayer($cellhandle, $portlayername, "${portlayername}_flat", "K");
    # For all port layers that touch port text, add to new port layer
    sagCalculateLayer($cellhandle, "${portlayername}_textsquares", "texttopolygon(${portlayername},.005)","S");
    sagCalculateLayer($cellhandle, "${portlayername}_flat_valid", "touching(${portlayername}_flat,${portlayername}_textsquares)","S");
    sagCalculateLayer($cellhandle, $portlayername,"${portlayername}_flat_valid","S");
  }
} 


sub AddViaPadPropsInCell {

  my $cellhandle = shift;
  
  my %dg_layer_lookup = (
    metal1_enclosure => 'metal1',
    metal2_enclosure => 'metal2',
    metal3_enclosure => 'metal3',  # Using metal7dg... 1264 does not have a DG layer for every metal :(
  );

  my %layer_dg_lookup = (
    metal1 => 'metal1_enclosure',
    metal2 => 'metal2_enclosure',
    metal3 => 'metal3_enclosure',
  );

  my %dg_ply_table;

  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = lc(sagLayerName($layer));
    if (exists $dg_layer_lookup{$layername}) {
      foreach my $polygon (sagPolygons($layer)) {
	my $coords_string = join(' ', sagPolygonCoordinates($polygon));
	$dg_ply_table{$dg_layer_lookup{$layername}}{$coords_string} = 0;
      }
    }
  }
  
  foreach my $layer (sagLayers($cellhandle)) {
    my $layername = lc(sagLayerName($layer));
    if (exists $dg_ply_table{$layername}) {
      foreach my $polygon (sagPolygons($layer)) {
	my $coords_string = join(' ', sagPolygonCoordinates($polygon));
	if (exists $dg_ply_table{$layername}{$coords_string}) {
	  sagAddProperty($polygon, "via_pad_marker", $layer_dg_lookup{$layername});
	  $dg_ply_table{$layername}{$coords_string}++;
	}
      }
    }
  }

  foreach my $layername (sort keys %dg_ply_table) {
    my $matched_dg_markers = 0;
    my $total_dg_markers = scalar keys %{ $dg_ply_table{$layername} };
    foreach my $coords_string (sort keys %{ $dg_ply_table{$layername} }) {
      if ($dg_ply_table{$layername}{$coords_string}) {
	$matched_dg_markers++;
      } else {
	print "-W- AddViaPadPropsInCell: Property not created for via marker: $layername  $coords_string\n";
      }
    }
    print "-I- AddViaPadPropsInCell: $matched_dg_markers of $total_dg_markers via enclosure markers for $layername had properties added\n";
  }
}



sub GetHierarchy {

  my $cellhandle = shift;
  my $master_cell_table_ref = shift;
  
  foreach my $instance (sagInstances($cellhandle)) {
    my $currentcellhandle = sagInstanceCell($instance);
    $$master_cell_table_ref{sagCellName($currentcellhandle)} = $currentcellhandle;
    &GetHierarchy($currentcellhandle, $master_cell_table_ref);
  }
}


sub GetHierarchyDepthFirst {

  my $cellhandle = shift;
  my $cell_already_processed_ref = shift;
  my $ordered_cell_list_ref = shift;
  
  my $cellname = sagCellName($cellhandle);
  unless (exists $$cell_already_processed_ref{$cellname}) {
    foreach my $instance (sagInstances($cellhandle)) {
      my $currentcellhandle = sagInstanceCell($instance);
      &GetHierarchyDepthFirst($currentcellhandle, $cell_already_processed_ref, $ordered_cell_list_ref);
    }
    push (@{ $ordered_cell_list_ref }, $cellname);
    $$cell_already_processed_ref{$cellname} = $cellhandle;
  }
}

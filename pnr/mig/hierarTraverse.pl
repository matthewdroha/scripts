#!/usr/intel/bin/perl

# use strict;
use sagperllib;
use Getopt::Long;

$FLOAT_MAX = 10e10;
$DEV_PITCH = 0.16;
$GATE_LEN = 0.04;

%cellExpanded = (); # indicator of cell expansion
$dropPgonProperty = 0; # count dropped net properties of polygons
$dropPathProperty = 0; # count dropped net properties of paths

print "-I- running $0\n"; # notify running program
GetOptions("i=s" => \$inFile, # get input file
	   "o=s" => \$outFile, # set output file
	   "debug" => \$debug, # data debug flag
	   # flag border manipulation
	   "borderMake" => \$borderMake,
	   # flag dummy gate generation
	   "dummyGate" => \$dummyGate,
	   # flag multi-value net name property drop
	   "propertyDrop" => \$propertyDrop,
	   # flag text removal except of diffusion
	   "textDrop" => \$textDrop,
	   # flag convertion of property to text
	   "prop2text" => \$prop2text,
           # flag creation of metal2 jogging seeds
	   "jogMetal2" => \$jogMetal2,
	   # flag layer statistics collection
	   "layerStat" => \$layerStat);

$layoutRoot = sagLoadCif($inFile); # read input file into layout root
my $cells = sagCells($layoutRoot); # get cells of layout
my $topCell = sagTopCell($layoutRoot); # read input file into layout root

if ($borderMake) {
  print "-I- manipulate cell borders\n";
}
if ($dummyGate) {
  print "-I- create dummy gates\n";
}
if ($propertyDrop) { # drop multi-value net name propertirs
  print "-I- net name multi-value property drop\n";
  do propertyDrop($topCell); # do for top
}
if ($textDrop) { # drop text of all layers except diffusion
  print "-I- text removal except of diffusion\n";
  do textDrop($topCell); # do for top
}
if ($prop2text) { # convert property to text
  print "-I- convert net name property to text\n";
  do prop2text($topCell); # do for top
}
if ($jogMetal2) { # create metal2 jogging seeds
  print "-I- create metal2 jogging seeds\n";
  do jogMetal2($topCell); # do for top
}
if ($layerStat) { # collect layer stasistics
  print "-I- collect layer stasistics\n";
}

# start hierarchy traversal at root
foreach my $instance (sagInstances($topCell)) {
  do hierarTraverse($instance, 1);
}

if ($dummyGate) {
  # flatten gates and dummies of cells to top
  sagFlatLayer($topCell, "cellDummy", "cellDummyFlat", "K");
  sagFlatLayer($topCell, "vpoly", "vpolyFlat", "K");
  sagCalculateLayer($topCell, "topGate", "cellDummyFlat|vpolyFlat", "S");
  # apply dummy gate filling to top cell
  do makeDummyGate($topCell, "topGate", "topDummy");
}

if ($layerStat) { # collect layer stasistics
  my @layers = ("metal2", "metal3", "metal4");
  foreach $layer (@layers) {
    # Get layer name to derive statistic. This name must conform with
    # the name created by polar.
    my $layerTopPath = $layer."TopPath";
    # get statistics of layer
    do layerStat($topCell, $layer, $layerTopPath);
  }
}

sagSaveCif($layoutRoot, $outFile); # save modified cif file
if ($propertyDrop) {
  print "-I- dropped $dropPgonProperty multi-value net properties of polygons\n";
  print "-I- dropped $dropPathProperty multi-value net properties of paths\n";
}

################################################################################

# implements pre-order traversal of the hierarchy tree
sub hierarTraverse { # expand all instances of a cell

  # root of current traversal emanates from the passed instance

  my $instance = $_[0]; # current instance
  my $depth = $_[1]; # hierarchy depth of current instance

  my $cell = sagInstanceCell($instance); # get current cell
  my $cellName = sagCellName($cell); # get cell name

  if ($borderMake) { # assign evenness borders according to hierarchy depth
    do borderMake($instance, $depth); # create shadow of instance within parent
    if (!defined($cellExpanded{$cellName})) { # ensure single treatment of cell
      # apply recursively to all instance's instances
      foreach my $sonInstance (sagInstances($cell)) {
	do hierarTraverse($sonInstance, $depth + 1);
      }
      $cellExpanded{$cellName} = 1; # indicate that cell has been expanded
    }   
  }

  if (!defined($cellExpanded{$cellName})) { # ensure single treatment of cell
    if ($dummyGate) { # create dummy gates and break large diffusions
      do makeDummyGate($cell, "cellGate", "cellDummy");
    }
    if ($propertyDrop) { # drop multi-value net name propertirs
      do propertyDrop($cell);
    }
    if ($textDrop) { # drop text of all layers except diffusion
      do textDrop($cell);
    }
    if ($prop2text) { # convert property to text
      do prop2text($cell);
    }
    # apply recursively to all instance's instances
    foreach my $sonInstance (sagInstances($cell)) {
      do hierarTraverse($sonInstance, $depth + 1);
    }
    $cellExpanded{$cellName} = 1; # indicate that cell has been expanded
  }
} # hierarTraverse

################################################################################

# subroutine for evenness designation of cell instances
sub borderMake {

  my $instance = $_[0]; # current instance
  my $depth = $_[1]; # hierarchy depth of current instance

  my $parentCell = sagInstanceParentCell($instance); # get parent cell;
  my $sonCell = sagInstanceCell($instance); # get instance cell;
  # get transform of instance within parent cell
  my @transform = sagInstanceTransformation($instance);
  my $instBorderLayer; # layer in parent to reside shadow of instance
  my $depthEvenness; # set name of border accordeing to evenness of depth 
  if (($depth % 2) == 0) { $depthEvenness = "oddDepthBorder";}
  else { $depthEvenness = "evenDepthBorder"; }
  # add evenness layer to parent
  sagAddLayer($parentCell, $depthEvenness);
  my $instBorderLayer = # get handle to layer
    sagLayer($parentCell, $depthEvenness);
  # Traverse boundary polygons of cell. It is assumed that border polygon of
  # cell is assigned appropriate property, while instances (if exist) are not.
  $chkBoundary = sagLayer($sonCell, "chkBoundary");
  foreach my $polygon (sagPolygons($chkBoundary)) {
    if (sagPropertyExists($polygon, "gdsprop 30")) { # get self border
      my @mat = tranform2mat(@transform); # get transforation matrix
      my @coords = sagPolygonCoordinates($polygon); # get polygon coordinates
      my @newCoords; # calculate coordinates of instance within parent
      for (my $coord = 0; $coord < scalar @coords; $coord += 2) {
	push(@newCoords,
	     $coords[$coord] * $mat[0][0] +
	     $coords[$coord+1] * $mat[1][0] + 
	     $mat[2][0]);
	push(@newCoords,
	     $coords[$coord] * $mat[0][1] +
	     $coords[$coord+1] * $mat[1][1] +
	     $mat[2][1]);
      }
      # add instance border to parent
      sagAddPolygon($instBorderLayer, \@newCoords);
    }
  }
} # borderMake

################################################################################

# subroutine for dummy gate generation
sub makeDummyGate {

  my $cell = $_[0]; # current cell
  my $gateLayerName = $_[1]; # layer to reside gates
  my $dummyName = $_[2]; # layer to reside dummy gates

  my $XgateLeftMost = $FLOAT_MAX;

  sagCalculateLayer($cell, $gateLayerName, # get real gates
		    "$gateLayerName|(vpoly&(ndiff|pdiff))", "S");
  my $gateLayer = sagLayer($cell, $gateLayerName); # get gate layer
  my $gateExists = 0; # if gate exists get leftmost coordinate
  foreach my $polygon (sagPolygons($gateLayer)) { # traverse polygons
    $gateExists = 1; # indicate gate existence
    my @coords = sagPolygonCoordinates($polygon); # get polygon coordinates
    $XgateLeftMost = min($XgateLeftMost, $coords[0]); # get leftmost x coord
    $XgateLeftMost = min($XgateLeftMost, $coords[4]); # get leftmost x coord
  }
  if ($gateExists) {
    # add dummy gate layer
    my $dummyLayer = sagAddLayer($cell, $dummyName);
    # create dummy gates rightwards
    my @coords = sagCellBoundingBox($cell); # get border of cell
    my $XcellLeft = $coords[0]; my $XcellRight = $coords[2];
    my $YcellBottom = $coords[1]; my $YcellTop = $coords[3];
    for (my $x = $XgateLeftMost; $x < $XcellRight; $x +=  $DEV_PITCH) {
      my @dummyGateCoords = (); # list of dummy gate polygon coordinates
      push(@dummyGateCoords, $x, $YcellBottom, $x, $YcellTop, 
	   $x + $GATE_LEN, $YcellTop, $x + $GATE_LEN, $YcellBottom);
      sagAddPolygon($dummyLayer, \@dummyGateCoords);
    }
    # create dummy gates leftwards
    for (my $x = $XgateLeftMost + $GATE_LEN - $DEV_PITCH; $x >= $XcellLeft;
	 $x -=  $DEV_PITCH) {
      my @dummyGateCoords = (); # list of dummy gate polygon coordinates
      push(@dummyGateCoords, $x, $YcellBottom, $x, $YcellTop, 
	   $x - $GATE_LEN, $YcellTop, $x - $GATE_LEN, $YcellBottom);
      sagAddPolygon($dummyLayer, \@dummyGateCoords);
    }
    # break large diffusions
    do breakeLargeDiff($cell, $gateLayerName, $dummyName);
  }
  sagCalculateLayer($cell, "$dummyName", # create final dummy gate
		    "$dummyName&!($gateLayerName|vpoly)", "S");
} # makeDummyGate

################################################################################

sub breakeLargeDiff {

  my $cell = $_[0]; # current cell
  my $gateLayerName = $_[1]; # layer to reside gates
  my $dummyGateLayerName = $_[2]; # layer to reside dummy gates
  
  # help layers calculations
  sagCalculateLayer($cell, "diff0", # get diffusion polygons
		    "selectshape(POLYGONS,(ndiff|pdiff))", "S");
  # get diffusion nodes
  sagCalculateLayer($cell, "diffNode", "diff0&!$gateLayerName", "S");
  # Non-minimal diffusion nodes need be cutting. These must be covered by
  # some dummy gate created before. Othersize, it was covered by real gate
  # and then wouldn't be a big node.
  sagCalculateLayer($cell, "bigNode",
		    "touching(diffNode,$dummyGateLayerName-0.01x)", "S");
  # Diffusion cutters are then created at the locations where dummy gates
  # are crossing difffusion. Cutters are built around dummy gate which is
  # oversizesd.
  sagCalculateLayer($cell, "cutter",
		    "(bigNode&$dummyGateLayerName)+0.03x", "S");
  # cut diffusion big nodes to get diff pieces
  sagCalculateLayer($cell, "diffSplit", "bigNode&!cutter", "S");
  # create GCN bridge to connect diffusion pieces. Bridge is sized such
  # that its overlap with diffusion cuts is the width of TCN, 0.06u.
  sagCalculateLayer($cell, "GCNbridge0", "cutter+0.06x", "S");
  # create TCN over GCN bridge to connect diffusion pieces
  sagCalculateLayer($cell, "TCNbridge0", "GCNbridge0&diffSplit", "S");
  # Create GCN bridge to connect diffusion pieces. The 0.01u trim is required
  # for proper space of GCN to adjacent real gate
  sagCalculateLayer($cell, "GCNbridge", "GCNbridge0-0.01x", "S");
  # Leave only relevant TCN over diffusion. In case of big diffusion node
  # more than two TCNs are resulting. Only the two extreem are in order.
  # The intermediate ones are dropped.
  sagCalculateLayer($cell, "TCNbridge",
		    "touching(TCNbridge0,diff0&!GCNbridge)", "S");
} # breakeLargeDiff

################################################################################

# subroutine to drop multi-value net name propertirs
sub propertyDrop {

  my $cell = $_[0]; # current cell
  my $cellName = sagCellName($cell);

  # Traverse all layers. In each layer traverse all polygons and paths.
  # Trap polygons possesseing multiple value net property and then trop
  # this property.
  foreach my $layer (sagLayers($cell)) { # traverse layers
    foreach my $polygon (sagPolygons($layer)) { # traverse polygons
      # get net name propery
      my @values = sagPropertyValues($polygon, "gdsprop 126");
      # check for multi-value or diffusion layer
      if ($#values > 0) {
	sagRemoveProperty($polygon); # drop property
	++$dropPgonProperty; # count gropped properties
	if ($debug) { # print out dropped property
	  my @coords = sagPolygonCoordinates($polygon);
	  print "multi-value net property: \"@values\" ";\
	  print "cell: at cell $cellName in coord ($coords[0],$coords[1])\n";
	}
      }
    }
    foreach my $path (sagPaths($layer)) { # traverse paths
      # get net name propery
      my @values = sagPropertyValues($path, "gdsprop 126");
      if ($#values > 0) { # check for multi-value
	sagRemoveProperty($path); # drop property
	++$dropPathProperty; # count gropped properties
	if ($debug) { # print out dropped property
	  my @coords = sagPathCoordinates($path);
	  print "multi-value net property: \"@values\" ";
	  print "cell: $cellName ($coords[0],$coords[1])\n";
	}
      }
    }
  }
} # propertyDrop

################################################################################

# subroutine to drop text of all layers except diffusion
sub textDrop {

  my $cell = $_[0]; # current cell

  foreach my $layer (sagLayers($cell)) { # traverse layers
    my $layerName = sagLayerName($layer); # verify non diffusion layer
    if (($layerName cmp "ndiff") && ($layerName cmp "pdiff")) {
      foreach my $text (sagTexts($layer)) { # traverse texts
	sagRemoveText($text); # drop text
      }
    }
  }
} # textDrop

################################################################################

# subroutine to convert property to text
sub prop2text {

  my $cell = $_[0]; # current cell

  foreach my $layer (sagLayers($cell)) { # traverse layers
    my $layerName = sagLayerName($layer); # verify non diffusion layer
    if (($layerName cmp "ndiff") && ($layerName cmp "pdiff")) {
      foreach my $polygon (sagPolygons($layer)) { # traverse polygons
	# verify existence of net name property
	if (sagPropertyExists($polygon, "gdsprop 126")) {
	  my @values = sagPropertyValues($polygon, "gdsprop 126");
	  if ($#values == 0) { # check for unique value
	    # get coordinates of polygon
	    my @coords = sagPolygonCoordinates($polygon);
	    # verify non diffusion related layer and make text from property
            if (sagLayerName($layer) ne "diffSD") {
              sagAddText($layer, [$coords[0], $coords[1]], $values[0]);
            }
	    # Layer is diffusion related. Since origin is not known, texts
            # are added to both ndiff and pdiff. Redundent texts are removed
            # before exiting.
            else {
	      # check for existence of ndiff layer
	      my $layer = eval { sagLayer($cell, "ndiff") };
	      if (!$@) { # ndiff layer exists
		sagAddText($layer, [$coords[0], $coords[1]], $values[0]);
	      }
	      # check for existence of pdiff layer
              my $layer = eval { sagLayer($cell, "pdiff") };
	      if (!$@) { # pdiff layer exists
		sagAddText($layer, [$coords[0], $coords[1]], $values[0]);
	      }
            }
	  }
	}
      }
      foreach my $path (sagPaths($layer)) { # traverse paths
        # verify existence of net name property
        if (sagPropertyExists($path, "gdsprop 126")) {
          my @values = sagPropertyValues($path, "gdsprop 126");
          if ($#values == 0) { # check for unique value
            # get coordinates of path
            my @coords = sagPathCoordinates($path);
            sagAddText($layer, [$coords[0], $coords[1]], $values[0]);
          }
        }
      }
    }
  }
  # remove texts added to opposite polarity diffusion
  sagCalculateLayer($cell, "ndiff",
		    "ndiff&selectshape(PATHS&POLYGONS,ndiff)", "S");
  sagCalculateLayer($cell, "pdiff",
		    "pdiff&selectshape(PATHS&POLYGONS,pdiff)", "S");

} # prop2text

################################################################################

# create transformation matrix
sub tranform2mat
{
  # get mirror, rotation and X and Y translations
  my ($M, $R, $Tx, $Ty) = (shift, shift, shift, shift);
  # apply translation to unit matrix
  my @mat = ([1, 0, 0], [0, 1, 0], [$Tx, $Ty, 1]);
  if ($R eq "R90") { # rotate in 90 degrees
    $mat[0][0] = 0; $mat[0][1] = 1; $mat[1][0] = -1; $mat[1][1] = 0;
  }
  elsif ($R eq "R180") { # rotate in 180 degrees
    $mat[0][0] = -1; $mat[0][1] = 0; $mat[1][0] = 0; $mat[1][1] = -1;
  }
  elsif ($R eq "R270") { # rotate in 270 degrees
    $mat[0][0] = 0; $mat[0][1] = -1; $mat[1][0] = 1; $mat[1][1] = 0;
  }
  if (($M eq "MX") || ($M eq "MXY")) { # apply X mirror
    $mat[0][0] *= -1; $mat[0][1] *= -1;
  }
  if (($M eq "MY") || ($M eq "MXY")) { # apply Y mirror
    $mat[1][0] *= -1; $mat[1][1] *= -1;
  }
  return @mat;
} # tranform2mat

################################################################################

# get minimum of two numbers
sub min {
  if ($_[0] < $_[1]) {return $_[0]}
  else {return $_[1]}
} # min

################################################################################

# get maximum of two numbers
sub max {
  if ($_[0] < $_[1]) {return $_[1]}
  else {return $_[0]}
} # max

################################################################################

# subroutine to create metal2 jogging seeds
sub jogMetal2 {

  my $cell = $_[0]; # current cell
  
  # add jog marker layer
  my $jogMarkLayer = sagAddLayer($cell, "metal2JogMark");
  foreach my $layer (sagLayers($cell)) { # traverse layers
    # get jog recontacting layer
    if (sagLayerName($layer) eq "metal2JogRecon") {
      foreach my $polygon (sagPolygons($layer)) { # traverse polygons
	# get polygon coordinates
	my @coords = sagPolygonCoordinates($polygon);
	my $x_mid = ($coords[0] + $coords[4]) / 2;
	my $y_mid = ($coords[1] + $coords[5]) / 2;
	my @coords; # calculate coordinates of marker
	push(@coords, $x_mid - 0.005);
	push(@coords, $y_mid - 0.005);
	push(@coords, $x_mid - 0.005);
	push(@coords, $y_mid + 0.005);
	push(@coords, $x_mid + 0.005);
	push(@coords, $y_mid + 0.005);
	push(@coords, $x_mid + 0.005);
	push(@coords, $y_mid - 0.005);
	sagAddPolygon($jogMarkLayer, \@coords); # add marker to layer
      }
    }
  }
} # jogMetal2

################################################################################

# subroutine to collect layer statistics
sub layerStat {

  my $cell = $_[0]; # current cell
  my $layerName = $_[1]; # original layer
  my $statLayerName = $_[2]; # layer to get statistics

  my $layer = sagLayer($cell, $statLayerName); # get layer of interest 
  eval { $layer }; # check for existence of layer
  if (!$@) { # layer exists
    my %vertDist = (); # distribution of horizontal wires
    my %horizDist = (); # distribution of vertical wires
    my $totVertLen = 0; # total length of verical wires
    my $totHorizLen = 0; # total length of horizontal wires
    foreach my $path (sagPaths($layer)) { # traverse paths
      # get net name propery
      my @values = sagPropertyValues($path, "gdsprop 126");
      if ($#values > 0) { # check for multi-value
	  print "-E- unexpected multi-value net property\n";
      }
      # get widths and lengths of paths
      my $width = sagPathWidth($path);
      my @coords = sagPathCoordinates($path);
      my @extend = sagPathExtends($path);
      # traverese segments of path
      for (my $coord = 0; $coord < scalar @coords - 2; $coord += 2) {
	my $segLen = # get length of segment
	  abs($coords[$coord+3] - $coords[$coord+1]) +
	    abs($coords[$coord+2] - $coords[$coord]);
	if ($coords[$coord] eq $coords[$coord+2]) {
	  # segment is vertical, update commulators
	  $totVertLen += $segLen;
	  $vertDist{$width} += $segLen;
	}
	else {
	  # segment is horizontal, update commulators
	  $totHorizLen += $segLen;
	  $horizDist{$width} += $segLen;
	}
      }
    }
    
    if ($totVertLen > 0) {
      # collect and sort vertical wire widths repertoire
      my @widths;
      foreach my $width (keys(%vertDist)) {
	push(@widths, $width);
      }
      printf("\n$layerName vertical wire width distribution:\n");
      my @sortedWidths = sort(@widths); # init width reperoire
      my $aveWidth = 0; # init average width 
      foreach my $width (@sortedWidths) { # print width distribution
	$aveWidth += $width * $vertDist{$width}; # update average width
	my $percentage = ($vertDist{$width} * 100) / $totVertLen;
	printf("-I-  w = %4.2f ; l = %7d ; %6.2f\%\n", 
	       $width, $vertDist{$width}, $percentage);
      }
      printf("total length %7d ; average width %4.2f\n",
	     $totVertLen, $aveWidth / $totVertLen);
    }
    
    if ($totHorizLen > 0) {
      # collect and sort horizontal wire widths repertoire
      my @widths;
      foreach my $width (keys(%horizDist)) {
	push(@widths, $width);
      }
      printf("\n$layerName horizontal wire width distribution:\n");
      my @sortedWidths = sort(@widths); # init width reperoire
      my $aveWidth = 0; # init average width 
      foreach my $width (@sortedWidths) { # print width distribution
	$aveWidth += $width * $horizDist{$width}; # update average width
	my $percentage = ($horizDist{$width} * 100) / $totHorizLen;
	printf("-I-  w = %4.2f ; l = %7d ; %6.2f\%\n", 
	       $width, $horizDist{$width}, $percentage);
      }
      printf("total length %7d ; average width %4.2f\n",
	     $totHorizLen, $aveWidth / $totHorizLen);
    }
  }
} # layerStat

################################################################################

# $Id: mig.tcl,v 1.21 2006/02/18 16:31:26 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  mig.tcl                      Project: Penryn
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* (C) Copyright Intel Corporation, 2004
#* Licensed material -- Program property of Intel Corporation
#* All Rights Reserved
#*
#* This program is the property of Intel Corporation and is furnished
#* pursuant to a written license agreement. It may not be used, reproduced,
#* or disclosed to others except in accordance with the terms and conditions
#* of that agreement.
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Original Author: Matthew Roha 
#*
#* Functional description:
#* 
#* Collection of Genesys tcl procedures used for migration
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

catch {namespace delete mig}
namespace eval ::mig {


proc markVia {} {

  global fwk cellnamelist env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "markVia: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]
  set tech [cell_get_tech $cell]

  set targetcut(via1) 1
  set targetcut(via2) 1
  set targetcut(via3) 1

  set marklayer(via1:metal1) [tech_get_layer $tech "metal1ovz"]
  set marklayer(via1:metal2) [tech_get_layer $tech "via1ovz"]
  set marklayer(via2:metal2) [tech_get_layer $tech "metal2ovz"]
  set marklayer(via2:metal3) [tech_get_layer $tech "via2ovz"]
  set marklayer(via3:metal3) [tech_get_layer $tech "metal3ovz"]

  ::boo::IOUT 1 1 "markVia: *** Start Run ***"
  ::boo::IOUT 1 1 "markVia: Top Cell: $cellName"

  set cellnamelist {}
  template_hier $cell 0
  lappend cellnamelist "[cell_get_name $cell]"
  set cellnamelist [lsort -dictionary $cellnamelist]
  set cellnamelist [lsort -unique $cellnamelist]

  set i 0
  foreach celln $cellnamelist {
    incr i
    ::boo::IOUT 1 1 "markVia: cell_$i)   $celln"
  }
  ::boo::IOUT 1 1 "markVia: $i master cells in hierarchy"

  set cellmgr [cell_mgr_get_mgr]
  # For each cell in the cell list
  #::boo::IOUT 1 1 "About to iterate through cells"
  set i 0
  set plycount 0
  foreach celln $cellnamelist {
    ::boo::IOUT 1 1 "markVia: Iterating through cell: $celln"
    # Get pointer to cell and validate
    set cell [cell_mgr_get_cell $cellmgr $celln]
    # Get pointer to list of layout objects
    set loiter [cell_get_layout_objs_iter $cell]
    # For each layout object
    set totalvias 0
    set operatedvias 0
    set viaoperatedon 0
    set newplylist {}
    #::boo::IOUT 1 1 "Iterating through layout objs: $celln"
    while {[layout_obj_iter_advance $loiter]} {
      # Check if it is a via and annotate M1, M2, M3 enclosures only
      set lo [layout_obj_iter_get_current $loiter]
      if {[isa_via $lo]} {
	incr totalvias
	set cutlist [via_get_cuts $lo]
	#::boo::IOUT 1 1 "**** New Via ****"
	foreach cut $cutlist {
	  set cutlayer [polygon_get_layer $cut]
	  set cutlayern [layer_get_name $cutlayer]
	  set cuthandled [array names targetcut $cutlayern]
	  if {$cuthandled != ""} {
	    set enclosurelist [via_get_enclosures $lo]
	    foreach encl $enclosurelist {
	      set layer [polygon_get_layer $encl]
	      set layern [layer_get_name $layer]
	      set viaenccombo "$cutlayern:$layern"
	      #::boo::IOUT 1 1 "Combo search: $viaenccombo"
	      set combohandled [array names marklayer $viaenccombo]	      
	      if {$combohandled != ""} {
	      #::boo::IOUT 1 1 "Adding marker polygon"
		set newply [new_polygon_copy $encl]
		if { [polygon_set_layer $newply $marklayer($combohandled)] } {
		  lappend newplylist $newply
		  set viaoperatedon 1
		}
	      }
	    }  
	  }
	}
	if { $viaoperatedon } {
	  incr operatedvias
	  set viaoperatedon 0
	}
      }
    }
    foreach viamarker $newplylist {
      set success [geo_polygon_create $cell $viamarker]
      incr plycount
    }
    ::boo::IOUT 1 1 "markVia: $celln-> $operatedvias of $totalvias vias marked"
    incr i
  }
  ::boo::IOUT 1 1 "markVia: $i master cells had vias marked"
  ::boo::IOUT 1 1 "markVia: $plycount polygons added to database"
  ::boo::IOUT 1 1 "markVia: *** End Run ***"
}


proc fixSlivCont {} {

  global fwk cellnamelist env
  
  if {[$fwk getActiveView]!=0} {
    set cvi [[[$fwk getActiveView] getDocument] getCvi]
    catch {::boo:BaaCellViewInfo -this $cvi}
    set cellName [$cvi cget -memoryCellName]
    set cellView [$cvi cget -memoryViewName]
  } else {
    ::boo::EOUT 1 1 "No cell is currently open"
    destroy $base
    return
  }

  set cell [cell_mgr_get_cell [cell_mgr_get_mgr] $cellName $cellView]
  if {$cell == ""} {
    ::boo::EOUT 1 1 "Cell $cellName not found"
    return
  }

  set tech [cell_get_tech $cell]
  ::boo::IOUT 1 1 "fixSlivCont: *** Start Run ***"
  ::boo::IOUT 1 1 "fixSlivCont: Top Cell: $cellName"

  set cellnamelist {}
  template_hier $cell 0
  lappend cellnamelist "[cell_get_name $cell]"
  set cellnamelist [lsort -dictionary $cellnamelist]
  set cellnamelist [lsort -unique $cellnamelist]

  ::boo::IOUT 1 1 "fixSlivCont: [llength $cellnamelist] master cells in hierarchy"

  set cellmgr [cell_mgr_get_mgr]
  set gigenmgr [gigen_mgr_get_mgr]
  set targetgenerator [gigen_mgr_get_generator $gigenmgr "strap"]
  if {$targetgenerator == ""} {
    ::boo::EOUT 1 1 "fixSlivCont: Generator type strap not found"
    return
  }
  # For each cell in the cell list
  set slivcontpresent 0
  foreach celln $cellnamelist {
    # Get pointer to cell and validate
    set cell [cell_mgr_get_cell $cellmgr $celln $cellView]
    # Get pointer to list of layout objects
    set loiter [cell_get_layout_objs_iter $cell]
    # For each layout object
    set totalslivcontvias 0
    set converttocutvias 0
    set totalbadgenvias 0
    set resetgenvias 0
    set slivcontlist {}
    while {[layout_obj_iter_advance $loiter]} {
      # Check if it is a via, and also check if it is of type SLIVCONT
      set lo [layout_obj_iter_get_current $loiter]
      if {[isa_via $lo]} {
	set enclosurelist [via_get_enclosures $lo]
	set cutlist [via_get_cuts $lo]
	foreach cut $cutlist {
	  set cutlayer [polygon_get_layer $cut]
	  set cutlayern [layer_get_name $cutlayer]
	  if {$cutlayern == "slivcont"} {
	    incr totalslivcontvias
	    set slivcontpresent 1
	    geo_obj_set_bit $lo 0 1
	    set difffound 0
	    set metal1found 0
	    foreach enclosure $enclosurelist {
	      set enclosurelayern [layer_get_name [polygon_get_layer $enclosure]]
	      #::boo::IOUT 1 1 "Enclosure: $enclosurelayern"
	      if {[regexp {[n|p]wirediff} $enclosurelayern]} {
		set difffound 1
	      } elseif {$enclosurelayern == "metal1"} {
		set metal1found 1
	      }
	    }
	    if {$difffound == 1 && $metal1found == 1} {
	      #::boo::IOUT 1 1 "fixSlivCont: Via is strap"
	      set generator [via_get_generator $lo]
	      set generatorn [gigen_get_name $generator]
	      #::boo::IOUT 1 1 "fixSlivCont: Generator: $generatorn"
	      if {[regexp {smart_via1|libmosfetgen} $generatorn]} {
		incr totalbadgenvias
		if {[via_set_generator $lo $targetgenerator]} {
		  incr resetgenvias
		}
	      }
	    }
	    lappend slivcontlist $lo
	  }
	}
      }
    }
    foreach slivcontobj $slivcontlist {
      if { [udm_utils_convert_to_cuts $slivcontobj] } {
	incr converttocutvias
      }
    }
    if {$slivcontpresent == 1} {
      ::boo::IOUT 1 1 "fixSlivCont: SLIVCONT layer detected in cell: $celln"
      ::boo::IOUT 1 1 "fixSlivCont: $resetgenvias of $totalbadgenvias slivcont straps with wrong generator were reset: $celln"
      ::boo::IOUT 1 1 "fixSlivCont: $converttocutvias of $totalslivcontvias slivcont vias/contacts fixed: $celln"
      set slivcontpresent 0
    } else {
      ::boo::IOUT 1 1 "fixSlivCont: No SLIVCONT layers in cell: $celln"
    }
  }
  ::boo::IOUT 1 1 "fixSlivCont: *** End Run ***"
}




proc findSlivContCells {} {

  global fwk cellnamelist env
  
  if {[$fwk getActiveView]!=0} {
    set cvi [[[$fwk getActiveView] getDocument] getCvi]
    catch {::boo:BaaCellViewInfo -this $cvi}
    set cellName [$cvi cget -memoryCellName]
    set cellView [$cvi cget -memoryViewName]
  } else {
    ::boo::EOUT 1 1 "findSlivContCells: No cell is currently open"
    destroy $base
    return
  }

  set cell [cell_mgr_get_cell [cell_mgr_get_mgr] $cellName $cellView]
  if {$cell == ""} {
    ::boo::EOUT 1 1 "findSlivContCells: Cell $cellName not found"
    return
  }

  set tech [cell_get_tech $cell]

  ::boo::IOUT 1 1 "findSlivContCells: Top Cell: $cellName"

  set cellnamelist {}
  template_hier $cell 0
  lappend cellnamelist "[cell_get_name $cell]"
  set cellnamelist [lsort -dictionary $cellnamelist]
  set cellnamelist [lsort -unique $cellnamelist]

  set i 0
  foreach celln $cellnamelist {
    incr i
  }
  ::boo::IOUT 1 1 "findSlivContCells: $i master cells in hierarchy"

  set cellmgr [cell_mgr_get_mgr]
  # For each cell in the cell list
  set i 0
  set slivcontpresent 0
  foreach celln $cellnamelist {
    # Get pointer to cell and validate
    set cell [cell_mgr_get_cell $cellmgr $celln $cellView]
    # Get pointer to list of layout objects
    set loiter [cell_get_layout_objs_iter $cell]
    # For each layout object
    set totalvias 0
    set operatedvias 0
    while {[layout_obj_iter_advance $loiter]} {
      # Check if it is a via, and also check if it is of type SLIVCONT
      set lo [layout_obj_iter_get_current $loiter]
      if {[isa_via $lo]} {
	incr totalvias
	set enclosurelist [via_get_enclosures $lo]
	set cutlist [via_get_cuts $lo]
	foreach cut $cutlist {
	  set cutlayer [polygon_get_layer $cut]
	  set cutlayern [layer_get_name $cutlayer]
	  set strcmp [string compare $cutlayern "slivcont"]
	  if {$strcmp == 0} {
	    set slivcontpresent 1
	    break
	  }
	}
      }
      if {$slivcontpresent == 1} {
	break
      }
    }
    if {$slivcontpresent == 1} {
      ::boo::IOUT 1 1 "findSlivContCells: SLIVCONT layer detected in cell: $celln"
      set slivcontpresent 0
    } else {
      ::boo::IOUT 1 1 "findSlivContCells: No SLIVCONT layers in cell: $celln"
    }
  }
}


proc getCellHeightWidth {} {

  global fwk env
  
  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "getCellHeightWidth: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellView [cell_get_cell_view $cell 'lnf']

  set tech [cell_get_tech $cell]

  ::boo::IOUT 1 1 "getCellHeightWidth: Top Cell: $cellName"

  set cellbound [cell_get_boundary $cell]
  set cellbbox [gig_figure_get_bbox $cellbound]
  set height [tech_udm_to_micron $tech [bbox_get_height $cellbbox]]
  set width [tech_udm_to_micron $tech [bbox_get_width $cellbbox]]

  ::boo::IOUT 1 1 "getCellHeightWidth: Cell X Width: $width u"
  ::boo::IOUT 1 1 "getCellHeightWidth: Cell Y Height: $height u"
	    
}


proc deleteCell {cellName} {
  
  global fwk env cellnamelist
  
  if {[$fwk getActiveView]!=""} {
    set initcell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$initcell==""} { ::boo::EOUT 1 1 "deleteCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]

  if {[regexp {\*$} $cellName]} {
    ::boo::IOUT 1 1 "deleteCell: Found wildcard cell: $cellName"
    set prefix [string trimright $cellName "*"]
    ::boo::IOUT 1 1 "deleteCell: Prefix:( $prefix )"
    set cellnamelist {}
    template_hier $initcell 0
    lappend cellnamelist "[cell_get_name $initcell]"
    set cellnamelist [lsort -dictionary $cellnamelist]
    set cellnamelist [lsort -unique $cellnamelist]
    foreach celln $cellnamelist {
      ::boo::IOUT 1 1 "deleteCell: Scanning cell $celln"
      if {[regexp -- "^$prefix" $celln]} {
        ::boo::IOUT 1 1 "deleteCell: Found cell."
	set targetcell [cell_mgr_get_cell $cellmgr $celln "lnf"]
	set tempname [cell_get_name $targetcell]
	::boo::IOUT 1 1 "deleteCell: Deleting cell ($tempname)"
	set isRem [cell_mgr_rem_cell $cellmgr $targetcell 1]
	if {$isRem == 1} {
	  ::boo::IOUT 1 1 "deleteCell: Cell $cellName DELETED"
	} else {
	  ::boo::EOUT 1 1 "deleteCell: Cell $cellName not deleted successfully"
	}
      }
    }
  } else {
    ::boo::IOUT 1 1 "deleteCell: Attempting to delete cell: $cellName"
    set targetcell [cell_mgr_get_cell $cellmgr $cellName "lnf"]
    if {$targetcell == ""} {
      ::boo::IOUT 1 1 "deleteCell: Cell $cellName not found in hierarchy"
    } else {
      set isRem [cell_mgr_rem_cell $cellmgr $targetcell 1]
      if {$isRem == 1} {
	::boo::IOUT 1 1 "deleteCell: Cell $cellName DELETED"
      } else {
	::boo::EOUT 1 1 "deleteCell: Cell $cellName not deleted successfully"
      }
    }
  }
}


proc deleteBonusCells {} {

  global env

  set filename "$env(GLOBALS)/genbonus_cell.list.mrm"
  ::boo::IOUT 1 1 "***** Start: deleteBonusCells *****"
  ::boo::IOUT 1 1 "deleteBonusCells: Reading file: $filename"
  set file [open $filename r] 
  while { ![eof $file]} { 
    gets $file line
    set cellname [split $line]
    if {[regexp {\S+} $cellname]} {
      #::boo::IOUT 1 1 "deleteBonusCells: Cell $cellname"
      set return [deleteCell $cellname]
    }
  }
  close $file
  ::boo::IOUT 1 1 "***** End: deleteBonusCells *****"
}



proc template_hier {cell i} {
  global cellnamelist
  foreach inst [cell_get_cell_insts $cell] {
    lappend cellnamelist "[cell_get_name [inst_get_master_cell $inst]]"
    template_hier [inst_get_master_cell $inst] [expr $i+1]
  }
}


proc arrayTest {} {

  set testarray(hey) "hey"
  set testarray(there) "there"
  set testarray(heyhudim) "heyhudim"

  ::boo::IOUT 1 1 "arrayTest: *** Start ***"

  set list [array names testarray];
  foreach item $list {
    ::boo::IOUT 1 1 "arrayTest: $item"
  }
  set list {}
  set list [array names testarray "hey"]
  foreach item $list {
    ::boo::IOUT 1 1 "arrayTest: $item"
  }
  
}


proc cell_hier_depth_first {cell i} {
  global cellnamelist cellsalreadyprocessed
  
  set celln [cell_get_name $cell]
  set cellprocessed [array names cellsalreadyprocessed $celln]
  #::boo::IOUT 1 1 "cell_hier_depth_first: Cell processed $cellprocessed"
  if {$cellprocessed == ""} {
    #::boo::IOUT 1 1 "cell_hier_depth_first: Processing $celln."
    foreach inst [cell_get_cell_insts $cell] {
      cell_hier_depth_first [inst_get_master_cell $inst] [expr $i+1]
    }
    lappend cellnamelist $celln
    set cellsalreadyprocessed($celln) 1
  } else {
    #::boo::IOUT 1 1 "cell_hier_depth_first: Skipping $celln. Already processed"
  } 
}


proc deleteLayer {udmlayern} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "markLanding: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "deleteLayer: *** Start Run: $udmlayern ***"
  ::boo::IOUT 1 1 "deleteLayer: $cellName"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcell $cellnamelist {
    deleteLayerFromCell $targetcell $udmlayern
  }

  ::boo::IOUT 1 1 "deleteLayer: *** End Run ***"
}



proc deleteKOR {udmlayern} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "deleteKOR: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "deleteKOR: *** Start Run: $udmlayern ***"
  ::boo::IOUT 1 1 "deleteKOR: $cellName"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcell $cellnamelist {
    deleteKORFromCell $targetcell $udmlayern
  }

  ::boo::IOUT 1 1 "deleteKOR: *** End Run ***"
}





proc getLayDeviceCount {} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "getLayDeviceCount: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "getLayDeviceCount: *** Start Run: $cellName ***"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcell $cellnamelist {
    getLayDeviceCountFromCell $targetcell
  }

  ::boo::IOUT 1 1 "getLayDeviceCount: *** End Run ***"
}


proc getLayDeviceCountFromCell {celln} {

  global getLayDeviceCountFromCell fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "getLayDeviceCountFromCell: No cell is currently open"; return }

  #::boo::IOUT 1 1 "deleteLayerFromCell: $celln"

  set cellmgr [cell_mgr_get_mgr]
 
  set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]
  if {$cell == ""} {
    ::boo::IOUT 1 1 "getLayDeviceCountFromCell: Cell $celln not found in hierarchy"
  }

  set devcount 0

  set devices [cell_get_devices $cell]
  foreach device $devices {
    incr devcount
  }
  
  ::boo::IOUT 1 1 "getLayDeviceCountFromCell: Number of layout devices in cell $celln:($devcount)"
}

proc i0plus {celln} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "i0plus: No cell is currently open"; return }
  
  set cellmgr [cell_mgr_get_mgr]
  
  set cell [cell_mgr_get_cell $cellmgr $celln]
  if {$cell == ""} {
    ::boo::IOUT 1 1 "i0plus: Cell $celln not found in hierarchy"
  }

  set institer [cell_get_cell_insts_iter $cell]
  set instlist ""
  set newnamelist ""
  while {[icell_iter_advance $institer]} {
    
    set inst [icell_iter_get_current $institer]
    set instname [inst_get_name $inst]

    regsub {^i0\+} $instname "" newinstname
    lappend instlist $inst
    lappend newnamelist $newinstname
  }

  foreach inst $instlist newname $newnamelist {
    set instname [inst_get_name $inst]
    ::boo::IOUT 1 1 "i0plus: Renaming ($instname)->($newname)"
    inst_rename $inst $newname
  }

  set institer [cell_get_cell_insts_iter $cell]
  while {[icell_iter_advance $institer]} {
    set inst [icell_iter_get_current $institer]
    set instname [inst_get_name $inst]
    if {[regexp {^i0\+} $instname]} {
      ::boo::EOUT 1 1 "i0plus: Instance still has bad naming:($instname)"
    }
  }
}


proc deleteLayerFromCell {celln targetlayern} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "deleteLayerInCell: No cell is currently open"; return }

  #::boo::IOUT 1 1 "deleteLayerFromCell: $celln"

  set cellmgr [cell_mgr_get_mgr]
  set gocount 0
  set godeleted 0

  set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]
  if {$cell == ""} {
    ::boo::IOUT 1 1 "deleteLayerFromCell: Cell $celln not found in hierarchy"
  }

  set goiter [cell_get_geo_objs_iter $cell] 

  set targetgolist {}
  while {[geo_obj_iter_advance $goiter]} {
    
    set go [geo_obj_iter_get_current $goiter]
    set golayer [geo_obj_get_layer $go]
    set golayern [layer_get_name $golayer]

    if {$golayern == $targetlayern} {
      geo_obj_set_bit $go 0 1
      lappend targetgolist $go
      incr gocount
    }
  }
  foreach targetgo $targetgolist {
    if { [obj_destroy $targetgo] } {
      incr godeleted
    } else {
      ::boo::EOUT 1 1 "deleteLayerFromCell: Could not delete ply from layer $targetlayern in $celln"
    }
  }
  ::boo::IOUT 1 1 "deleteLayerFromCell: $godeleted of $gocount $targetlayern shapes deleted in cell $celln"
}




proc deleteKORFromCell {celln targetlayern} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "deleteKORFromCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]
  set gocount 0
  set godeleted 0

  set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]
  if {$cell == ""} {
    ::boo::IOUT 1 1 "deleteKORFromCell: Cell $celln not found in hierarchy"
  }

  set goiter [cell_get_geo_objs_iter $cell] 

  set targetgolist {}
  while {[geo_obj_iter_advance $goiter]} {
    set go [geo_obj_iter_get_current $goiter]
    if {[isa_kor $go]} {
      set golayer [geo_obj_get_layer $go]
      set golayern [layer_get_name $golayer]
      
      if {$golayern == $targetlayern} {
	lappend targetgolist $go
	incr gocount
      }
    }
  }
  foreach targetgo $targetgolist {
    if { [obj_destroy $targetgo] } {
      incr godeleted
    } else {
      ::boo::EOUT 1 1 "deleteKORFromCell: Could not delete ply from layer $targetlayern in $celln"
    }
  }
  ::boo::IOUT 1 1 "deleteKORFromCell: $godeleted of $gocount $targetlayern shapes deleted in cell $celln"
}



proc runCmdDepthFirst {cmd} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "runCmdDepthFirst: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "runCmdDepthFirst: --> Running command on all hierarchies: $cmd <---"
  ::boo::IOUT 1 1 "runCmdDepthFirst: *** Start Run ***"
  ::boo::IOUT 1 1 "runCmdDepthFirst: $cellName"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcelln $cellnamelist {
     runCmdDepthFirstInCell $targetcelln $cmd
  }

  ::boo::IOUT 1 1 "runCmdDepthFirst: *** End Run ***"
}



proc runCmdDepthFirstInCell {celln cmd} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "runCmdDepthFirstInCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]
  set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]

  if {$cell == ""} {
    ::boo::IOUT 1 1 "runCmdDepthFirstInCell: Cell $celln not found in hierarchy"
  }  
  ::boo::IOUT 1 1 "runCmdDepthFirstInCell: Start $celln"
  ::boo::IOUT 1 1 "runCmdDepthFirstInCell: --> Running: $cmd <cell ptr> <--"
  set status [$cmd $cell]
  ::boo::IOUT 1 1 "runCmdDepthFirstInCell: End $celln"
}



proc markTermInsts {} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "markTermInsts: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "markTermInsts: *** Start Run ***"
  ::boo::IOUT 1 1 "markTermInsts: $cellName"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcelln $cellnamelist {
    markTermInstsInCell $targetcelln
  }

  ::boo::IOUT 1 1 "markTermInsts: *** End Run ***"
}


proc markTermInstsInCell {celln} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "markTermInstsInCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]
  set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]

  if {$cell == ""} {
    ::boo::IOUT 1 1 "markTermInstsInCell: Cell $celln not found in hierarchy"
  }

  set tech [cell_get_tech $cell]
  set markti(wirepoly) [tech_get_layer $tech "wirepolykeepout"]
  set markti(diffcon)  [tech_get_layer $tech "diffconkeepout"]
  set markti(polycon)  [tech_get_layer $tech "polyconkeepout"]
  set markti(metal1)   [tech_get_layer $tech "metal1keepout"]
  set markti(metal2)   [tech_get_layer $tech "metal2keepout"]
  set markti(metal3)   [tech_get_layer $tech "metal3keepout"]
  set markti(metal4)   [tech_get_layer $tech "metal4keepout"]
  set markti(metal5)   [tech_get_layer $tech "metal5keepout"]
  set markti(metal6)   [tech_get_layer $tech "metal6keepout"]
  set markti(metal7)   [tech_get_layer $tech "metal7keepout"]
  set markti(metal8)   [tech_get_layer $tech "metal8keepout"]


  if {$cell == ""} {
    ::boo::IOUT 1 1 "markTermInstsInCell: Cell $celln not found in hierarchy"
  }
  ::boo::IOUT 1 1 "markTermInstsInCell: Start $celln"
  # For each instance in cell
  foreach inst [cell_get_cell_insts $cell] {
    set terminstcount 0
    set handledterminstcount 0
    set terminstmarked 0
    # For each terminst on instance
    set instn [inst_get_name $inst]
    foreach terminst [inst_get_term_insts $inst] {
      # If the terminst is on a target layer and it is not ported
      if {[layout_obj_get_ported $terminst] == 0} {
	set layern [layer_get_name [geo_obj_get_layer $terminst]]
	set layerhandled [array names markti $layern]
	if {$layerhandled != ""} {
	  set targetplys [geo_obj_get_polygons $terminst]
	  if {[llength $targetplys] != 1} {
	    ::boo::EOUT 1 1 "markTermInstsInCell: Num of polygons in terminst is not equal to one"
	    continue
	  }
	  set newply [new_polygon_copy [lindex $targetplys 0]]
	  if { [polygon_set_layer $newply $markti($layern)] } {
	    geo_polygon_create $cell $newply
	    incr terminstmarked
	  }
	  incr handledterminstcount
	}
      }
      incr terminstcount
    }
    ::boo::IOUT 1 1 "markTermInstsInCell: $handledterminstcount of $terminstcount terminsts eligible for marking in instance $instn"
    ::boo::IOUT 1 1 "markTermInstsInCell: $terminstmarked of $handledterminstcount terminsts marked for instance $instn"
  }
  ::boo::IOUT 1 1 "markTermInstsInCell: End $celln"
}



proc textNwell {} {

  global fwk cellnamelist cellsalreadyprocessed env

  set cell ""
  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "textNwell: No cell is currently open"; return }

  set cellName [cell_get_name $cell]
  set cellmgr [cell_mgr_get_mgr]

  ::boo::IOUT 1 1 "textNwell: *** Start Run ***"
  ::boo::IOUT 1 1 "textNwell: $cellName"

  set cellnamelist {}
  array unset cellsalreadyprocessed
  cell_hier_depth_first $cell 0

  foreach targetcelln $cellnamelist {
    markTermInstsInCell $targetcelln
  }

  ::boo::IOUT 1 1 "textNwell: *** End Run ***"
}


proc textNwellInCell {celln} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "textNwellInCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]
  set cell [cell_mgr_get_cell $cellmgr $celln]

  if {$cell == ""} {
    ::boo::IOUT 1 1 "textNwellInCell: Cell $celln not found in hierarchy"
  }

  set tech [cell_get_tech $cell]
  set targetlayern "nwell"
  # For each instance in cell
  
  set goiter [cell_get_geo_objs_iter $cell] 

  while {[geo_obj_iter_advance $goiter]} {
    
    set go [geo_obj_iter_get_current $goiter]
    set golayer [geo_obj_get_layer $go]
    set golayern [layer_get_name $golayer]
    
    if {$golayern == $targetlayern} {
      geo_obj_set_bit $go 0 1
      set plys [geo_obj_get_polygons]
      foreach ply $plys {
	set net [geo_polygon_get_net]
      }
      lappend targetgolist $go
      incr gocount
    }
  }
  foreach targetgo $targetgolist {
    if { [obj_destroy $targetgo] } {
      incr godeleted
    } else {
      ::boo::EOUT 1 1 "deleteLayerFromCell: Could not delete ply from layer $targetlayern in $celln"
    }
  }
}




proc gcell {} {

  global fwk env

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "markTermInstsInCell: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]
  set celln [cell_get_name $cell]

  if {$cell == ""} {
    ::boo::IOUT 1 1 "gcell: Cell $celln not found in hierarchy"
  }

  set tech [cell_get_tech $cell]
  set markerlayer [tech_get_layer $tech "annotation9"]

  set cellbound [cell_get_boundary $cell]
  set newply [new_polygon_copy $cellbound]
  polygon_set_layer $newply $markerlayer
  geo_polygon_create $cell $newply
}

proc gcoff {} {

  [::dpe::DpeCtl_get] setLayerPen "annotation9" 0 65280 0 0 65280 0 0 0 0 0 0 "solid" "" ""
  Redraw

}


proc gcon {} {

  [::dpe::DpeCtl_get] setLayerPen "annotation9" 0 65280 0 0 65280 0 0 0 0 4 0 "solid" "PdCross" ""
  Redraw

}



proc gmark {} {

  global fwk env cellnamelist

  if {[$fwk getActiveView]!=""} {
    set cell [[[$fwk getActiveView] getDocument] getCell]
  }
  if {$cell==""} { ::boo::EOUT 1 1 "gmark: No cell is currently open"; return }

  set cellmgr [cell_mgr_get_mgr]

  if {$cell == ""} {
    ::boo::IOUT 1 1 "gcell: Cell $celln not found in hierarchy"
  }

  set tech [cell_get_tech $cell]
  set markerlayer [tech_get_layer $tech "annotation9"]
  set markerlayern [layer_get_name $markerlayer]

  set cellnamelist {}
  template_hier $cell 0
  lappend cellnamelist "[cell_get_name $cell]"
  set cellnamelist [lsort -dictionary $cellnamelist]
  set cellnamelist [lsort -unique $cellnamelist]

  foreach celln $cellnamelist {
    ::boo::IOUT 1 1 "Working on cell: $celln"
    # Get pointer to cell and validate
    set cell [cell_mgr_get_cell $cellmgr $celln]
    # Get pointer to list of geo objects
    set goiter [cell_get_geo_objs_iter $cell]
    set targetgolist {}
    while {[geo_obj_iter_advance $goiter]} {
      set go [geo_obj_iter_get_current $goiter]
      set golayern [layer_get_name [geo_obj_get_layer $go]]
      if {$golayern == $markerlayern} {
	lappend targetgolist $go
      }
    }
    foreach targetgo $targetgolist {
      set bbox [bbox_from_xy -1 -1 1 1]
      ::lvcmds::createUserDefinedMarker "grid_$celln" "markerio" $bbox
      break
    }
  }
}

}

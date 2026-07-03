# $Id: fmrMig.tcl,v 1.1 2010/01/08 19:57:06 mroha Exp $
#
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* Filename:  fmrMig.tcl                      Project: Ivy Bridge
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#*
#* (C) Copyright Intel Corporation, 2008
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
#* Collection of Genesys tcl procedures used for migration and analysis
#*
#* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

catch {namespace delete fmrMig}
namespace eval fmrMig {
  
  global env
  
  
  proc getLeafCellMetricsFromHier {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getLeafCellMetricsFromHier: No cell is currently open"; return }
    set masterName [cell_get_name $master]
    set masterTech [cell_get_tech $master]
    set masterView [getActiveViewName]

    ::boo::IOUT 1 1 "getLeafCellMetricsFromHier: Run started for Cell->$masterName"
    # Identify leaf cells by prefix or diffusion content
    set techName [tech_get_name $masterTech]
    set diffLayers [list $techName:pwirediff $techName:nwirediff]
    set hierCells [udm_utils_get_hierarchy $master 1]
    set leafCellNames {}
    array set leafCellHash {}
    foreach targetCell $hierCells {
      set targetCellName [cell_get_name $targetCell]
      if {[regexp {^(w\d+)?(yg0|yg4|yg7|yn4|ai0|an4|ai3|ai7|axx)} $targetCellName]} {
	lappend leafCellNames $targetCellName
	set leafCellHash($targetCellName) $targetCell
	set cellContainsDevice($targetCellName) 0
      } else {
	set diffObjList [cell_get_geo_objs_filtered_list $targetCell [cell_get_boundary $targetCell] {} $diffLayers]
	if {[llength $diffObjList] > 0} {
	  lappend leafCellNames $targetCellName
	  set leafCellHash($targetCellName) $targetCell
	}
      }
    }


    # Found out later there is a better way to do this
    # Grab all instances to get instance count
    # Record which instances are standard cell instances so we can determine whether modular cells are stand alone or inside standard cells
    array set instCountHash {}
    array set stdCellInstHash {}
    set insts [cell_get_cell_insts $master 99]
    udm_app_set_virtual_hierarchy_depth 99
    foreach inst $insts {
      set cellName [cell_get_name [inst_get_master_cell $inst]]
      if {[lsearch $leafCellNames $cellName] >= 0} {
	if {[info exist instCountHash($cellName)]} {
	  incr instCountHash($cellName)
	} else {
	  set instCountHash($cellName) 1
	}
      }
      if {[regexp {^(yg0|ai0)} $cellName]} {
	set instName [inst_get_name $inst]
	set stdCellInstHash($instName) 1
      }
    }

    array set modularCellInstCountHash {}
    foreach inst $insts {
      set cellName [cell_get_name [inst_get_master_cell $inst]]
      if {[regexp {^(yg4|ai3)} $cellName]} {
	set modularCellInstName [inst_get_name $inst]
	set instanceList [split $modularCellInstName "/"]
	if {[llength $instanceList] > 0} {
	  set instanceList [lrange $instanceList 0 end-1]
	  set parentInstName [join $instanceList "/"]
	  if {![info exist stdCellInstHash($parentInstName)]} {
	    if {[info exist modularCellInstCountHash($cellName)]} {
	      incr modularCellInstCountHash($cellName)
	    } else {
	      set modularCellInstCountHash($cellName) 1
	    }
	  }
	}
      }
    }
    udm_app_set_virtual_hierarchy_depth 0
    unset insts
    foreach targetCellName [array names leafCellHash] {
      set cvmanager [::boo::CellViewMgr_getCellViewMgr]
      set cvinfo [::boo::CellViewMgr_getCellViewInfo $cvmanager $targetCellName $masterView]
      set libName [::boo::BaaCellViewInfo_libraryName_get $cvinfo]
      if {$libName == ""} {
        set libName "LOCAL_COPY"
      }
      ::boo::IOUT 1 1 "getLeafCellMetricsFromHier: TopLevel->$masterName  Cell->$targetCellName  Lib->$libName  InstCount->$instCountHash($targetCellName)"
      if {[info exist modularCellInstCountHash($targetCellName)]} {
	::boo::IOUT 1 1 "getLeafCellMetricsFromHier: TopLevel->$masterName  Cell->$targetCellName  ModularStandAloneInstCount->$modularCellInstCountHash($targetCellName)"
      }
      getCellMetrics $leafCellHash($targetCellName)
    }
  }
  

  proc getCellMetricsWithHierDevCount {{master ""} {debug 0}} {
    
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getCellMetrics: No cell is currently open"; return }
    set masterName [cell_get_name $master]
    set masterTech [cell_get_tech $master]
    set masterView [getActiveViewName]
    
    set masterbound [cell_get_boundary $master]
    set masterbbox [gig_figure_get_bbox $masterbound]
    set lowerleft [bbox_get_ll $masterbbox]
    set height [tech_udm_to_micron $masterTech [bbox_get_height $masterbbox]]
    set width [tech_udm_to_micron $masterTech [bbox_get_width $masterbbox]]
    set hierdevcount [getUniqueLayDeviceCountFromHier $master]
    ::boo::IOUT 1 1 "getCellMetricsWithHierDevCount: Cell->$masterName  LowerLeft->$lowerleft  XWidth->${width}u  YHeight->${height}u  HierDevCount->$hierdevcount"
  }
  

  proc getCellMetrics {{master ""} {debug 0}} {
    
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getCellMetrics: No cell is currently open"; return }
    set masterName [cell_get_name $master]
    set masterTech [cell_get_tech $master]
    set masterView [getActiveViewName]
    
    set masterbound [cell_get_boundary $master]
    set masterbbox [gig_figure_get_bbox $masterbound]
    set lowerleft [bbox_get_ll $masterbbox]
    set height [tech_udm_to_micron $masterTech [bbox_get_height $masterbbox]]
    set width [tech_udm_to_micron $masterTech [bbox_get_width $masterbbox]]
    set devcount [getLayDeviceCount $master]
    set dummydevcount [getDummyLayDeviceCount $master]
    set diffcount [getDiffPlyCount $master]
    ::boo::IOUT 1 1 "getCellMetrics: Cell->$masterName  LowerLeft->$lowerleft  XWidth->${width}u  YHeight->${height}u  DevCount->$devcount  DummyDevCount->$dummydevcount  DiffPlyCount->$diffcount"
  }
 
 
  proc getUniqueLayDeviceCountFromHier {{master ""} {debug 0}} {
    
    global fwk cellnamelist cellsalreadyprocessed env
    
    if {$master==""} { ::boo::EOUT 1 1 "getUniqueLayDeviceCountFromHier: No cell is currently open"; return }
    
    set cellName [cell_get_name $master]
    set cellmgr [cell_mgr_get_mgr]
    
    set cellnamelist {}
    array unset cellsalreadyprocessed
    cell_hier_depth_first $master 0
    
    set uniquecount 0
    set devcount 0
    foreach targetcell $cellnamelist {
      set devcount [getLayDeviceCountFromCell $targetcell]
      set uniquecount [expr $uniquecount + $devcount] 
    }
    return $uniquecount
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
 

  proc getDummyLayDeviceCount {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "logiDevicesInCell: No cell is currently open"; return }
    
    set dummydevcount 0
    set devices [cell_get_devices $master]
    set mosCat [udm_cat_get_ucm_mos_cat]
    foreach device $devices {
      set pinInsts [igen_get_pin_insts $device]
      set syncount 0
      set powercount 0
      foreach pinInst $pinInsts {
	set net [ipin_get_external_net $pinInst]
        set netName [net_get_name $net]
	if {[regexp {^syn} $netName]} {
	  incr syncount
	} elseif {[regexp {^(vc|vss|gnac)} $netName]} {
	  incr powercount
	}
      }
      if {$powercount == 4} {
	incr dummydevcount
      } elseif {$syncount > 2} {
	incr dummydevcount
      }
    }
    return $dummydevcount
  }
    



  proc TestFunc {{master ""} {debug 0}} {
    # Get all objects in cell
    set cellObjs [cell_get_geo_objs $master]	
    # Get pdiff ply list
    set pdiffPlyList [::fmgGig::returnPolys $cellObjs pwirediff vcc]
    # Get ndiff ply list
    set ndiffPlyList [::fmgGig::returnPolys $cellObjs nwirediff vss]
    set diffPlyCount [expr [llength $pdiffPlyList] + [llength $ndiffPlyList]]
    # If there are any pdiff or ndiff plys
    if {$diffPlyCount > 0} {
      # Get named ndiff ply list
      foreach ply $ndiffPlyList {
	if {[::fmgGluon::objGetNet $ply] == "vss"} {
	  set $deviceList [gig_op_and_two_lists [list $ply] $nwellPlyList]
	  if {[llength $deviceList] == 0} {
	    incr devcount
	  }
	}
      }
      foreach ply $pdiffPlyList {
	if {[::fmgGluon::objGetNet $ply] == "vcc"} {
	  set $deviceList [gig_op_and_two_lists [list $ply] $nwellPlyList]
	  if {[llength $deviceList] > 0} {
	    incr devcount
	  }
	}
      }
    }
    return $devcount
  }


  proc getLayDeviceCount {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getLayDeviceCount: No cell is currently open"; return }
    
    set devcount 0
    set devices [cell_get_devices $master]
    foreach device $devices {
      incr devcount
    }

    return $devcount
  }


  proc getDiffPlyCount {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getDiffPlyCount: No cell is currently open"; return }

    set techName [tech_get_name [cell_get_tech $master]]
    set diffLayers [list $techName:pwirediff $techName:nwirediff]
    set diffObjList [cell_get_geo_objs_filtered_list $master [cell_get_boundary $master] {} $diffLayers]
    return [llength $diffObjList]
  }


  proc getLayDeviceCountFromCellname {celln} {
    
    global fwk env
    
    if {[$fwk getActiveView]!=""} {
      set cell [[[$fwk getActiveView] getDocument] getCell]
    }
    if {$cell==""} { ::boo::EOUT 1 1 "getLayDeviceCountFromCellname: No cell is currently open"; return }
    
  #::boo::IOUT 1 1 "deleteLayerFromCell: $celln"
    
    set cellmgr [cell_mgr_get_mgr]
    
    set cell [cell_mgr_get_cell $cellmgr $celln "lnf"]
    if {$cell == ""} {
      ::boo::IOUT 1 1 "getLayDeviceCountFromCellname: Cell $celln not found in hierarchy"
    }
    
    return [getLayDeviceCount $cell]
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



}

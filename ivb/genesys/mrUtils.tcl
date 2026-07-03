catch {namespace delete mrUtils}
namespace eval mrUtils {
  
  global env
  
  
  proc printTermLayers {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getLeafCellMetricsFromHier: No cell is currently open"; return }
    set masterName [cell_get_name $master]
    set masterTech [cell_get_tech $master]
    set masterView [getActiveViewName]
    set techName [tech_get_name $masterTech]
    array set termCountHash {}
    
    ::boo::IOUT 1 1 "printTermLayers: Run started for Cell->$masterName"
    # Identify leaf cells by prefix or diffusion content
    set piniter [cell_get_pins_iter $master]
    while {[pin_iter_advance $piniter]} {
      set pin [pin_iter_get_current $piniter]
      set terms [pin_get_terms $pin]
      foreach term $terms {
	set layerName [layer_get_name [term_get_layer $term]]
	if {[info exist termCountHash($layerName)]} {
	  incr termCountHash($layerName)
	} else {
          set termCountHash($layerName) 1
	}
      }
    }
    set targetFile /usr/users/home2/mroha/${masterName}.termfile
    set targetHandle [open $targetFile w]
    foreach targetLayer [array names termCountHash] {
      puts $targetHandle "${masterName},${targetLayer},$termCountHash($targetLayer)"
    }
    close $targetHandle
    ::boo::IOUT 1 1 "printTermLayers: Run complete for Cell->$masterName"
  }

}
catch {namespace delete mrSkl}
namespace eval mrSkl {

  global env


  proc thisIsTheName {{master ""} {debug 0}} {
    if {$master == ""} {
      set master [getCv]
    }
    if {$master == ""} { ::boo::EOUT 1 1 "getLeafCellMetricsFromHier: No cell is currently open"; return }
    set masterName [cell_get_name $master]
    set masterTech [cell_get_tech $master]
    set masterView [getActiveViewName]

    ::boo::IOUT 1 1 "thisIsTheName: Cellname->($masterName)"

  }
}

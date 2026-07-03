#!/bin/sh -f

# \
exec $CAD_ROOT/cafe/1.2.5/cafe -script $0 $*

lassign [split $argv] cell targetsn

if {[catch {ispl_parse_circuit -circuit $cell -macro $cell -file $targetsn} msg]} {
  error "$msg"
}

set macros [ispl_list_macros]

foreach macro $macros {
  set digitaldevicecount 0
  set analogdevicecount 0
  set netcount 0
  set connectioncount 0
  array set netCountHash {}
  set instancemasterlist {}
  foreach element [ispl_list_elements -macro $macro] {
    ispl_element -macro $macro -type type -template template $element
    if {$type == "mos"} {
      set valuecount 0
      foreach value [ispl_list_values -macro $macro -types -evaluate_type $element] {
        if {$valuecount == 2} {
          if {[regexp {^0\.(052|08(0)?|058|088|116)\s+REAL} $value]} {
            incr analogdevicecount
          } else {
            incr digitaldevicecount
          }
          break
        }
        incr valuecount
      }
    } elseif {$type == "instance"} {
      lappend instancemasterlist $template
    }
    foreach connection [ispl_list_connections -macro $macro -element $element] {
      if {![regexp {^(vc|vs)} $connection]} {
        if {[info exist netCountHash($connection)]} {
          incr netCountHash($connection)
        } else {
          set netCountHash($connection) 1
        }
      }
    }
  }
  set netcount [array size netCountHash]
  foreach targetConnection [array names netCountHash] {
    set connectioncount [expr $netCountHash($targetConnection) + $connectioncount]
    if {$netCountHash($targetConnection) > 1} {
      incr connectioncount -1
    }
  }

  puts "getSNMetrics: macro->($macro)  digitalDeviceCount->($digitaldevicecount)  analogDeviceCount->($analogdevicecount)  netCount->($netcount)  connectionCount->($connectioncount)  instMasters->($instancemasterlist)"
  array unset netCountHash
}

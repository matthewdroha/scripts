#!/bin/sh -f

# \
exec $CAD_ROOT/cafe/1.2.5/cafe -script $0 $*

lassign [split $argv] cell targetsn

if {[catch {ispl_parse_circuit -circuit $cell -macro $cell -file $targetsn} msg]} {
  error "$msg"
}

set macros [ispl_list_macros]

foreach macro $macros {
  set devcount 0
  foreach element [ispl_list_elements -macro $macro] {
    ispl_element -macro $macro -type type -template template $element
    puts "type: $type"
    if {$type == "mos"} {
      incr devcount
    }
  }
  puts "getSNDeviceCount: Number of schematic devices in cell $macro:($devcount)"
}

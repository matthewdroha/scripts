#!/bin/sh -f

# \
exec $CAFE/cafe -script $0 $*

lassign [split $argv] cell targetsn zlfile outsn

set file [open $zlfile r]
while { ![eof $file] } {
  gets $file line
  lassign [split $line] key newz newl
  set targetz($key) $newz
  set targetl($key) $newl
}

if {[catch {ispl_parse_circuit -circuit $cell -macro $cell -file $targetsn} msg]} {
  error "$msg"
}

set macros [ispl_list_macros]


foreach macro $macros {
  foreach element [ispl_list_elements -macro $macro] {
    ispl_element -macro $macro -type type -template template $element
    if {$type == "mos"} {
      lassign [ispl_list_values -macro $macro $element] pnType size length
      lassign [ispl_list_connections -macro $macro -element $element -limit 0] drain gate source
      set key1 "${macro}__${source}__${gate}__${drain}__${pnType}"
      set key2 "${macro}__${drain}__${gate}__${source}__${pnType}"
      
      set key1handled [array names targetz -exact $key1]
      set key2handled [array names targetz -exact $key2]
      if { $key1handled != "" } {
	ispl_set_element_value -macro $macro $element -index 1 $targetz($key1)
	ispl_set_element_value -macro $macro $element -index 2 $targetl($key1)
	puts "Z(P1): Resized $key1 (${size}) => ($targetz($key1))"
	puts "L(P1): Resized $key1 (${length}) => ($targetl($key1))"
      } elseif { $key2handled != "" } {
	ispl_set_element_value -macro $macro $element -index 1 $targetz($key2)
	ispl_set_element_value -macro $macro $element -index 2 $targetl($key2)
	puts "Z(P2): Resized $key2 (${size}) => ($targetz($key2))"
	puts "L(P2): Resized $key2 (${length}) => ($targetl($key2))"
      } else {
	puts "-W- Key not matched: $key1"
      }
    }
  }
}

set outfile [open $outsn w]
puts $outfile ".GLOBAL vcc vss"
ispl_write_ispec -macro $cell -recursive $outfile
close $outfile


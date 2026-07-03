#!/bin/sh -f

# \
exec $CAFE/cafe -script $0 $*

lassign [split $argv] cell insn outsn

if {[catch {ispl_parse_circuit -circuit $cell -macro $cell -file $insn} msg]} {
  error "$msg"
}

set outfile [open $outsn w]
puts $outfile ".GLOBAL vcc vss"
ispl_write_ispec -macro $cell -recursive $outfile
close $outfile
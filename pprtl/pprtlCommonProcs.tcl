# proc iproc_pprtl_remove_lib_generated_clock
# Searches for all HIP generated clocks and removes them
# mroha: Taken from the MCSS clocks header from Remi's flow and updated for rtl_shell and pwr_shell,  removed some loops.
# PLL -> ADOP -> PDOP --> LDOP --> RCB --> LCB -> ICG
proc iproc_pprtl_remove_lib_generated_clock {} {
  set procname [lindex [info level 0] 0]
  set procname [string trimleft $procname "::"]
  set printmargin [ expr [string length $procname] + 35 ]

  puts "### START $procname\n"

  # mroha: pwr_shell and rtl_shell have different attributes for lib generated clocks
  set filterstring 0
  if { [info exists ::synopsys_program_name] && ( $::synopsys_program_name == "pt_shell" || $::synopsys_program_name == "pwr_shell" ) } {
    puts [format "%-${printmargin}s\n" "${procname}: -I- Inside pt_shell or pwr_shell"]
    set filterstring "is_generated_from_lib_cell"
  } elseif { [info exists ::synopsys_program_name] && ( $::synopsys_program_name == "fc_shell" || $::synopsys_program_name == "rtl_shell" ) } {
    puts [format "%-${printmargin}s\n" "${procname}: -I- Inside fc_shell or rtl_shell"]
    set filterstring "is_lib_cell_generated"
  }

  set clockcount 0
  if { [string first "is_" $filterstring] >= 0 } {
    foreach_in_collection genclock [get_clocks -quiet -filter "${filterstring} == true"] {
      puts [format "%-${printmargin}s: %s" "${procname}: -I- Lib generated clock removed" [get_attribute $genclock full_name]]
      remove_generated_clock $genclock
      incr clockcount 
    }
  } else {
    puts [format "%-${printmargin}s\n" "${procname}: -W- synopsys_program_name not supported"]
  }
  puts [format "%-${printmargin}s: %s\n" "${procname}: -I- Count of generated clocks found and removed" $clockcount]

  puts "\n### FINISH $procname\n"
}


# proc iproc_pprtl_disable_dop_scanclk_arc
# mroha: Searches for DOP/glbdrv stdcells given a stdcell pattern and disables the timing arc between scanclk and clkout.
proc iproc_pprtl_disable_dop_scanclk_arc {{doppattern g1mgdv*}} {
  set procname [lindex [info level 0] 0]
  set procname [string trimleft $procname "::"]
  set printmargin [ expr [string length $procname] + 35 ]

  puts "### START $procname\n"

  set dopcells [get_cells -quiet -hierarchical -filter "ref_name =~ $doppattern"]
  set dopcellcount [sizeof_collection $dopcells]
  puts [format "%-${printmargin}s: %s\n" "${procname}: -I- DOP cell count" $dopcellcount]

  if {$dopcellcount > 0 }  {
    foreach_in_collection cell $dopcells {
      set cellname [get_attribute $cell full_name]
      set refmodulename [get_attribute $cell ref_name]
      puts [format "%-${printmargin}s: %s" "${procname}: -I- Running set_disable_timing on" $cellname]
      set_disable_timing -from scanclk -to clkout [get_object_name  $cell]
      incr doprefs($refmodulename)
    }
    puts "\n"
    foreach refmodulename [lsort [array names doprefs]] {
      puts [format "%-${printmargin}s: %s" "${procname}: -I- DOP Library Cell (${refmodulename}) usage count" $doprefs($refmodulename)]
    }
  } else {
    puts "${procname} -I- No DOP cells present in design"   
  }

  puts "\n### FINISH $procname\n"
}


# proc iproc_pprtl_generate_clock_for_dop_clkout
# mroha: Searches for DOP/glbdrv stdcells given a stdcell pattern and adds a generated clock to clkout based on the first clock returned from clkin
# Meant to augment existing clocks if input constraints are incomplete.  Ideally not required.
# Proc will not add a generated clock if clkin and clkout both have associated clocks
# Proc will select the first clock returned on clkin
# Proc will select first master clock object returned for selected root clock 
proc iproc_pprtl_generate_clock_for_dop_clkout {{doppattern g1mgdv*}} {
  set procname [lindex [info level 0] 0]
  set procname [string trimleft $procname "::"]
  set printmargin [ expr [string length $procname] + 35 ]

  puts "### START $procname\n"

  set dopcells [get_cells -quiet -hierarchical -filter "ref_name =~ $doppattern"]
  set dopcellcount [sizeof_collection $dopcells]
  puts [format "%-${printmargin}s : %s\n" "${procname}: -I- DOP cell count" $dopcellcount]

  set genclkcount 0
  if {$dopcellcount > 0 }  {
    foreach_in_collection cell $dopcells {
      incr instcount
      set cellname [get_attribute $cell full_name]
      set refmodulename [get_attribute $cell ref_name]
      puts [format "%-${printmargin}s: %s" "${procname}: -I- Processing Instance" $cellname]
      set gdv_inst_clkin  [get_pins -of $cell -filter "lib_pin_name==clkin"]
      set gdv_inst_clkout [get_pins -of $cell -filter "lib_pin_name==clkout"]
      set gdv_inst_clks [get_attribute $gdv_inst_clkin clocks]
      set gdv_inst_clkout_clks [get_attribute $gdv_inst_clkout clocks]
      set gdv_inst_clks_name [get_attribute $gdv_inst_clks full_name] 

      # mroha: get_attribute clocks can return more than one clock
      # mroha: each clock could have multiple source pins
      if { [sizeof_collection $gdv_inst_clks] > 0 } {
        puts [format "%-${printmargin}s: %s" "${procname}: -I- Master Clocks" $gdv_inst_clks_name]
        set targetMasterClock [index_collection $gdv_inst_clks 0]
        set targetMasterClockName [get_attribute $targetMasterClock full_name]
        # mroha: If more than one clock was returned, select the first one
        if { [sizeof_collection $gdv_inst_clks] > 1 } {
          puts [format "%-${printmargin}s" "${procname}: -I- Multiple master clocks returned"]
          puts [format "%-${printmargin}s: %s" "${procname}: -I- Reduced Master Clocks" $targetMasterClockName]
	}
        set gdv_inst_clk_source [get_attribute $targetMasterClock sources]
        set gdv_inst_clk_source_name [get_object_name $gdv_inst_clk_source]
        if { [sizeof_collection $gdv_inst_clk_source] > 0 } {
          puts [format "%-${printmargin}s: %s" "${procname}: -I- Master Clock Sources" $gdv_inst_clk_source_name]
	  set targetMasterClockSource [index_collection $gdv_inst_clk_source 0]
	  set targetMasterClockSourceName [get_attribute $targetMasterClockSource full_name]
	  # mroha:If more than one master clock source was returned,  select the first one for the single target clock
          if { [sizeof_collection $gdv_inst_clk_source] > 1 } {
	    puts [format "%-${printmargin}s" "${procname}: -I- Multiple master clock sources returned"]
            puts [format "%-${printmargin}s: %s" "${procname}: -I- Reduced Master Clock Sources" $targetMasterClockSourceName]
          }

	  # mroha: Create generated clock if clkout doesn't already have one
          if { [sizeof_collection $gdv_inst_clkout_clks] > 0 } {
            puts [format "%-${printmargin}s: %s" "${procname}: -I- Instance already has clocks on clkin and clockout. Skipping. Instance number" $instcount] 	
            continue 
          }
          set generatedClockName ${targetMasterClockName}_gen_${instcount}
	  set clkoutName [get_object_name $gdv_inst_clkout] 
	  puts [format "%-${printmargin}s" "${procname}: -I- Running create_generated_clock for $generatedClockName"]
          create_generated_clock -name $generatedClockName -add -divide_by 1 -master_clock $targetMasterClockName -source $targetMasterClockSourceName $clkoutName
	  incr genclkcount
	} else {
          puts [format "%-${printmargin}s" "${procname}: -W- No master clock source found on instance clkin pin"]
        }
      } else {
        puts [format "%-${printmargin}s" "${procname}: -W- No master clock found on instance clkin pin"]
      }
      puts "\n"
    }
    puts "\n"
    puts [format "%-${printmargin}s : %s" "${procname}:-I- DOP cell count" $dopcellcount]
    puts [format "%-${printmargin}s : %s" "${procname}:-I- DOP cells with generated clock applied" $genclkcount]
    puts "\n"
  } else {
    puts "${procname} No DOP cells present in design"   
  }
  puts "\n### FINISH $procname\n"
}

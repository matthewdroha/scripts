#fub,cell,device_count

lassign [split $argv] cell snfile
puts "cell->($cell)"
puts "snfile->($snfile)"

ispl_parse_circuit -circuit $cell -macro $cell -file $snfile
set macros [ispl_list_macros]
foreach macro $macros {
  set elements [ispl_list_elements -macro $macro]
  foreach element $elements {
    ispl_element -macro $macro -type type -template template $element
    if {$type == "mos"} {
      foreach value [ispl_list_values -macro $macro -types -evaluate_type $element] {
        puts "element->($element) info->($value)"
      }
    }
    # puts "macro->($macro) element->($element) type->($type) template->($template)"
  } 
}
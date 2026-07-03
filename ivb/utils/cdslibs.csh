#!/usr/intel/bin/tcsh
grep DEFINE $CDSLIB | perl -e 'while (<>) {@record = split; $lib = $record[1]; @record = split("/", $record[2]); pop @record; $tag = pop @record; $tag =~ s/work/LATEST/; printf "%-30s %s\n", $lib, $tag;}' | egrep '_(lay|sch|net)' | sort

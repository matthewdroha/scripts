#!/usr/intel/bin/tcsh -f
set ctech = "/p/hdk/cad/ctech/s14nm/c4v19ww40d_hdk162_mtps_v20ww16d"
set ctech_exp = "/p/hdk/cad/ctech/s14nm/ctech_exp_c4v20ww12e_hdk161_mtps_v20ww18b"

foreach f ( ${cwd}/*.ctech.*.t )
  set infile = `basename $f`
  set outfile = `echo $infile | sed 's/\.t//'`
  /usr/intel/pkgs/perl/5.26.1/bin/tpage --define CTECH=$ctech --define CTECH_EXP=$ctech_exp $infile > $outfile
  echo "Generated: $outfile"
end

#!/usr/intel/bin/tcsh -f
set dut = "USCG"
set custs = (MTL GNR)
set facets = ""
set mc = "pciess_no_stf_ult_scan_ctlr"
# Comment partitions if you don't want to split the tests by febe block
set partitions = (pciess_no_stf_ult_scan_ctlr)
set partition_prefix = ""
set partition_suffix = ""
set iproot = "/nfs/fm/disks/w.mroha.102/ip-ultiscan-mat161-baseline-20200526-WW22.2/generated_TSA"

set targetdir = "${iproot}/t"

if( ! -d $targetdir ) then
  mkdir $targetdir
  if( -d $targetdir ) then
    echo "-I- Target dir created: $targetdir"
  else
    echo "-F- Target dir not created: $targetdir"
    exit 1
  endif 
endif

foreach cust ($custs) 
  foreach f ( ${cwd}/* )
    set targetfile = `basename $f`
    set partition = ""
    set febeblock = ""
    set febeblockdefines = ""
    switch( "$targetfile" )
      case "*.t.block.template":
        set testprefix = `echo $targetfile | sed s/\.t\.block\.template//`
        if($?partitions) then
          foreach partition ($partitions)
            set febeblock = "${partition_prefix}${partition}${partition_suffix}"
            set targetfile = "${testprefix}_${febeblock}_${cust}.t"
            set fulltargetfile = "${targetdir}/${targetfile}"
            /usr/intel/pkgs/perl/5.26.1/bin/tpage --define DUT=$dut --define CUST=$cust --define FACETS=$facets --define IP_ROOT=$iproot --define MC=$mc --define PARTITION=$partition --define FEBEBLOCK=$febeblock $f > $fulltargetfile
            echo "tpage out(.t template indiv febeblocks): $targetfile"
          end
        else
          set targetfile = "${testprefix}_${cust}.t"
          set fulltargetfile = "${targetdir}/${targetfile}"
          /usr/intel/pkgs/perl/5.26.1/bin/tpage --define DUT=$dut --define CUST=$cust --define FACETS=$facets --define IP_ROOT=$iproot --define MC=$mc --define PARTITION=$partition --define FEBEBLOCK=$febeblock $f > $fulltargetfile
          echo "tpage out(.t template febeblock wildcard): $targetfile"
        endif
        breaksw
   
      case "testrules.yml.template":
        set testprefix = `echo $targetfile | sed s/\.template//`
        set targetfile = "${testprefix}.${cust}"
        set fulltargetfile = "${targetdir}/${targetfile}"
        if ($?partitions) then
          @ partitionnum = 0
          foreach partition ($partitions)
            set febeblock = "${partition_prefix}${partition}${partition_suffix}"
            set febeblockdefines = "${febeblockdefines} --define FEBEBLOCK${partitionnum}=$febeblock"
            @ partitionnum++
          end
          /usr/intel/pkgs/perl/5.26.1/bin/tpage --define CUST=$cust $febeblockdefines $f > $fulltargetfile
          echo "tpage out(testrules.yml): $targetfile"
        endif
        breaksw

      case "*.t.template":
        set testprefix = `echo $targetfile | sed s/\.t\.template//`
        set targetfile = "${testprefix}_${cust}.t"
        set fulltargetfile = "${targetdir}/${targetfile}"
        /usr/intel/pkgs/perl/5.26.1/bin/tpage --define DUT=$dut --define CUST=$cust --define FACETS=$facets --define IP_ROOT=$iproot --define MC=$mc --define PARTITION=$partition  --define FEBEBLOCK=$febeblock $f > $fulltargetfile
        echo "tpage out(.t template default): $targetfile"
        chmod +x $fulltargetfile
        breaksw

      default:
        set targetfile = `echo $targetfile | sed s/\.template//`
        set fulltargetfile = "${targetdir}/${targetfile}"
        /usr/intel/pkgs/perl/5.26.1/bin/tpage --define DUT=$dut --define CUST=$cust --define FACETS=$facets --define IP_ROOT=$iproot --define MC=$mc --define PARTITION=$partition  --define FEBEBLOCK=$febeblock $f > $fulltargetfile
        echo "tpage out(default): $targetfile"
        chmod +x $fulltargetfile
    endsw
  end
end

echo "prove targetdir: $targetdir"

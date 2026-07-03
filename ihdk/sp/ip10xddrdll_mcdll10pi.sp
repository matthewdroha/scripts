** SRCSTATUS: PACKAGE=Production,RUN_MODE=Flat,ERROR_COUNT=0,WARNING_COUNT=2,WAIVERS_COUNT=0,USERID=cvphan,DATE_RUN=Aug 25 13:30:30 2014,SETUP_VER=DTS_14ww29 3,SRC_VER=p14ww33,SIM_VER=p1274 0_14ww31 5,COLL_VER=p1274 0_14ww32 2
** SRCWAIVERS: NONE
** generated for: hspiceD
** generated on: Sep  3 15:05:52 2014
** design library name: ip10xddrdll_ihdk_sch
** design cell name: ip10xddrdll_mcdll10pi
** design view name: schematic
.global vss

************** Start Of Includes ******************
*******************************************************
* /p/hdk/cad/process/p1274.0_sim/p1274.0_14ww35.2/erc/erc_global_corners_file.hsp:tttt
*******************************************************
 
 
************** End Of Includes ******************
** library name: ec0basic
** cell name: ec0nand02al1n06x5
** view name: schematic
.subckt ec0nand02al1n06x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n06x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n06x5/schematic 
* CELLLOG ec0basic nil ec0nand02al1n06x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n06x5/symbol 
* TAG: schematic 
* COUNTER: 43393 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=204e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=204e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=204e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=204e-9 m=1
.ends ec0nand02al1n06x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02al1n02x5
** view name: schematic
.subckt ec0nand02al1n02x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n02x5/schematic 
* CELLLOG ec0basic nil ec0nand02al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 48325 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=68e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0nand02al1n02x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000al1n02x5
** view name: schematic
.subckt ec0inv000al1n02x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n02x5/schematic 
* CELLLOG ec0basic nil ec0inv000al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 31331 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0inv000al1n02x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02al1n03x5
** view name: schematic
.subckt ec0nand02al1n03x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n03x5/schematic 
* CELLLOG ec0basic nil ec0nand02al1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n03x5/symbol 
* TAG: schematic 
* COUNTER: 43375 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=102e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=102e-9 m=1
.ends ec0nand02al1n03x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmpideccell
** view name: schematic
.subckt ip10xddrdll_mcmpideccell banksel mxlsb prevsel sel0 sel1 vccxx
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpideccell schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpideccell/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpideccell symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpideccell/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 12587 
* Version: 1.2 
* INPUT:  mxlsb  prevsel  vccxx 
*+ banksel 
* OUTPUT:  sel1  sel0 
* ----------------------------
*.PININFO  mxlsb:I  prevsel:I  vccxx:I 
*.PININFO  banksel:I 
*.PININFO  sel1:O  sel0:O 
* ----------------------------

xnand2 prop0_b sel0_b sel0 vccxx ec0nand02al1n06x5
xnand4 sel0_b sel1_b sel1 vccxx ec0nand02al1n06x5
xnand0 prevsel mxlsb prop0_b vccxx ec0nand02al1n02x5
xnand3 banksel mxlsb sel1_b vccxx ec0nand02al1n02x5
xinv0 mxlsb lsb_b vccxx ec0inv000al1n02x5
xnand1 banksel lsb_b sel0_b vccxx ec0nand02al1n03x5
.ends ip10xddrdll_mcmpideccell
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdecdrv
** view name: schematic
.subckt ip10xddrdll_mcmdecdrv mx0banksel mx0lsb mx0prevsel mx0sel[0] mx0sel[1] mx1banksel mx1lsb mx1prevsel mx1sel[0] mx1sel[1] mx2banksel mx2lsb mx2prevsel mx2sel[0] mx2sel[1] mx3banksel mx3lsb mx3prevsel mx3sel[0] mx3sel[1] mxd0banksel mxd0lsb mxd0prevsel mxd0sel[0] mxd0sel[1] vccxx
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdecdrv schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdecdrv/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdecdrv symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdecdrv/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 17494 
* Version: 1.3 
* INPUT:  mx0banksel  mx3prevsel  mx1banksel 
*+ mx3lsb  mx3banksel  vccxx  mx2lsb 
*+ mx1prevsel  mx2banksel  mx0lsb  mx1lsb 
*+ mx0prevsel  mxd0lsb  mxd0banksel  mxd0prevsel 
*+ mx2prevsel 
* OUTPUT:  mx2sel[0]  mx1sel[0]  mx0sel[0] 
*+ mx2sel[1]  mx0sel[1]  mx3sel[1]  mx3sel[0] 
*+ mxd0sel[0]  mxd0sel[1]  mx1sel[1] 
* ----------------------------
*.PININFO  mx0banksel:I  mx3prevsel:I  mx1banksel:I 
*.PININFO  mx3lsb:I  mx3banksel:I  vccxx:I  mx2lsb:I 
*.PININFO  mx1prevsel:I  mx2banksel:I  mx0lsb:I  mx1lsb:I 
*.PININFO  mx0prevsel:I  mxd0lsb:I  mxd0banksel:I  mxd0prevsel:I 
*.PININFO  mx2prevsel:I 
*.PININFO  mx2sel[0]:O  mx1sel[0]:O  mx0sel[0]:O 
*.PININFO  mx2sel[1]:O  mx0sel[1]:O  mx3sel[1]:O  mx3sel[0]:O 
*.PININFO  mxd0sel[0]:O  mxd0sel[1]:O  mx1sel[1]:O 
* ----------------------------

xmx2drv mx2banksel mx2lsb mx2prevsel mx2sel[0] mx2sel[1] vccxx ip10xddrdll_mcmpideccell
xmx3drv mx3banksel mx3lsb mx3prevsel mx3sel[0] mx3sel[1] vccxx ip10xddrdll_mcmpideccell
xmx0drv mx0banksel mx0lsb mx0prevsel mx0sel[0] mx0sel[1] vccxx ip10xddrdll_mcmpideccell
xmx1drv mx1banksel mx1lsb mx1prevsel mx1sel[0] mx1sel[1] vccxx ip10xddrdll_mcmpideccell
ximxrefdrv mxd0banksel mxd0lsb mxd0prevsel mxd0sel[0] mxd0sel[1] vccxx ip10xddrdll_mcmpideccell
.ends ip10xddrdll_mcmdecdrv
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000an1n03x5
** view name: schematic
.subckt ec0inv000an1n03x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000an1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n03x5/schematic 
* CELLLOG ec0basic nil ec0inv000an1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n03x5/symbol 
* TAG: schematic 
* COUNTER: 33970 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=102e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=102e-9 m=1
.ends ec0inv000an1n03x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000an1n02x5
** view name: schematic
.subckt ec0inv000an1n02x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000an1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n02x5/schematic 
* CELLLOG ec0basic nil ec0inv000an1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n02x5/symbol 
* TAG: schematic 
* COUNTER: 34187 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=68e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=68e-9 m=1
.ends ec0inv000an1n02x5
** end of subcircuit definition.

** library name: e3modules
** cell name: e3ylcin00af
** view name: schematic
** end of subcircuit definition.

** library name: e9prim
** cell name: e9ytdf
** view name: schematic
** end of subcircuit definition.

** library name: e9prim
** cell name: e9yinf
** view name: schematic
** end of subcircuit definition.

** library name: e9prim
** cell name: e9yxff
** view name: schematic
** end of subcircuit definition.

** library name: e3modules
** cell name: e3ylpc000af
** view name: schematic
** end of subcircuit definition.

** library name: e3modules
** cell name: e3yino000af
** view name: schematic
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0lsn090an1n04x3
** view name: schematic
.subckt ec0lsn090an1n04x3 clkb d o1 vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0lsn090an1n04x3 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn090an1n04x3/schematic 
* CELLLOG ec0sequential nil ec0lsn090an1n04x3 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn090an1n04x3/symbol 
* TAG: schematic 
* COUNTER: 224902 
* Version: Unmanaged 
* INPUT:  d  vcc  clkb 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  d:I  vcc:I  clkb:I 
*.PININFO  o1:O 
* ----------------------------

mg1.qn0 nc1 clkb vss vss n l=20e-9 w=34e-9 m=1
mg1.qp0 nc1 clkb vcc vcc p l=20e-9 w=34e-9 m=1
mg0.g3.qnd g0.g3.n2 g0.nk1 vss vss n l=20e-9 w=34e-9 m=1
mg0.g3.qnck nk2 clkb g0.g3.n2 vss n l=20e-9 w=34e-9 m=1
mg0.g3.qpd g0.g3.n1 g0.nk1 vcc vcc p l=20e-9 w=68e-9 m=1
mg0.g3.qpckb nk2 nc1 g0.g3.n1 vcc p l=20e-9 w=68e-9 m=1
mg0.g99.qna g0.nk1 nk2 vss vss n l=20e-9 w=34e-9 m=1
mg0.g99.qpa g0.nk1 nk2 vcc vcc p l=20e-9 w=68e-9 m=1
mg0.g1.qns nk2 nc1 d vss n l=20e-9 w=34e-9 m=1
mg0.g1.qpsb nk2 clkb d vcc p l=20e-9 w=68e-9 m=1
mg101.qpa o1 nk2 vcc vcc p l=20e-9 w=136e-9 m=1
mg101.qna o1 nk2 vss vss n l=20e-9 w=136e-9 m=1
.ends ec0lsn090an1n04x3
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand03an1n06x5
** view name: schematic
.subckt ec0nand03an1n06x5 a b c o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand03an1n06x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03an1n06x5/schematic 
* CELLLOG ec0basic nil ec0nand03an1n06x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03an1n06x5/symbol 
* TAG: schematic 
* COUNTER: 67298 
* Version: Unmanaged 
* INPUT:  a  b  c 
*+ vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  c:I 
*.PININFO  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a n1 vss n l=20e-9 w=204e-9 m=1
mqn2 n1 b n2 vss n l=20e-9 w=204e-9 m=1
mqn3 n2 c vss vss n l=20e-9 w=204e-9 m=1
mqp2 o1 b vcc vcc p l=20e-9 w=136e-9 m=1
mqp3 o1 c vcc vcc p l=20e-9 w=136e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=136e-9 m=1
.ends ec0nand03an1n06x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0lsn090al1n02x5
** view name: schematic
.subckt ec0lsn090al1n02x5 clkb d o1 vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0lsn090al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn090al1n02x5/schematic 
* CELLLOG ec0sequential nil ec0lsn090al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn090al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 221228 
* Version: Unmanaged 
* INPUT:  d  vcc  clkb 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  d:I  vcc:I  clkb:I 
*.PININFO  o1:O 
* ----------------------------

mg1.qn0 nc1 clkb vss vss n l=20e-9 w=34e-9 m=1
mg1.qp0 nc1 clkb vcc vcc p l=20e-9 w=34e-9 m=1
mg0.g3.qnd g0.g3.n2 g0.nk1 vss vss nsvt l=20e-9 w=34e-9 m=1
mg0.g3.qnck nk2 clkb g0.g3.n2 vss nsvt l=20e-9 w=34e-9 m=1
mg0.g3.qpd g0.g3.n1 g0.nk1 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg0.g3.qpckb nk2 nc1 g0.g3.n1 vcc psvt l=20e-9 w=68e-9 m=1
mg0.g99.qna g0.nk1 nk2 vss vss nsvt l=20e-9 w=34e-9 m=1
mg0.g99.qpa g0.nk1 nk2 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg0.g1.qns nk2 nc1 d vss nsvt l=20e-9 w=34e-9 m=1
mg0.g1.qpsb nk2 clkb d vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o1 nk2 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qna o1 nk2 vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0lsn090al1n02x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000an1n06x5
** view name: schematic
.subckt ec0inv000an1n06x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000an1n06x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n06x5/schematic 
* CELLLOG ec0basic nil ec0inv000an1n06x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n06x5/symbol 
* TAG: schematic 
* COUNTER: 31340 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=204e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=204e-9 m=1
.ends ec0inv000an1n06x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000an1n20x5
** view name: schematic
.subckt ec0inv000an1n20x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000an1n20x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n20x5/schematic 
* CELLLOG ec0basic nil ec0inv000an1n20x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n20x5/symbol 
* TAG: schematic 
* COUNTER: 33970 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=680e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=680e-9 m=1
.ends ec0inv000an1n20x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmbankdec4
** view name: schematic
.subckt ip10xddrdll_mcmbankdec4 mxbanksel[3] mxbanksel[2] mxbanksel[1] mxbanksel[0] mxlsb picode[5] picode[4] picode[3] picodeupdate pien pienout vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmbankdec4 schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmbankdec4/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmbankdec4 symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmbankdec4/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 23185 
* Version: 1.3 
* INPUT:  vccxx_lv  picode[3]  picode[4] 
*+ picode[5]  picodeupdate  pien 
* OUTPUT:  mxlsb  pienout  mxbanksel[0] 
*+ mxbanksel[1]  mxbanksel[2]  mxbanksel[3] 
* ----------------------------
*.PININFO  vccxx_lv:I  picode[3]:I  picode[4]:I 
*.PININFO  picode[5]:I  picodeupdate:I  pien:I 
*.PININFO  mxlsb:O  pienout:O  mxbanksel[0]:O 
*.PININFO  mxbanksel[1]:O  mxbanksel[2]:O  mxbanksel[3]:O 
* ----------------------------

xi70 pien pien_b vccxx_lv ec0inv000an1n03x5
xinv16 pien_b banken vccxx_lv ec0inv000an1n03x5
xinn0 vss softhi vccxx_lv ec0inv000an1n03x5
xinv13 muxen muxdisable vccxx_lv ec0inv000an1n02x5
xinv18 muxen_b muxen vccxx_lv ec0inv000an1n02x5
xinv17 banken muxen_b vccxx_lv ec0inv000an1n02x5
xinv14 muxdisable pienout vccxx_lv ec0inv000an1n02x5
xlatch1[3] picodeupdate bnksel_b[3] mxbanksel[3] vccxx_lv ec0lsn090an1n04x3
xlatch1[2] picodeupdate bnksel_b[2] mxbanksel[2] vccxx_lv ec0lsn090an1n04x3
xlatch1[1] picodeupdate bnksel_b[1] mxbanksel[1] vccxx_lv ec0lsn090an1n04x3
xlatch1[0] picodeupdate bnksel_b[0] mxbanksel[0] vccxx_lv ec0lsn090an1n04x3
xbnknand1 picode_b[5] picode[4] softhi bnksel_b[1] vccxx_lv ec0nand03an1n06x5
xbnknand3 picode[5] picode[4] softhi bnksel_b[3] vccxx_lv ec0nand03an1n06x5
xbnknand2 picode[5] picode_b[4] softhi bnksel_b[2] vccxx_lv ec0nand03an1n06x5
xbnknand0 picode_b[5] picode_b[4] softhi bnksel_b[0] vccxx_lv ec0nand03an1n06x5
xlan0 picodeupdate picode[3] picode_b[3] vccxx_lv ec0lsn090al1n02x5
xinv11 picode[5] picode_b[5] vccxx_lv ec0inv000an1n06x5
xinv10 picode[4] picode_b[4] vccxx_lv ec0inv000an1n06x5
xinv12 picode_b[3] mxlsb vccxx_lv ec0inv000an1n20x5
.ends ip10xddrdll_mcmbankdec4
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000al1n08x5
** view name: schematic
.subckt ec0inv000al1n08x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000al1n08x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n08x5/schematic 
* CELLLOG ec0basic nil ec0inv000al1n08x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n08x5/symbol 
* TAG: schematic 
* COUNTER: 31114 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vcc vcc psvt l=20e-9 w=272e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=272e-9 m=1
.ends ec0inv000al1n08x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0lsn010al1d05x5
** view name: schematic
.subckt ec0lsn010al1d05x5 clk d o1 vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0lsn010al1d05x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn010al1d05x5/schematic 
* CELLLOG ec0sequential nil ec0lsn010al1d05x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lsn010al1d05x5/symbol 
* TAG: schematic 
* COUNTER: 209620 
* Version: Unmanaged 
* INPUT:  clk  d  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  clk:I  d:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mg1.qn0 nc1 clk vss vss n l=20e-9 w=34e-9 m=1
mg1.qp0 nc1 clk vcc vcc p l=20e-9 w=68e-9 m=1
mg0.g3.qnd g0.g3.n2 g0.nk1 vss vss nsvt l=20e-9 w=34e-9 m=1
mg0.g3.qnck nk2 nc1 g0.g3.n2 vss nsvt l=20e-9 w=34e-9 m=1
mg0.g3.qpd g0.g3.n1 g0.nk1 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg0.g3.qpckb nk2 clk g0.g3.n1 vcc psvt l=20e-9 w=68e-9 m=1
mg0.g99.qna g0.nk1 nk2 vss vss nsvt l=20e-9 w=34e-9 m=1
mg0.g99.qpa g0.nk1 nk2 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg0.g1.qns nk2 clk d vss nsvt l=20e-9 w=68e-9 m=1
mg0.g1.qpsb nk2 nc1 d vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o1 nk2 vcc vcc psvt l=20e-9 w=170e-9 m=1
mg101.qna o1 nk2 vss vss nsvt l=20e-9 w=170e-9 m=1
.ends ec0lsn010al1d05x5
** end of subcircuit definition.

** library name: ec0complex
** cell name: ec0xnr002an1n03x5
** view name: schematic
.subckt ec0xnr002an1n03x5 a b out0 vcc
* ----------------------------
* CELLLOG ec0complex nil ec0xnr002an1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0complex/ec0xnr002an1n03x5/schematic 
* CELLLOG ec0complex nil ec0xnr002an1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0complex/ec0xnr002an1n03x5/symbol 
* TAG: schematic 
* COUNTER: 72479 
* Version: Unmanaged 
* INPUT:  b  a  vcc 
* OUTPUT:  out0 
* ----------------------------
*.PININFO  b:I  a:I  vcc:I 
*.PININFO  out0:O 
* ----------------------------

mg4.qns out0 a n2 vss n l=20e-9 w=102e-9 m=1
mg4.qpsb out0 n3 n2 vcc p l=20e-9 w=102e-9 m=1
mg2.qns out0 n3 n1 vss n l=20e-9 w=102e-9 m=1
mg2.qpsb out0 a n1 vcc p l=20e-9 w=102e-9 m=1
mg5.qna n3 a vss vss n l=20e-9 w=68e-9 m=1
mg5.qpa n3 a vcc vcc p l=20e-9 w=68e-9 m=1
mg1.qna n1 b vss vss n l=20e-9 w=204e-9 m=1
mg1.qpa n1 b vcc vcc p l=20e-9 w=204e-9 m=1
mg3.qna n2 n1 vss vss n l=20e-9 w=136e-9 m=1
mg3.qpa n2 n1 vcc vcc p l=20e-9 w=136e-9 m=1
.ends ec0xnr002an1n03x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nor002al1n02x5
** view name: schematic
.subckt ec0nor002al1n02x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nor002al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor002al1n02x5/schematic 
* CELLLOG ec0basic nil ec0nor002al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor002al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 42008 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a n1 vcc psvt l=20e-9 w=102e-9 m=1
mqp2 n1 b vcc vcc psvt l=20e-9 w=102e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn2 o1 b vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0nor002al1n02x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmthdec
** view name: schematic
.subckt ip10xddrdll_mcmthdec picode[3] picode[2] picode[1] picode[0] picodeupdate pithcode[7] pithcode[6] pithcode[5] pithcode[4] pithcode[3] pithcode[2] pithcode[1] pithcode[0] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmthdec schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmthdec/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmthdec symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmthdec/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 37160 
* Version: 1.2 
* INPUT:  vccxx_lv  picode[0]  picode[1] 
*+ picode[2]  picode[3]  picodeupdate 
* OUTPUT:  pithcode[0]  pithcode[1]  pithcode[2] 
*+ pithcode[3]  pithcode[4]  pithcode[5]  pithcode[6] 
*+ pithcode[7] 
* ----------------------------
*.PININFO  vccxx_lv:I  picode[0]:I  picode[1]:I 
*.PININFO  picode[2]:I  picode[3]:I  picodeupdate:I 
*.PININFO  pithcode[0]:O  pithcode[1]:O  pithcode[2]:O 
*.PININFO  pithcode[3]:O  pithcode[4]:O  pithcode[5]:O  pithcode[6]:O 
*.PININFO  pithcode[7]:O 
* ----------------------------

xna6 thcode_b[1] thcodeb_b[0] thcode[0] vccxx_lv ec0nand02al1n02x5
xna0 picode[1] picode[0] thcodea_b[2] vccxx_lv ec0nand02al1n02x5
xna1 thcodea_b[2] thcode_b[3] thcode[2] vccxx_lv ec0nand02al1n02x5
xna4 thcode_b[5] thcodeb_b[4] thcode[4] vccxx_lv ec0nand02al1n02x5
xna3 picode[2] picode[0] thcodeb_b[4] vccxx_lv ec0nand02al1n02x5
xna2 picode[2] picode[1] thcode_b[5] vccxx_lv ec0nand02al1n02x5
xinv9 picode[3] picode_b[3] vccxx_lv ec0inv000al1n08x5
xlan0[7] picodeupdate pithcode_b[7] pithcode[7] vccxx_lv ec0lsn010al1d05x5
xlan0[6] picodeupdate pithcode_b[6] pithcode[6] vccxx_lv ec0lsn010al1d05x5
xlan0[5] picodeupdate pithcode_b[5] pithcode[5] vccxx_lv ec0lsn010al1d05x5
xlan0[4] picodeupdate pithcode_b[4] pithcode[4] vccxx_lv ec0lsn010al1d05x5
xlan0[3] picodeupdate pithcode_b[3] pithcode[3] vccxx_lv ec0lsn010al1d05x5
xlan0[2] picodeupdate pithcode_b[2] pithcode[2] vccxx_lv ec0lsn010al1d05x5
xlan0[1] picodeupdate pithcode_b[1] pithcode[1] vccxx_lv ec0lsn010al1d05x5
xlan0[0] picodeupdate pithcode_b[0] pithcode[0] vccxx_lv ec0lsn010al1d05x5
xinv5 picode[0] thcodeb_b[6] vccxx_lv ec0inv000al1n02x5
xinv7 vss thcode_b[7] vccxx_lv ec0inv000al1n02x5
xinv6 thcode_b[7] thcode[7] vccxx_lv ec0inv000al1n02x5
xinv8 picode[0] thcodeb_b[0] vccxx_lv ec0inv000al1n02x5
xinv1 thcode_b[1] thcode[1] vccxx_lv ec0inv000al1n02x5
xinv4 thcode_b[5] thcode[5] vccxx_lv ec0inv000al1n02x5
xinv3 thcode_b[3] thcode[3] vccxx_lv ec0inv000al1n02x5
xinv2 picode[2] thcode_b[3] vccxx_lv ec0inv000al1n02x5
xyor[7] picode_b[3] thcode[7] pithcode_b[7] vccxx_lv ec0xnr002an1n03x5
xyor[6] picode_b[3] thcode[6] pithcode_b[6] vccxx_lv ec0xnr002an1n03x5
xyor[5] picode_b[3] thcode[5] pithcode_b[5] vccxx_lv ec0xnr002an1n03x5
xyor[4] picode_b[3] thcode[4] pithcode_b[4] vccxx_lv ec0xnr002an1n03x5
xyor[3] picode_b[3] thcode[3] pithcode_b[3] vccxx_lv ec0xnr002an1n03x5
xyor[2] picode_b[3] thcode[2] pithcode_b[2] vccxx_lv ec0xnr002an1n03x5
xyor[1] picode_b[3] thcode[1] pithcode_b[1] vccxx_lv ec0xnr002an1n03x5
xyor[0] picode_b[3] thcode[0] pithcode_b[0] vccxx_lv ec0xnr002an1n03x5
xno2 thcode_b[5] thcodeb_b[6] thcode[6] vccxx_lv ec0nor002al1n02x5
xno1 picode[2] picode[1] thcode_b[1] vccxx_lv ec0nor002al1n02x5
.ends ip10xddrdll_mcmthdec
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmpredec_x4pi_skl
** view name: schematic
.subckt ip10xddrdll_mcmpredec_x4pi_skl mxbanksel[3] mxbanksel[2] mxbanksel[1] mxbanksel[0] mxlsb picode[5] picode[4] picode[3] picode[2] picode[1] picode[0] pien pienable pithcode[7] pithcode[6] pithcode[5] pithcode[4] pithcode[3] pithcode[2] pithcode[1] pithcode[0] piupdate vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpredec_x4pi_skl schematic 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpredec_x4pi_skl/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpredec_x4pi_skl symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpredec_x4pi_skl/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 13992 
* Version: 1.3 
* INPUT:  vccxx_lv  pien  picode[0] 
*+ picode[1]  picode[2]  picode[3]  picode[4] 
*+ picode[5]  piupdate 
* OUTPUT:  mxlsb  mxbanksel[0]  mxbanksel[1] 
*+ mxbanksel[2]  mxbanksel[3]  pienable  pithcode[0] 
*+ pithcode[1]  pithcode[2]  pithcode[3]  pithcode[4] 
*+ pithcode[5]  pithcode[6]  pithcode[7] 
* ----------------------------
*.PININFO  vccxx_lv:I  pien:I  picode[0]:I 
*.PININFO  picode[1]:I  picode[2]:I  picode[3]:I  picode[4]:I 
*.PININFO  picode[5]:I  piupdate:I 
*.PININFO  mxlsb:O  mxbanksel[0]:O  mxbanksel[1]:O 
*.PININFO  mxbanksel[2]:O  mxbanksel[3]:O  pienable:O  pithcode[0]:O 
*.PININFO  pithcode[1]:O  pithcode[2]:O  pithcode[3]:O  pithcode[4]:O 
*.PININFO  pithcode[5]:O  pithcode[6]:O  pithcode[7]:O 
* ----------------------------

xbankdec mxbanksel[3] mxbanksel[2] mxbanksel[1] mxbanksel[0] mxlsb picode[5] picode[4] picode[3] piupdate pien pienable vccxx_lv ip10xddrdll_mcmbankdec4
xthdec picode[3] picode[2] picode[1] picode[0] piupdate pithcode[7] pithcode[6] pithcode[5] pithcode[4] pithcode[3] pithcode[2] pithcode[1] pithcode[0] vccxx_lv ip10xddrdll_mcmthdec
.ends ip10xddrdll_mcmpredec_x4pi_skl
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmpidecoder_x4pi
** view name: schematic
.subckt ip10xddrdll_mcmpidecoder_x4pi d0clken d0code[5] d0code[4] d0code[3] d0code[2] d0code[1] d0code[0] d0enable mux0sel[1] mux0sel[0] mux0sel[3] mux0sel[2] mux0sel[5] mux0sel[4] mux0sel[7] mux0sel[6] mux1sel[1] mux1sel[0] mux1sel[3] mux1sel[2] mux1sel[5] mux1sel[4] mux1sel[7] mux1sel[6] mux2sel[1] mux2sel[0] mux2sel[3] mux2sel[2] mux2sel[5] mux2sel[4] mux2sel[7] mux2sel[6] mux3sel[1] mux3sel[0] mux3sel[3] mux3sel[2] mux3sel[5] mux3sel[4] mux3sel[7] mux3sel[6] muxd0sel[1] muxd0sel[0] muxd0sel[3] muxd0sel[2] muxd0sel[5] muxd0sel[4] muxd0sel[7] muxd0sel[6] pi0code[5] pi0code[4] pi0code[3] pi0code[2] pi0code[1] pi0code[0] pi0enable pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] pi1code[5] pi1code[4] pi1code[3] pi1code[2] pi1code[1] pi1code[0] pi1enable pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] pi2code[5] pi2code[4] pi2code[3] pi2code[2] pi2code[1] pi2code[0] pi2enable pi2thcode[7]
+pi2thcode[6] pi2thcode[5] pi2thcode[4] pi2thcode[3] pi2thcode[2] pi2thcode[1] pi2thcode[0] pi3code[5] pi3code[4] pi3code[3] pi3code[2] pi3code[1] pi3code[0] pi3enable pi3thcode[7] pi3thcode[6] pi3thcode[5] pi3thcode[4] pi3thcode[3] pi3thcode[2] pi3thcode[1] pi3thcode[0] pid0thcode[7] pid0thcode[6] pid0thcode[5] pid0thcode[4] pid0thcode[3] pid0thcode[2] pid0thcode[1] pid0thcode[0] pienable[0] pienable[1] pienable[2] pienable[3] piupdateqnnnh[3] piupdateqnnnh[2] piupdateqnnnh[1] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpidecoder_x4pi schematic 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpidecoder_x4pi/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpidecoder_x4pi symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpidecoder_x4pi/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 84988 
* Version: 1.2 
* INPUT:  vccxx_lv  pi3enable  pi2enable 
*+ pi0enable  pi1enable  d0enable  pi0code[0] 
*+ pi0code[1]  pi0code[2]  pi0code[3]  pi0code[4] 
*+ pi0code[5]  pi1code[0]  pi1code[1]  pi1code[2] 
*+ pi1code[3]  pi1code[4]  pi1code[5]  pi2code[0] 
*+ pi2code[1]  pi2code[2]  pi2code[3]  pi2code[4] 
*+ pi2code[5]  pi3code[0]  pi3code[1]  pi3code[2] 
*+ pi3code[3]  pi3code[4]  pi3code[5]  d0code[0] 
*+ d0code[1]  d0code[2]  d0code[3]  d0code[4] 
*+ d0code[5]  piupdateqnnnh[1]  piupdateqnnnh[2]  piupdateqnnnh[3] 
* OUTPUT:  pi3thcode[0]  pi3thcode[1]  pi3thcode[2] 
*+ pi3thcode[3]  pi3thcode[4]  pi3thcode[5]  pi3thcode[6] 
*+ pi3thcode[7]  pi1thcode[0]  pi1thcode[1]  pi1thcode[2] 
*+ pi1thcode[3]  pi1thcode[4]  pi1thcode[5]  pi1thcode[6] 
*+ pi1thcode[7]  pi2thcode[0]  pi2thcode[1]  pi2thcode[2] 
*+ pi2thcode[3]  pi2thcode[4]  pi2thcode[5]  pi2thcode[6] 
*+ pi2thcode[7]  pi0thcode[0]  pi0thcode[1]  pi0thcode[2] 
*+ pi0thcode[3]  pi0thcode[4]  pi0thcode[5]  pi0thcode[6] 
*+ pi0thcode[7]  mux3sel[0]  mux3sel[1]  mux0sel[0] 
*+ mux0sel[1]  mux2sel[0]  mux2sel[1]  mux1sel[0] 
*+ mux1sel[1]  mux1sel[2]  mux1sel[3]  mux2sel[2] 
*+ mux2sel[3]  mux0sel[2]  mux0sel[3]  mux2sel[6] 
*+ mux2sel[7]  mux0sel[6]  mux0sel[7]  mux3sel[4] 
*+ mux3sel[5]  d0clken  mux1sel[6]  mux1sel[7] 
*+ mux2sel[4]  mux2sel[5]  mux1sel[4]  mux1sel[5] 
*+ mux0sel[4]  mux0sel[5]  mux3sel[6]  mux3sel[7] 
*+ mux3sel[2]  mux3sel[3]  pienable[0]  pienable[1] 
*+ pienable[2]  pienable[3]  muxd0sel[0]  muxd0sel[1] 
*+ muxd0sel[2]  muxd0sel[3]  muxd0sel[4]  muxd0sel[5] 
*+ muxd0sel[6]  muxd0sel[7]  pid0thcode[0]  pid0thcode[1] 
*+ pid0thcode[2]  pid0thcode[3]  pid0thcode[4]  pid0thcode[5] 
*+ pid0thcode[6]  pid0thcode[7] 
* ----------------------------
*.PININFO  vccxx_lv:I  pi3enable:I  pi2enable:I 
*.PININFO  pi0enable:I  pi1enable:I  d0enable:I  pi0code[0]:I 
*.PININFO  pi0code[1]:I  pi0code[2]:I  pi0code[3]:I  pi0code[4]:I 
*.PININFO  pi0code[5]:I  pi1code[0]:I  pi1code[1]:I  pi1code[2]:I 
*.PININFO  pi1code[3]:I  pi1code[4]:I  pi1code[5]:I  pi2code[0]:I 
*.PININFO  pi2code[1]:I  pi2code[2]:I  pi2code[3]:I  pi2code[4]:I 
*.PININFO  pi2code[5]:I  pi3code[0]:I  pi3code[1]:I  pi3code[2]:I 
*.PININFO  pi3code[3]:I  pi3code[4]:I  pi3code[5]:I  d0code[0]:I 
*.PININFO  d0code[1]:I  d0code[2]:I  d0code[3]:I  d0code[4]:I 
*.PININFO  d0code[5]:I  piupdateqnnnh[1]:I  piupdateqnnnh[2]:I  piupdateqnnnh[3]:I 
*.PININFO  pi3thcode[0]:O  pi3thcode[1]:O  pi3thcode[2]:O 
*.PININFO  pi3thcode[3]:O  pi3thcode[4]:O  pi3thcode[5]:O  pi3thcode[6]:O 
*.PININFO  pi3thcode[7]:O  pi1thcode[0]:O  pi1thcode[1]:O  pi1thcode[2]:O 
*.PININFO  pi1thcode[3]:O  pi1thcode[4]:O  pi1thcode[5]:O  pi1thcode[6]:O 
*.PININFO  pi1thcode[7]:O  pi2thcode[0]:O  pi2thcode[1]:O  pi2thcode[2]:O 
*.PININFO  pi2thcode[3]:O  pi2thcode[4]:O  pi2thcode[5]:O  pi2thcode[6]:O 
*.PININFO  pi2thcode[7]:O  pi0thcode[0]:O  pi0thcode[1]:O  pi0thcode[2]:O 
*.PININFO  pi0thcode[3]:O  pi0thcode[4]:O  pi0thcode[5]:O  pi0thcode[6]:O 
*.PININFO  pi0thcode[7]:O  mux3sel[0]:O  mux3sel[1]:O  mux0sel[0]:O 
*.PININFO  mux0sel[1]:O  mux2sel[0]:O  mux2sel[1]:O  mux1sel[0]:O 
*.PININFO  mux1sel[1]:O  mux1sel[2]:O  mux1sel[3]:O  mux2sel[2]:O 
*.PININFO  mux2sel[3]:O  mux0sel[2]:O  mux0sel[3]:O  mux2sel[6]:O 
*.PININFO  mux2sel[7]:O  mux0sel[6]:O  mux0sel[7]:O  mux3sel[4]:O 
*.PININFO  mux3sel[5]:O  d0clken:O  mux1sel[6]:O  mux1sel[7]:O 
*.PININFO  mux2sel[4]:O  mux2sel[5]:O  mux1sel[4]:O  mux1sel[5]:O 
*.PININFO  mux0sel[4]:O  mux0sel[5]:O  mux3sel[6]:O  mux3sel[7]:O 
*.PININFO  mux3sel[2]:O  mux3sel[3]:O  pienable[0]:O  pienable[1]:O 
*.PININFO  pienable[2]:O  pienable[3]:O  muxd0sel[0]:O  muxd0sel[1]:O 
*.PININFO  muxd0sel[2]:O  muxd0sel[3]:O  muxd0sel[4]:O  muxd0sel[5]:O 
*.PININFO  muxd0sel[6]:O  muxd0sel[7]:O  pid0thcode[0]:O  pid0thcode[1]:O 
*.PININFO  pid0thcode[2]:O  pid0thcode[3]:O  pid0thcode[4]:O  pid0thcode[5]:O 
*.PININFO  pid0thcode[6]:O  pid0thcode[7]:O 
* ----------------------------

xidrv0 mx0banksel[0] mx0lsb mx0banksel[3] mux0sel[0] mux0sel[1] mx1banksel[0] mx1lsb mx1banksel[3] mux1sel[0] mux1sel[1] mx2banksel[0] mx2lsb mx2banksel[3] mux2sel[0] mux2sel[1] mx3banksel[0] mx3lsb mx3banksel[3] mux3sel[0] mux3sel[1] mxd0banksel[0] mxd0lsb mxd0banksel[3] muxd0sel[0] muxd0sel[1] vccxx_lv ip10xddrdll_mcmdecdrv
xidrv1 mx0banksel[1] mx0lsb mx0banksel[0] mux0sel[2] mux0sel[3] mx1banksel[1] mx1lsb mx1banksel[0] mux1sel[2] mux1sel[3] mx2banksel[1] mx2lsb mx2banksel[0] mux2sel[2] mux2sel[3] mx3banksel[1] mx3lsb mx3banksel[0] mux3sel[2] mux3sel[3] mxd0banksel[1] mxd0lsb mxd0banksel[0] muxd0sel[2] muxd0sel[3] vccxx_lv ip10xddrdll_mcmdecdrv
xidrv3 mx0banksel[3] mx0lsb mx0banksel[2] mux0sel[6] mux0sel[7] mx1banksel[3] mx1lsb mx1banksel[2] mux1sel[6] mux1sel[7] mx2banksel[3] mx2lsb mx2banksel[2] mux2sel[6] mux2sel[7] mx3banksel[3] mx3lsb mx3banksel[2] mux3sel[6] mux3sel[7] mxd0banksel[3] mxd0lsb mxd0banksel[2] muxd0sel[6] muxd0sel[7] vccxx_lv ip10xddrdll_mcmdecdrv
xidrv2 mx0banksel[2] mx0lsb mx0banksel[1] mux0sel[4] mux0sel[5] mx1banksel[2] mx1lsb mx1banksel[1] mux1sel[4] mux1sel[5] mx2banksel[2] mx2lsb mx2banksel[1] mux2sel[4] mux2sel[5] mx3banksel[2] mx3lsb mx3banksel[1] mux3sel[4] mux3sel[5] mxd0banksel[2] mxd0lsb mxd0banksel[1] muxd0sel[4] muxd0sel[5] vccxx_lv ip10xddrdll_mcmdecdrv
xidec2 mx2banksel[3] mx2banksel[2] mx2banksel[1] mx2banksel[0] mx2lsb pi2code[5] pi2code[4] pi2code[3] pi2code[2] pi2code[1] pi2code[0] pi2enable pienable[2] pi2thcode[7] pi2thcode[6] pi2thcode[5] pi2thcode[4] pi2thcode[3] pi2thcode[2] pi2thcode[1] pi2thcode[0] piupdateqnnnh[2] vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
xidec0 mx0banksel[3] mx0banksel[2] mx0banksel[1] mx0banksel[0] mx0lsb pi0code[5] pi0code[4] pi0code[3] pi0code[2] pi0code[1] pi0code[0] pi0enable pienable[0] pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] vss vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
xidec1 mx1banksel[3] mx1banksel[2] mx1banksel[1] mx1banksel[0] mx1lsb pi1code[5] pi1code[4] pi1code[3] pi1code[2] pi1code[1] pi1code[0] pi1enable pienable[1] pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] piupdateqnnnh[1] vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
xidec3 mx3banksel[3] mx3banksel[2] mx3banksel[1] mx3banksel[0] mx3lsb pi3code[5] pi3code[4] pi3code[3] pi3code[2] pi3code[1] pi3code[0] pi3enable pienable[3] pi3thcode[7] pi3thcode[6] pi3thcode[5] pi3thcode[4] pi3thcode[3] pi3thcode[2] pi3thcode[1] pi3thcode[0] piupdateqnnnh[3] vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
xidecd0 mxd0banksel[3] mxd0banksel[2] mxd0banksel[1] mxd0banksel[0] mxd0lsb d0code[5] d0code[4] d0code[3] d0code[2] d0code[1] d0code[0] d0enable d0clken pid0thcode[7] pid0thcode[6] pid0thcode[5] pid0thcode[4] pid0thcode[3] pid0thcode[2] pid0thcode[1] pid0thcode[0] vss vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
.ends ip10xddrdll_mcmpidecoder_x4pi
** end of subcircuit definition.

** library name: e8lib
** cell name: e8xlmfc4b0n4000xn3unx
** view name: schematic
.subckt e8xlmfc4b0n4000xn3unx mfcport1 mfcvcc_nom
* ----------------------------
* CELLLOG e8lib nil e8xlmfc4b0n4000xn3unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8lib/e8xlmfc4b0n4000xn3unx/schematic 
* CELLLOG e8lib nil e8xlmfc4b0n4000xn3unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8lib/e8xlmfc4b0n4000xn3unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 12564 
* Version: Unmanaged 
* INOUT:  mfcport1  mfcvcc_nom 
* ----------------------------
*.PININFO  mfcport1:B  mfcvcc_nom:B 
* ----------------------------

crfti1.1 mfcport1 mfcvcc_nom c=8.763e-15
drfti1.1 0 mfcvcc_nom djnw area=1.32192e-12 pj=0.1e-6 level=1
.ends e8xlmfc4b0n4000xn3unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpbiascap1
** view name: schematic
.subckt ip10xddrdll_mcpbiascap1 vccxx_lv vpbias
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpbiascap1 schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpbiascap1/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpbiascap1 symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpbiascap1/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 25863 
* Version: 1.4 
* INOUT:  vccxx_lv  vpbias 
* ----------------------------
*.PININFO  vccxx_lv:B  vpbias:B 
* ----------------------------

xipbiasunx[19] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[18] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[17] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[16] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[15] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[14] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[13] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[12] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[11] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[10] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[9] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[8] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[7] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[6] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[5] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[4] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[3] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[2] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[1] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
xipbiasunx[0] vpbias vccxx_lv e8xlmfc4b0n4000xn3unx
.ends ip10xddrdll_mcpbiascap1
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp220tn2000ps1unx
** view name: schematic
.subckt e8xltp220tn2000ps1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp220tn2000ps1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp220tn2000ps1unx/schematic 
* CELLLOG e8libana nil e8xltp220tn2000ps1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp220tn2000ps1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14289 
* Version: Unmanaged 
* INOUT:  d  b  s 
* INPUT:  g 
* ----------------------------
*.PININFO  d:B  b:B  s:B 
*.PININFO  g:I 
* ----------------------------

mqn3 d g s b psvt l=20e-9 w=68e-9 m=1
mqn2 d g s b psvt l=20e-9 w=68e-9 m=1
.ends e8xltp220tn2000ps1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_inv_2dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_inv_2dgsvtsp24x_nonadt a o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_2dgsvtsp24x_nonadt schematic 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_2dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_2dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_2dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 35384 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqpdummy o1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn1dum o1 vss vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
.ends ip10xddrdll_inv_2dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp220tn2000ns1unx
** view name: schematic
.subckt e8xltp220tn2000ns1unx d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp220tn2000ns1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp220tn2000ns1unx/schematic 
* CELLLOG e8libana nil e8xltp220tn2000ns1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp220tn2000ns1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14573 
* Version: Unmanaged 
* INOUT:  s  d 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B 
*.PININFO  g:I 
* ----------------------------

mqn0 d g s vss nsvt l=20e-9 w=68e-9 m=1
mqn1 d g s vss nsvt l=20e-9 w=68e-9 m=1
.ends e8xltp220tn2000ns1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mc5pi2to1svtmux
** view name: schematic
.subckt ip10xddrdll_mc5pi2to1svtmux a b o sa vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5pi2to1svtmux schematic 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5pi2to1svtmux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5pi2to1svtmux symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5pi2to1svtmux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 88626 
* Version: 1.2 
* INPUT:  b  a  sa 
*+ vccxx_lv 
* OUTPUT:  o 
* ----------------------------
*.PININFO  b:I  a:I  sa:I 
*.PININFO  vccxx_lv:I 
*.PININFO  o:O 
* ----------------------------

xqp1 vccxx_lv net019 sa n1 e8xltp220tn2000ps1unx
xqp2 vccxx_lv net019 sab n0 e8xltp220tn2000ps1unx
xinv00 b n1 vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv02 a n0 vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv03 sab o vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv01 sa sab vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xqn1 n1 sab net019 e8xltp220tn2000ns1unx
xqn2 n0 sa net019 e8xltp220tn2000ns1unx
.ends ip10xddrdll_mc5pi2to1svtmux
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_nand3_4dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_nand3_4dgsvtsp24x_nonadt a b c o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nand3_4dgsvtsp24x_nonadt schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nand3_4dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nand3_4dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nand3_4dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 87046 
* Version: 1.2 
* INPUT:  a  b  c 
*+ vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  c:I 
*.PININFO  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqpdum o1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=1.768e-15 as=1.768e-15 pd=74.66667e-9 ps=74.66667e-9 m=1
mqp2 o1 b vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp3 o1 c vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp1 o1 a vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=136e-9 m=1
mqn1dum o1 vss vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn2 n1 b n2 vss nsvt l=20e-9 w=136e-9 m=1
mqn3 n2 c vss vss nsvt l=20e-9 w=136e-9 m=1
.ends ip10xddrdll_nand3_4dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mc5pimux
** view name: schematic
.subckt ip10xddrdll_mc5pimux dismixerin muxsel[0] muxsel[7] picode[7] picode[6] picode[5] picode[4] picode[3] picode[2] picode[1] picode[0] picodefinal[7] picodefinal[6] picodefinal[5] picodefinal[4] picodefinal[3] picodefinal[2] picodefinal[1] picodefinal[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5pimux schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5pimux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5pimux symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5pimux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 15826 
* Version: 1.2 
* INPUT:  vccxx_lv  muxsel[0]  dismixerin 
*+ picode[0]  picode[1]  picode[2]  picode[3] 
*+ picode[4]  picode[5]  picode[6]  picode[7] 
*+ muxsel[7] 
* OUTPUT:  picodefinal[0]  picodefinal[1]  picodefinal[2] 
*+ picodefinal[3]  picodefinal[4]  picodefinal[5]  picodefinal[6] 
*+ picodefinal[7] 
* ----------------------------
*.PININFO  vccxx_lv:I  muxsel[0]:I  dismixerin:I 
*.PININFO  picode[0]:I  picode[1]:I  picode[2]:I  picode[3]:I 
*.PININFO  picode[4]:I  picode[5]:I  picode[6]:I  picode[7]:I 
*.PININFO  muxsel[7]:I 
*.PININFO  picodefinal[0]:O  picodefinal[1]:O  picodefinal[2]:O 
*.PININFO  picodefinal[3]:O  picodefinal[4]:O  picodefinal[5]:O  picodefinal[6]:O 
*.PININFO  picodefinal[7]:O 
* ----------------------------

xisel[7] picode[7] picode[3] picodefinal[7] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[6] picode[6] picode[3] picodefinal[6] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[5] picode[5] picode[3] picodefinal[5] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[4] picode[4] picode[3] picodefinal[4] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[3] picode[3] picode[3] picodefinal[3] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[2] picode[2] picode[3] picodefinal[2] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[1] picode[1] picode[3] picodefinal[1] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xisel[0] picode[0] picode[3] picodefinal[0] dismixerwk_b vccxx_lv ip10xddrdll_mc5pi2to1svtmux
xinand0 muxsel[0] muxsel[7] dismixerin dismixerwk_b vccxx_lv ip10xddrdll_nand3_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mc5pimux
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_buf_4dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_buf_4dgsvtsp24x_nonadt a o vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_buf_4dgsvtsp24x_nonadt schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_buf_4dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_buf_4dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_buf_4dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 38596 
* Version: 1.2 
* INPUT:  vccxx_lv  a 
* OUTPUT:  o 
* ----------------------------
*.PININFO  vccxx_lv:I  a:I 
*.PININFO  o:O 
* ----------------------------

mqp1 n1 a vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp0dum o vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1dum n1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp0 o n1 vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn0dum o vss vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1dum n1 vss vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn1 n1 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn0 o n1 vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
.ends ip10xddrdll_buf_4dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp420tn2000ps1unx
** view name: schematic
.subckt e8xltp420tn2000ps1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp420tn2000ps1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000ps1unx/schematic 
* CELLLOG e8libana nil e8xltp420tn2000ps1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000ps1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 13627 
* Version: Unmanaged 
* INOUT:  d  b  s 
* INPUT:  g 
* ----------------------------
*.PININFO  d:B  b:B  s:B 
*.PININFO  g:I 
* ----------------------------

mqn3 d g s b psvt l=20e-9 w=136e-9 m=1
mqn2 d g s b psvt l=20e-9 w=136e-9 m=1
.ends e8xltp420tn2000ps1unx
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp420tn2000ns1unx
** view name: schematic
.subckt e8xltp420tn2000ns1unx d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp420tn2000ns1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000ns1unx/schematic 
* CELLLOG e8libana nil e8xltp420tn2000ns1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000ns1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14652 
* Version: Unmanaged 
* INOUT:  s  d 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B 
*.PININFO  g:I 
* ----------------------------

mqn0 d g s vss nsvt l=20e-9 w=136e-9 m=1
mqn1 d g s vss nsvt l=20e-9 w=136e-9 m=1
.ends e8xltp420tn2000ns1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmuxcell
** view name: schematic
.subckt ip10xddrdll_mcmuxcell i o_b sel vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmuxcell schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmuxcell/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmuxcell symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmuxcell/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 23579 
* Version: 1.3 
* INOUT:  o_b 
* INPUT:  vccxx_lv  sel  i 
* ----------------------------
*.PININFO  o_b:B 
*.PININFO  vccxx_lv:I  sel:I  i:I 
* ----------------------------

xmup1[1] vccxx_lv pxx i vccxx_lv e8xltp420tn2000ps1unx
xmup1[0] vccxx_lv pxx i vccxx_lv e8xltp420tn2000ps1unx
xmup0[1] vccxx_lv o_b sel_b pxx e8xltp420tn2000ps1unx
xmup0[0] vccxx_lv o_b sel_b pxx e8xltp420tn2000ps1unx
xmiqn1 selbuf sel_b vss e8xltp220tn2000ns1unx
xmiqn0 sel_b sel vss e8xltp220tn2000ns1unx
xmun1[1] nxx i vss e8xltp420tn2000ns1unx
xmun1[0] nxx i vss e8xltp420tn2000ns1unx
xmun0[1] o_b selbuf nxx e8xltp420tn2000ns1unx
xmun0[0] o_b selbuf nxx e8xltp420tn2000ns1unx
xmiqp0 vccxx_lv sel_b sel vccxx_lv e8xltp220tn2000ps1unx
xmiqp1 vccxx_lv selbuf sel_b vccxx_lv e8xltp220tn2000ps1unx
.ends ip10xddrdll_mcmuxcell
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_aoi4_2dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_aoi4_2dgsvtsp24x_nonadt a b c d o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_aoi4_2dgsvtsp24x_nonadt schematic 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_aoi4_2dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_aoi4_2dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_aoi4_2dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 103156 
* Version: 1.2 
* INPUT:  d  c  b 
*+ a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  d:I  c:I  b:I 
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqpdum vccxx_lv vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=1.156e-15 as=2.992e-15 pd=34e-9 ps=156e-9 m=4
mqp1 o1 a n1 vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp3 n1 c vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp4 n1 d vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp2 o1 b n1 vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqn4 n3 d vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqndum vss vss vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=4
mqn2 n2 b vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn1 o1 a n2 vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn3 o1 c n3 vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
.ends ip10xddrdll_aoi4_2dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_aoi3_2dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_aoi3_2dgsvtsp24x_nonadt a b c o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_aoi3_2dgsvtsp24x_nonadt schematic 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_aoi3_2dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_aoi3_2dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_aoi3_2dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 84022 
* Version: 1.2 
* INPUT:  a  b  c 
*+ vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  c:I 
*.PININFO  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqp3 n1 c vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp2dum n1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=1.156e-15 as=2.992e-15 pd=34e-9 ps=156e-9 m=1
mqp1dum o1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp3dum vccxx_lv vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=1.156e-15 as=2.992e-15 pd=34e-9 ps=156e-9 m=1
mqp2 n1 b vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqp1 o1 a n1 vccxx_lv psvt l=20e-9 w=68e-9 m=1
mqn3 n2 c vss vss nsvt l=20e-9 w=68e-9 m=1
mqn1dum vss vss vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn3dum vss vss vss vss nsvt l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=2
mqn2 o1 b n2 vss nsvt l=20e-9 w=68e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ip10xddrdll_aoi3_2dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcphdrven
** view name: schematic
.subckt ip10xddrdll_mcphdrven mux0sel mux1sel mux2sel mux3sel muxd0sel phdrpwrsavon phdrven pien0 pien1 pien2 pien3 piend0 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcphdrven schematic 1.11 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcphdrven/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcphdrven symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcphdrven/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 25793 
* Version: 1.3 
* INPUT:  vccxx_lv  muxd0sel  mux1sel 
*+ mux0sel  mux2sel  mux3sel  phdrpwrsavon 
*+ pien0  pien1  pien2  pien3 
*+ piend0 
* OUTPUT:  phdrven 
* ----------------------------
*.PININFO  vccxx_lv:I  muxd0sel:I  mux1sel:I 
*.PININFO  mux0sel:I  mux2sel:I  mux3sel:I  phdrpwrsavon:I 
*.PININFO  pien0:I  pien1:I  pien2:I  pien3:I 
*.PININFO  piend0:I 
*.PININFO  phdrven:O 
* ----------------------------

xcon1 mux0sel pien0 mux1sel pien1 b vccxx_lv ip10xddrdll_aoi4_2dgsvtsp24x_nonadt
xcon2 mux2sel pien2 mux3sel pien3 c vccxx_lv ip10xddrdll_aoi4_2dgsvtsp24x_nonadt
xinn0 phdrpwrsavon phdrpwrsavon_b vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xcon0 phdrpwrsavon_b muxd0sel piend0 a vccxx_lv ip10xddrdll_aoi3_2dgsvtsp24x_nonadt
xnan0 a b c phdrven vccxx_lv ip10xddrdll_nand3_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mcphdrven
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmux0stage
** view name: schematic
.subckt ip10xddrdll_mcmux0stage clkmxd0_b clkmxph_b[0] clkmxph_b[1] clkmxph_b[2] clkmxph_b[3] clkph mx0sel mx1sel mx2sel mx3sel mxd0en phdrpwrsavon phdrven pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmux0stage schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmux0stage/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmux0stage symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmux0stage/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 31146 
* Version: 1.2 
* INOUT:  clkmxph_b[3]  clkmxph_b[1]  clkmxph_b[2] 
*+ clkmxph_b[0]  clkmxd0_b 
* INPUT:  vccxx_lv  mx3sel  clkph 
*+ mxd0en  mx1sel  mx0sel  mx2sel 
*+ phdrpwrsavon  pien[0]  pien[1]  pien[2] 
*+ pien[3]  pien[4] 
* OUTPUT:  phdrven 
* ----------------------------
*.PININFO  clkmxph_b[3]:B  clkmxph_b[1]:B  clkmxph_b[2]:B 
*.PININFO  clkmxph_b[0]:B  clkmxd0_b:B 
*.PININFO  vccxx_lv:I  mx3sel:I  clkph:I 
*.PININFO  mxd0en:I  mx1sel:I  mx0sel:I  mx2sel:I 
*.PININFO  phdrpwrsavon:I  pien[0]:I  pien[1]:I  pien[2]:I 
*.PININFO  pien[3]:I  pien[4]:I 
*.PININFO  phdrven:O 
* ----------------------------

ximux3 clkph clkmxph_b[3] mx3sel vccxx_lv ip10xddrdll_mcmuxcell
ximux2 clkph clkmxph_b[2] mx2sel vccxx_lv ip10xddrdll_mcmuxcell
ximux1 clkph clkmxph_b[1] mx1sel vccxx_lv ip10xddrdll_mcmuxcell
ximux0 clkph clkmxph_b[0] mx0sel vccxx_lv ip10xddrdll_mcmuxcell
ximuxref clkph clkmxd0_b mxd0en vccxx_lv ip10xddrdll_mcmuxcell
xi12 mx0sel mx1sel mx2sel mx3sel mxd0en phdrpwrsavon phdrven pien[0] pien[1] pien[2] pien[3] pien[4] vccxx_lv ip10xddrdll_mcphdrven
.ends ip10xddrdll_mcmux0stage
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmux
** view name: schematic
.subckt ip10xddrdll_mcmux clkd0ph0_b clkd0ph1_b clkmxph0_b[3] clkmxph0_b[2] clkmxph0_b[1] clkmxph0_b[0] clkmxph1_b[3] clkmxph1_b[2] clkmxph1_b[1] clkmxph1_b[0] clkph[7] clkph[6] clkph[5] clkph[4] clkph[3] clkph[2] clkph[1] clkph[0] mux0sel[7] mux0sel[6] mux0sel[5] mux0sel[4] mux0sel[3] mux0sel[2] mux0sel[1] mux0sel[0] mux1sel[7] mux1sel[6] mux1sel[5] mux1sel[4] mux1sel[3] mux1sel[2] mux1sel[1] mux1sel[0] mux2sel[7] mux2sel[6] mux2sel[5] mux2sel[4] mux2sel[3] mux2sel[2] mux2sel[1] mux2sel[0] mux3sel[7] mux3sel[6] mux3sel[5] mux3sel[4] mux3sel[3] mux3sel[2] mux3sel[1] mux3sel[0] phdrpwrsavon phdrven[7] phdrven[6] phdrven[5] phdrven[4] phdrven[3] phdrven[2] phdrven[1] phdrven[0] pien[4] pien[3] pien[2] pien[1] pien[0] refpisel[7] refpisel[6] refpisel[5] refpisel[4] refpisel[3] refpisel[2] refpisel[1] refpisel[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmux schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmux symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 154392 
* Version: 1.3 
* INPUT:  mux1sel[0]  mux1sel[1]  mux1sel[2] 
*+ mux1sel[3]  mux1sel[4]  mux1sel[5]  mux1sel[6] 
*+ mux1sel[7]  mux2sel[0]  mux2sel[1]  mux2sel[2] 
*+ mux2sel[3]  mux2sel[4]  mux2sel[5]  mux2sel[6] 
*+ mux2sel[7]  clkph[0]  clkph[1]  clkph[2] 
*+ clkph[3]  clkph[4]  clkph[5]  clkph[6] 
*+ clkph[7]  vccxx_lv  phdrpwrsavon  mux0sel[0] 
*+ mux0sel[1]  mux0sel[2]  mux0sel[3]  mux0sel[4] 
*+ mux0sel[5]  mux0sel[6]  mux0sel[7]  mux3sel[0] 
*+ mux3sel[1]  mux3sel[2]  mux3sel[3]  mux3sel[4] 
*+ mux3sel[5]  mux3sel[6]  mux3sel[7]  refpisel[0] 
*+ refpisel[1]  refpisel[2]  refpisel[3]  refpisel[4] 
*+ refpisel[5]  refpisel[6]  refpisel[7]  pien[0] 
*+ pien[1]  pien[2]  pien[3]  pien[4] 
* OUTPUT:  phdrven[0]  phdrven[1]  phdrven[2] 
*+ phdrven[3]  phdrven[4]  phdrven[5]  phdrven[6] 
*+ phdrven[7]  clkmxph1_b[0]  clkmxph1_b[1]  clkmxph1_b[2] 
*+ clkmxph1_b[3]  clkmxph0_b[0]  clkmxph0_b[1]  clkmxph0_b[2] 
*+ clkmxph0_b[3]  clkd0ph1_b  clkd0ph0_b 
* ----------------------------
*.PININFO  mux1sel[0]:I  mux1sel[1]:I  mux1sel[2]:I 
*.PININFO  mux1sel[3]:I  mux1sel[4]:I  mux1sel[5]:I  mux1sel[6]:I 
*.PININFO  mux1sel[7]:I  mux2sel[0]:I  mux2sel[1]:I  mux2sel[2]:I 
*.PININFO  mux2sel[3]:I  mux2sel[4]:I  mux2sel[5]:I  mux2sel[6]:I 
*.PININFO  mux2sel[7]:I  clkph[0]:I  clkph[1]:I  clkph[2]:I 
*.PININFO  clkph[3]:I  clkph[4]:I  clkph[5]:I  clkph[6]:I 
*.PININFO  clkph[7]:I  vccxx_lv:I  phdrpwrsavon:I  mux0sel[0]:I 
*.PININFO  mux0sel[1]:I  mux0sel[2]:I  mux0sel[3]:I  mux0sel[4]:I 
*.PININFO  mux0sel[5]:I  mux0sel[6]:I  mux0sel[7]:I  mux3sel[0]:I 
*.PININFO  mux3sel[1]:I  mux3sel[2]:I  mux3sel[3]:I  mux3sel[4]:I 
*.PININFO  mux3sel[5]:I  mux3sel[6]:I  mux3sel[7]:I  refpisel[0]:I 
*.PININFO  refpisel[1]:I  refpisel[2]:I  refpisel[3]:I  refpisel[4]:I 
*.PININFO  refpisel[5]:I  refpisel[6]:I  refpisel[7]:I  pien[0]:I 
*.PININFO  pien[1]:I  pien[2]:I  pien[3]:I  pien[4]:I 
*.PININFO  phdrven[0]:O  phdrven[1]:O  phdrven[2]:O 
*.PININFO  phdrven[3]:O  phdrven[4]:O  phdrven[5]:O  phdrven[6]:O 
*.PININFO  phdrven[7]:O  clkmxph1_b[0]:O  clkmxph1_b[1]:O  clkmxph1_b[2]:O 
*.PININFO  clkmxph1_b[3]:O  clkmxph0_b[0]:O  clkmxph0_b[1]:O  clkmxph0_b[2]:O 
*.PININFO  clkmxph0_b[3]:O  clkd0ph1_b:O  clkd0ph0_b:O 
* ----------------------------

ximuxcel3 clkd0ph1_b clkmxph1_b[0] clkmxph1_b[1] clkmxph1_b[2] clkmxph1_b[3] clkph[3] mux0sel[3] mux1sel[3] mux2sel[3] mux3sel[3] refpisel[3] phdrpwrsavon phdrven[3] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell7 clkd0ph1_b clkmxph1_b[0] clkmxph1_b[1] clkmxph1_b[2] clkmxph1_b[3] clkph[7] mux0sel[7] mux1sel[7] mux2sel[7] mux3sel[7] refpisel[7] phdrpwrsavon phdrven[7] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell5 clkd0ph1_b clkmxph1_b[0] clkmxph1_b[1] clkmxph1_b[2] clkmxph1_b[3] clkph[5] mux0sel[5] mux1sel[5] mux2sel[5] mux3sel[5] refpisel[5] phdrpwrsavon phdrven[5] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell1 clkd0ph1_b clkmxph1_b[0] clkmxph1_b[1] clkmxph1_b[2] clkmxph1_b[3] clkph[1] mux0sel[1] mux1sel[1] mux2sel[1] mux3sel[1] refpisel[1] phdrpwrsavon phdrven[1] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell0 clkd0ph0_b clkmxph0_b[0] clkmxph0_b[1] clkmxph0_b[2] clkmxph0_b[3] clkph[0] mux0sel[0] mux1sel[0] mux2sel[0] mux3sel[0] refpisel[0] phdrpwrsavon phdrven[0] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell4 clkd0ph0_b clkmxph0_b[0] clkmxph0_b[1] clkmxph0_b[2] clkmxph0_b[3] clkph[4] mux0sel[4] mux1sel[4] mux2sel[4] mux3sel[4] refpisel[4] phdrpwrsavon phdrven[4] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcel2 clkd0ph0_b clkmxph0_b[0] clkmxph0_b[1] clkmxph0_b[2] clkmxph0_b[3] clkph[2] mux0sel[2] mux1sel[2] mux2sel[2] mux3sel[2] refpisel[2] phdrpwrsavon phdrven[2] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
ximuxcell6 clkd0ph0_b clkmxph0_b[0] clkmxph0_b[1] clkmxph0_b[2] clkmxph0_b[3] clkph[6] mux0sel[6] mux1sel[6] mux2sel[6] mux3sel[6] refpisel[6] phdrpwrsavon phdrven[6] pien[4] pien[3] pien[2] pien[1] pien[0] vccxx_lv ip10xddrdll_mcmux0stage
.ends ip10xddrdll_mcmux
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_inv_4dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_inv_4dgsvtsp24x_nonadt a o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_4dgsvtsp24x_nonadt schematic 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_4dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_4dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_4dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 36201 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqpdummy o1 vccxx_lv vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1 o1 a vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1dum o1 vss vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
.ends ip10xddrdll_inv_4dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_cnor2_4dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_cnor2_4dgnomsp24x_nonadt clk clkout enb vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_cnor2_4dgnomsp24x_nonadt schematic 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_cnor2_4dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_cnor2_4dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_cnor2_4dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 47785 
* Version: 1.2 
* INPUT:  clk  enb  vccxx_lv 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  enb:I  vccxx_lv:I 
*.PININFO  clkout:O 
* ----------------------------

mqn2dum vss vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=4
mqn0 clkout clk vss vss n l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
mqn1 clkout enb vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
mqp1 clkout clk n0 vccxx_lv p l=20e-9 w=136e-9 ad=3.536e-15 as=3.536e-15 pd=97.33333e-9 ps=97.33333e-9 m=4
mqp2 n0 enb vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=2.312e-15 as=4.148e-15 pd=34e-9 ps=129e-9 m=4
.ends ip10xddrdll_cnor2_4dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_buf_4dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_buf_4dgnomsp24x_nonadt a o vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_buf_4dgnomsp24x_nonadt schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_buf_4dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_buf_4dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_buf_4dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 40112 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o:O 
* ----------------------------

mqn0dum o vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1dum n1 vss vss vss n l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqn1 n1 a vss vss n l=20e-9 w=68e-9 m=1
mqn0 o n1 vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1dum n1 vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp0dum o vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp0 o n1 vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1 n1 a vccxx_lv vccxx_lv p l=20e-9 w=68e-9 m=1
.ends ip10xddrdll_buf_4dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltc21dtn2000nn1unx
** view name: schematic
.subckt e8xltc21dtn2000nn1unx g1 n1 n3 x
* ----------------------------
* CELLLOG e8libana nil e8xltc21dtn2000nn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc21dtn2000nn1unx/schematic 
* CELLLOG e8libana nil e8xltc21dtn2000nn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc21dtn2000nn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 5234 
* Version: Unmanaged 
* INOUT:  x  n1  n3 
* INPUT:  g1 
* ----------------------------
*.PININFO  x:B  n1:B  n3:B 
*.PININFO  g1:I 
* ----------------------------

mqn1 n1 g1 n3 vss n l=20e-9 w=68e-9 m=1
mqn0 n3 x x vss n l=20e-9 w=68e-9 m=1
.ends e8xltc21dtn2000nn1unx
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltc21dtn2000pn1unx
** view name: schematic
.subckt e8xltc21dtn2000pn1unx b g1 n1 n3 x
* ----------------------------
* CELLLOG e8libana nil e8xltc21dtn2000pn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc21dtn2000pn1unx/schematic 
* CELLLOG e8libana nil e8xltc21dtn2000pn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc21dtn2000pn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 5685 
* Version: Unmanaged 
* INOUT:  x  n1  n3 
*+ b 
* INPUT:  g1 
* ----------------------------
*.PININFO  x:B  n1:B  n3:B 
*.PININFO  b:B 
*.PININFO  g1:I 
* ----------------------------

mqn1 n3 g1 n1 b p l=20e-9 w=68e-9 m=1
mqn0 x x n3 b p l=20e-9 w=68e-9 m=1
.ends e8xltc21dtn2000pn1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpimixermux
** view name: schematic
.subckt ip10xddrdll_mcpimixermux nctl pctl pin pout vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpimixermux schematic 1.11 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpimixermux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpimixermux symbol 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpimixermux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 52048 
* Version: 1.6 
* INPUT:  pctl  pin  nctl 
*+ vccxx_lv 
* OUTPUT:  pout 
* ----------------------------
*.PININFO  pctl:I  pin:I  nctl:I 
*.PININFO  vccxx_lv:I 
*.PININFO  pout:O 
* ----------------------------

xqn1 nctl nxx vss vss e8xltc21dtn2000nn1unx
xqn0 pin nxx pout vss e8xltc21dtn2000nn1unx
xqp1 vccxx_lv pin pxx pout vccxx_lv e8xltc21dtn2000pn1unx
xqp0 vccxx_lv pctl pxx vccxx_lv vccxx_lv e8xltc21dtn2000pn1unx
.ends ip10xddrdll_mcpimixermux
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp420tn2000nn1unx
** view name: schematic
.subckt e8xltp420tn2000nn1unx d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp420tn2000nn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000nn1unx/schematic 
* CELLLOG e8libana nil e8xltp420tn2000nn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000nn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14450 
* Version: Unmanaged 
* INOUT:  s  d 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B 
*.PININFO  g:I 
* ----------------------------

mqn0 d g s vss n l=20e-9 w=136e-9 m=1
mqn1 d g s vss n l=20e-9 w=136e-9 m=1
.ends e8xltp420tn2000nn1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpassgate
** view name: schematic
.subckt ip10xddrdll_mcpassgate i o s sb vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpassgate schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpassgate/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpassgate symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpassgate/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 17291 
* Version: 1.2 
* INPUT:  vccxx_lv  s  sb 
*+ i 
* OUTPUT:  o 
* ----------------------------
*.PININFO  vccxx_lv:I  s:I  sb:I 
*.PININFO  i:I 
*.PININFO  o:O 
* ----------------------------

xqpsb vccxx_lv o sb i e8xltp420tn2000ps1unx
xqns o s i e8xltp420tn2000nn1unx
.ends ip10xddrdll_mcpassgate
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_inv_4dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_inv_4dgnomsp24x_nonadt a o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_4dgnomsp24x_nonadt schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_4dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_4dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_4dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 34865 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1dum o1 vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqpdummy o1 vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1 o1 a vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
.ends ip10xddrdll_inv_4dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltp420tn2000pn1unx
** view name: schematic
.subckt e8xltp420tn2000pn1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltp420tn2000pn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000pn1unx/schematic 
* CELLLOG e8libana nil e8xltp420tn2000pn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltp420tn2000pn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 13404 
* Version: Unmanaged 
* INOUT:  d  b  s 
* INPUT:  g 
* ----------------------------
*.PININFO  d:B  b:B  s:B 
*.PININFO  g:I 
* ----------------------------

mqn3 d g s b p l=20e-9 w=136e-9 m=1
mqn2 d g s b p l=20e-9 w=136e-9 m=1
.ends e8xltp420tn2000pn1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpimixer
** view name: schematic
.subckt ip10xddrdll_mcpimixer picb[2] picb[1] picb[0] piclkout piclkph0 piclkph1 pimxsel[7] pimxsel[6] pimxsel[5] pimxsel[4] pimxsel[3] pimxsel[2] pimxsel[1] pimxsel[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpimixer schematic 1.15 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpimixer/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpimixer symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpimixer/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 735706 
* Version: 1.1 
* INPUT:  vccxx_lv  pimxsel[0]  pimxsel[1] 
*+ pimxsel[2]  pimxsel[3]  pimxsel[4]  pimxsel[5] 
*+ pimxsel[6]  pimxsel[7]  picb[0]  picb[1] 
*+ picb[2]  piclkph0  piclkph1 
* OUTPUT:  piclkout 
* ----------------------------
*.PININFO  vccxx_lv:I  pimxsel[0]:I  pimxsel[1]:I 
*.PININFO  pimxsel[2]:I  pimxsel[3]:I  pimxsel[4]:I  pimxsel[5]:I 
*.PININFO  pimxsel[6]:I  pimxsel[7]:I  picb[0]:I  picb[1]:I 
*.PININFO  picb[2]:I  piclkph0:I  piclkph1:I 
*.PININFO  piclkout:O 
* ----------------------------

xiph0mxsel2 pimxselb[2] pimxsel[2] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel7 pimxsel[7] pimxselb[7] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel7 pimxselb[7] pimxsel[7] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel2 pimxsel[2] pimxselb[2] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel6 pimxsel[6] pimxselb[6] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel3 pimxselb[3] pimxsel[3] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel5 pimxselb[5] pimxsel[5] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel6 pimxselb[6] pimxsel[6] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel4 pimxsel[4] pimxselb[4] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel3 pimxsel[3] pimxselb[3] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel4 pimxselb[4] pimxsel[4] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel0 pimxsel[0] pimxselb[0] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel1 pimxsel[1] pimxselb[1] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel1 pimxselb[1] pimxsel[1] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph0mxsel0 pimxselb[0] pimxsel[0] piclkph0 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xiph1mxsel5 pimxsel[5] pimxselb[5] piclkph1 pimixerout vccxx_lv ip10xddrdll_mcpimixermux
xinv015 pimxsel[7] pimxselb[7] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv016 pimxsel[5] pimxselb[5] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv012 pimxsel[3] pimxselb[3] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv014 pimxsel[6] pimxselb[6] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv011 pimxsel[1] pimxselb[1] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv017 pimxsel[4] pimxselb[4] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv09 pimxsel[0] pimxselb[0] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv013 pimxsel[2] pimxselb[2] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xg4[1] piclkph1 n4 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xg4[0] piclkph1 n4 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xpg2[3] piclkph0 n0 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xpg2[2] piclkph0 n0 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xpg2[1] piclkph0 n0 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xpg2[0] piclkph0 n0 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xpg0 piclkph0 n2 picb[0] picb_b[0] vccxx_lv ip10xddrdll_mcpassgate
xg6[3] pimixerout n6 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg6[2] pimixerout n6 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg6[1] pimixerout n6 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg6[0] pimixerout n6 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg5[1] pimixerout n7 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xg5[0] pimixerout n7 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xg3[3] piclkph1 n3 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg3[2] piclkph1 n3 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg3[1] piclkph1 n3 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xg3[0] piclkph1 n3 picb[2] picb_b[2] vccxx_lv ip10xddrdll_mcpassgate
xpg1[1] piclkph0 n1 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xpg1[0] piclkph0 n1 picb[1] picb_b[1] vccxx_lv ip10xddrdll_mcpassgate
xgn5 piclkph1 n5 picb[0] picb_b[0] vccxx_lv ip10xddrdll_mcpassgate
xg8 pimixerout n8 picb[0] picb_b[0] vccxx_lv ip10xddrdll_mcpassgate
xinvpicb[2] picb[2] picb_b[2] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinvpicb[1] picb[1] picb_b[1] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinvpicb[0] picb[0] picb_b[0] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv010 pimixerout piclkout vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xqp1[3] vccxx_lv vccxx_lv n2 vccxx_lv e8xltp420tn2000pn1unx
xqp1[2] vccxx_lv vccxx_lv n2 vccxx_lv e8xltp420tn2000pn1unx
xqp1[1] vccxx_lv vccxx_lv n2 vccxx_lv e8xltp420tn2000pn1unx
xqp1[0] vccxx_lv vccxx_lv n2 vccxx_lv e8xltp420tn2000pn1unx
xqp0[7] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[6] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[5] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[4] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[3] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[2] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[1] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp0[0] vccxx_lv vccxx_lv n1 vccxx_lv e8xltp420tn2000pn1unx
xqp15[15] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[14] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[13] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[12] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[11] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[10] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[9] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[8] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[7] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[6] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[5] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[4] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[3] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[2] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[1] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp15[0] vccxx_lv vccxx_lv n0 vccxx_lv e8xltp420tn2000pn1unx
xqp7[3] vccxx_lv vccxx_lv n8 vccxx_lv e8xltp420tn2000pn1unx
xqp7[2] vccxx_lv vccxx_lv n8 vccxx_lv e8xltp420tn2000pn1unx
xqp7[1] vccxx_lv vccxx_lv n8 vccxx_lv e8xltp420tn2000pn1unx
xqp7[0] vccxx_lv vccxx_lv n8 vccxx_lv e8xltp420tn2000pn1unx
xqp2[15] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[14] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[13] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[12] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[11] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[10] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[9] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[8] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[7] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[6] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[5] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[4] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[3] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[2] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[1] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp2[0] vccxx_lv vccxx_lv n3 vccxx_lv e8xltp420tn2000pn1unx
xqp3[7] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[6] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[5] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[4] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[3] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[2] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[1] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp3[0] vccxx_lv vccxx_lv n4 vccxx_lv e8xltp420tn2000pn1unx
xqp4[3] vccxx_lv vccxx_lv n5 vccxx_lv e8xltp420tn2000pn1unx
xqp4[2] vccxx_lv vccxx_lv n5 vccxx_lv e8xltp420tn2000pn1unx
xqp4[1] vccxx_lv vccxx_lv n5 vccxx_lv e8xltp420tn2000pn1unx
xqp4[0] vccxx_lv vccxx_lv n5 vccxx_lv e8xltp420tn2000pn1unx
xqp5[15] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[14] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[13] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[12] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[11] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[10] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[9] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[8] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[7] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[6] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[5] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[4] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[3] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[2] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[1] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp5[0] vccxx_lv vccxx_lv n6 vccxx_lv e8xltp420tn2000pn1unx
xqp6[7] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[6] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[5] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[4] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[3] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[2] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[1] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqp6[0] vccxx_lv vccxx_lv n7 vccxx_lv e8xltp420tn2000pn1unx
xqn7[3] vss n8 vss e8xltp420tn2000nn1unx
xqn7[2] vss n8 vss e8xltp420tn2000nn1unx
xqn7[1] vss n8 vss e8xltp420tn2000nn1unx
xqn7[0] vss n8 vss e8xltp420tn2000nn1unx
xqn11[15] vss n0 vss e8xltp420tn2000nn1unx
xqn11[14] vss n0 vss e8xltp420tn2000nn1unx
xqn11[13] vss n0 vss e8xltp420tn2000nn1unx
xqn11[12] vss n0 vss e8xltp420tn2000nn1unx
xqn11[11] vss n0 vss e8xltp420tn2000nn1unx
xqn11[10] vss n0 vss e8xltp420tn2000nn1unx
xqn11[9] vss n0 vss e8xltp420tn2000nn1unx
xqn11[8] vss n0 vss e8xltp420tn2000nn1unx
xqn11[7] vss n0 vss e8xltp420tn2000nn1unx
xqn11[6] vss n0 vss e8xltp420tn2000nn1unx
xqn11[5] vss n0 vss e8xltp420tn2000nn1unx
xqn11[4] vss n0 vss e8xltp420tn2000nn1unx
xqn11[3] vss n0 vss e8xltp420tn2000nn1unx
xqn11[2] vss n0 vss e8xltp420tn2000nn1unx
xqn11[1] vss n0 vss e8xltp420tn2000nn1unx
xqn11[0] vss n0 vss e8xltp420tn2000nn1unx
xqn4[3] vss n5 vss e8xltp420tn2000nn1unx
xqn4[2] vss n5 vss e8xltp420tn2000nn1unx
xqn4[1] vss n5 vss e8xltp420tn2000nn1unx
xqn4[0] vss n5 vss e8xltp420tn2000nn1unx
xqn1[7] vss n1 vss e8xltp420tn2000nn1unx
xqn1[6] vss n1 vss e8xltp420tn2000nn1unx
xqn1[5] vss n1 vss e8xltp420tn2000nn1unx
xqn1[4] vss n1 vss e8xltp420tn2000nn1unx
xqn1[3] vss n1 vss e8xltp420tn2000nn1unx
xqn1[2] vss n1 vss e8xltp420tn2000nn1unx
xqn1[1] vss n1 vss e8xltp420tn2000nn1unx
xqn1[0] vss n1 vss e8xltp420tn2000nn1unx
xqn0[3] vss n2 vss e8xltp420tn2000nn1unx
xqn0[2] vss n2 vss e8xltp420tn2000nn1unx
xqn0[1] vss n2 vss e8xltp420tn2000nn1unx
xqn0[0] vss n2 vss e8xltp420tn2000nn1unx
xqn2[15] vss n3 vss e8xltp420tn2000nn1unx
xqn2[14] vss n3 vss e8xltp420tn2000nn1unx
xqn2[13] vss n3 vss e8xltp420tn2000nn1unx
xqn2[12] vss n3 vss e8xltp420tn2000nn1unx
xqn2[11] vss n3 vss e8xltp420tn2000nn1unx
xqn2[10] vss n3 vss e8xltp420tn2000nn1unx
xqn2[9] vss n3 vss e8xltp420tn2000nn1unx
xqn2[8] vss n3 vss e8xltp420tn2000nn1unx
xqn2[7] vss n3 vss e8xltp420tn2000nn1unx
xqn2[6] vss n3 vss e8xltp420tn2000nn1unx
xqn2[5] vss n3 vss e8xltp420tn2000nn1unx
xqn2[4] vss n3 vss e8xltp420tn2000nn1unx
xqn2[3] vss n3 vss e8xltp420tn2000nn1unx
xqn2[2] vss n3 vss e8xltp420tn2000nn1unx
xqn2[1] vss n3 vss e8xltp420tn2000nn1unx
xqn2[0] vss n3 vss e8xltp420tn2000nn1unx
xqn3[7] vss n4 vss e8xltp420tn2000nn1unx
xqn3[6] vss n4 vss e8xltp420tn2000nn1unx
xqn3[5] vss n4 vss e8xltp420tn2000nn1unx
xqn3[4] vss n4 vss e8xltp420tn2000nn1unx
xqn3[3] vss n4 vss e8xltp420tn2000nn1unx
xqn3[2] vss n4 vss e8xltp420tn2000nn1unx
xqn3[1] vss n4 vss e8xltp420tn2000nn1unx
xqn3[0] vss n4 vss e8xltp420tn2000nn1unx
xqn5[15] vss n6 vss e8xltp420tn2000nn1unx
xqn5[14] vss n6 vss e8xltp420tn2000nn1unx
xqn5[13] vss n6 vss e8xltp420tn2000nn1unx
xqn5[12] vss n6 vss e8xltp420tn2000nn1unx
xqn5[11] vss n6 vss e8xltp420tn2000nn1unx
xqn5[10] vss n6 vss e8xltp420tn2000nn1unx
xqn5[9] vss n6 vss e8xltp420tn2000nn1unx
xqn5[8] vss n6 vss e8xltp420tn2000nn1unx
xqn5[7] vss n6 vss e8xltp420tn2000nn1unx
xqn5[6] vss n6 vss e8xltp420tn2000nn1unx
xqn5[5] vss n6 vss e8xltp420tn2000nn1unx
xqn5[4] vss n6 vss e8xltp420tn2000nn1unx
xqn5[3] vss n6 vss e8xltp420tn2000nn1unx
xqn5[2] vss n6 vss e8xltp420tn2000nn1unx
xqn5[1] vss n6 vss e8xltp420tn2000nn1unx
xqn5[0] vss n6 vss e8xltp420tn2000nn1unx
xqn6[7] vss n7 vss e8xltp420tn2000nn1unx
xqn6[6] vss n7 vss e8xltp420tn2000nn1unx
xqn6[5] vss n7 vss e8xltp420tn2000nn1unx
xqn6[4] vss n7 vss e8xltp420tn2000nn1unx
xqn6[3] vss n7 vss e8xltp420tn2000nn1unx
xqn6[2] vss n7 vss e8xltp420tn2000nn1unx
xqn6[1] vss n7 vss e8xltp420tn2000nn1unx
xqn6[0] vss n7 vss e8xltp420tn2000nn1unx
.ends ip10xddrdll_mcpimixer
** end of subcircuit definition.

** library name: e9prim
** cell name: e92psvt_stack
** view name: schematic
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltr220tn2000ps1unx
** view name: schematic
.subckt e8xltr220tn2000ps1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltr220tn2000ps1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000ps1unx/schematic 
* CELLLOG e8libana nil e8xltr220tn2000ps1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000ps1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14592 
* Version: Unmanaged 
* INOUT:  s  d  b 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B  b:B 
*.PININFO  g:I 
* ----------------------------

mstkp0.stckp1 d g stkp0.sd01 b psvt l=20e-9 w=68e-9 m=1
mstkp0.stckp0 stkp0.sd01 g s b psvt l=20e-9 w=68e-9 m=1
.ends e8xltr220tn2000ps1unx
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltc41dtn2000nn1unx
** view name: schematic
.subckt e8xltc41dtn2000nn1unx g1 n1 n3 x
* ----------------------------
* CELLLOG e8libana nil e8xltc41dtn2000nn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc41dtn2000nn1unx/schematic 
* CELLLOG e8libana nil e8xltc41dtn2000nn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc41dtn2000nn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 5436 
* Version: Unmanaged 
* INOUT:  x  n1  n3 
* INPUT:  g1 
* ----------------------------
*.PININFO  x:B  n1:B  n3:B 
*.PININFO  g1:I 
* ----------------------------

mqn1 n1 g1 n3 vss n l=20e-9 w=136e-9 m=1
mqn0 n3 x x vss n l=20e-9 w=136e-9 m=1
.ends e8xltc41dtn2000nn1unx
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltc41dtn2000pn1unx
** view name: schematic
.subckt e8xltc41dtn2000pn1unx b g1 n1 n3 x
* ----------------------------
* CELLLOG e8libana nil e8xltc41dtn2000pn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc41dtn2000pn1unx/schematic 
* CELLLOG e8libana nil e8xltc41dtn2000pn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltc41dtn2000pn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 5908 
* Version: Unmanaged 
* INOUT:  x  n1  n3 
*+ b 
* INPUT:  g1 
* ----------------------------
*.PININFO  x:B  n1:B  n3:B 
*.PININFO  b:B 
*.PININFO  g1:I 
* ----------------------------

mqn1 n3 g1 n1 b p l=20e-9 w=136e-9 m=1
mqn0 x x n3 b p l=20e-9 w=136e-9 m=1
.ends e8xltc41dtn2000pn1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdlycellbwcb
** view name: schematic
.subckt ip10xddrdll_mcdlycellbwcb i nb nb0en nbw0 nbw1 nbw2 nbw3 ob pb pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlycellbwcb schematic 1.14 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlycellbwcb/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlycellbwcb symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlycellbwcb/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 75268 
* Version: 1.5 
* INPUT:  nb0en  pb0enb  vccxx_lv 
*+ pb  nb  i  nbw3 
*+ nbw2  nbw1  nbw0  pbw3 
*+ pbw2  pbw1  pbw0 
* OUTPUT:  ob 
* ----------------------------
*.PININFO  nb0en:I  pb0enb:I  vccxx_lv:I 
*.PININFO  pb:I  nb:I  i:I  nbw3:I 
*.PININFO  nbw2:I  nbw1:I  nbw0:I  pbw3:I 
*.PININFO  pbw2:I  pbw1:I  pbw0:I 
*.PININFO  ob:O 
* ----------------------------

xqn9[3] nxx4 nb vss e8xltp420tn2000nn1unx
xqn9[2] nxx4 nb vss e8xltp420tn2000nn1unx
xqn9[1] nxx4 nb vss e8xltp420tn2000nn1unx
xqn9[0] nxx4 nb vss e8xltp420tn2000nn1unx
xqn5 nxx2 nb vss e8xltp420tn2000nn1unx
xqn10[3] nxx nbw3 nxx4 e8xltp420tn2000nn1unx
xqn10[2] nxx nbw3 nxx4 e8xltp420tn2000nn1unx
xqn10[1] nxx nbw3 nxx4 e8xltp420tn2000nn1unx
xqn10[0] nxx nbw3 nxx4 e8xltp420tn2000nn1unx
xqn7[1] nxx3 nb vss e8xltp420tn2000nn1unx
xqn7[0] nxx3 nb vss e8xltp420tn2000nn1unx
xqn6 nxx nbw1 nxx2 e8xltp420tn2000nn1unx
xqn8[1] nxx nbw2 nxx3 e8xltp420tn2000nn1unx
xqn8[0] nxx nbw2 nxx3 e8xltp420tn2000nn1unx
xqn2 nxx nb0en nxx0 e8xltp420tn2000nn1unx
xqn1 nxx0 nb vss e8xltp420tn2000nn1unx
xqn0 ob i nxx e8xltp420tn2000nn1unx
xqn3q nb vss nxx1 vss e8xltc41dtn2000nn1unx
xqn4 nbw0 nxx nxx1 vss e8xltc41dtn2000nn1unx
xqp5 vccxx_lv pxx2 pb vccxx_lv e8xltp420tn2000pn1unx
xqp6 vccxx_lv pxx pbw1 pxx2 e8xltp420tn2000pn1unx
xqp10[3] vccxx_lv pxx pbw3 pxx4 e8xltp420tn2000pn1unx
xqp10[2] vccxx_lv pxx pbw3 pxx4 e8xltp420tn2000pn1unx
xqp10[1] vccxx_lv pxx pbw3 pxx4 e8xltp420tn2000pn1unx
xqp10[0] vccxx_lv pxx pbw3 pxx4 e8xltp420tn2000pn1unx
xqp9[3] vccxx_lv pxx4 pb vccxx_lv e8xltp420tn2000pn1unx
xqp9[2] vccxx_lv pxx4 pb vccxx_lv e8xltp420tn2000pn1unx
xqp9[1] vccxx_lv pxx4 pb vccxx_lv e8xltp420tn2000pn1unx
xqp9[0] vccxx_lv pxx4 pb vccxx_lv e8xltp420tn2000pn1unx
xqp7[1] vccxx_lv pxx3 pb vccxx_lv e8xltp420tn2000pn1unx
xqp7[0] vccxx_lv pxx3 pb vccxx_lv e8xltp420tn2000pn1unx
xqp8[1] vccxx_lv pxx pbw2 pxx3 e8xltp420tn2000pn1unx
xqp8[0] vccxx_lv pxx pbw2 pxx3 e8xltp420tn2000pn1unx
xqp1 vccxx_lv pxx0 pb vccxx_lv e8xltp420tn2000pn1unx
xqp0 vccxx_lv ob i pxx e8xltp420tn2000pn1unx
xqp2 vccxx_lv pxx pb0enb pxx0 e8xltp420tn2000pn1unx
xqp4 vccxx_lv pbw0 pxx pxx1 vccxx_lv e8xltc41dtn2000pn1unx
xqp3 vccxx_lv pb vccxx_lv pxx1 vccxx_lv e8xltc41dtn2000pn1unx
.ends ip10xddrdll_mcdlycellbwcb
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_nand2_4dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_nand2_4dgsvtsp24x_nonadt a b o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nand2_4dgsvtsp24x_nonadt schematic 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nand2_4dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nand2_4dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nand2_4dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 57272 
* Version: 1.2 
* INPUT:  a  b  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
mqp1 o1 a vccxx_lv vccxx_lv psvt l=20e-9 w=68e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
mqn2 n0 b vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn2dum vss vss vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1dum o1 vss vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn1 o1 a n0 vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
.ends ip10xddrdll_nand2_4dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcbiasedmpimux
** view name: schematic
.subckt ip10xddrdll_mcbiasedmpimux bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] mxclkph0 mxclkph1 nb pb piclk0 piclk1 pien vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbiasedmpimux schematic 1.12 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbiasedmpimux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbiasedmpimux symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbiasedmpimux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 123781 
* Version: 1.4 
* INPUT:  vccxx_lv  pien  nb 
*+ pb  bwctrl[0]  bwctrl[1]  bwctrl[2] 
*+ bwctrl[3]  mxclkph1  mxclkph0 
* OUTPUT:  piclk1  piclk0 
* ----------------------------
*.PININFO  vccxx_lv:I  pien:I  nb:I 
*.PININFO  pb:I  bwctrl[0]:I  bwctrl[1]:I  bwctrl[2]:I 
*.PININFO  bwctrl[3]:I  mxclkph1:I  mxclkph0:I 
*.PININFO  piclk1:O  piclk0:O 
* ----------------------------

xqp0 vccxx_lv piclk1 pien vccxx_lv e8xltr220tn2000ps1unx
xstkn1q vccxx_lv piclk0 pien vccxx_lv e8xltr220tn2000ps1unx
xipiph1[1] piclkph1b nb pien nbw[0] nbw[1] nbw[2] nbw[3] piclk1 pb pienb pbw[0] pbw[1] pbw[2] pbw[3] vccxx_lv ip10xddrdll_mcdlycellbwcb
xipiph1[0] piclkph1b nb pien nbw[0] nbw[1] nbw[2] nbw[3] piclk1 pb pienb pbw[0] pbw[1] pbw[2] pbw[3] vccxx_lv ip10xddrdll_mcdlycellbwcb
xipiph0[1] piclkph0b nb pien nbw[0] nbw[1] nbw[2] nbw[3] piclk0 pb pienb pbw[0] pbw[1] pbw[2] pbw[3] vccxx_lv ip10xddrdll_mcdlycellbwcb
xipiph0[0] piclkph0b nb pien nbw[0] nbw[1] nbw[2] nbw[3] piclk0 pb pienb pbw[0] pbw[1] pbw[2] pbw[3] vccxx_lv ip10xddrdll_mcdlycellbwcb
xinv1[3] pbw[3] nbw[3] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[2] pbw[2] nbw[2] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[1] pbw[1] nbw[1] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[0] pbw[0] nbw[0] vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv00[1] mxclkph1 piclkph1b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv00[0] mxclkph1 piclkph1b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv01[3] pien pienb vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv01[2] pien pienb vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv01[1] pien pienb vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv01[0] pien pienb vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv0[1] mxclkph0 piclkph0b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv0[0] mxclkph0 piclkph0b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinand2[3] bwctrl[3] pien pbw[3] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand2[2] bwctrl[2] pien pbw[2] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand2[1] bwctrl[1] pien pbw[1] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand2[0] bwctrl[0] pien pbw[0] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mcbiasedmpimux
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmpiana
** view name: schematic
.subckt ip10xddrdll_mcmpiana clkph0_b clkph1_b drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picb[2] picb[1] picb[0] piclk pien pisel[7] pisel[6] pisel[5] pisel[4] pisel[3] pisel[2] pisel[1] pisel[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpiana schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpiana/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpiana symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpiana/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 58880 
* Version: 1.3 
* INPUT:  clkph0_b  clkph1_b  picb[0] 
*+ picb[1]  picb[2]  nbias_a  pbias_a 
*+ pien  drvsel[0]  drvsel[1]  drvsel[2] 
*+ drvsel[3]  vccxx_lv  pisel[0]  pisel[1] 
*+ pisel[2]  pisel[3]  pisel[4]  pisel[5] 
*+ pisel[6]  pisel[7] 
* OUTPUT:  piclk 
* ----------------------------
*.PININFO  clkph0_b:I  clkph1_b:I  picb[0]:I 
*.PININFO  picb[1]:I  picb[2]:I  nbias_a:I  pbias_a:I 
*.PININFO  pien:I  drvsel[0]:I  drvsel[1]:I  drvsel[2]:I 
*.PININFO  drvsel[3]:I  vccxx_lv:I  pisel[0]:I  pisel[1]:I 
*.PININFO  pisel[2]:I  pisel[3]:I  pisel[4]:I  pisel[5]:I 
*.PININFO  pisel[6]:I  pisel[7]:I 
*.PININFO  piclk:O 
* ----------------------------

xiphasemixer picb[2] picb[1] picb[0] piclk piclkph0 piclkph1 pisel[7] pisel[6] pisel[5] pisel[4] pisel[3] pisel[2] pisel[1] pisel[0] vccxx_lv ip10xddrdll_mcpimixer
ximux drvsel[3] drvsel[2] drvsel[1] drvsel[0] clkph0_b clkph1_b nbias_a pbias_a piclkph0 piclkph1 pien vccxx_lv ip10xddrdll_mcbiasedmpimux
.ends ip10xddrdll_mcmpiana
** end of subcircuit definition.

** library name: e9prim
** cell name: e92p_stack
** view name: schematic
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltr220tn2000pn1unx
** view name: schematic
.subckt e8xltr220tn2000pn1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltr220tn2000pn1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000pn1unx/schematic 
* CELLLOG e8libana nil e8xltr220tn2000pn1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000pn1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14592 
* Version: Unmanaged 
* INOUT:  s  d  b 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B  b:B 
*.PININFO  g:I 
* ----------------------------

mstkp0.stckp1 d g stkp0.sd01 b p l=20e-9 w=68e-9 m=1
mstkp0.stckp0 stkp0.sd01 g s b p l=20e-9 w=68e-9 m=1
.ends e8xltr220tn2000pn1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmpitop
** view name: schematic
.subckt ip10xddrdll_mcmpitop clkph0_b clkph1_b drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picb[2] picb[1] picb[0] piclkout pienable pisel[7] pisel[6] pisel[5] pisel[4] pisel[3] pisel[2] pisel[1] pisel[0] rcvenable vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpitop schematic 1.15 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpitop/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmpitop symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmpitop/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 67254 
* Version: 1.4 
* INPUT:  drvsel[0]  drvsel[1]  drvsel[2] 
*+ drvsel[3]  nbias_a  pienable  vccxx_lv 
*+ picb[0]  picb[1]  picb[2]  clkph1_b 
*+ clkph0_b  rcvenable  pbias_a  pisel[0] 
*+ pisel[1]  pisel[2]  pisel[3]  pisel[4] 
*+ pisel[5]  pisel[6]  pisel[7] 
* OUTPUT:  piclkout 
* ----------------------------
*.PININFO  drvsel[0]:I  drvsel[1]:I  drvsel[2]:I 
*.PININFO  drvsel[3]:I  nbias_a:I  pienable:I  vccxx_lv:I 
*.PININFO  picb[0]:I  picb[1]:I  picb[2]:I  clkph1_b:I 
*.PININFO  clkph0_b:I  rcvenable:I  pbias_a:I  pisel[0]:I 
*.PININFO  pisel[1]:I  pisel[2]:I  pisel[3]:I  pisel[4]:I 
*.PININFO  pisel[5]:I  pisel[6]:I  pisel[7]:I 
*.PININFO  piclkout:O 
* ----------------------------

xinvrcven rcvenable rcven_b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinven pienable pidisable vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv00 pidisable pienabled vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinor_dqsp pickmixo_b piout rcven_b vccxx_lv ip10xddrdll_cnor2_4dgnomsp24x_nonadt
xiogpibuf1[3] piout piclkout vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiogpibuf1[2] piout piclkout vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiogpibuf1[1] piout piclkout vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiogpibuf1[0] piout piclkout vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xidllddrpiana clkph0_b clkph1_b drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbs[2] picbs[1] picbs[0] pickmixo_b rcvenable pisel[7] pisel[6] pisel[5] pisel[4] pisel[3] pisel[2] pisel[1] pisel[0] vccxx_lv ip10xddrdll_mcmpiana
xbfn00[2] picb[2] picbs[2] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xbfn00[1] picb[1] picbs[1] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xbfn00[0] picb[0] picbs[0] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xqp1 vccxx_lv vccxx_lv pienabled vccxx_lv e8xltr220tn2000pn1unx
.ends ip10xddrdll_mcmpitop
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mc5piana
** view name: schematic
.subckt ip10xddrdll_mc5piana clkinqh[7] clkinqh[6] clkinqh[5] clkinqh[4] clkinqh[3] clkinqh[2] clkinqh[1] clkinqh[0] dismixerinwklockqnnnl drvsel[3] drvsel[2] drvsel[1] drvsel[0] mux0selqnnnh[7] mux0selqnnnh[6] mux0selqnnnh[5] mux0selqnnnh[4] mux0selqnnnh[3] mux0selqnnnh[2] mux0selqnnnh[1] mux0selqnnnh[0] mux1selqnnnh[7] mux1selqnnnh[6] mux1selqnnnh[5] mux1selqnnnh[4] mux1selqnnnh[3] mux1selqnnnh[2] mux1selqnnnh[1] mux1selqnnnh[0] mux2selqnnnh[7] mux2selqnnnh[6] mux2selqnnnh[5] mux2selqnnnh[4] mux2selqnnnh[3] mux2selqnnnh[2] mux2selqnnnh[1] mux2selqnnnh[0] mux3selqnnnh[7] mux3selqnnnh[6] mux3selqnnnh[5] mux3selqnnnh[4] mux3selqnnnh[3] mux3selqnnnh[2] mux3selqnnnh[1] mux3selqnnnh[0] muxrefselqnnnh[7] muxrefselqnnnh[6] muxrefselqnnnh[5] muxrefselqnnnh[4] muxrefselqnnnh[3] muxrefselqnnnh[2] muxrefselqnnnh[1] muxrefselqnnnh[0] nbias_a pbias_a phdrenqnnnh[7] phdrenqnnnh[6] phdrenqnnnh[5] phdrenqnnnh[4] phdrenqnnnh[3] phdrenqnnnh[2] phdrenqnnnh[1] phdrenqnnnh[0] phdrpwrsavonqnnnh picbqnnnh[2] picbqnnnh[1]
+picbqnnnh[0] piclk[3] piclk[2] piclk[1] piclk[0] piclkd0 picode0thmqnnnh[7] picode0thmqnnnh[6] picode0thmqnnnh[5] picode0thmqnnnh[4] picode0thmqnnnh[3] picode0thmqnnnh[2] picode0thmqnnnh[1] picode0thmqnnnh[0] picode1thmqnnnh[7] picode1thmqnnnh[6] picode1thmqnnnh[5] picode1thmqnnnh[4] picode1thmqnnnh[3] picode1thmqnnnh[2] picode1thmqnnnh[1] picode1thmqnnnh[0] picode2thmqnnnh[7] picode2thmqnnnh[6] picode2thmqnnnh[5] picode2thmqnnnh[4] picode2thmqnnnh[3] picode2thmqnnnh[2] picode2thmqnnnh[1] picode2thmqnnnh[0] picode3thmqnnnh[7] picode3thmqnnnh[6] picode3thmqnnnh[5] picode3thmqnnnh[4] picode3thmqnnnh[3] picode3thmqnnnh[2] picode3thmqnnnh[1] picode3thmqnnnh[0] picoded0thmqnnnh[7] picoded0thmqnnnh[6] picoded0thmqnnnh[5] picoded0thmqnnnh[4] picoded0thmqnnnh[3] picoded0thmqnnnh[2] picoded0thmqnnnh[1] picoded0thmqnnnh[0] pienqnnnh[3] pienqnnnh[2] pienqnnnh[1] pienqnnnh[0] pirefenqnnnh vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5piana schematic 1.16 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5piana/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc5piana symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc5piana/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 265074 
* Version: 1.3 
* INPUT:  dismixerinwklockqnnnl  picode2thmqnnnh[0]  picode2thmqnnnh[1] 
*+ picode2thmqnnnh[2]  picode2thmqnnnh[3]  picode2thmqnnnh[4]  picode2thmqnnnh[5] 
*+ picode2thmqnnnh[6]  picode2thmqnnnh[7]  drvsel[0]  drvsel[1] 
*+ drvsel[2]  drvsel[3]  vccxx_lv  picbqnnnh[0] 
*+ picbqnnnh[1]  picbqnnnh[2]  pirefenqnnnh  pienqnnnh[0] 
*+ pienqnnnh[1]  pienqnnnh[2]  pienqnnnh[3]  picode1thmqnnnh[0] 
*+ picode1thmqnnnh[1]  picode1thmqnnnh[2]  picode1thmqnnnh[3]  picode1thmqnnnh[4] 
*+ picode1thmqnnnh[5]  picode1thmqnnnh[6]  picode1thmqnnnh[7]  pbias_a 
*+ picode0thmqnnnh[0]  picode0thmqnnnh[1]  picode0thmqnnnh[2]  picode0thmqnnnh[3] 
*+ picode0thmqnnnh[4]  picode0thmqnnnh[5]  picode0thmqnnnh[6]  picode0thmqnnnh[7] 
*+ picode3thmqnnnh[0]  picode3thmqnnnh[1]  picode3thmqnnnh[2]  picode3thmqnnnh[3] 
*+ picode3thmqnnnh[4]  picode3thmqnnnh[5]  picode3thmqnnnh[6]  picode3thmqnnnh[7] 
*+ nbias_a  mux0selqnnnh[0]  mux0selqnnnh[1]  mux0selqnnnh[2] 
*+ mux0selqnnnh[3]  mux0selqnnnh[4]  mux0selqnnnh[5]  mux0selqnnnh[6] 
*+ mux0selqnnnh[7]  mux2selqnnnh[0]  mux2selqnnnh[1]  mux2selqnnnh[2] 
*+ mux2selqnnnh[3]  mux2selqnnnh[4]  mux2selqnnnh[5]  mux2selqnnnh[6] 
*+ mux2selqnnnh[7]  mux1selqnnnh[0]  mux1selqnnnh[1]  mux1selqnnnh[2] 
*+ mux1selqnnnh[3]  mux1selqnnnh[4]  mux1selqnnnh[5]  mux1selqnnnh[6] 
*+ mux1selqnnnh[7]  mux3selqnnnh[0]  mux3selqnnnh[1]  mux3selqnnnh[2] 
*+ mux3selqnnnh[3]  mux3selqnnnh[4]  mux3selqnnnh[5]  mux3selqnnnh[6] 
*+ mux3selqnnnh[7]  picoded0thmqnnnh[0]  picoded0thmqnnnh[1]  picoded0thmqnnnh[2] 
*+ picoded0thmqnnnh[3]  picoded0thmqnnnh[4]  picoded0thmqnnnh[5]  picoded0thmqnnnh[6] 
*+ picoded0thmqnnnh[7]  muxrefselqnnnh[0]  muxrefselqnnnh[1]  muxrefselqnnnh[2] 
*+ muxrefselqnnnh[3]  muxrefselqnnnh[4]  muxrefselqnnnh[5]  muxrefselqnnnh[6] 
*+ muxrefselqnnnh[7]  clkinqh[0]  clkinqh[1]  clkinqh[2] 
*+ clkinqh[3]  clkinqh[4]  clkinqh[5]  clkinqh[6] 
*+ clkinqh[7]  phdrpwrsavonqnnnh 
* OUTPUT:  phdrenqnnnh[0]  phdrenqnnnh[1]  phdrenqnnnh[2] 
*+ phdrenqnnnh[3]  phdrenqnnnh[4]  phdrenqnnnh[5]  phdrenqnnnh[6] 
*+ phdrenqnnnh[7]  piclk[0]  piclk[1]  piclk[2] 
*+ piclk[3]  piclkd0 
* ----------------------------
*.PININFO  dismixerinwklockqnnnl:I  picode2thmqnnnh[0]:I  picode2thmqnnnh[1]:I 
*.PININFO  picode2thmqnnnh[2]:I  picode2thmqnnnh[3]:I  picode2thmqnnnh[4]:I  picode2thmqnnnh[5]:I 
*.PININFO  picode2thmqnnnh[6]:I  picode2thmqnnnh[7]:I  drvsel[0]:I  drvsel[1]:I 
*.PININFO  drvsel[2]:I  drvsel[3]:I  vccxx_lv:I  picbqnnnh[0]:I 
*.PININFO  picbqnnnh[1]:I  picbqnnnh[2]:I  pirefenqnnnh:I  pienqnnnh[0]:I 
*.PININFO  pienqnnnh[1]:I  pienqnnnh[2]:I  pienqnnnh[3]:I  picode1thmqnnnh[0]:I 
*.PININFO  picode1thmqnnnh[1]:I  picode1thmqnnnh[2]:I  picode1thmqnnnh[3]:I  picode1thmqnnnh[4]:I 
*.PININFO  picode1thmqnnnh[5]:I  picode1thmqnnnh[6]:I  picode1thmqnnnh[7]:I  pbias_a:I 
*.PININFO  picode0thmqnnnh[0]:I  picode0thmqnnnh[1]:I  picode0thmqnnnh[2]:I  picode0thmqnnnh[3]:I 
*.PININFO  picode0thmqnnnh[4]:I  picode0thmqnnnh[5]:I  picode0thmqnnnh[6]:I  picode0thmqnnnh[7]:I 
*.PININFO  picode3thmqnnnh[0]:I  picode3thmqnnnh[1]:I  picode3thmqnnnh[2]:I  picode3thmqnnnh[3]:I 
*.PININFO  picode3thmqnnnh[4]:I  picode3thmqnnnh[5]:I  picode3thmqnnnh[6]:I  picode3thmqnnnh[7]:I 
*.PININFO  nbias_a:I  mux0selqnnnh[0]:I  mux0selqnnnh[1]:I  mux0selqnnnh[2]:I 
*.PININFO  mux0selqnnnh[3]:I  mux0selqnnnh[4]:I  mux0selqnnnh[5]:I  mux0selqnnnh[6]:I 
*.PININFO  mux0selqnnnh[7]:I  mux2selqnnnh[0]:I  mux2selqnnnh[1]:I  mux2selqnnnh[2]:I 
*.PININFO  mux2selqnnnh[3]:I  mux2selqnnnh[4]:I  mux2selqnnnh[5]:I  mux2selqnnnh[6]:I 
*.PININFO  mux2selqnnnh[7]:I  mux1selqnnnh[0]:I  mux1selqnnnh[1]:I  mux1selqnnnh[2]:I 
*.PININFO  mux1selqnnnh[3]:I  mux1selqnnnh[4]:I  mux1selqnnnh[5]:I  mux1selqnnnh[6]:I 
*.PININFO  mux1selqnnnh[7]:I  mux3selqnnnh[0]:I  mux3selqnnnh[1]:I  mux3selqnnnh[2]:I 
*.PININFO  mux3selqnnnh[3]:I  mux3selqnnnh[4]:I  mux3selqnnnh[5]:I  mux3selqnnnh[6]:I 
*.PININFO  mux3selqnnnh[7]:I  picoded0thmqnnnh[0]:I  picoded0thmqnnnh[1]:I  picoded0thmqnnnh[2]:I 
*.PININFO  picoded0thmqnnnh[3]:I  picoded0thmqnnnh[4]:I  picoded0thmqnnnh[5]:I  picoded0thmqnnnh[6]:I 
*.PININFO  picoded0thmqnnnh[7]:I  muxrefselqnnnh[0]:I  muxrefselqnnnh[1]:I  muxrefselqnnnh[2]:I 
*.PININFO  muxrefselqnnnh[3]:I  muxrefselqnnnh[4]:I  muxrefselqnnnh[5]:I  muxrefselqnnnh[6]:I 
*.PININFO  muxrefselqnnnh[7]:I  clkinqh[0]:I  clkinqh[1]:I  clkinqh[2]:I 
*.PININFO  clkinqh[3]:I  clkinqh[4]:I  clkinqh[5]:I  clkinqh[6]:I 
*.PININFO  clkinqh[7]:I  phdrpwrsavonqnnnh:I 
*.PININFO  phdrenqnnnh[0]:O  phdrenqnnnh[1]:O  phdrenqnnnh[2]:O 
*.PININFO  phdrenqnnnh[3]:O  phdrenqnnnh[4]:O  phdrenqnnnh[5]:O  phdrenqnnnh[6]:O 
*.PININFO  phdrenqnnnh[7]:O  piclk[0]:O  piclk[1]:O  piclk[2]:O 
*.PININFO  piclk[3]:O  piclkd0:O 
* ----------------------------

xpimux0 dismixerinwklockd mux0selqnnnh[0] mux0selqnnnh[7] picode0thmqnnnh[7] picode0thmqnnnh[6] picode0thmqnnnh[5] picode0thmqnnnh[4] picode0thmqnnnh[3] picode0thmqnnnh[2] picode0thmqnnnh[1] picode0thmqnnnh[0] picode0thfinal[7] picode0thfinal[6] picode0thfinal[5] picode0thfinal[4] picode0thfinal[3] picode0thfinal[2] picode0thfinal[1] picode0thfinal[0] vccxx_lv ip10xddrdll_mc5pimux
xpimuxd0 dismixerinwklockd muxrefselqnnnh[0] muxrefselqnnnh[7] picoded0thmqnnnh[7] picoded0thmqnnnh[6] picoded0thmqnnnh[5] picoded0thmqnnnh[4] picoded0thmqnnnh[3] picoded0thmqnnnh[2] picoded0thmqnnnh[1] picoded0thmqnnnh[0] picoded0final[7] picoded0final[6] picoded0final[5] picoded0final[4] picoded0final[3] picoded0final[2] picoded0final[1] picoded0final[0] vccxx_lv ip10xddrdll_mc5pimux
xpimux03 dismixerinwklockd mux3selqnnnh[0] mux3selqnnnh[7] picode3thmqnnnh[7] picode3thmqnnnh[6] picode3thmqnnnh[5] picode3thmqnnnh[4] picode3thmqnnnh[3] picode3thmqnnnh[2] picode3thmqnnnh[1] picode3thmqnnnh[0] picode3thfinal[7] picode3thfinal[6] picode3thfinal[5] picode3thfinal[4] picode3thfinal[3] picode3thfinal[2] picode3thfinal[1] picode3thfinal[0] vccxx_lv ip10xddrdll_mc5pimux
xpimux1 dismixerinwklockd mux1selqnnnh[0] mux1selqnnnh[7] picode1thmqnnnh[7] picode1thmqnnnh[6] picode1thmqnnnh[5] picode1thmqnnnh[4] picode1thmqnnnh[3] picode1thmqnnnh[2] picode1thmqnnnh[1] picode1thmqnnnh[0] picode1thfinal[7] picode1thfinal[6] picode1thfinal[5] picode1thfinal[4] picode1thfinal[3] picode1thfinal[2] picode1thfinal[1] picode1thfinal[0] vccxx_lv ip10xddrdll_mc5pimux
xpimux2 dismixerinwklockd mux2selqnnnh[0] mux2selqnnnh[7] picode2thmqnnnh[7] picode2thmqnnnh[6] picode2thmqnnnh[5] picode2thmqnnnh[4] picode2thmqnnnh[3] picode2thmqnnnh[2] picode2thmqnnnh[1] picode2thmqnnnh[0] picode2thfinal[7] picode2thfinal[6] picode2thfinal[5] picode2thfinal[4] picode2thfinal[3] picode2thfinal[2] picode2thfinal[1] picode2thfinal[0] vccxx_lv ip10xddrdll_mc5pimux
xibufdismixer dismixerinwklockqnnnl dismixerinwklockd vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xpien_buf[4] pirefenqnnnh pien[4] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xpien_buf[3] pienqnnnh[3] pien[3] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xpien_buf[2] pienqnnnh[2] pien[2] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xpien_buf[1] pienqnnnh[1] pien[1] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xpien_buf[0] pienqnnnh[0] pien[0] vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
ximux clkd0ph0_b clkd0ph1_b clkph0_b[3] clkph0_b[2] clkph0_b[1] clkph0_b[0] clkph1_b[3] clkph1_b[2] clkph1_b[1] clkph1_b[0] clkinqh[7] clkinqh[6] clkinqh[5] clkinqh[4] clkinqh[3] clkinqh[2] clkinqh[1] clkinqh[0] mux0selqnnnh[7] mux0selqnnnh[6] mux0selqnnnh[5] mux0selqnnnh[4] mux0selqnnnh[3] mux0selqnnnh[2] mux0selqnnnh[1] mux0selqnnnh[0] mux1selqnnnh[7] mux1selqnnnh[6] mux1selqnnnh[5] mux1selqnnnh[4] mux1selqnnnh[3] mux1selqnnnh[2] mux1selqnnnh[1] mux1selqnnnh[0] mux2selqnnnh[7] mux2selqnnnh[6] mux2selqnnnh[5] mux2selqnnnh[4] mux2selqnnnh[3] mux2selqnnnh[2] mux2selqnnnh[1] mux2selqnnnh[0] mux3selqnnnh[7] mux3selqnnnh[6] mux3selqnnnh[5] mux3selqnnnh[4] mux3selqnnnh[3] mux3selqnnnh[2] mux3selqnnnh[1] mux3selqnnnh[0] phdrpwrsavonqnnnh phdrenqnnnh[7] phdrenqnnnh[6] phdrenqnnnh[5] phdrenqnnnh[4] phdrenqnnnh[3] phdrenqnnnh[2] phdrenqnnnh[1] phdrenqnnnh[0] pien[4] pien[3] pien[2] pien[1] pien[0] muxrefselqnnnh[7] muxrefselqnnnh[6] muxrefselqnnnh[5] muxrefselqnnnh[4] muxrefselqnnnh[3] muxrefselqnnnh[2] 
+ muxrefselqnnnh[1] muxrefselqnnnh[0] vccxx_lv ip10xddrdll_mcmux
xirefpi clkd0ph0_b clkd0ph1_b drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] piclkd0 pirefenqnnnh picoded0final[7] picoded0final[6] picoded0final[5] picoded0final[4] picoded0final[3] picoded0final[2] picoded0final[1] picoded0final[0] pirefenqnnnh vccxx_lv ip10xddrdll_mcmpitop
xipi[3] clkph0_b[3] clkph1_b[3] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] piclk[3] pienqnnnh[3] picode3thfinal[7] picode3thfinal[6] picode3thfinal[5] picode3thfinal[4] picode3thfinal[3] picode3thfinal[2] picode3thfinal[1] picode3thfinal[0] pienqnnnh[3] vccxx_lv ip10xddrdll_mcmpitop
xipi[2] clkph0_b[2] clkph1_b[2] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] piclk[2] pienqnnnh[2] picode2thfinal[7] picode2thfinal[6] picode2thfinal[5] picode2thfinal[4] picode2thfinal[3] picode2thfinal[2] picode2thfinal[1] picode2thfinal[0] pienqnnnh[2] vccxx_lv ip10xddrdll_mcmpitop
xipi[1] clkph0_b[1] clkph1_b[1] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] piclk[1] pienqnnnh[1] picode1thfinal[7] picode1thfinal[6] picode1thfinal[5] picode1thfinal[4] picode1thfinal[3] picode1thfinal[2] picode1thfinal[1] picode1thfinal[0] pienqnnnh[1] vccxx_lv ip10xddrdll_mcmpitop
xipi[0] clkph0_b[0] clkph1_b[0] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] piclk[0] pienqnnnh[0] picode0thfinal[7] picode0thfinal[6] picode0thfinal[5] picode0thfinal[4] picode0thfinal[3] picode0thfinal[2] picode0thfinal[1] picode0thfinal[0] pienqnnnh[0] vccxx_lv ip10xddrdll_mcmpitop
.ends ip10xddrdll_mc5piana
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_inv_2dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_inv_2dgnomsp24x_nonadt a o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_2dgnomsp24x_nonadt schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_2dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_2dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_2dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 33824 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=68e-9 m=1
mqn1dum o1 vss vss vss n l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqpdummy o1 vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=68e-9 ad=2.992e-15 as=2.992e-15 pd=156e-9 ps=156e-9 m=1
mqp1 o1 a vccxx_lv vccxx_lv p l=20e-9 w=68e-9 m=1
.ends ip10xddrdll_inv_2dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_invtri_4dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_invtri_4dgnomsp24x_nonadt a o1 vccxx_lv x xb 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_invtri_4dgnomsp24x_nonadt schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_invtri_4dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_invtri_4dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_invtri_4dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 19258 
* Version: 1.2 
* INPUT:  a  x  xb 
*+ vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  x:I  xb:I 
*.PININFO  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqn1dum vss vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn0dum o1 vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqn0 o1 a nxx vss n l=20e-9 w=136e-9 m=1
mqn1 nxx x vss vss n l=20e-9 w=136e-9 m=1
mqp0dum o1 vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1dum vccxx_lv vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=1
mqp1 pxx xb vccxx_lv vccxx_lv p l=20e-9 w=136e-9 m=1
mqp0 o1 a pxx vccxx_lv p l=20e-9 w=136e-9 m=1
.ends ip10xddrdll_invtri_4dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmbuf
** view name: schematic
.subckt ip10xddrdll_mcmbuf normalmodel pin pout pout_b vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmbuf schematic 1.10 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmbuf/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmbuf symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmbuf/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 96561 
* Version: 1.3 
* INPUT:  vccxx_lv  pin  normalmodel 
* OUTPUT:  pout_b  pout 
* ----------------------------
*.PININFO  vccxx_lv:I  pin:I  normalmodel:I 
*.PININFO  pout_b:O  pout:O 
* ----------------------------

xicouple1 intopd_b inbotd vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xicouple2 inbotd intopd_b vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xicouple4 inbot_b intopd vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xicouple3 intopd inbot_b vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xtmp_qp0 vccxx_lv vccxx_lv inbot_b vccxx_lv e8xltp420tn2000ps1unx
xmtmp_qp1[1] vccxx_lv vccxx_lv inbotd vccxx_lv e8xltp420tn2000ps1unx
xmtmp_qp1[0] vccxx_lv vccxx_lv inbotd vccxx_lv e8xltp420tn2000ps1unx
xmipcap2 vccxx_lv intopd_b vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xmipcap5 vccxx_lv inbotd vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xinvtopdb[7] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[6] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[5] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[4] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[3] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[2] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[1] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopdb[0] intopd_b pout vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[7] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[6] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[5] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[4] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[3] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[2] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[1] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvbotd[0] inbotd pout_b vccxx_lv normalmode_d normalmode_b ip10xddrdll_invtri_4dgnomsp24x_nonadt
xinvtopb[1] intop_b intopd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtopb[0] intop_b intopd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbot[1] pin inbot_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbot[0] pin inbot_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbotb[3] inbot_b inbotd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbotb[2] inbot_b inbotd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbotb[1] inbot_b inbotd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvbotb[0] inbot_b inbotd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtop[1] pin intop_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtop[0] pin intop_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xi6 normalmode_b normalmode_d vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xi7 normalmodel normalmode_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtopd[3] intopd intopd_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtopd[2] intopd intopd_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtopd[1] intopd intopd_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvtopd[0] intopd intopd_b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xmtmp_qn0[1] vss inbotd vss e8xltp420tn2000ns1unx
xmtmp_qn0[0] vss inbotd vss e8xltp420tn2000ns1unx
xmincap0 vss inbot_b vss e8xltp420tn2000ns1unx
xmincap3 intopd_b vss vss e8xltp420tn2000ns1unx
xmincap6 inbotd vss vss e8xltp420tn2000ns1unx
.ends ip10xddrdll_mcmbuf
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_cnand2_4dgnomsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_cnand2_4dgnomsp24x_nonadt clk clkout en vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_cnand2_4dgnomsp24x_nonadt schematic 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_cnand2_4dgnomsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_cnand2_4dgnomsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_cnand2_4dgnomsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 47568 
* Version: 1.2 
* INPUT:  clk  en  vccxx_lv 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  en:I  vccxx_lv:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk n0 vss n l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
mqndum n0 vss vss vss n l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
mqn2 n0 en vss vss n l=20e-9 w=136e-9 ad=3.536e-15 as=3.536e-15 pd=97.33333e-9 ps=97.33333e-9 m=4
mqpdum vccxx_lv vccxx_lv vccxx_lv vccxx_lv p l=20e-9 w=136e-9 m=4
mqp1 clkout clk vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
mqp2 clkout en vccxx_lv vccxx_lv p l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
.ends ip10xddrdll_cnand2_4dgnomsp24x_nonadt
** end of subcircuit definition.

** library name: e9prim
** cell name: e92nsvt_stack
** view name: schematic
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltr220tn2000ns1unx
** view name: schematic
.subckt e8xltr220tn2000ns1unx d g s
* ----------------------------
* CELLLOG e8libana nil e8xltr220tn2000ns1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000ns1unx/schematic 
* CELLLOG e8libana nil e8xltr220tn2000ns1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr220tn2000ns1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 16413 
* Version: Unmanaged 
* INOUT:  s  d 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B 
*.PININFO  g:I 
* ----------------------------

mstkn0.stckn0 stkn0.sd01 g s vss nsvt l=20e-9 w=68e-9 m=1
mstkn0.stckn1 d g stkn0.sd01 vss nsvt l=20e-9 w=68e-9 m=1
.ends e8xltr220tn2000ns1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlyfrontbwcb
** view name: schematic
.subckt ip10xddrdll_mcmdlyfrontbwcb ckin ckout clken en en_b nb0en nbias nbw0 nbw1 nbw2 nbw3 park_b pb0enb pbias pbw0 pbw1 pbw2 pbw3 tapout vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyfrontbwcb schematic 1.14 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyfrontbwcb/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyfrontbwcb symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyfrontbwcb/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 93769 
* Version: 1.5 
* INPUT:  nbw3  vccxx_lv  nbias 
*+ pbias  en_b  nb0en  pb0enb 
*+ pbw3  pbw0  ckin  pbw1 
*+ pbw2  nbw0  nbw1  nbw2 
*+ clken  park_b  en 
* OUTPUT:  tapout  ckout 
* ----------------------------
*.PININFO  nbw3:I  vccxx_lv:I  nbias:I 
*.PININFO  pbias:I  en_b:I  nb0en:I  pb0enb:I 
*.PININFO  pbw3:I  pbw0:I  ckin:I  pbw1:I 
*.PININFO  pbw2:I  nbw0:I  nbw1:I  nbw2:I 
*.PININFO  clken:I  park_b:I  en:I 
*.PININFO  tapout:O  ckout:O 
* ----------------------------

xinvfreerunclk[1] tapout chx vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvfreerunclk[0] tapout chx vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xipidrivech1[3] chx ckout vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xipidrivech1[2] chx ckout vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xipidrivech1[1] chx ckout vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xipidrivech1[0] chx ckout vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinand ckin ckgated_b clken vccxx_lv ip10xddrdll_cnand2_4dgnomsp24x_nonadt
xqp2 vccxx_lv tapout en park_b e8xltr220tn2000ps1unx
xqn1 park_b en_b tapout e8xltr220tn2000ns1unx
xi1[1] ckgated_b nbias nb0en nbw0 nbw1 nbw2 nbw3 tapout pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xi1[0] ckgated_b nbias nb0en nbw0 nbw1 nbw2 nbw3 tapout pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
.ends ip10xddrdll_mcmdlyfrontbwcb
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcbuf
** view name: schematic
.subckt ip10xddrdll_mcbuf en en_b en_d vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbuf schematic 1.11 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbuf/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbuf symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbuf/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 26493 
* Version: 1.3 
* INPUT:  vccxx_lv  en 
* OUTPUT:  en_b  en_d 
* ----------------------------
*.PININFO  vccxx_lv:I  en:I 
*.PININFO  en_b:O  en_d:O 
* ----------------------------

xinv1[3] en en_b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[2] en en_b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[1] en en_b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv1[0] en en_b vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv4[3] en_b en_d vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv4[2] en_b en_d vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv4[1] en_b en_d vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv4[0] en_b en_d vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mcbuf
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlyendstagedummy
** view name: schematic
.subckt ip10xddrdll_mcmdlyendstagedummy ckfb en en_b nb0en nbias nbw0 nbw1 nbw2 nbw3 pb0enb pbias pbw0 pbw1 pbw2 pbw3 tapin vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyendstagedummy schematic 1.14 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyendstagedummy/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyendstagedummy symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyendstagedummy/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 74332 
* Version: 1.5 
* INPUT:  nbw3  vccxx_lv  nbias 
*+ tapin  pbias  pbw3  en 
*+ en_b  pb0enb  nb0en  nbw1 
*+ pbw0  nbw0  pbw2  pbw1 
*+ nbw2 
* OUTPUT:  ckfb 
* ----------------------------
*.PININFO  nbw3:I  vccxx_lv:I  nbias:I 
*.PININFO  tapin:I  pbias:I  pbw3:I  en:I 
*.PININFO  en_b:I  pb0enb:I  nb0en:I  nbw1:I 
*.PININFO  pbw0:I  nbw0:I  pbw2:I  pbw1:I 
*.PININFO  nbw2:I 
*.PININFO  ckfb:O 
* ----------------------------

xickinv1[1] tapterminate nocon vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv1[0] tapterminate nocon vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv01[3] fbckb ckfb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv01[2] fbckb ckfb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv01[1] fbckb ckfb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv01[0] fbckb ckfb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[1] tapin fbckb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[0] tapin fbckb vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidlycell1[1] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 tapterminate pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell1[0] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 tapterminate pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell0[1] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell0[0] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xstkn1q vccxx_lv tapoutb en vccxx_lv e8xltr220tn2000ps1unx
xqn0 tapterminate en_b vss e8xltr220tn2000ns1unx
.ends ip10xddrdll_mcmdlyendstagedummy
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_inv_8dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_inv_8dgsvtsp24x_nonadt a o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_8dgsvtsp24x_nonadt schematic 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_8dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_inv_8dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_inv_8dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 37117 
* Version: 1.2 
* INPUT:  a  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
mqn1 o1 a vss vss nsvt l=20e-9 w=136e-9 ad=5.984e-15 as=5.984e-15 pd=224e-9 ps=224e-9 m=2
.ends ip10xddrdll_inv_8dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcbwctrl_update
** view name: schematic
.subckt ip10xddrdll_mcbwctrl_update bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] nb0en nbw[3] nbw[2] nbw[1] nbw[0] pb0enb pbleg0en pbw[3] pbw[2] pbw[1] pbw[0] vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbwctrl_update schematic 1.13 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbwctrl_update/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcbwctrl_update symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcbwctrl_update/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 89575 
* Version: 1.4 
* INPUT:  pbleg0en  vccxx_lv  bwctrl[0] 
*+ bwctrl[1]  bwctrl[2]  bwctrl[3] 
* OUTPUT:  nb0en  pbw[0]  pbw[1] 
*+ pbw[2]  pbw[3]  nbw[0]  nbw[1] 
*+ nbw[2]  nbw[3]  pb0enb 
* ----------------------------
*.PININFO  pbleg0en:I  vccxx_lv:I  bwctrl[0]:I 
*.PININFO  bwctrl[1]:I  bwctrl[2]:I  bwctrl[3]:I 
*.PININFO  nb0en:O  pbw[0]:O  pbw[1]:O 
*.PININFO  pbw[2]:O  pbw[3]:O  nbw[0]:O  nbw[1]:O 
*.PININFO  nbw[2]:O  nbw[3]:O  pb0enb:O 
* ----------------------------

xinv00 pbleg0en pb0enb vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv01 pb0enb nb0en vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[3] pbw[3] nbw[3] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[2] pbw[2] nbw[2] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[1] pbw[1] nbw[1] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[0] pbw[0] nbw[0] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv2[3] bwctrl[3] pbw[3] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv2[2] bwctrl[2] pbw[2] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv2[1] bwctrl[1] pbw[1] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv2[0] bwctrl[0] pbw[0] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
.ends ip10xddrdll_mcbwctrl_update
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlydrv0bwcb_ch0_tri
** view name: schematic
.subckt ip10xddrdll_mcmdlydrv0bwcb_ch0_tri enable i ob park vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlydrv0bwcb_ch0_tri schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlydrv0bwcb_ch0_tri/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlydrv0bwcb_ch0_tri symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlydrv0bwcb_ch0_tri/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 65796 
* Version: 1.3 
* INPUT:  enable  vccxx_lv  i 
*+ park 
* OUTPUT:  ob 
* ----------------------------
*.PININFO  enable:I  vccxx_lv:I  i:I 
*.PININFO  park:I 
*.PININFO  ob:O 
* ----------------------------

xmung nxx en vss e8xltp420tn2000nn1unx
xmun0 ob i nxx e8xltp420tn2000nn1unx
xmqnsel1 en enb vss e8xltp220tn2000ns1unx
xmqnsel0 enb enable vss e8xltp220tn2000ns1unx
xmqpsel0q vccxx_lv enb enable vccxx_lv e8xltr220tn2000ps1unx
xmqpsel1 vccxx_lv en enb vccxx_lv e8xltr220tn2000ps1unx
xqp1q vccxx_lv ob en park e8xltr220tn2000ps1unx
xqn0 park enb ob e8xltr220tn2000ns1unx
xmup0 vccxx_lv ob i pxx e8xltp420tn2000pn1unx
xmupg vccxx_lv pxx enb vccxx_lv e8xltp420tn2000pn1unx
.ends ip10xddrdll_mcmdlydrv0bwcb_ch0_tri
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlydrv0bwcb_ch1_tri
** view name: schematic
.subckt ip10xddrdll_mcmdlydrv0bwcb_ch1_tri enable i ob park vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlydrv0bwcb_ch1_tri schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlydrv0bwcb_ch1_tri/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlydrv0bwcb_ch1_tri symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlydrv0bwcb_ch1_tri/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 67338 
* Version: 1.3 
* INPUT:  enable  i  park 
*+ vccxx_lv 
* OUTPUT:  ob 
* ----------------------------
*.PININFO  enable:I  i:I  park:I 
*.PININFO  vccxx_lv:I 
*.PININFO  ob:O 
* ----------------------------

xmung nxx en vss e8xltp420tn2000nn1unx
xmun0 ob i nxx e8xltp420tn2000nn1unx
xmqnsel1 en enb vss e8xltp220tn2000ns1unx
xmqnsel0 enb enable vss e8xltp220tn2000ns1unx
xmqpsel0q vccxx_lv enb enable vccxx_lv e8xltr220tn2000ps1unx
xmqpsel1 vccxx_lv en enb vccxx_lv e8xltr220tn2000ps1unx
xqp1 vccxx_lv ob en park e8xltr220tn2000ps1unx
xqn0 park enb ob e8xltr220tn2000ns1unx
xmup0 vccxx_lv ob i pxx e8xltp420tn2000pn1unx
xmupg vccxx_lv pxx enb vccxx_lv e8xltp420tn2000pn1unx
.ends ip10xddrdll_mcmdlydrv0bwcb_ch1_tri
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlystagebwcb
** view name: schematic
.subckt ip10xddrdll_mcmdlystagebwcb ch0clk ch0phdrven ch1clk ch1phdrven en en_b nb0en nbias nbw0 nbw1 nbw2 nbw3 park park_b pb0enb pbias pbw0 pbw1 pbw2 pbw3 tapin tapout vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlystagebwcb schematic 1.13 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlystagebwcb/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlystagebwcb symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlystagebwcb/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 155825 
* Version: 1.5 
* INPUT:  pbw3  nbw3  nbias 
*+ tapin  pbias  vccxx_lv  en 
*+ park  en_b  nb0en  pb0enb 
*+ nbw1  pbw0  nbw0  pbw2 
*+ pbw1  nbw2  ch1phdrven  ch0phdrven 
*+ park_b 
* OUTPUT:  tapout  ch1clk  ch0clk 
* ----------------------------
*.PININFO  pbw3:I  nbw3:I  nbias:I 
*.PININFO  tapin:I  pbias:I  vccxx_lv:I  en:I 
*.PININFO  park:I  en_b:I  nb0en:I  pb0enb:I 
*.PININFO  nbw1:I  pbw0:I  nbw0:I  pbw2:I 
*.PININFO  pbw1:I  nbw2:I  ch1phdrven:I  ch0phdrven:I 
*.PININFO  park_b:I 
*.PININFO  tapout:O  ch1clk:O  ch0clk:O 
* ----------------------------

xinv01 ch0clk0 ch0clk0b vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[3] ch1clkb ch1clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[2] ch1clkb ch1clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[1] ch1clkb ch1clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv00[0] ch1clkb ch1clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv0[3] ch0clk0b ch0clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv0[2] ch0clk0b ch0clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv0[1] ch0clk0b ch0clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv0[0] ch0clk0b ch0clk vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidlycell0[1] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell0[0] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell1[1] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 tapout pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell1[0] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 tapout pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xipidrivech0 ch0phdrven tapoutb ch0clk0 park_b vccxx_lv ip10xddrdll_mcmdlydrv0bwcb_ch0_tri
xipidrivech1 ch1phdrven tapout ch1clkb park vccxx_lv ip10xddrdll_mcmdlydrv0bwcb_ch1_tri
xqn0 park en_b tapoutb e8xltr220tn2000ns1unx
xqn1 park_b en_b tapout e8xltr220tn2000ns1unx
xqp1 vccxx_lv tapoutb en park e8xltr220tn2000ps1unx
xqp2 vccxx_lv tapout en park_b e8xltr220tn2000ps1unx
.ends ip10xddrdll_mcmdlystagebwcb
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlyckfreedummy
** view name: schematic
.subckt ip10xddrdll_mcmdlyckfreedummy en en_b nb0en nbias nbw0 nbw1 nbw2 nbw3 pb0enb pbias pbw0 pbw1 pbw2 pbw3 tapin vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyckfreedummy schematic 1.12 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyckfreedummy/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlyckfreedummy symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlyckfreedummy/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 64875 
* Version: 1.5 
* INPUT:  pbias  pbw3  nbw3 
*+ nbias  tapin  vccxx_lv  en 
*+ en_b  nbw1  pbw0  nbw0 
*+ pbw2  pbw1  nbw2  nb0en 
*+ pb0enb 
* ----------------------------
*.PININFO  pbias:I  pbw3:I  nbw3:I 
*.PININFO  nbias:I  tapin:I  vccxx_lv:I  en:I 
*.PININFO  en_b:I  nbw1:I  pbw0:I  nbw0:I 
*.PININFO  pbw2:I  pbw1:I  nbw2:I  nb0en:I 
*.PININFO  pb0enb:I 
* ----------------------------

xidlycell1[1] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 net21 pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell1[0] tapoutb nbias nb0en nbw0 nbw1 nbw2 nbw3 net21 pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell0[1] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xidlycell0[0] tapin nbias nb0en nbw0 nbw1 nbw2 nbw3 tapoutb pbias pb0enb pbw0 pbw1 pbw2 pbw3 vccxx_lv ip10xddrdll_mcdlycellbwcb
xstkn1q vccxx_lv tapoutb en vccxx_lv e8xltr220tn2000ps1unx
xstkn0 net21 en_b vss e8xltr220tn2000ns1unx
xipidrive[1] net21 nocon vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xipidrive[0] net21 nocon vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mcmdlyckfreedummy
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdlylinebwcb
** view name: schematic
.subckt ip10xddrdll_mcmdlylinebwcb auxin bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] ch0clkph[7] ch0clkph[6] ch0clkph[5] ch0clkph[4] ch0clkph[3] ch0clkph[2] ch0clkph[1] ch0clkph[0] ch0phdrven[7] ch0phdrven[6] ch0phdrven[5] ch0phdrven[4] ch0phdrven[3] ch0phdrven[2] ch0phdrven[1] ch0phdrven[0] ch1clkph[7] ch1clkph[6] ch1clkph[5] ch1clkph[4] ch1clkph[3] ch1clkph[2] ch1clkph[1] ch1clkph[0] ch1phdrven[7] ch1phdrven[6] ch1phdrven[5] ch1phdrven[4] ch1phdrven[3] ch1phdrven[2] ch1phdrven[1] ch1phdrven[0] ckfb ckfreerunref ckref ddrdlloffvalue en mdllen nbias normalmode pbias qclkin vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlylinebwcb schematic 1.18 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlylinebwcb/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdlylinebwcb symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdlylinebwcb/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 861748 
* Version: 1.5 
* INPUT:  pbias  en  qclkin 
*+ auxin  normalmode  mdllen  nbias 
*+ ch0phdrven[0]  ch0phdrven[1]  ch0phdrven[2]  ch0phdrven[3] 
*+ ch0phdrven[4]  ch0phdrven[5]  ch0phdrven[6]  ch0phdrven[7] 
*+ bwctrl[0]  bwctrl[1]  bwctrl[2]  bwctrl[3] 
*+ vccxx_lv  ch1phdrven[0]  ch1phdrven[1]  ch1phdrven[2] 
*+ ch1phdrven[3]  ch1phdrven[4]  ch1phdrven[5]  ch1phdrven[6] 
*+ ch1phdrven[7]  ddrdlloffvalue 
* OUTPUT:  ch1clkph[0]  ch1clkph[1]  ch1clkph[2] 
*+ ch1clkph[3]  ch1clkph[4]  ch1clkph[5]  ch1clkph[6] 
*+ ch1clkph[7]  ckfb  ckfreerunref  ckref 
*+ ch0clkph[0]  ch0clkph[1]  ch0clkph[2]  ch0clkph[3] 
*+ ch0clkph[4]  ch0clkph[5]  ch0clkph[6]  ch0clkph[7] 
* ----------------------------
*.PININFO  pbias:I  en:I  qclkin:I 
*.PININFO  auxin:I  normalmode:I  mdllen:I  nbias:I 
*.PININFO  ch0phdrven[0]:I  ch0phdrven[1]:I  ch0phdrven[2]:I  ch0phdrven[3]:I 
*.PININFO  ch0phdrven[4]:I  ch0phdrven[5]:I  ch0phdrven[6]:I  ch0phdrven[7]:I 
*.PININFO  bwctrl[0]:I  bwctrl[1]:I  bwctrl[2]:I  bwctrl[3]:I 
*.PININFO  vccxx_lv:I  ch1phdrven[0]:I  ch1phdrven[1]:I  ch1phdrven[2]:I 
*.PININFO  ch1phdrven[3]:I  ch1phdrven[4]:I  ch1phdrven[5]:I  ch1phdrven[6]:I 
*.PININFO  ch1phdrven[7]:I  ddrdlloffvalue:I 
*.PININFO  ch1clkph[0]:O  ch1clkph[1]:O  ch1clkph[2]:O 
*.PININFO  ch1clkph[3]:O  ch1clkph[4]:O  ch1clkph[5]:O  ch1clkph[6]:O 
*.PININFO  ch1clkph[7]:O  ckfb:O  ckfreerunref:O  ckref:O 
*.PININFO  ch0clkph[0]:O  ch0clkph[1]:O  ch0clkph[2]:O  ch0clkph[3]:O 
*.PININFO  ch0clkph[4]:O  ch0clkph[5]:O  ch0clkph[6]:O  ch0clkph[7]:O 
* ----------------------------

xidlylinefront qclkin ckref dllenable en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_b pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] taprefclk vccxx_lv ip10xddrdll_mcmdlyfrontbwcb
xirefclkbuf qclkin ckfreerunref auxin en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_b pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] xdummyload vccxx_lv ip10xddrdll_mcmdlyfrontbwcb
xibuf en en_b en_d vccxx_lv ip10xddrdll_mcbuf
xifbclkbuff ckfb en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap8 vccxx_lv ip10xddrdll_mcmdlyendstagedummy
xinv00 dllenableb dllenable vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xibwctrl bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] nb0en nbw[3] nbw[2] nbw[1] nbw[0] pb0enb mdllen pbw[3] pbw[2] pbw[1] pbw[0] vccxx_lv ip10xddrdll_mcbwctrl_update
xdelaycell2 ch0clkph[2] ch0phdrven[2] ch1clkph[2] ch1phdrven[2] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d park_bd pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap2 tap3 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell3 ch0clkph[3] ch0phdrven[3] ch1clkph[3] ch1phdrven[3] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d park_bd pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap3 tap4 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell4 ch0clkph[4] ch0phdrven[4] ch1clkph[4] ch1phdrven[4] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d1 park_bd1 pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap4 tap5 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell5 ch0clkph[5] ch0phdrven[5] ch1clkph[5] ch1phdrven[5] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d1 park_bd1 pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap5 tap6 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell6 ch0clkph[6] ch0phdrven[6] ch1clkph[6] ch1phdrven[6] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d2 park_bd2 pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap6 tap7 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell ch0clkph[7] ch0phdrven[7] ch1clkph[7] ch1phdrven[7] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park_d2 park_bd2 pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap7 tap8 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell0 ch0clkph[0] ch0phdrven[0] ch1clkph[0] ch1phdrven[0] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park park_b pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] taprefclk tap1 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell1 ch0clkph[1] ch0phdrven[1] ch1clkph[1] ch1phdrven[1] en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] park park_b pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] tap1 tap2 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xickfreedum en_d en_b nb0en nbias nbw[0] nbw[1] nbw[2] nbw[3] pb0enb pbias pbw[0] pbw[1] pbw[2] pbw[3] xdummyload vccxx_lv ip10xddrdll_mcmdlyckfreedummy
xinv1 ddrdlloffvalue parkinv vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xnand0 normalmode mdllen dllenableb vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xiparkbuf5 park_bd1 park_bd2 vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf1 park_b park_bd vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xipark_bbuf ddrdlloffvalue park_b vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf6 park_d1 park_d2 vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf2 park park_d vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf parkinv park vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf3 park_bd park_bd1 vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbu4 park_d park_d1 vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
.ends ip10xddrdll_mcmdlylinebwcb
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02an1n04x5
** view name: schematic
.subckt ec0nand02an1n04x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02an1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02an1n04x5/schematic 
* CELLLOG ec0basic nil ec0nand02an1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02an1n04x5/symbol 
* TAG: schematic 
* COUNTER: 48336 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn2 n1 b vss vss n l=20e-9 w=136e-9 m=1
mqn1 o1 a n1 vss n l=20e-9 w=136e-9 m=1
mqp2 o1 b vcc vcc p l=20e-9 w=102e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=102e-9 m=1
.ends ec0nand02an1n04x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000an1n05x5
** view name: schematic
.subckt ec0inv000an1n05x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000an1n05x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n05x5/schematic 
* CELLLOG ec0basic nil ec0inv000an1n05x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000an1n05x5/symbol 
* TAG: schematic 
* COUNTER: 33970 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a vss vss n l=20e-9 w=170e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=170e-9 m=1
.ends ec0inv000an1n05x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdlldfthalfdly
** view name: schematic
.subckt ip10xddrdll_mcdlldfthalfdly en enb in out vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldfthalfdly schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldfthalfdly/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldfthalfdly symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldfthalfdly/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 13838 
* Version: 1.3 
* INPUT:  vccxx_lv  enb  en 
*+ in 
* OUTPUT:  out 
* ----------------------------
*.PININFO  vccxx_lv:I  enb:I  en:I 
*.PININFO  in:I 
*.PININFO  out:O 
* ----------------------------

xi11 vccxx_lv out dlyin_b vccxx_lv e8xltp420tn2000ps1unx
xi1 vccxx_lv dlyin_b in n7 e8xltp220tn2000ps1unx
xi0 vccxx_lv n7 enb vccxx_lv e8xltp220tn2000ps1unx
xipullup vccxx_lv dlyin_b en vccxx_lv e8xltp220tn2000ps1unx
xi3 n6 en vss e8xltp220tn2000ns1unx
xi2 dlyin_b in n6 e8xltp220tn2000ns1unx
xi10 out dlyin_b vss e8xltp420tn2000ns1unx
.ends ip10xddrdll_mcdlldfthalfdly
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdlldftdly
** view name: schematic
.subckt ip10xddrdll_mcdlldftdly en enb in out vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldftdly schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldftdly/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldftdly symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldftdly/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 3432 
* Version: 1.2 
* INPUT:  vccxx_lv  enb  en 
*+ in 
* OUTPUT:  out 
* ----------------------------
*.PININFO  vccxx_lv:I  enb:I  en:I 
*.PININFO  in:I 
*.PININFO  out:O 
* ----------------------------

xihalfdly2 en enb in2 out vccxx_lv ip10xddrdll_mcdlldfthalfdly
xihalfdly1 en enb in in2 vccxx_lv ip10xddrdll_mcdlldfthalfdly
.ends ip10xddrdll_mcdlldftdly
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000al1n04x5
** view name: schematic
.subckt ec0inv000al1n04x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000al1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n04x5/schematic 
* CELLLOG ec0basic nil ec0inv000al1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n04x5/symbol 
* TAG: schematic 
* COUNTER: 31114 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vcc vcc psvt l=20e-9 w=136e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=136e-9 m=1
.ends ec0inv000al1n04x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand03an1n03x5
** view name: schematic
.subckt ec0nand03an1n03x5 a b c o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand03an1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03an1n03x5/schematic 
* CELLLOG ec0basic nil ec0nand03an1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03an1n03x5/symbol 
* TAG: schematic 
* COUNTER: 67298 
* Version: Unmanaged 
* INPUT:  a  b  c 
*+ vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  c:I 
*.PININFO  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqn1 o1 a n1 vss n l=20e-9 w=102e-9 m=1
mqn2 n1 b n2 vss n l=20e-9 w=102e-9 m=1
mqn3 n2 c vss vss n l=20e-9 w=102e-9 m=1
mqp2 o1 b vcc vcc p l=20e-9 w=68e-9 m=1
mqp3 o1 c vcc vcc p l=20e-9 w=68e-9 m=1
mqp1 o1 a vcc vcc p l=20e-9 w=68e-9 m=1
.ends ec0nand03an1n03x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0inv000al1n03x5
** view name: schematic
.subckt ec0inv000al1n03x5 a o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0inv000al1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n03x5/schematic 
* CELLLOG ec0basic nil ec0inv000al1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0inv000al1n03x5/symbol 
* TAG: schematic 
* COUNTER: 31114 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a vcc vcc psvt l=20e-9 w=102e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=102e-9 m=1
.ends ec0inv000al1n03x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand03al1n03x5
** view name: schematic
.subckt ec0nand03al1n03x5 a b c o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand03al1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03al1n03x5/schematic 
* CELLLOG ec0basic nil ec0nand03al1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand03al1n03x5/symbol 
* TAG: schematic 
* COUNTER: 60406 
* Version: Unmanaged 
* INPUT:  a  b  c 
*+ vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  c:I 
*.PININFO  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp3 o1 c vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=102e-9 m=1
mqn2 n1 b n2 vss nsvt l=20e-9 w=102e-9 m=1
mqn3 n2 c vss vss nsvt l=20e-9 w=102e-9 m=1
.ends ec0nand03al1n03x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdll3to1nandmux_ec0
** view name: schematic
.subckt ip10xddrdll_mcdll3to1nandmux_ec0 cko clka clkb clkc sa sb sc vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll3to1nandmux_ec0 schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll3to1nandmux_ec0/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll3to1nandmux_ec0 symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll3to1nandmux_ec0/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 6505 
* Version: 1.2 
* INPUT:  vccxx_lv  clka  clkb 
*+ sa  sb  sc  clkc 
* OUTPUT:  cko 
* ----------------------------
*.PININFO  vccxx_lv:I  clka:I  clkb:I 
*.PININFO  sa:I  sb:I  sc:I  clkc:I 
*.PININFO  cko:O 
* ----------------------------

xi2 a_b b_b c_b cko vccxx_lv ec0nand03al1n03x5
xi1 clkb sb b_b vccxx_lv ec0nand02al1n03x5
xi0 clka sa a_b vccxx_lv ec0nand02al1n03x5
xi8 clkc sc c_b vccxx_lv ec0nand02al1n03x5
.ends ip10xddrdll_mcdll3to1nandmux_ec0
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdll2to1nandmux_ec0
** view name: schematic
.subckt ip10xddrdll_mcdll2to1nandmux_ec0 cko clka clkb sa vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll2to1nandmux_ec0 schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll2to1nandmux_ec0/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll2to1nandmux_ec0 symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll2to1nandmux_ec0/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 7167 
* Version: 1.2 
* INPUT:  vccxx_lv  sa  clkb 
*+ clka 
* OUTPUT:  cko 
* ----------------------------
*.PININFO  vccxx_lv:I  sa:I  clkb:I 
*.PININFO  clka:I 
*.PININFO  cko:O 
* ----------------------------

xi4 sa sb vccxx_lv ec0inv000al1n03x5
xi2 nb na cko vccxx_lv ec0nand02al1n03x5
xi1 clka sa na vccxx_lv ec0nand02al1n03x5
xi0 clkb sb nb vccxx_lv ec0nand02al1n03x5
.ends ip10xddrdll_mcdll2to1nandmux_ec0
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdllpfdchopmux_ec0
** view name: schematic
.subckt ip10xddrdll_mcdllpfdchopmux_ec0 dly200 dly400 dly600 dly800 dly1000 dly1200 dly1400 en200 en400 en600 en800 en1000 en1200 en1400 enbar200 enbar400 enbar600 enbar800 enbar1000 enbar1200 enbar1400 out_b s0 s1 s2 vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllpfdchopmux_ec0 schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllpfdchopmux_ec0/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllpfdchopmux_ec0 symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllpfdchopmux_ec0/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 127960 
* Version: 1.1 
* INPUT:  s1  s0  dly200 
*+ dly400  s2  dly600  dly1400 
*+ dly1000  dly800  dly1200  vccxx_lv 
* OUTPUT:  enbar1000  enbar1200  enbar1400 
*+ en1200  en800  en1000  en200 
*+ en400  en600  enbar200  enbar400 
*+ enbar600  enbar800  en1400  out_b 
* ----------------------------
*.PININFO  s1:I  s0:I  dly200:I 
*.PININFO  dly400:I  s2:I  dly600:I  dly1400:I 
*.PININFO  dly1000:I  dly800:I  dly1200:I  vccxx_lv:I 
*.PININFO  enbar1000:O  enbar1200:O  enbar1400:O 
*.PININFO  en1200:O  en800:O  en1000:O  en200:O 
*.PININFO  en400:O  en600:O  enbar200:O  enbar400:O 
*.PININFO  enbar600:O  enbar800:O  en1400:O  out_b:O 
* ----------------------------

xi2 s0 s0_b vccxx_lv ec0inv000al1n04x5
xi1 s2 s2_b vccxx_lv ec0inv000al1n04x5
xi0 s1 s1_b vccxx_lv ec0inv000al1n04x5
xi159 s2 s1_b s0_b sel800_b vccxx_lv ec0nand03an1n03x5
xi158 s2_b s1 s0 sel600_b vccxx_lv ec0nand03an1n03x5
xi7 s2_b s1 s0_b sel400_b vccxx_lv ec0nand03an1n03x5
xi161 s2 s1 s0_b sel1200_b vccxx_lv ec0nand03an1n03x5
xi160 s2 s1_b s0 sel1000_b vccxx_lv ec0nand03an1n03x5
xi157 s2_b s1_b s0 sel200_b vccxx_lv ec0nand03an1n03x5
xi136 en400 enbar400 vccxx_lv ec0inv000al1n03x5
xi137 en600 enbar600 vccxx_lv ec0inv000al1n03x5
xi138 en800 enbar800 vccxx_lv ec0inv000al1n03x5
xi139 en1000 enbar1000 vccxx_lv ec0inv000al1n03x5
xi284 out1 out_b vccxx_lv ec0inv000al1n03x5
xi135 en200 enbar200 vccxx_lv ec0inv000al1n03x5
xi301 sel600_b sel600d vccxx_lv ec0inv000al1n03x5
xi140 en1200 enbar1200 vccxx_lv ec0inv000al1n03x5
xi150 en1400 enbar1400 vccxx_lv ec0inv000al1n03x5
xi202 sel1400_b en1400 vccxx_lv ec0inv000al1n03x5
xi299 sel400_b sel400d vccxx_lv ec0inv000al1n03x5
xi298 sel200_b sel200d vccxx_lv ec0inv000al1n03x5
xi302 sel1000_b sel1000d vccxx_lv ec0inv000al1n03x5
xi296 sel1400or1200_b sel1400or1200d vccxx_lv ec0inv000al1n03x5
xi297 sel1400_b sel1400d vccxx_lv ec0inv000al1n03x5
xi162 s2 s1 s0 sel1400_b vccxx_lv ec0nand03an1n06x5
xi32 sel1200_b sel1400_b en1200 vccxx_lv ec0nand02al1n03x5
xi156 sel200_b enbar400 en200 vccxx_lv ec0nand02al1n03x5
xi155 sel400_b enbar600 en400 vccxx_lv ec0nand02al1n03x5
xi152 sel1000_b enbar1200 en1000 vccxx_lv ec0nand02al1n03x5
xi153 sel800_b enbar1000 en800 vccxx_lv ec0nand02al1n03x5
xi154 sel600_b enbar800 en600 vccxx_lv ec0nand02al1n03x5
xi305 s0 s1 s1nands0 vccxx_lv ec0nand02al1n02x5
xi295 s2 s1 sel1400or1200_b vccxx_lv ec0nand02al1n02x5
xi306 s1nands0 s2_b s2ors1s0 vccxx_lv ec0nand02al1n02x5
ximux_last out1 dly200 dly400 dly1400_600 sel200d sel400d s2ors1s0 vccxx_lv ip10xddrdll_mcdll3to1nandmux_ec0
ximux_1400_600 dly1400_600 dly600 dly1400_800 sel600d vccxx_lv ip10xddrdll_mcdll2to1nandmux_ec0
ximux_1400_1200 dly1400_1200 dly1400 dly1200 sel1400d vccxx_lv ip10xddrdll_mcdll2to1nandmux_ec0
xi221 dly1400_800 dly1400_1200 dly1000_800 sel1400or1200d vccxx_lv ip10xddrdll_mcdll2to1nandmux_ec0
ximux_1000_800 dly1000_800 dly1000 dly800 sel1000d vccxx_lv ip10xddrdll_mcdll2to1nandmux_ec0
.ends ip10xddrdll_mcdllpfdchopmux_ec0
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdlldftchopperdly_ec0
** view name: schematic
.subckt ip10xddrdll_mcdlldftchopperdly_ec0 dlyin dlyout_b i0 i1 i2 vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldftchopperdly_ec0 schematic 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldftchopperdly_ec0/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlldftchopperdly_ec0 symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlldftchopperdly_ec0/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 23972 
* Version: 1.1 
* INPUT:  vccxx_lv  dlyin  i0 
*+ i1  i2 
* OUTPUT:  dlyout_b 
* ----------------------------
*.PININFO  vccxx_lv:I  dlyin:I  i0:I 
*.PININFO  i1:I  i2:I 
*.PININFO  dlyout_b:O 
* ----------------------------

xidly1400 en1400 en1400b dly1200 dly1400 vccxx_lv ip10xddrdll_mcdlldftdly
xidly1200 en1200 en1200b dly1000 dly1200 vccxx_lv ip10xddrdll_mcdlldftdly
xidly1000 en1000 en1000b dly800 dly1000 vccxx_lv ip10xddrdll_mcdlldftdly
xidecodermux dly200 dly400 dly600 dly800 dly1000 dly1200 dly1400 en200 en400 en600 en800 en1000 en1200 en1400 en200b en400b en600b en800b en1000b en1200b en1400b dlyout_b i0 i1 i2 vccxx_lv ip10xddrdll_mcdllpfdchopmux_ec0
xidly800 en800 en800b dly600 dly800 vccxx_lv ip10xddrdll_mcdlldfthalfdly
xidly600 en600 en600b dly400 dly600 vccxx_lv ip10xddrdll_mcdlldfthalfdly
xidly400 en400 en400b dly200 dly400 vccxx_lv ip10xddrdll_mcdlldfthalfdly
xidly200 en200 en200b dlyin dly200 vccxx_lv ip10xddrdll_mcdlldfthalfdly
.ends ip10xddrdll_mcdlldftchopperdly_ec0
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdlllockdetector_ec0
** view name: schematic
.subckt ip10xddrdll_mcdlllockdetector_ec0 dllchopperdelay[2] dllchopperdelay[1] dllchopperdelay[0] dlllock dn startupend up vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlllockdetector_ec0 schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlllockdetector_ec0/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdlllockdetector_ec0 symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdlllockdetector_ec0/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 46975 
* Version: 1.1 
* INPUT:  vccxx_lv  dn  dllchopperdelay[0] 
*+ dllchopperdelay[1]  dllchopperdelay[2]  up  startupend 
* OUTPUT:  dlllock 
* ----------------------------
*.PININFO  vccxx_lv:I  dn:I  dllchopperdelay[0]:I 
*.PININFO  dllchopperdelay[1]:I  dllchopperdelay[2]:I  up:I  startupend:I 
*.PININFO  dlllock:O 
* ----------------------------

xi5 dn dndd dnc vccxx_lv ec0nand02an1n04x5
xi4 up updd upc vccxx_lv ec0nand02an1n04x5
xi6 upc dnc timerreset vccxx_lv ec0nand02an1n04x5
xi19 startupend timerreset_b lockreset vccxx_lv ec0nand02an1n04x5
xi23 upd_b updd vccxx_lv ec0inv000an1n05x5
xi24 dnd_b dndd vccxx_lv ec0inv000an1n05x5
xi18 timerreset timerreset_b vccxx_lv ec0inv000an1n05x5
xidlldftchoper up upd_b dllchopperdelay[0] dllchopperdelay[1] dllchopperdelay[2] vccxx_lv ip10xddrdll_mcdlldftchopperdly_ec0
xidlldftchoper1 dn dnd_b dllchopperdelay[0] dllchopperdelay[1] dllchopperdelay[2] vccxx_lv ip10xddrdll_mcdlldftchopperdly_ec0
xi22 lockreset dlllock vccxx_lv ec0inv000al1n08x5
.ends ip10xddrdll_mcdlllockdetector_ec0
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_nor2_4dgsvtsp24x_nonadt
** view name: schematic
.subckt ip10xddrdll_nor2_4dgsvtsp24x_nonadt a b o1 vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nor2_4dgsvtsp24x_nonadt schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nor2_4dgsvtsp24x_nonadt/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_nor2_4dgsvtsp24x_nonadt symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_nor2_4dgsvtsp24x_nonadt/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 47160 
* Version: 1.2 
* INPUT:  a  b  vccxx_lv 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vccxx_lv:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a n1 vccxx_lv psvt l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
mqp0 n1 b vccxx_lv vccxx_lv psvt l=20e-9 w=136e-9 ad=2.312e-15 as=5.984e-15 pd=34e-9 ps=224e-9 m=2
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 ad=1.156e-15 as=2.992e-15 pd=34e-9 ps=156e-9 m=2
mqn0 o1 b vss vss nsvt l=20e-9 w=68e-9 ad=1.156e-15 as=2.992e-15 pd=34e-9 ps=156e-9 m=2
.ends ip10xddrdll_nor2_4dgsvtsp24x_nonadt
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcnbiasgen
** view name: schematic
.subckt ip10xddrdll_mcnbiasgen ddrnormalmodel nbias_a nbiasen_b pbias_a vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcnbiasgen schematic 1.19 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcnbiasgen/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcnbiasgen symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcnbiasgen/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 109693 
* Version: 1.5 
* INPUT:  ddrnormalmodel  pbias_a  vccxx_lv 
*+ nbiasen_b 
* OUTPUT:  nbias_a 
* ----------------------------
*.PININFO  ddrnormalmodel:I  pbias_a:I  vccxx_lv:I 
*.PININFO  nbiasen_b:I 
*.PININFO  nbias_a:O 
* ----------------------------

xinv1 nbiasen nbiasen_xb vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xinv01 nbiasen1 pbiasen vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xmqp0[3] vccxx_lv pxx10 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmqp0[2] vccxx_lv pxx10 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmqp0[1] vccxx_lv pxx10 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmqp0[0] vccxx_lv pxx10 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmip1[3] vccxx_lv pxx01 pbias_a pxx00 e8xltp420tn2000ps1unx
xmip1[2] vccxx_lv pxx01 pbias_a pxx00 e8xltp420tn2000ps1unx
xmip1[1] vccxx_lv pxx01 pbias_a pxx00 e8xltp420tn2000ps1unx
xmip1[0] vccxx_lv pxx01 pbias_a pxx00 e8xltp420tn2000ps1unx
xmip4 vccxx_lv nxx2 nbiasen_xb vccxx_lv e8xltp420tn2000ps1unx
xmip0[3] vccxx_lv pxx00 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmip0[2] vccxx_lv pxx00 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmip0[1] vccxx_lv pxx00 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmip0[0] vccxx_lv pxx00 pbiasen vccxx_lv e8xltp420tn2000ps1unx
xmqp1[3] vccxx_lv pxx11 pbias_a pxx10 e8xltp420tn2000ps1unx
xmqp1[2] vccxx_lv pxx11 pbias_a pxx10 e8xltp420tn2000ps1unx
xmqp1[1] vccxx_lv pxx11 pbias_a pxx10 e8xltp420tn2000ps1unx
xmqp1[0] vccxx_lv pxx11 pbias_a pxx10 e8xltp420tn2000ps1unx
xqp2[1] vccxx_lv nbias_a pbiasen pxx11 e8xltp420tn2000ps1unx
xqp2[0] vccxx_lv nbias_a pbiasen pxx11 e8xltp420tn2000ps1unx
xqp3[1] vccxx_lv nbias_a pbiasen pxx01 e8xltp420tn2000ps1unx
xqp3[0] vccxx_lv nbias_a pbiasen pxx01 e8xltp420tn2000ps1unx
xinv00 ddrnormalmodel normalb vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv0 nbiasen_b nbiasen vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xi1 nbiasen_b normalb nbiasen1 vccxx_lv ip10xddrdll_nor2_4dgsvtsp24x_nonadt
xmin4 nxx2 nbiasen_xb vss e8xltp420tn2000ns1unx
xmin0[3] nxx00 nbiasen1 vss e8xltp420tn2000ns1unx
xmin0[2] nxx00 nbiasen1 vss e8xltp420tn2000ns1unx
xmin0[1] nxx00 nbiasen1 vss e8xltp420tn2000ns1unx
xmin0[0] nxx00 nbiasen1 vss e8xltp420tn2000ns1unx
xmin2[1] nbias_a nbiasen nxx01 e8xltp420tn2000ns1unx
xmin2[0] nbias_a nbiasen nxx01 e8xltp420tn2000ns1unx
xqn0[1] nbias_a nbiasen1 nxx11 e8xltp420tn2000ns1unx
xqn0[0] nbias_a nbiasen1 nxx11 e8xltp420tn2000ns1unx
xmin3 nbias_a nbiasen_xb nxx2 e8xltp420tn2000ns1unx
xmin1[3] nxx01 nbias_a nxx00 e8xltp420tn2000ns1unx
xmin1[2] nxx01 nbias_a nxx00 e8xltp420tn2000ns1unx
xmin1[1] nxx01 nbias_a nxx00 e8xltp420tn2000ns1unx
xmin1[0] nxx01 nbias_a nxx00 e8xltp420tn2000ns1unx
xmqn1[3] nxx10 nbiasen1 vss e8xltp420tn2000ns1unx
xmqn1[2] nxx10 nbiasen1 vss e8xltp420tn2000ns1unx
xmqn1[1] nxx10 nbiasen1 vss e8xltp420tn2000ns1unx
xmqn1[0] nxx10 nbiasen1 vss e8xltp420tn2000ns1unx
xmqn0[3] nxx11 nbias_a nxx10 e8xltp420tn2000ns1unx
xmqn0[2] nxx11 nbias_a nxx10 e8xltp420tn2000ns1unx
xmqn0[1] nxx11 nbias_a nxx10 e8xltp420tn2000ns1unx
xmqn0[0] nxx11 nbias_a nxx10 e8xltp420tn2000ns1unx
.ends ip10xddrdll_mcnbiasgen
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcupdnrep
** view name: schematic
.subckt ip10xddrdll_mcupdnrep dn dnd up upd vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcupdnrep schematic 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcupdnrep/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcupdnrep symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcupdnrep/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 6666 
* Version: 1.2 
* INPUT:  vccxx_lv  up  dn 
* OUTPUT:  upd  dnd 
* ----------------------------
*.PININFO  vccxx_lv:I  up:I  dn:I 
*.PININFO  upd:O  dnd:O 
* ----------------------------

xickinv0 up upb vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xickinv2 dn dnb vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xickinv1 upb upd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xickinv3 dnb dnd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
.ends ip10xddrdll_mcupdnrep
** end of subcircuit definition.

** library name: e8libana
** cell name: e8xltr420tn2000ps1unx
** view name: schematic
.subckt e8xltr420tn2000ps1unx b d g s
* ----------------------------
* CELLLOG e8libana nil e8xltr420tn2000ps1unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr420tn2000ps1unx/schematic 
* CELLLOG e8libana nil e8xltr420tn2000ps1unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8libana/e8xltr420tn2000ps1unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 14593 
* Version: Unmanaged 
* INOUT:  s  d  b 
* INPUT:  g 
* ----------------------------
*.PININFO  s:B  d:B  b:B 
*.PININFO  g:I 
* ----------------------------

mstkp0.stckp1 d g stkp0.sd01 b psvt l=20e-9 w=136e-9 m=1
mstkp0.stckp0 stkp0.sd01 g s b psvt l=20e-9 w=136e-9 m=1
.ends e8xltr420tn2000ps1unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mccp
** view name: schematic
.subckt ip10xddrdll_mccp copbiasen dn dn_b enable nbias_a pbias_a up up_b vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mccp schematic 1.15 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mccp/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mccp symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mccp/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 206116 
* Version: 1.1 
* INOUT:  pbias_a 
* INPUT:  vccxx_lv  up_b  dn_b 
*+ copbiasen  up  nbias_a  dn 
*+ enable 
* ----------------------------
*.PININFO  pbias_a:B 
*.PININFO  vccxx_lv:I  up_b:I  dn_b:I 
*.PININFO  copbiasen:I  up:I  nbias_a:I  dn:I 
*.PININFO  enable:I 
* ----------------------------

xqp1 vccxx_lv dn enabled vccxx_lv e8xltr220tn2000ps1unx
xstkn1q vccxx_lv dn_b enabled vccxx_lv e8xltr220tn2000ps1unx
xstkn0 up enable_b vss e8xltr220tn2000ns1unx
xqn1 up_b enable_b vss e8xltr220tn2000ns1unx
xg1 enable enable_b vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xg0 enable_b enabled vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xmip4[3] vccxx_lv ps0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip4[2] vccxx_lv ps0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip4[1] vccxx_lv ps0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip4[0] vccxx_lv ps0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip6[1] vccxx_lv copbias_a dn_b ps1 e8xltp420tn2000ps1unx
xmip6[0] vccxx_lv copbias_a dn_b ps1 e8xltp420tn2000ps1unx
xmip0[3] vccxx_lv pxx0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip0[2] vccxx_lv pxx0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip0[1] vccxx_lv pxx0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xmip0[0] vccxx_lv pxx0 enable_b vccxx_lv e8xltp420tn2000ps1unx
xqp2[1] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp2[0] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp6 vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp8 vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp5[1] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp5[0] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xmip5[3] vccxx_lv ps1 copbias_a ps0 e8xltp420tn2000ps1unx
xmip5[2] vccxx_lv ps1 copbias_a ps0 e8xltp420tn2000ps1unx
xmip5[1] vccxx_lv ps1 copbias_a ps0 e8xltp420tn2000ps1unx
xmip5[0] vccxx_lv ps1 copbias_a ps0 e8xltp420tn2000ps1unx
xqp0[1] vccxx_lv vccxx_lv dn vccxx_lv e8xltp420tn2000ps1unx
xqp0[0] vccxx_lv vccxx_lv dn vccxx_lv e8xltp420tn2000ps1unx
xqp4[1] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp4[0] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xmip36[1] vccxx_lv pbias_a dn_b pxx1 e8xltp420tn2000ps1unx
xmip36[0] vccxx_lv pbias_a dn_b pxx1 e8xltp420tn2000ps1unx
xmip1[3] vccxx_lv pxx1 copbias_a pxx0 e8xltp420tn2000ps1unx
xmip1[2] vccxx_lv pxx1 copbias_a pxx0 e8xltp420tn2000ps1unx
xmip1[1] vccxx_lv pxx1 copbias_a pxx0 e8xltp420tn2000ps1unx
xmip1[0] vccxx_lv pxx1 copbias_a pxx0 e8xltp420tn2000ps1unx
xqp3[1] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xqp3[0] vccxx_lv vccxx_lv vccxx_lv vccxx_lv e8xltp420tn2000ps1unx
xmip2[1] vccxx_lv copbias_a dn pxx1 e8xltp420tn2000ps1unx
xmip2[0] vccxx_lv copbias_a dn pxx1 e8xltp420tn2000ps1unx
xqn7[1] vss vss vss e8xltp420tn2000ns1unx
xqn7[0] vss vss vss e8xltp420tn2000ns1unx
xqn6 vss vss vss e8xltp420tn2000ns1unx
xqn8[1] vss vss vss e8xltp420tn2000ns1unx
xqn8[0] vss vss vss e8xltp420tn2000ns1unx
xqn2 vss vss vss e8xltp420tn2000ns1unx
xqn4[1] vss vss vss e8xltp420tn2000ns1unx
xqn4[0] vss vss vss e8xltp420tn2000ns1unx
xmin1[3] nxx1 nbias_a nxx0 e8xltp420tn2000ns1unx
xmin1[2] nxx1 nbias_a nxx0 e8xltp420tn2000ns1unx
xmin1[1] nxx1 nbias_a nxx0 e8xltp420tn2000ns1unx
xmin1[0] nxx1 nbias_a nxx0 e8xltp420tn2000ns1unx
xmin2[1] copbias_a up_b nxx1 e8xltp420tn2000ns1unx
xmin2[0] copbias_a up_b nxx1 e8xltp420tn2000ns1unx
xmin3[1] pbias_a up nxx1 e8xltp420tn2000ns1unx
xmin3[0] pbias_a up nxx1 e8xltp420tn2000ns1unx
xmin4[3] ns0 enabled vss e8xltp420tn2000ns1unx
xmin4[2] ns0 enabled vss e8xltp420tn2000ns1unx
xmin4[1] ns0 enabled vss e8xltp420tn2000ns1unx
xmin4[0] ns0 enabled vss e8xltp420tn2000ns1unx
xqn5[1] vss vss vss e8xltp420tn2000ns1unx
xqn5[0] vss vss vss e8xltp420tn2000ns1unx
xqn0[1] vss up_b vss e8xltp420tn2000ns1unx
xqn0[0] vss up_b vss e8xltp420tn2000ns1unx
xmin0[3] nxx0 enabled vss e8xltp420tn2000ns1unx
xmin0[2] nxx0 enabled vss e8xltp420tn2000ns1unx
xmin0[1] nxx0 enabled vss e8xltp420tn2000ns1unx
xmin0[0] nxx0 enabled vss e8xltp420tn2000ns1unx
xmin5[3] ns1 nbias_a ns0 e8xltp420tn2000ns1unx
xmin5[2] ns1 nbias_a ns0 e8xltp420tn2000ns1unx
xmin5[1] ns1 nbias_a ns0 e8xltp420tn2000ns1unx
xmin5[0] ns1 nbias_a ns0 e8xltp420tn2000ns1unx
xmin6[1] copbias_a up ns1 e8xltp420tn2000ns1unx
xmin6[0] copbias_a up ns1 e8xltp420tn2000ns1unx
xicappbias[14] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[13] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[12] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[11] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[10] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[9] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[8] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[7] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[6] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[5] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[4] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[3] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[2] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xicappbias[1] vccxx_lv copbias_a ip10xddrdll_mcpbiascap1
xqn3 vccxx_lv copbias_a copbiasen vccxx_lv e8xltr420tn2000ps1unx
.ends ip10xddrdll_mccp
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcvctrlpdown
** view name: schematic
.subckt ip10xddrdll_mcvctrlpdown dischen[2] dischen[1] dischen[0] reset_b vccxx_lv vctrl vctrlhi_b
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcvctrlpdown schematic 1.10 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcvctrlpdown/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcvctrlpdown symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcvctrlpdown/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 34850 
* Version: 1.3 
* INOUT:  vctrl 
* INPUT:  vccxx_lv  dischen[0]  dischen[1] 
*+ dischen[2]  reset_b  vctrlhi_b 
* ----------------------------
*.PININFO  vctrl:B 
*.PININFO  vccxx_lv:I  dischen[0]:I  dischen[1]:I 
*.PININFO  dischen[2]:I  reset_b:I  vctrlhi_b:I 
* ----------------------------

xmipdn0t vctrl dischen[0] pdn0 e8xltp220tn2000ns1unx
xmipdn1t[1] vctrl dischen[1] pdn1 e8xltp220tn2000ns1unx
xmipdn1t[0] vctrl dischen[1] pdn1 e8xltp220tn2000ns1unx
xmipdn2t[2] vctrl dischen[2] pdn2 e8xltp220tn2000ns1unx
xmipdn2t[1] vctrl dischen[2] pdn2 e8xltp220tn2000ns1unx
xmipdn2t[0] vctrl dischen[2] pdn2 e8xltp220tn2000ns1unx
xmipdn0b pdn0 dischen[0] vss e8xltp220tn2000ns1unx
xmipdn1b[1] pdn1 dischen[1] vss e8xltp220tn2000ns1unx
xmipdn1b[0] pdn1 dischen[1] vss e8xltp220tn2000ns1unx
xmipdn2b[2] pdn2 dischen[2] vss e8xltp220tn2000ns1unx
xmipdn2b[1] pdn2 dischen[2] vss e8xltp220tn2000ns1unx
xmipdn2b[0] pdn2 dischen[2] vss e8xltp220tn2000ns1unx
xmipup0 vccxx_lv pup1 reset_b vccxx_lv e8xltp220tn2000ps1unx
xmipup1 vccxx_lv vctrl reset_b pup1 e8xltp220tn2000ps1unx
xmipvctrlhi1 vccxx_lv vctrl vctrlhi_b pup0 e8xltp220tn2000ps1unx
xmipvctrlhi0 vccxx_lv pup0 vctrlhi_b vccxx_lv e8xltp220tn2000ps1unx
.ends ip10xddrdll_mcvctrlpdown
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcvctrldischdec
** view name: schematic
.subckt ip10xddrdll_mcvctrldischdec dischrate[2] dischrate[1] dischrate[0] en[2] en[1] en[0] pbiasreset vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcvctrldischdec schematic 1.12 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcvctrldischdec/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcvctrldischdec symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcvctrldischdec/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 20772 
* Version: 1.4 
* INPUT:  vccxx_lv  dischrate[0]  dischrate[1] 
*+ dischrate[2]  pbiasreset 
* OUTPUT:  en[0]  en[1]  en[2] 
* ----------------------------
*.PININFO  vccxx_lv:I  dischrate[0]:I  dischrate[1]:I 
*.PININFO  dischrate[2]:I  pbiasreset:I 
*.PININFO  en[0]:O  en[1]:O  en[2]:O 
* ----------------------------

xnand1 pbiasreset dischrate[0] enb[0] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xnand0 pbiasreset dischrate[1] enb[1] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinv1 pbiasreset dischrate[2] enb[2] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinv01 enb[1] en[1] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv02 enb[0] en[0] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv00 enb[2] en[2] vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
.ends ip10xddrdll_mcvctrldischdec
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdllvctrlpdown
** view name: schematic
.subckt ip10xddrdll_mcdllvctrlpdown dischrate[2] dischrate[1] dischrate[0] reset_b vccxx_lv vctrl vctrlhi_b 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllvctrlpdown schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllvctrlpdown/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllvctrlpdown symbol 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllvctrlpdown/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 21912 
* Version: 1.4 
* INOUT:  vctrl 
* INPUT:  vccxx_lv  reset_b  dischrate[0] 
*+ dischrate[1]  dischrate[2]  vctrlhi_b 
* ----------------------------
*.PININFO  vctrl:B 
*.PININFO  vccxx_lv:I  reset_b:I  dischrate[0]:I 
*.PININFO  dischrate[1]:I  dischrate[2]:I  vctrlhi_b:I 
* ----------------------------

xivctrlpulldown dischend[2] dischend[1] dischend[0] reset_b vccxx_lv vctrl vctrlhi_b ip10xddrdll_mcvctrlpdown
xidischdec dischrate[2] dischrate[1] dischrate[0] dischend[2] dischend[1] dischend[0] reset_b vccxx_lv ip10xddrdll_mcvctrldischdec
.ends ip10xddrdll_mcdllvctrlpdown
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpdrst
** view name: schematic
.subckt ip10xddrdll_mcpdrst a b c pout vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpdrst schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpdrst/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpdrst symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpdrst/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 63813 
* Version: 1.3 
* INPUT:  vccxx_lv  a  c 
*+ b 
* OUTPUT:  pout 
* ----------------------------
*.PININFO  vccxx_lv:I  a:I  c:I 
*.PININFO  b:I 
*.PININFO  pout:O 
* ----------------------------

xipb0[1] vccxx_lv o1 b np0 e8xltp420tn2000pn1unx
xipb0[0] vccxx_lv o1 b np0 e8xltp420tn2000pn1unx
xmdummy2[1] vccxx_lv np1 vccxx_lv vccxx_lv e8xltp420tn2000pn1unx
xmdummy2[0] vccxx_lv np1 vccxx_lv vccxx_lv e8xltp420tn2000pn1unx
xmiqp1[3] vccxx_lv pout out_b vccxx_lv e8xltp420tn2000pn1unx
xmiqp1[2] vccxx_lv pout out_b vccxx_lv e8xltp420tn2000pn1unx
xmiqp1[1] vccxx_lv pout out_b vccxx_lv e8xltp420tn2000pn1unx
xmiqp1[0] vccxx_lv pout out_b vccxx_lv e8xltp420tn2000pn1unx
xipa0[1] vccxx_lv np0 a vccxx_lv e8xltp420tn2000pn1unx
xipa0[0] vccxx_lv np0 a vccxx_lv e8xltp420tn2000pn1unx
xmiqp0 vccxx_lv out_b o1 vccxx_lv e8xltp420tn2000pn1unx
xmipe vccxx_lv o1 c vccxx_lv e8xltp420tn2000pn1unx
xmdummy1[1] vccxx_lv np0 vccxx_lv vccxx_lv e8xltp420tn2000pn1unx
xmdummy1[0] vccxx_lv np0 vccxx_lv vccxx_lv e8xltp420tn2000pn1unx
xipa1[1] vccxx_lv o1 a np1 e8xltp420tn2000pn1unx
xipa1[0] vccxx_lv o1 a np1 e8xltp420tn2000pn1unx
xipb1[1] vccxx_lv np1 b vccxx_lv e8xltp420tn2000pn1unx
xipb1[0] vccxx_lv np1 b vccxx_lv e8xltp420tn2000pn1unx
xmiqn0[1] out_b o1 vss e8xltp420tn2000nn1unx
xmiqn0[0] out_b o1 vss e8xltp420tn2000nn1unx
xmina[1] o1 a nxx e8xltp420tn2000nn1unx
xmina[0] o1 a nxx e8xltp420tn2000nn1unx
xminb[1] o1 b nxx e8xltp420tn2000nn1unx
xminb[0] o1 b nxx e8xltp420tn2000nn1unx
xmiqn1[3] pout out_b vss e8xltp420tn2000nn1unx
xmiqn1[2] pout out_b vss e8xltp420tn2000nn1unx
xmiqn1[1] pout out_b vss e8xltp420tn2000nn1unx
xmiqn1[0] pout out_b vss e8xltp420tn2000nn1unx
xminc[3] nxx c vss e8xltp420tn2000nn1unx
xminc[2] nxx c vss e8xltp420tn2000nn1unx
xminc[1] nxx c vss e8xltp420tn2000nn1unx
xminc[0] nxx c vss e8xltp420tn2000nn1unx
.ends ip10xddrdll_mcpdrst
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpdcell
** view name: schematic
.subckt ip10xddrdll_mcpdcell clk clken out rst vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpdcell schematic 1.10 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpdcell/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpdcell symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpdcell/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 58371 
* Version: 1.2 
* INPUT:  clk  clken  vccxx_lv 
*+ rst 
* OUTPUT:  out 
* ----------------------------
*.PININFO  clk:I  clken:I  vccxx_lv:I 
*.PININFO  rst:I 
*.PININFO  out:O 
* ----------------------------

xmipu1[3] vccxx_lv out d0_b vccxx_lv e8xltp420tn2000pn1unx
xmipu1[2] vccxx_lv out d0_b vccxx_lv e8xltp420tn2000pn1unx
xmipu1[1] vccxx_lv out d0_b vccxx_lv e8xltp420tn2000pn1unx
xmipu1[0] vccxx_lv out d0_b vccxx_lv e8xltp420tn2000pn1unx
xmipu0t[3] vccxx_lv npup0 qclkd vccxx_lv e8xltp420tn2000pn1unx
xmipu0t[2] vccxx_lv npup0 qclkd vccxx_lv e8xltp420tn2000pn1unx
xmipu0t[1] vccxx_lv npup0 qclkd vccxx_lv e8xltp420tn2000pn1unx
xmipu0t[0] vccxx_lv npup0 qclkd vccxx_lv e8xltp420tn2000pn1unx
xmipu0b[3] vccxx_lv d0_b rst npup0 e8xltp420tn2000pn1unx
xmipu0b[2] vccxx_lv d0_b rst npup0 e8xltp420tn2000pn1unx
xmipu0b[1] vccxx_lv d0_b rst npup0 e8xltp420tn2000pn1unx
xmipu0b[0] vccxx_lv d0_b rst npup0 e8xltp420tn2000pn1unx
xiclkinv[3] qclk_b qclkd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiclkinv[2] qclk_b qclkd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiclkinv[1] qclk_b qclkd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiclkinv[0] qclk_b qclkd vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinand clk qclk_b clken vccxx_lv ip10xddrdll_cnand2_4dgnomsp24x_nonadt
xminpdn1b[7] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[6] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[5] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[4] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[3] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[2] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[1] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1b[0] npdn1 d0_b vss e8xltp420tn2000nn1unx
xminpdn1t[7] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[6] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[5] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[4] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[3] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[2] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[1] out qclkd npdn1 e8xltp420tn2000nn1unx
xminpdn1t[0] out qclkd npdn1 e8xltp420tn2000nn1unx
xmipdn0[3] d0_b rst vss e8xltp420tn2000nn1unx
xmipdn0[2] d0_b rst vss e8xltp420tn2000nn1unx
xmipdn0[1] d0_b rst vss e8xltp420tn2000nn1unx
xmipdn0[0] d0_b rst vss e8xltp420tn2000nn1unx
xikeeper_inv3 d0 d0_b vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xikeeper_inv2 d0_b d0 vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xikeeper_inv1 out_b out vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
xikeeper_inv0 out out_b vccxx_lv ip10xddrdll_inv_2dgnomsp24x_nonadt
.ends ip10xddrdll_mcpdcell
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpfd
** view name: schematic
.subckt ip10xddrdll_mcpfd dn fbclk fbclken pfden refclk refclken up vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpfd schematic 1.10 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpfd/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpfd symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpfd/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 29138 
* Version: 1.2 
* INPUT:  vccxx_lv  fbclken  fbclk 
*+ refclken  refclk  pfden 
* OUTPUT:  up  dn 
* ----------------------------
*.PININFO  vccxx_lv:I  fbclken:I  fbclk:I 
*.PININFO  refclken:I  refclk:I  pfden:I 
*.PININFO  up:O  dn:O 
* ----------------------------

xipdrst up_b dn_b pfden rst vccxx_lv ip10xddrdll_mcpdrst
xinvup[3] up_b up vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvup[2] up_b up vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvup[1] up_b up vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinvup[0] up_b up vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv0[1] vss rstx vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv0[0] vss rstx vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiinvdn[3] dn_b dn vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiinvdn[2] dn_b dn vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiinvdn[1] dn_b dn vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xiinvdn[0] dn_b dn vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv1[3] rstx net023 vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv1[2] rstx net023 vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv1[1] rstx net023 vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xidrv1[0] rstx net023 vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xipdcelldn fbclk fbclken dn_b rst vccxx_lv ip10xddrdll_mcpdcell
xipdcellup refclk refclken up_b rst vccxx_lv ip10xddrdll_mcpdcell
.ends ip10xddrdll_mcpfd
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdllana
** view name: schematic
.subckt ip10xddrdll_mcmdllana ch0phdrven[7] ch0phdrven[6] ch0phdrven[5] ch0phdrven[4] ch0phdrven[3] ch0phdrven[2] ch0phdrven[1] ch0phdrven[0] ch1phdrven[7] ch1phdrven[6] ch1phdrven[5] ch1phdrven[4] ch1phdrven[3] ch1phdrven[2] ch1phdrven[1] ch1phdrven[0] ckfbdly ckfreerunref ckrefdly clkch0ph[7] clkch0ph[6] clkch0ph[5] clkch0ph[4] clkch0ph[3] clkch0ph[2] clkch0ph[1] clkch0ph[0] clkch1ph[7] clkch1ph[6] clkch1ph[5] clkch1ph[4] clkch1ph[3] clkch1ph[2] clkch1ph[1] clkch1ph[0] ddrdlloffvalue dllchopperdelay[2] dllchopperdelay[1] dllchopperdelay[0] dlllock dnd drvsel[3] drvsel[2] drvsel[1] drvsel[0] fbclken mdllen nbias_a nbiasen_b normalmode pbias_a pbiasdischrate[2] pbiasdischrate[1] pbiasdischrate[0] pbiasreset pfden qclk2xin refclken upd vccxx_lv vctrlhi_b 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdllana schematic 1.14 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdllana/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdllana symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdllana/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 403879 
* Version: 1.3 
* INOUT:  nbias_a  pbias_a 
* INPUT:  ch0phdrven[0]  ch0phdrven[1]  ch0phdrven[2] 
*+ ch0phdrven[3]  ch0phdrven[4]  ch0phdrven[5]  ch0phdrven[6] 
*+ ch0phdrven[7]  nbiasen_b  fbclken  pbiasreset 
*+ refclken  pfden  dllchopperdelay[0]  dllchopperdelay[1] 
*+ dllchopperdelay[2]  drvsel[0]  drvsel[1]  drvsel[2] 
*+ drvsel[3]  pbiasdischrate[0]  pbiasdischrate[1]  pbiasdischrate[2] 
*+ ch1phdrven[0]  ch1phdrven[1]  ch1phdrven[2]  ch1phdrven[3] 
*+ ch1phdrven[4]  ch1phdrven[5]  ch1phdrven[6]  ch1phdrven[7] 
*+ qclk2xin  vccxx_lv  vctrlhi_b  normalmode 
*+ ddrdlloffvalue  mdllen 
* OUTPUT:  clkch0ph[0]  clkch0ph[1]  clkch0ph[2] 
*+ clkch0ph[3]  clkch0ph[4]  clkch0ph[5]  clkch0ph[6] 
*+ clkch0ph[7]  upd  dnd  dlllock 
*+ ckfreerunref  ckfbdly  ckrefdly  clkch1ph[0] 
*+ clkch1ph[1]  clkch1ph[2]  clkch1ph[3]  clkch1ph[4] 
*+ clkch1ph[5]  clkch1ph[6]  clkch1ph[7] 
* ----------------------------
*.PININFO  nbias_a:B  pbias_a:B 
*.PININFO  ch0phdrven[0]:I  ch0phdrven[1]:I  ch0phdrven[2]:I 
*.PININFO  ch0phdrven[3]:I  ch0phdrven[4]:I  ch0phdrven[5]:I  ch0phdrven[6]:I 
*.PININFO  ch0phdrven[7]:I  nbiasen_b:I  fbclken:I  pbiasreset:I 
*.PININFO  refclken:I  pfden:I  dllchopperdelay[0]:I  dllchopperdelay[1]:I 
*.PININFO  dllchopperdelay[2]:I  drvsel[0]:I  drvsel[1]:I  drvsel[2]:I 
*.PININFO  drvsel[3]:I  pbiasdischrate[0]:I  pbiasdischrate[1]:I  pbiasdischrate[2]:I 
*.PININFO  ch1phdrven[0]:I  ch1phdrven[1]:I  ch1phdrven[2]:I  ch1phdrven[3]:I 
*.PININFO  ch1phdrven[4]:I  ch1phdrven[5]:I  ch1phdrven[6]:I  ch1phdrven[7]:I 
*.PININFO  qclk2xin:I  vccxx_lv:I  vctrlhi_b:I  normalmode:I 
*.PININFO  ddrdlloffvalue:I  mdllen:I 
*.PININFO  clkch0ph[0]:O  clkch0ph[1]:O  clkch0ph[2]:O 
*.PININFO  clkch0ph[3]:O  clkch0ph[4]:O  clkch0ph[5]:O  clkch0ph[6]:O 
*.PININFO  clkch0ph[7]:O  upd:O  dnd:O  dlllock:O 
*.PININFO  ckfreerunref:O  ckfbdly:O  ckrefdly:O  clkch1ph[0]:O 
*.PININFO  clkch1ph[1]:O  clkch1ph[2]:O  clkch1ph[3]:O  clkch1ph[4]:O 
*.PININFO  clkch1ph[5]:O  clkch1ph[6]:O  clkch1ph[7]:O 
* ----------------------------

xidnbuf normalmoded dn dnbuf dnbuf_b vccxx_lv ip10xddrdll_mcmbuf
xiupbuf normalmoded up upbuf upbuf_b vccxx_lv ip10xddrdll_mcmbuf
ximdlyline hi_sig drvsel[3] drvsel[2] drvsel[1] drvsel[0] clkch0ph[7] clkch0ph[6] clkch0ph[5] clkch0ph[4] clkch0ph[3] clkch0ph[2] clkch0ph[1] clkch0ph[0] ch1phdrven[7] ch1phdrven[6] ch1phdrven[5] ch1phdrven[4] ch1phdrven[3] ch1phdrven[2] ch1phdrven[1] ch1phdrven[0] clkch1ph[7] clkch1ph[6] clkch1ph[5] clkch1ph[4] clkch1ph[3] clkch1ph[2] clkch1ph[1] clkch1ph[0] ch0phdrven[7] ch0phdrven[6] ch0phdrven[5] ch0phdrven[4] ch0phdrven[3] ch0phdrven[2] ch0phdrven[1] ch0phdrven[0] ckfb ckfreerunref ckref ddrdlloffvalue dlylineen mdllen nbias_a normalmoded pbias_a qclk2xin vccxx_lv ip10xddrdll_mcmdlylinebwcb
xinv00 nbiasen_b dlylineen vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xinv02 nbiasen_b copbiasen vccxx_lv ip10xddrdll_inv_4dgnomsp24x_nonadt
xbfn00 normalmode normalmoded vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xi311 ckfb fbclk vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xiparkbuf ckref refclk vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xi313 ckref ckrefdly vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xi312 ckfb ckfbdly vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt
xi314 dllchopperdelay[2] dllchopperdelay[1] dllchopperdelay[0] dlllock dn fbclken up vccxx_lv ip10xddrdll_mcdlllockdetector_ec0
xinbias normalmoded nbias_a nbiasen_b pbias_a vccxx_lv ip10xddrdll_mcnbiasgen
xiupdnrep dn dnd up upd vccxx_lv ip10xddrdll_mcupdnrep
xinv03 pbiasreset pbiasreset_b vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xinv01 vss hi_sig vccxx_lv ip10xddrdll_inv_2dgsvtsp24x_nonadt
xicp copbiasen dnbuf dnbuf_b normalmoded nbias_a pbias_a upbuf upbuf_b vccxx_lv ip10xddrdll_mccp
xivctrlpulldown pbiasdischrate[2] pbiasdischrate[1] pbiasdischrate[0] pbiasreset_b vccxx_lv pbias_a vctrlhi_b ip10xddrdll_mcdllvctrlpdown
xipfd dn fbclk fbclken pfden refclk refclken up vccxx_lv ip10xddrdll_mcpfd
.ends ip10xddrdll_mcmdllana
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cnan03an1n04x5
** view name: schematic
.subckt ec0cnan03an1n04x5 clk clkout en1 en2 vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cnan03an1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnan03an1n04x5/schematic 
* CELLLOG ec0clock nil ec0cnan03an1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnan03an1n04x5/symbol 
* TAG: schematic 
* COUNTER: 103060 
* Version: Unmanaged 
* INPUT:  clk  en2  en1 
*+ vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  en2:I  en1:I 
*.PININFO  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn2 n1 en2 vss vss n l=20e-9 w=204e-9 m=1
mqn1 n0 en1 n1 vss n l=20e-9 w=204e-9 m=1
mqn0 clkout clk n0 vss n l=20e-9 w=136e-9 m=1
mqp0 clkout clk vcc vcc p l=20e-9 w=102e-9 m=1
mqp1 clkout en1 vcc vcc p l=20e-9 w=102e-9 m=1
mqp2 clkout en2 vcc vcc p l=20e-9 w=102e-9 m=1
.ends ec0cnan03an1n04x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0fsn000al1n02x5
** view name: schematic
.subckt ec0fsn000al1n02x5 clk d o vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0fsn000al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fsn000al1n02x5/schematic 
* CELLLOG ec0sequential nil ec0fsn000al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fsn000al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 187349 
* Version: Unmanaged 
* INPUT:  clk  d  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  clk:I  d:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mgtd2.qns nk5 clk nk4 vss nsvt l=20e-9 w=34e-9 m=1
mgtd2.qpsb nk5 nc1 nk4 vcc psvt l=20e-9 w=68e-9 m=1
mgtd1.qns nk3 nc1 d vss nsvt l=20e-9 w=34e-9 m=1
mgtd1.qpsb nk3 nc8 d vcc psvt l=20e-9 w=68e-9 m=1
mgd1.qnd gd1.n2 nk4 vss vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qnck nk3 nc8 gd1.n2 vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qpd gd1.n1 nk4 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1.qpckb nk3 nc1 gd1.n1 vcc psvt l=20e-9 w=68e-9 m=1
mgd2.qnd gd2.n2 nk6 vss vss nsvt l=20e-9 w=34e-9 m=1
mgd2.qnck nk5 nc1 gd2.n2 vss nsvt l=20e-9 w=34e-9 m=1
mgd2.qpd gd2.n1 nk6 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd2.qpckb nk5 clk gd2.n1 vcc psvt l=20e-9 w=68e-9 m=1
mgclkn.qna nc1 clk vss vss n l=20e-9 w=68e-9 m=1
mgclkn.qpa nc1 clk vcc vcc p l=20e-9 w=68e-9 m=1
mgclkdd.qna nc8 nc1 vss vss n l=20e-9 w=34e-9 m=1
mgclkdd.qpa nc8 nc1 vcc vcc p l=20e-9 w=68e-9 m=1
mg99.qna nk6 nk5 vss vss nsvt l=20e-9 w=34e-9 m=1
mg99.qpa nk6 nk5 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1n.qna nk4 nk3 vss vss nsvt l=20e-9 w=68e-9 m=1
mgd1n.qpa nk4 nk3 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o nk5 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qna o nk5 vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0fsn000al1n02x5
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cinv00an1n06x5
** view name: schematic
.subckt ec0cinv00an1n06x5 clk clkout vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cinv00an1n06x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n06x5/schematic 
* CELLLOG ec0clock nil ec0cinv00an1n06x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n06x5/symbol 
* TAG: schematic 
* COUNTER: 25532 
* Version: Unmanaged 
* INPUT:  clk  vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk vss vss n l=20e-9 w=204e-9 m=1
mqp1 clkout clk vcc vcc p l=20e-9 w=272e-9 m=1
.ends ec0cinv00an1n06x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0fmn200an1n04x5
** view name: schematic
.subckt ec0fmn200an1n04x5 clk d o vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0fmn200an1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fmn200an1n04x5/schematic 
* CELLLOG ec0sequential nil ec0fmn200an1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fmn200an1n04x5/symbol 
* TAG: schematic 
* COUNTER: 542347 
* Version: Unmanaged 
* INPUT:  clk  d  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  clk:I  d:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mg19.qnd g19.n2 nk6 vss vss n l=20e-9 w=136e-9 m=1
mg19.qnck nk5 nc1 g19.n2 vss n l=20e-9 w=136e-9 m=1
mg19.qpd g19.n1 nk6 vcc vcc p l=20e-9 w=136e-9 m=1
mg19.qpckb nk5 nc91 g19.n1 vcc p l=20e-9 w=136e-9 m=1
mg13.qnd g13.n2 nk4 vss vss n l=20e-9 w=136e-9 m=1
mg13.qnck nk3 nc2 g13.n2 vss n l=20e-9 w=136e-9 m=1
mg13.qpd g13.n1 nk4 vcc vcc p l=20e-9 w=136e-9 m=1
mg13.qpckb nk3 nc1 g13.n1 vcc p l=20e-9 w=136e-9 m=1
mg3.qnd g3.n2 nk14 vss vss n l=20e-9 w=136e-9 m=1
mg3.qnck nk13 nc12 g3.n2 vss n l=20e-9 w=136e-9 m=1
mg3.qpd g3.n1 nk14 vcc vcc p l=20e-9 w=136e-9 m=1
mg3.qpckb nk13 nc11 g3.n1 vcc p l=20e-9 w=136e-9 m=1
mg9.qnd g9.n2 nk16 vss vss n l=20e-9 w=68e-9 m=1
mg9.qnck nk15 nc11 g9.n2 vss n l=20e-9 w=68e-9 m=1
mg9.qpd g9.n1 nk16 vcc vcc p l=20e-9 w=68e-9 m=1
mg9.qpckb nk15 clk g9.n1 vcc p l=20e-9 w=68e-9 m=1
mg12.qns nk3 nc1 n7 vss n l=20e-9 w=68e-9 m=1
mg12.qpsb nk3 nc2 n7 vcc p l=20e-9 w=68e-9 m=1
mg2.qns nk13 nc11 n17 vss n l=20e-9 w=68e-9 m=1
mg2.qpsb nk13 nc12 n17 vcc p l=20e-9 w=68e-9 m=1
mg4.qns nk15 clk nk14 vss n l=20e-9 w=68e-9 m=1
mg4.qpsb nk15 nc11 nk14 vcc p l=20e-9 w=68e-9 m=1
mg14.qns nk5 nc91 nk4 vss n l=20e-9 w=68e-9 m=1
mg14.qpsb nk5 nc1 nk4 vcc p l=20e-9 w=68e-9 m=1
mg18.qna nk4 nk3 vss vss n l=20e-9 w=136e-9 m=1
mg18.qpa nk4 nk3 vcc vcc p l=20e-9 w=136e-9 m=1
mg16.qna nc1 nc91 vss vss n l=20e-9 w=68e-9 m=1
mg16.qpa nc1 nc91 vcc vcc p l=20e-9 w=68e-9 m=1
mg15.qna n9 nk5 vss vss n l=20e-9 w=68e-9 m=1
mg15.qpa n9 nk5 vcc vcc p l=20e-9 w=68e-9 m=1
mg22.qna nc91 nc90 vss vss n l=20e-9 w=68e-9 m=1
mg22.qpa nc91 nc90 vcc vcc p l=20e-9 w=68e-9 m=1
mg17.qna nc2 nc1 vss vss n l=20e-9 w=68e-9 m=1
mg17.qpa nc2 nc1 vcc vcc p l=20e-9 w=68e-9 m=1
mg20.qna nk6 nk5 vss vss n l=20e-9 w=136e-9 m=1
mg20.qpa nk6 nk5 vcc vcc p l=20e-9 w=136e-9 m=1
mg11.qna n7 d vss vss n l=20e-9 w=136e-9 m=1
mg11.qpa n7 d vcc vcc p l=20e-9 w=136e-9 m=1
mg1.qna n17 n10 vss vss n l=20e-9 w=136e-9 m=1
mg1.qpa n17 n10 vcc vcc p l=20e-9 w=136e-9 m=1
mg99.qna nk16 nk15 vss vss n l=20e-9 w=68e-9 m=1
mg99.qpa nk16 nk15 vcc vcc p l=20e-9 w=68e-9 m=1
mg7.qna nc12 nc11 vss vss n l=20e-9 w=68e-9 m=1
mg7.qpa nc12 nc11 vcc vcc p l=20e-9 w=68e-9 m=1
mg5.qna n19 nk15 vss vss n l=20e-9 w=68e-9 m=1
mg5.qpa n19 nk15 vcc vcc p l=20e-9 w=68e-9 m=1
mg6.qna nc11 clk vss vss n l=20e-9 w=68e-9 m=1
mg6.qpa nc11 clk vcc vcc p l=20e-9 w=68e-9 m=1
mg8.qna nk14 nk13 vss vss n l=20e-9 w=136e-9 m=1
mg8.qpa nk14 nk13 vcc vcc p l=20e-9 w=136e-9 m=1
mg23.qna nc90 clk vss vss n l=20e-9 w=68e-9 m=1
mg23.qpa nc90 clk vcc vcc p l=20e-9 w=68e-9 m=1
mg21.qna n10 n9 vss vss n l=20e-9 w=68e-9 m=1
mg21.qpa n10 n9 vcc vcc p l=20e-9 w=68e-9 m=1
mg101.qpa o n19 vcc vcc p l=20e-9 w=136e-9 m=1
mg101.qna o n19 vss vss n l=20e-9 w=136e-9 m=1
.ends ec0fmn200an1n04x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcpiupdate
** view name: schematic
.subckt ip10xddrdll_mcpiupdate clkdllioagpichqh[3] clkdllioagpichqh[2] clkdllioagpichqh[1] ddrdqstxenpilongqnn1h ddrdqtxdriveqnn6h ddrrcvenpiqnn4h dllforcepiupdateqnnnh pidftenablevccioagqnnnh piupdateqnnnh[3] piupdateqnnnh[2] piupdateqnnnh[1] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpiupdate schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpiupdate/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcpiupdate symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcpiupdate/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 45890 
* Version: 1.3 
* INPUT:  vccxx_lv  pidftenablevccioagqnnnh  ddrdqstxenpilongqnn1h 
*+ dllforcepiupdateqnnnh  ddrdqtxdriveqnn6h  ddrrcvenpiqnn4h  clkdllioagpichqh[1] 
*+ clkdllioagpichqh[2]  clkdllioagpichqh[3] 
* OUTPUT:  piupdateqnnnh[1]  piupdateqnnnh[2]  piupdateqnnnh[3] 
* ----------------------------
*.PININFO  vccxx_lv:I  pidftenablevccioagqnnnh:I  ddrdqstxenpilongqnn1h:I 
*.PININFO  dllforcepiupdateqnnnh:I  ddrdqtxdriveqnn6h:I  ddrrcvenpiqnn4h:I  clkdllioagpichqh[1]:I 
*.PININFO  clkdllioagpichqh[2]:I  clkdllioagpichqh[3]:I 
*.PININFO  piupdateqnnnh[1]:O  piupdateqnnnh[2]:O  piupdateqnnnh[3]:O 
* ----------------------------

xinan1 ddrdqtxdrivenqnn7h piupdateb[3] pidftenvccioag3 dllforcepib vccxx_lv ec0cnan03an1n04x5
xnan0 ddrdqstxenpilongqnn2h piupdateb[2] pidftenvccioag2 dllforcepib vccxx_lv ec0cnan03an1n04x5
xnan1 ddrrcvenpiqnn5h piupdateb[1] pidftenvccioag1 dllforcepib vccxx_lv ec0cnan03an1n04x5
xinn0 dllforcepiupdateqnnnh dllforcepib vccxx_lv ec0inv000al1n02x5
xinn4 pidfeten2 pidftenvccioag2 vccxx_lv ec0inv000al1n02x5
xinn6 pidfeten3 pidftenvccioag3 vccxx_lv ec0inv000al1n02x5
xinn5 pidfeten1 pidftenvccioag1 vccxx_lv ec0inv000al1n02x5
xiclk2 clkdllioagpichqh[2] ddrdqstxenpilongqnn1h ddrdqstxenpilongqnn2h vccxx_lv ec0fsn000al1n02x5
xiclk3 clkdllioagpichqh[3] ddrdqtxdriveqnn6h ddrdqtxdrivenqnn7h vccxx_lv ec0fsn000al1n02x5
xfsn2 clkdllioagpichqh[1] ddrrcvenpiqnn4h ddrrcvenpiqnn5h vccxx_lv ec0fsn000al1n02x5
xinn3 piupdateb[1] piupdateqnnnh[1] vccxx_lv ec0cinv00an1n06x5
xinn2 piupdateb[2] piupdateqnnnh[2] vccxx_lv ec0cinv00an1n06x5
xinn1 piupdateb[3] piupdateqnnnh[3] vccxx_lv ec0cinv00an1n06x5
xfmn0 clkdllioagpichqh[2] pidftenablevccioagqnnnh pidfeten2 vccxx_lv ec0fmn200an1n04x5
xfmn1 clkdllioagpichqh[3] pidftenablevccioagqnnnh pidfeten3 vccxx_lv ec0fmn200an1n04x5
xfmn2 clkdllioagpichqh[1] pidftenablevccioagqnnnh pidfeten1 vccxx_lv ec0fmn200an1n04x5
.ends ip10xddrdll_mcpiupdate
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cinv00an1n18x5
** view name: schematic
.subckt ec0cinv00an1n18x5 clk clkout vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cinv00an1n18x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n18x5/schematic 
* CELLLOG ec0clock nil ec0cinv00an1n18x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n18x5/symbol 
* TAG: schematic 
* COUNTER: 25532 
* Version: Unmanaged 
* INPUT:  clk  vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk vss vss n l=20e-9 w=612e-9 m=1
mqp1 clkout clk vcc vcc p l=20e-9 w=714e-9 m=1
.ends ec0cinv00an1n18x5
** end of subcircuit definition.

** library name: e3modules
** cell name: e3yinc000af
** view name: schematic
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cmbn04an1n09x5
** view name: schematic
.subckt ec0cmbn04an1n09x5 a b c d o sa sb sc sd vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cmbn04an1n09x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cmbn04an1n09x5/schematic 
* CELLLOG ec0clock nil ec0cmbn04an1n09x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cmbn04an1n09x5/symbol 
* TAG: schematic 
* COUNTER: 297143 
* Version: Unmanaged 
* INPUT:  d  sd  a 
*+ sa  sc  sb  c 
*+ b  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  d:I  sd:I  a:I 
*.PININFO  sa:I  sc:I  sb:I  c:I 
*.PININFO  b:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mg11.qns n9 sd n7 vss n l=20e-9 w=102e-9 m=1
mg11.qpsb n9 n8 n7 vcc p l=20e-9 w=102e-9 m=1
mg2.qns n9 sa n1 vss n l=20e-9 w=102e-9 m=1
mg2.qpsb n9 n2 n1 vcc p l=20e-9 w=102e-9 m=1
mg5.qns n9 sb n3 vss n l=20e-9 w=102e-9 m=1
mg5.qpsb n9 n4 n3 vcc p l=20e-9 w=102e-9 m=1
mg8.qns n9 sc n5 vss n l=20e-9 w=102e-9 m=1
mg8.qpsb n9 n6 n5 vcc p l=20e-9 w=102e-9 m=1
mg3.qna n2 sa vss vss n l=20e-9 w=68e-9 m=1
mg3.qpa n2 sa vcc vcc p l=20e-9 w=68e-9 m=1
mg9.qna n6 sc vss vss n l=20e-9 w=68e-9 m=1
mg9.qpa n6 sc vcc vcc p l=20e-9 w=68e-9 m=1
mg7.qna n5 c vss vss n l=20e-9 w=204e-9 m=1
mg7.qpa n5 c vcc vcc p l=20e-9 w=204e-9 m=1
mg12.qna n8 sd vss vss n l=20e-9 w=68e-9 m=1
mg12.qpa n8 sd vcc vcc p l=20e-9 w=68e-9 m=1
mg10.qna n7 d vss vss n l=20e-9 w=204e-9 m=1
mg10.qpa n7 d vcc vcc p l=20e-9 w=204e-9 m=1
mg1.qna n1 a vss vss n l=20e-9 w=204e-9 m=1
mg1.qpa n1 a vcc vcc p l=20e-9 w=204e-9 m=1
mg4.qna n3 b vss vss n l=20e-9 w=204e-9 m=1
mg4.qpa n3 b vcc vcc p l=20e-9 w=204e-9 m=1
mg6.qna n4 sb vss vss n l=20e-9 w=68e-9 m=1
mg6.qpa n4 sb vcc vcc p l=20e-9 w=68e-9 m=1
mg101.qn0 o n9 vss vss n l=20e-9 w=306e-9 m=1
mg101.qp0 o n9 vcc vcc p l=20e-9 w=408e-9 m=1
.ends ec0cmbn04an1n09x5
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cmbn02an1n09x5
** view name: schematic
.subckt ec0cmbn02an1n09x5 a b o sa sb vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cmbn02an1n09x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cmbn02an1n09x5/schematic 
* CELLLOG ec0clock nil ec0cmbn02an1n09x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cmbn02an1n09x5/symbol 
* TAG: schematic 
* COUNTER: 127677 
* Version: Unmanaged 
* INPUT:  b  sa  sb 
*+ a  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  b:I  sa:I  sb:I 
*.PININFO  a:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mg2.qns n9 sa n1 vss n l=20e-9 w=102e-9 m=1
mg2.qpsb n9 n2 n1 vcc p l=20e-9 w=102e-9 m=1
mg5.qns n9 sb n3 vss n l=20e-9 w=102e-9 m=1
mg5.qpsb n9 n4 n3 vcc p l=20e-9 w=102e-9 m=1
mg4.qna n3 b vss vss n l=20e-9 w=204e-9 m=1
mg4.qpa n3 b vcc vcc p l=20e-9 w=204e-9 m=1
mg6.qna n4 sb vss vss n l=20e-9 w=68e-9 m=1
mg6.qpa n4 sb vcc vcc p l=20e-9 w=68e-9 m=1
mg3.qna n2 sa vss vss n l=20e-9 w=68e-9 m=1
mg3.qpa n2 sa vcc vcc p l=20e-9 w=68e-9 m=1
mg1.qna n1 a vss vss n l=20e-9 w=204e-9 m=1
mg1.qpa n1 a vcc vcc p l=20e-9 w=204e-9 m=1
mg101.qn0 o n9 vss vss n l=20e-9 w=306e-9 m=1
mg101.qp0 o n9 vcc vcc p l=20e-9 w=408e-9 m=1
.ends ec0cmbn02an1n09x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nor022al1n02x5
** view name: schematic
.subckt ec0nor022al1n02x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nor022al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor022al1n02x5/schematic 
* CELLLOG ec0basic nil ec0nor022al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor022al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 49307 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a n1 vcc psvt l=20e-9 w=68e-9 m=1
mqp2 n1 b vcc vcc psvt l=20e-9 w=68e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn2 o1 b vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0nor022al1n02x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcviewdec2to4
** view name: schematic
.subckt ip10xddrdll_mcviewdec2to4 vccxx viewsel[0] viewsel[1] viewselout[0] viewselout[1] viewselout[2] viewselout[3]
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcviewdec2to4 schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcviewdec2to4/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcviewdec2to4 symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcviewdec2to4/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 10058 
* Version: 1.2 
* INPUT:  viewsel[1]  viewsel[0]  vccxx 
* OUTPUT:  viewselout[0]  viewselout[3]  viewselout[2] 
*+ viewselout[1] 
* ----------------------------
*.PININFO  viewsel[1]:I  viewsel[0]:I  vccxx:I 
*.PININFO  viewselout[0]:O  viewselout[3]:O  viewselout[2]:O 
*.PININFO  viewselout[1]:O 
* ----------------------------

xi13 viewsel_b1[0] viewsel[1] viewselout[1] vccxx ec0nor022al1n02x5
xi10 viewsel[0] viewsel[1] viewselout[0] vccxx ec0nor022al1n02x5
xi14 viewsel[0] viewsel_b[1] viewselout[2] vccxx ec0nor022al1n02x5
xi15 viewsel_b1[0] viewsel_b[1] viewselout[3] vccxx ec0nor022al1n02x5
xi5 viewsel[1] viewsel_b[1] vccxx ec0inv000an1n02x5
xi6 viewsel[0] viewsel_b1[0] vccxx ec0inv000an1n02x5
.ends ip10xddrdll_mcviewdec2to4
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcviewmuxes
** view name: schematic
.subckt ip10xddrdll_mcviewmuxes pi[0] pi[1] pi[2] pi[3] qclk reffbclk refpi vccxx viewmuxout viewsel[2] viewsel[1] viewsel[0]
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcviewmuxes schematic 1.4 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcviewmuxes/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcviewmuxes symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcviewmuxes/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 17928 
* Version: 1.1 
* INPUT:  pi[3]  pi[2]  pi[1] 
*+ pi[0]  refpi  reffbclk  qclk 
*+ vccxx  viewsel[0]  viewsel[1]  viewsel[2] 
* OUTPUT:  viewmuxout 
* ----------------------------
*.PININFO  pi[3]:I  pi[2]:I  pi[1]:I 
*.PININFO  pi[0]:I  refpi:I  reffbclk:I  qclk:I 
*.PININFO  vccxx:I  viewsel[0]:I  viewsel[1]:I  viewsel[2]:I 
*.PININFO  viewmuxout:O 
* ----------------------------

xmxc1 refpi reffbclk qclk vss lobit sel[3] sel[2] sel[1] sel[0] vccxx ec0cmbn04an1n09x5
xmxc0 pi[3] pi[2] pi[1] pi[0] hibit sel[3] sel[2] sel[1] sel[0] vccxx ec0cmbn04an1n09x5
xmxc2 hibit lobit viewmuxout viewsel[2] viewselb[2] vccxx ec0cmbn02an1n09x5
xinn0 viewsel[2] viewselb[2] vccxx ec0inv000al1n02x5
xi28 vccxx viewsel[0] viewsel[1] sel[0] sel[1] sel[2] sel[3] ip10xddrdll_mcviewdec2to4
.ends ip10xddrdll_mcviewmuxes
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0bfn000al1n05x5
** view name: schematic
.subckt ec0bfn000al1n05x5 a o vcc
* ----------------------------
* CELLLOG ec0basic nil ec0bfn000al1n05x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n05x5/schematic 
* CELLLOG ec0basic nil ec0bfn000al1n05x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n05x5/symbol 
* TAG: schematic 
* COUNTER: 27817 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mqp1 n1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o n1 vcc vcc psvt l=20e-9 w=170e-9 m=1
mg101.qna o n1 vss vss nsvt l=20e-9 w=170e-9 m=1
mqn1 n1 a vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0bfn000al1n05x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdllviewslice
** view name: schematic
.subckt ip10xddrdll_mcdllviewslice chviewen chviewsel[2] chviewsel[1] chviewsel[0] clkin dftview pi[4] pi[3] pi[2] pi[1] pi[0] qclk vccxx_lv viewmuxout
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllviewslice schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllviewslice/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllviewslice symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllviewslice/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 18502 
* Version: 1.1 
* INPUT:  pi[0]  pi[1]  pi[2] 
*+ pi[3]  pi[4]  qclk  clkin 
*+ chviewen  chviewsel[0]  chviewsel[1]  chviewsel[2] 
*+ dftview  vccxx_lv 
* OUTPUT:  viewmuxout 
* ----------------------------
*.PININFO  pi[0]:I  pi[1]:I  pi[2]:I 
*.PININFO  pi[3]:I  pi[4]:I  qclk:I  clkin:I 
*.PININFO  chviewen:I  chviewsel[0]:I  chviewsel[1]:I  chviewsel[2]:I 
*.PININFO  dftview:I  vccxx_lv:I 
*.PININFO  viewmuxout:O 
* ----------------------------

xinn2 chviewen viewenb vccxx_lv ec0inv000al1n02x5
xinc1[1] muxop_b viewmuxout vccxx_lv ec0cinv00an1n18x5
xinc1[0] muxop_b viewmuxout vccxx_lv ec0cinv00an1n18x5
xinc0 muxop_iog muxop_b vccxx_lv ec0cinv00an1n18x5
xich0viewmux pi[0] pi[1] pi[2] pi[3] qclk clkin pi[4] vccxx_lv ch0muxout chviewsel[2] chviewsel[1] chviewsel[0] ip10xddrdll_mcviewmuxes
xibufdismixer ch0muxop muxop_iog vccxx_lv ec0bfn000al1n05x5
xmxc0 ch0muxout dftview ch0muxop chviewen viewenb vccxx_lv ec0cmbn02an1n09x5
.ends ip10xddrdll_mcdllviewslice
** end of subcircuit definition.

** library name: e8lib
** cell name: e8xlmfc4c0n4000xn3unx
** view name: schematic
.subckt e8xlmfc4c0n4000xn3unx mfcport1
* ----------------------------
* CELLLOG e8lib nil e8xlmfc4c0n4000xn3unx schematic Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8lib/e8xlmfc4c0n4000xn3unx/schematic 
* CELLLOG e8lib nil e8xlmfc4c0n4000xn3unx symbol Unmanaged /nfs/site/disks/hdk.cad.1/linux_2.6.16_x86-64/p1274/process/p1274.0_collateral/p1274.0_14ww35.1/e8lib/e8xlmfc4c0n4000xn3unx/symbol 
* TAG: p1274.0_14ww35.1 
* COUNTER: 12094 
* Version: Unmanaged 
* INOUT:  mfcport1 
* ----------------------------
*.PININFO  mfcport1:B 
* ----------------------------

i1 mfcport1 e8xlmfc4c0n4000xn3unx_prim
.ends e8xlmfc4c0n4000xn3unx
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcnbiascap1top
** view name: schematic
.subckt ip10xddrdll_mcnbiascap1top vnbias
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcnbiascap1top schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcnbiascap1top/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcnbiascap1top symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcnbiascap1top/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 9004 
* Version: 1.3 
* INOUT:  vnbias 
* ----------------------------
*.PININFO  vnbias:B 
* ----------------------------

xinbiasunx[19] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[18] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[17] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[16] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[15] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[14] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[13] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[12] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[11] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[10] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[9] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[8] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[7] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[6] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[5] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[4] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[3] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[2] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[1] vnbias e8xlmfc4c0n4000xn3unx
xinbiasunx[0] vnbias e8xlmfc4c0n4000xn3unx
.ends ip10xddrdll_mcnbiascap1top
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcdll10pi
** view name: schematic
.subckt ip10xddrdll_mcdll10pi i_2xclk i_ddrdlloffvalue i_dftview0en i_dftview1en i_digobs0 i_digobs0sel[2] i_digobs0sel[1] i_digobs0sel[0] i_digobs1 i_digobs1sel[2] i_digobs1sel[1] i_digobs1sel[0] i_dischen[2] i_dischen[1] i_dischen[0] i_dismixer i_dllforcepiupdate i_dqdrvenpi[1] i_dqdrvenpi[0] i_dqsdrvenpilong[1] i_dqsdrvenpilong[0] i_drvsel[2] i_drvsel[1] i_drvsel[0] i_fbclken i_lockthresh[2] i_lockthresh[1] i_lockthresh[0] i_mdllen i_normalmode i_pfden i_phsdrvpwrsavon i_pi0code[5] i_pi0code[4] i_pi0code[3] i_pi0code[2] i_pi0code[1] i_pi0code[0] i_pi1code[5] i_pi1code[4] i_pi1code[3] i_pi1code[2] i_pi1code[1] i_pi1code[0] i_pi2code[5] i_pi2code[4] i_pi2code[3] i_pi2code[2] i_pi2code[1] i_pi2code[0] i_pi3code[5] i_pi3code[4] i_pi3code[3] i_pi3code[2] i_pi3code[1] i_pi3code[0] i_pi4code[5] i_pi4code[4] i_pi4code[3] i_pi4code[2] i_pi4code[1] i_pi4code[0] i_pi5code[5] i_pi5code[4] i_pi5code[3] i_pi5code[2] i_pi5code[1] i_pi5code[0] i_pi6code[5] i_pi6code[4] i_pi6code[3] i_pi6code[2] i_pi6code[1] i_pi6code[0]
+i_pi7code[5] i_pi7code[4] i_pi7code[3] i_pi7code[2] i_pi7code[1] i_pi7code[0] i_pi8code[5] i_pi8code[4] i_pi8code[3] i_pi8code[2] i_pi8code[1] i_pi8code[0] i_pi9code[5] i_pi9code[4] i_pi9code[3] i_pi9code[2] i_pi9code[1] i_pi9code[0] i_picapsel[2] i_picapsel[1] i_picapsel[0] i_pidften[1] i_pidften[0] i_pien[9] i_pien[8] i_pien[7] i_pien[6] i_pien[5] i_pien[4] i_pien[3] i_pien[2] i_pien[1] i_pien[0] i_rcvenpi[1] i_rcvenpi[0] i_refclken i_resetd i_vctrlhi_b o_ckfbdly o_ckfreerunref o_ckrefdly o_digobs0 o_digobs1 o_locktimerreset o_nbias_a o_pbias_a o_piclk[9] o_piclk[8] o_piclk[7] o_piclk[6] o_piclk[5] o_piclk[4] o_piclk[3] o_piclk[2] o_piclk[1] o_piclk[0] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll10pi schematic 1.21 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll10pi/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdll10pi symbol 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdll10pi/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 941194 
* Version: 1.8 
* INPUT:  i_pi5code[0]  i_pi5code[1]  i_pi5code[2] 
*+ i_pi5code[3]  i_pi5code[4]  i_pi5code[5]  i_phsdrvpwrsavon 
*+ i_fbclken  i_pi4code[0]  i_pi4code[1]  i_pi4code[2] 
*+ i_pi4code[3]  i_pi4code[4]  i_pi4code[5]  i_pi3code[0] 
*+ i_pi3code[1]  i_pi3code[2]  i_pi3code[3]  i_pi3code[4] 
*+ i_pi3code[5]  i_pi2code[0]  i_pi2code[1]  i_pi2code[2] 
*+ i_pi2code[3]  i_pi2code[4]  i_pi2code[5]  i_pi0code[0] 
*+ i_pi0code[1]  i_pi0code[2]  i_pi0code[3]  i_pi0code[4] 
*+ i_pi0code[5]  i_pi7code[0]  i_pi7code[1]  i_pi7code[2] 
*+ i_pi7code[3]  i_pi7code[4]  i_pi7code[5]  i_pi8code[0] 
*+ i_pi8code[1]  i_pi8code[2]  i_pi8code[3]  i_pi8code[4] 
*+ i_pi8code[5]  i_pfden  i_dischen[0]  i_dischen[1] 
*+ i_dischen[2]  i_vctrlhi_b  i_lockthresh[0]  i_lockthresh[1] 
*+ i_lockthresh[2]  i_digobs0  i_digobs1sel[0]  i_digobs1sel[1] 
*+ i_digobs1sel[2]  i_ddrdlloffvalue  i_pi1code[0]  i_pi1code[1] 
*+ i_pi1code[2]  i_pi1code[3]  i_pi1code[4]  i_pi1code[5] 
*+ i_dqdrvenpi[0]  i_dqdrvenpi[1]  i_dftview1en  i_pi9code[0] 
*+ i_pi9code[1]  i_pi9code[2]  i_pi9code[3]  i_pi9code[4] 
*+ i_pi9code[5]  i_digobs1  i_picapsel[0]  i_picapsel[1] 
*+ i_picapsel[2]  vccxx_lv  i_2xclk  i_pi6code[0] 
*+ i_pi6code[1]  i_pi6code[2]  i_pi6code[3]  i_pi6code[4] 
*+ i_pi6code[5]  i_drvsel[0]  i_drvsel[1]  i_drvsel[2] 
*+ i_refclken  i_digobs0sel[0]  i_digobs0sel[1]  i_digobs0sel[2] 
*+ i_dismixer  i_mdllen  i_normalmode  i_resetd 
*+ i_pidften[0]  i_pidften[1]  i_dqsdrvenpilong[0]  i_dqsdrvenpilong[1] 
*+ i_pien[0]  i_pien[1]  i_pien[2]  i_pien[3] 
*+ i_pien[4]  i_pien[5]  i_pien[6]  i_pien[7] 
*+ i_pien[8]  i_pien[9]  i_dllforcepiupdate  i_rcvenpi[0] 
*+ i_rcvenpi[1]  i_dftview0en 
* OUTPUT:  o_ckrefdly  o_digobs1  o_ckfreerunref 
*+ o_piclk[0]  o_piclk[1]  o_piclk[2]  o_piclk[3] 
*+ o_piclk[4]  o_piclk[5]  o_piclk[6]  o_piclk[7] 
*+ o_piclk[8]  o_piclk[9]  o_digobs0  o_ckfbdly 
*+ o_nbias_a  o_pbias_a  o_locktimerreset 
* ----------------------------
*.PININFO  i_pi5code[0]:I  i_pi5code[1]:I  i_pi5code[2]:I 
*.PININFO  i_pi5code[3]:I  i_pi5code[4]:I  i_pi5code[5]:I  i_phsdrvpwrsavon:I 
*.PININFO  i_fbclken:I  i_pi4code[0]:I  i_pi4code[1]:I  i_pi4code[2]:I 
*.PININFO  i_pi4code[3]:I  i_pi4code[4]:I  i_pi4code[5]:I  i_pi3code[0]:I 
*.PININFO  i_pi3code[1]:I  i_pi3code[2]:I  i_pi3code[3]:I  i_pi3code[4]:I 
*.PININFO  i_pi3code[5]:I  i_pi2code[0]:I  i_pi2code[1]:I  i_pi2code[2]:I 
*.PININFO  i_pi2code[3]:I  i_pi2code[4]:I  i_pi2code[5]:I  i_pi0code[0]:I 
*.PININFO  i_pi0code[1]:I  i_pi0code[2]:I  i_pi0code[3]:I  i_pi0code[4]:I 
*.PININFO  i_pi0code[5]:I  i_pi7code[0]:I  i_pi7code[1]:I  i_pi7code[2]:I 
*.PININFO  i_pi7code[3]:I  i_pi7code[4]:I  i_pi7code[5]:I  i_pi8code[0]:I 
*.PININFO  i_pi8code[1]:I  i_pi8code[2]:I  i_pi8code[3]:I  i_pi8code[4]:I 
*.PININFO  i_pi8code[5]:I  i_pfden:I  i_dischen[0]:I  i_dischen[1]:I 
*.PININFO  i_dischen[2]:I  i_vctrlhi_b:I  i_lockthresh[0]:I  i_lockthresh[1]:I 
*.PININFO  i_lockthresh[2]:I  i_digobs0:I  i_digobs1sel[0]:I  i_digobs1sel[1]:I 
*.PININFO  i_digobs1sel[2]:I  i_ddrdlloffvalue:I  i_pi1code[0]:I  i_pi1code[1]:I 
*.PININFO  i_pi1code[2]:I  i_pi1code[3]:I  i_pi1code[4]:I  i_pi1code[5]:I 
*.PININFO  i_dqdrvenpi[0]:I  i_dqdrvenpi[1]:I  i_dftview1en:I  i_pi9code[0]:I 
*.PININFO  i_pi9code[1]:I  i_pi9code[2]:I  i_pi9code[3]:I  i_pi9code[4]:I 
*.PININFO  i_pi9code[5]:I  i_digobs1:I  i_picapsel[0]:I  i_picapsel[1]:I 
*.PININFO  i_picapsel[2]:I  vccxx_lv:I  i_2xclk:I  i_pi6code[0]:I 
*.PININFO  i_pi6code[1]:I  i_pi6code[2]:I  i_pi6code[3]:I  i_pi6code[4]:I 
*.PININFO  i_pi6code[5]:I  i_drvsel[0]:I  i_drvsel[1]:I  i_drvsel[2]:I 
*.PININFO  i_refclken:I  i_digobs0sel[0]:I  i_digobs0sel[1]:I  i_digobs0sel[2]:I 
*.PININFO  i_dismixer:I  i_mdllen:I  i_normalmode:I  i_resetd:I 
*.PININFO  i_pidften[0]:I  i_pidften[1]:I  i_dqsdrvenpilong[0]:I  i_dqsdrvenpilong[1]:I 
*.PININFO  i_pien[0]:I  i_pien[1]:I  i_pien[2]:I  i_pien[3]:I 
*.PININFO  i_pien[4]:I  i_pien[5]:I  i_pien[6]:I  i_pien[7]:I 
*.PININFO  i_pien[8]:I  i_pien[9]:I  i_dllforcepiupdate:I  i_rcvenpi[0]:I 
*.PININFO  i_rcvenpi[1]:I  i_dftview0en:I 
*.PININFO  o_ckrefdly:O  o_digobs1:O  o_ckfreerunref:O 
*.PININFO  o_piclk[0]:O  o_piclk[1]:O  o_piclk[2]:O  o_piclk[3]:O 
*.PININFO  o_piclk[4]:O  o_piclk[5]:O  o_piclk[6]:O  o_piclk[7]:O 
*.PININFO  o_piclk[8]:O  o_piclk[9]:O  o_digobs0:O  o_ckfbdly:O 
*.PININFO  o_nbias_a:O  o_pbias_a:O  o_locktimerreset:O 
* ----------------------------
xidllddrmpidec0 ch0clken i_pi4code[5] i_pi4code[4] i_pi4code[3] i_pi4code[2] i_pi4code[1] i_pi4code[0] i_pien[4] ch0mux0sel[1] ch0mux0sel[0] ch0mux0sel[3] ch0mux0sel[2] ch0mux0sel[5] ch0mux0sel[4] ch0mux0sel[7] ch0mux0sel[6] ch0mux1sel[1] ch0mux1sel[0] ch0mux1sel[3] ch0mux1sel[2] ch0mux1sel[5] ch0mux1sel[4] ch0mux1sel[7] ch0mux1sel[6] ch0mux2sel[1] ch0mux2sel[0] ch0mux2sel[3] ch0mux2sel[2] ch0mux2sel[5] ch0mux2sel[4] ch0mux2sel[7] ch0mux2sel[6] ch0mux3sel[1] ch0mux3sel[0] ch0mux3sel[3] ch0mux3sel[2] ch0mux3sel[5] ch0mux3sel[4] ch0mux3sel[7] ch0mux3sel[6] ch0muxd0sel[1] ch0muxd0sel[0] ch0muxd0sel[3] ch0muxd0sel[2] ch0muxd0sel[5] ch0muxd0sel[4] ch0muxd0sel[7] ch0muxd0sel[6] i_pi0code[5] i_pi0code[4] i_pi0code[3] i_pi0code[2] i_pi0code[1] i_pi0code[0] i_pien[0] pi0codesch0[7] pi0codesch0[6] pi0codesch0[5] pi0codesch0[4] pi0codesch0[3] pi0codesch0[2] pi0codesch0[1] pi0codesch0[0] i_pi1code[5] i_pi1code[4] i_pi1code[3] i_pi1code[2] i_pi1code[1] i_pi1code[0] i_pien[1] pi1codesch0[7] pi1codesch0[6] pi1codesch0[5] 
+ pi1codesch0[4] pi1codesch0[3] pi1codesch0[2] pi1codesch0[1] pi1codesch0[0] i_pi2code[5] i_pi2code[4] i_pi2code[3] i_pi2code[2] i_pi2code[1] i_pi2code[0] i_pien[2] pi2codesch0[7] pi2codesch0[6] pi2codesch0[5] pi2codesch0[4] pi2codesch0[3] pi2codesch0[2] pi2codesch0[1] pi2codesch0[0] i_pi3code[5] i_pi3code[4] i_pi3code[3] i_pi3code[2] i_pi3code[1] i_pi3code[0] i_pien[3] pi3codesch0[7] pi3codesch0[6] pi3codesch0[5] pi3codesch0[4] pi3codesch0[3] pi3codesch0[2] pi3codesch0[1] pi3codesch0[0] pid0codesch0[7] pid0codesch0[6] pid0codesch0[5] pid0codesch0[4] pid0codesch0[3] pid0codesch0[2] pid0codesch0[1] pid0codesch0[0] ch0pienable[0] ch0pienable[1] ch0pienable[2] ch0pienable[3] piupdate0[3] piupdate0[2] piupdate0[1] vccxx_lv ip10xddrdll_mcmpidecoder_x4pi
xidllddrmpidec1 ch1clken i_pi9code[5] i_pi9code[4] i_pi9code[3] i_pi9code[2] i_pi9code[1] i_pi9code[0] i_pien[9] ch1mux0sel[1] ch1mux0sel[0] ch1mux0sel[3] ch1mux0sel[2] ch1mux0sel[5] ch1mux0sel[4] ch1mux0sel[7] ch1mux0sel[6] ch1mux1sel[1] ch1mux1sel[0] ch1mux1sel[3] ch1mux1sel[2] ch1mux1sel[5] ch1mux1sel[4] ch1mux1sel[7] ch1mux1sel[6] ch1mux2sel[1] ch1mux2sel[0] ch1mux2sel[3] ch1mux2sel[2] ch1mux2sel[5] ch1mux2sel[4] ch1mux2sel[7] ch1mux2sel[6] net137[1] net137[0] net137[3] net137[2] net137[5] net137[4] net137[7] net137[6] ch1muxd0sel[1] ch1muxd0sel[0] ch1muxd0sel[3] ch1muxd0sel[2] ch1muxd0sel[5] ch1muxd0sel[4] ch1muxd0sel[7] ch1muxd0sel[6] i_pi5code[5] i_pi5code[4] i_pi5code[3] i_pi5code[2] i_pi5code[1] i_pi5code[0] i_pien[5] pi0codesch1[7] pi0codesch1[6] pi0codesch1[5] pi0codesch1[4] pi0codesch1[3] pi0codesch1[2] pi0codesch1[1] pi0codesch1[0] i_pi6code[5] i_pi6code[4] i_pi6code[3] i_pi6code[2] i_pi6code[1] i_pi6code[0] i_pien[6] pi1codesch1[7] pi1codesch1[6] pi1codesch1[5] pi1codesch1[4] pi1codesch1[3] 
+ pi1codesch1[2] pi1codesch1[1] pi1codesch1[0] i_pi7code[5] i_pi7code[4] i_pi7code[3] i_pi7code[2] i_pi7code[1] i_pi7code[0] i_pien[7] pi2codesch1[7] pi2codesch1[6] pi2codesch1[5] pi2codesch1[4] pi2codesch1[3] pi2codesch1[2] pi2codesch1[1] pi2codesch1[0] i_pi8code[5] i_pi8code[4] i_pi8code[3] i_pi8code[2] i_pi8code[1] i_pi8code[0] i_pien[8] pi3codesch1[7] pi3codesch1[6] pi3codesch1[5] pi3codesch1[4] pi3codesch1[3] pi3codesch1[2] pi3codesch1[1] pi3codesch1[0] pid0codesch1[7] pid0codesch1[6] pid0codesch1[5] pid0codesch1[4] pid0codesch1[3] pid0codesch1[2] pid0codesch1[1] pid0codesch1[0] ch1pienable[0] ch1pienable[1] ch1pienable[2] ch1pienable[3] piupdate1[3] piupdate1[2] piupdate1[1] vccxx_lv ip10xddrdll_mcmpidecoder_x4pi
xicappbias[30] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[29] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[28] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[27] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[26] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[25] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[24] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[23] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[22] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[21] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[20] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[19] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[18] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[17] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[16] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[15] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[14] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[13] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[12] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[11] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[10] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[9] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[8] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[7] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[6] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[5] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[4] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[3] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[2] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[1] vccxx_lv o_pbias_a ip10xddrdll_mcpbiascap1
xidllddr5pi_ch1 clkphch1[7] clkphch1[6] clkphch1[5] clkphch1[4] clkphch1[3] clkphch1[2] clkphch1[1] clkphch1[0] i_dismixer vss i_drvsel[2] i_drvsel[1] i_drvsel[0] ch1mux0sel[7] ch1mux0sel[6] ch1mux0sel[5] ch1mux0sel[4] ch1mux0sel[3] ch1mux0sel[2] ch1mux0sel[1] ch1mux0sel[0] ch1mux1sel[7] ch1mux1sel[6] ch1mux1sel[5] ch1mux1sel[4] ch1mux1sel[3] ch1mux1sel[2] ch1mux1sel[1] ch1mux1sel[0] ch1mux2sel[7] ch1mux2sel[6] ch1mux2sel[5] ch1mux2sel[4] ch1mux2sel[3] ch1mux2sel[2] ch1mux2sel[1] ch1mux2sel[0] net137[7] net137[6] net137[5] net137[4] net137[3] net137[2] net137[1] net137[0] ch1muxd0sel[7] ch1muxd0sel[6] ch1muxd0sel[5] ch1muxd0sel[4] ch1muxd0sel[3] ch1muxd0sel[2] ch1muxd0sel[1] ch1muxd0sel[0] o_nbias_a o_pbias_a ch1phdrven[7] ch1phdrven[6] ch1phdrven[5] ch1phdrven[4] ch1phdrven[3] ch1phdrven[2] ch1phdrven[1] ch1phdrven[0] i_phsdrvpwrsavon i_picapsel[2] i_picapsel[1] i_picapsel[0] o_piclk[8] o_piclk[7] o_piclk[6] o_piclk[5] o_piclk[9] pi0codesch1[7] pi0codesch1[6] pi0codesch1[5] pi0codesch1[4] pi0codesch1[3] 
+ pi0codesch1[2] pi0codesch1[1] pi0codesch1[0] pi1codesch1[7] pi1codesch1[6] pi1codesch1[5] pi1codesch1[4] pi1codesch1[3] pi1codesch1[2] pi1codesch1[1] pi1codesch1[0] pi2codesch1[7] pi2codesch1[6] pi2codesch1[5] pi2codesch1[4] pi2codesch1[3] pi2codesch1[2] pi2codesch1[1] pi2codesch1[0] pi3codesch1[7] pi3codesch1[6] pi3codesch1[5] pi3codesch1[4] pi3codesch1[3] pi3codesch1[2] pi3codesch1[1] pi3codesch1[0] pid0codesch1[7] pid0codesch1[6] pid0codesch1[5] pid0codesch1[4] pid0codesch1[3] pid0codesch1[2] pid0codesch1[1] pid0codesch1[0] ch1pienable[3] ch1pienable[2] ch1pienable[1] ch1pienable[0] ch1clken vccxx_lv ip10xddrdll_mc5piana 
xidllddr5pi_ch0 clkphch0[7] clkphch0[6] clkphch0[5] clkphch0[4] clkphch0[3] clkphch0[2] clkphch0[1] clkphch0[0] i_dismixer vss i_drvsel[2] i_drvsel[1] i_drvsel[0] ch0mux0sel[7] ch0mux0sel[6] ch0mux0sel[5] ch0mux0sel[4] ch0mux0sel[3] ch0mux0sel[2] ch0mux0sel[1] ch0mux0sel[0] ch0mux1sel[7] ch0mux1sel[6] ch0mux1sel[5] ch0mux1sel[4] ch0mux1sel[3] ch0mux1sel[2] ch0mux1sel[1] ch0mux1sel[0] ch0mux2sel[7] ch0mux2sel[6] ch0mux2sel[5] ch0mux2sel[4] ch0mux2sel[3] ch0mux2sel[2] ch0mux2sel[1] ch0mux2sel[0] ch0mux3sel[7] ch0mux3sel[6] ch0mux3sel[5] ch0mux3sel[4] ch0mux3sel[3] ch0mux3sel[2] ch0mux3sel[1] ch0mux3sel[0] ch0muxd0sel[7] ch0muxd0sel[6] ch0muxd0sel[5] ch0muxd0sel[4] ch0muxd0sel[3] ch0muxd0sel[2] ch0muxd0sel[1] ch0muxd0sel[0] o_nbias_a o_pbias_a ch0phdrven[7] ch0phdrven[6] ch0phdrven[5] ch0phdrven[4] ch0phdrven[3] ch0phdrven[2] ch0phdrven[1] ch0phdrven[0] i_phsdrvpwrsavon i_picapsel[2] i_picapsel[1] i_picapsel[0] o_piclk[3] o_piclk[2] o_piclk[1] o_piclk[0] o_piclk[4] pi0codesch0[7] pi0codesch0[6] pi0codesch0[5] 
+ pi0codesch0[4] pi0codesch0[3] pi0codesch0[2] pi0codesch0[1] pi0codesch0[0] pi1codesch0[7] pi1codesch0[6] pi1codesch0[5] pi1codesch0[4] pi1codesch0[3] pi1codesch0[2] pi1codesch0[1] pi1codesch0[0] pi2codesch0[7] pi2codesch0[6] pi2codesch0[5] pi2codesch0[4] pi2codesch0[3] pi2codesch0[2] pi2codesch0[1] pi2codesch0[0] pi3codesch0[7] pi3codesch0[6] pi3codesch0[5] pi3codesch0[4] pi3codesch0[3] pi3codesch0[2] pi3codesch0[1] pi3codesch0[0] pid0codesch0[7] pid0codesch0[6] pid0codesch0[5] pid0codesch0[4] pid0codesch0[3] pid0codesch0[2] pid0codesch0[1] pid0codesch0[0] ch0pienable[3] ch0pienable[2] ch0pienable[1] ch0pienable[0] ch0clken vccxx_lv ip10xddrdll_mc5piana 
xidllddrmdlltop ch0phdrven[7] ch0phdrven[6] ch0phdrven[5] ch0phdrven[4] ch0phdrven[3] ch0phdrven[2] ch0phdrven[1] ch0phdrven[0] ch1phdrven[7] ch1phdrven[6] ch1phdrven[5] ch1phdrven[4] ch1phdrven[3] ch1phdrven[2] ch1phdrven[1] ch1phdrven[0] o_ckfbdly o_ckfreerunref o_ckrefdly clkphch0[7] clkphch0[6] clkphch0[5] clkphch0[4] clkphch0[3] clkphch0[2] clkphch0[1] clkphch0[0] clkphch1[7] clkphch1[6] clkphch1[5] clkphch1[4] clkphch1[3] clkphch1[2] clkphch1[1] clkphch1[0] i_ddrdlloffvalue i_lockthresh[2] i_lockthresh[1] i_lockthresh[0] o_locktimerreset dnd vss i_drvsel[2] i_drvsel[1] i_drvsel[0] i_fbclken i_mdllen o_nbias_a i_resetd i_normalmode o_pbias_a i_dischen[2] i_dischen[1] i_dischen[0] i_resetd i_pfden i_2xclk i_refclken upd vccxx_lv i_vctrlhi_b ip10xddrdll_mcmdllana 
xidllddrpiupdate0 clkch0picvccioagd[3] clkch0picvccioagd[2] clkch0picvccioagd[1] i_dqsdrvenpilong[0] i_dqdrvenpi[0] i_rcvenpi[0] i_dllforcepiupdate i_pidften[0] piupdate0[3] piupdate0[2] piupdate0[1] vccxx_lv ip10xddrdll_mcpiupdate
xidllddrpiupdate1 clkch1picvccioagd[3] clkch1picvccioagd[2] clkch1picvccioagd[1] i_dqsdrvenpilong[1] i_dqdrvenpi[1] i_rcvenpi[1] i_dllforcepiupdate i_pidften[1] piupdate1[3] piupdate1[2] piupdate1[1] vccxx_lv ip10xddrdll_mcpiupdate
xi200 i_dftview1en i_digobs1sel[2] i_digobs1sel[1] i_digobs1sel[0] o_ckfbdly i_digobs1 clkch1picvccioagd[4] clkch1picvccioagd[3] clkch1picvccioagd[2] clkch1picvccioagd[1] clkch1picvccioagd[0] i_2xclk vccxx_lv o_digobs1 ip10xddrdll_mcdllviewslice
ximdllview[0] i_dftview0en i_digobs0sel[2] i_digobs0sel[1] i_digobs0sel[0] o_ckrefdly i_digobs0 clkch0picvccioagd[4] clkch0picvccioagd[3] clkch0picvccioagd[2] clkch0picvccioagd[1] clkch0picvccioagd[0] i_2xclk vccxx_lv o_digobs0 ip10xddrdll_mcdllviewslice
xicapnbias1[16] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[15] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[14] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[13] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[12] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[11] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[10] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[9] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[8] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[7] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[6] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[5] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[4] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[3] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[2] o_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[1] o_nbias_a ip10xddrdll_mcnbiascap1top
xich1ioag[4] o_piclk[9] clkch1picvccioagd[4] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich1ioag[3] o_piclk[8] clkch1picvccioagd[3] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich1ioag[2] o_piclk[7] clkch1picvccioagd[2] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich1ioag[1] o_piclk[6] clkch1picvccioagd[1] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich1ioag[0] o_piclk[5] clkch1picvccioagd[0] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich0ioag[4] o_piclk[4] clkch0picvccioagd[4] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich0ioag[3] o_piclk[3] clkch0picvccioagd[3] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich0ioag[2] o_piclk[2] clkch0picvccioagd[2] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich0ioag[1] o_piclk[1] clkch0picvccioagd[1] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
xich0ioag[0] o_piclk[0] clkch0picvccioagd[0] vccxx_lv ip10xddrdll_buf_4dgnomsp24x_nonadt 
.ends ip10xddrdll_mcdll10pi
** end of subcircuit definition.
.end

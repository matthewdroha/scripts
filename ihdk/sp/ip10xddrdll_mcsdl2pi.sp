** SRCSTATUS: PACKAGE=Production,RUN_MODE=Flat,ERROR_COUNT=0,WARNING_COUNT=1,WAIVERS_COUNT=0,USERID=cvphan,DATE_RUN=Aug 27 19:34:43 2014,SETUP_VER=DTS_14ww29 3,SRC_VER=p14ww33,SIM_VER=p1274 0_14ww31 5,COLL_VER=p1274 0_14ww32 2
** SRCWAIVERS: NONE
** generated for: hspiceD
** generated on: Sep  3 15:07:13 2014
** design library name: ip10xddrdll_ihdk_sch
** design cell name: ip10xddrdll_mcsdl2pi
** design view name: schematic
.global vss

************** Start Of Includes ******************
*******************************************************
* /p/hdk/cad/process/p1274.0_sim/p1274.0_14ww35.2/erc/erc_global_corners_file.hsp:tttt
*******************************************************
 
 
************** End Of Includes ******************
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
** cell name: ip10xddrdll_mcsmuxstage
** view name: schematic
.subckt ip10xddrdll_mcsmuxstage clkmxph_b[1] clkmxph_b[0] clkph0 mx0sel mx1sel vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsmuxstage schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsmuxstage/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsmuxstage symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsmuxstage/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 7066 
* Version: 1.2 
* INOUT:  clkmxph_b[0]  clkmxph_b[1] 
* INPUT:  vccxx_lv  mx0sel  mx1sel 
*+ clkph0 
* ----------------------------
*.PININFO  clkmxph_b[0]:B  clkmxph_b[1]:B 
*.PININFO  vccxx_lv:I  mx0sel:I  mx1sel:I 
*.PININFO  clkph0:I 
* ----------------------------

ximux0 clkph0 clkmxph_b[0] mx0sel vccxx_lv ip10xddrdll_mcmuxcell
xi0 clkph0 clkmxph_b[1] mx1sel vccxx_lv ip10xddrdll_mcmuxcell
.ends ip10xddrdll_mcsmuxstage
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcsmux
** view name: schematic
.subckt ip10xddrdll_mcsmux clkmxph0_b[1] clkmxph0_b[0] clkmxph1_b[1] clkmxph1_b[0] clkph[8] clkph[7] clkph[6] clkph[5] clkph[4] clkph[3] clkph[2] clkph[1] clkph[0] mux0sel[8] mux0sel[7] mux0sel[6] mux0sel[5] mux0sel[4] mux0sel[3] mux0sel[2] mux0sel[1] mux0sel[0] mux1sel[8] mux1sel[7] mux1sel[6] mux1sel[5] mux1sel[4] mux1sel[3] mux1sel[2] mux1sel[1] mux1sel[0] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsmux schematic 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsmux/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsmux symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsmux/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 46530 
* Version: 1.2 
* INPUT:  clkph[0]  clkph[1]  clkph[2] 
*+ clkph[3]  clkph[4]  clkph[5]  clkph[6] 
*+ clkph[7]  clkph[8]  mux0sel[0]  mux0sel[1] 
*+ mux0sel[2]  mux0sel[3]  mux0sel[4]  mux0sel[5] 
*+ mux0sel[6]  mux0sel[7]  mux0sel[8]  mux1sel[0] 
*+ mux1sel[1]  mux1sel[2]  mux1sel[3]  mux1sel[4] 
*+ mux1sel[5]  mux1sel[6]  mux1sel[7]  mux1sel[8] 
*+ vccxx_lv 
* OUTPUT:  clkmxph0_b[0]  clkmxph0_b[1]  clkmxph1_b[0] 
*+ clkmxph1_b[1] 
* ----------------------------
*.PININFO  clkph[0]:I  clkph[1]:I  clkph[2]:I 
*.PININFO  clkph[3]:I  clkph[4]:I  clkph[5]:I  clkph[6]:I 
*.PININFO  clkph[7]:I  clkph[8]:I  mux0sel[0]:I  mux0sel[1]:I 
*.PININFO  mux0sel[2]:I  mux0sel[3]:I  mux0sel[4]:I  mux0sel[5]:I 
*.PININFO  mux0sel[6]:I  mux0sel[7]:I  mux0sel[8]:I  mux1sel[0]:I 
*.PININFO  mux1sel[1]:I  mux1sel[2]:I  mux1sel[3]:I  mux1sel[4]:I 
*.PININFO  mux1sel[5]:I  mux1sel[6]:I  mux1sel[7]:I  mux1sel[8]:I 
*.PININFO  vccxx_lv:I 
*.PININFO  clkmxph0_b[0]:O  clkmxph0_b[1]:O  clkmxph1_b[0]:O 
*.PININFO  clkmxph1_b[1]:O 
* ----------------------------

ximuxcell10 clkmxph1_b[1] clkmxph1_b[0] clkph[5] mux0sel[5] mux1sel[5] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell6 clkmxph1_b[1] clkmxph1_b[0] clkph[3] mux0sel[3] mux1sel[3] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell2 clkmxph1_b[1] clkmxph1_b[0] clkph[1] mux0sel[1] mux1sel[1] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell14 clkmxph1_b[1] clkmxph1_b[0] clkph[7] mux0sel[7] mux1sel[7] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell8 clkmxph0_b[1] clkmxph0_b[0] clkph[4] mux0sel[4] mux1sel[4] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell4 clkmxph0_b[1] clkmxph0_b[0] clkph[2] mux0sel[2] mux1sel[2] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell0 clkmxph0_b[1] clkmxph0_b[0] clkph[0] mux0sel[0] mux1sel[0] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell12 clkmxph0_b[1] clkmxph0_b[0] clkph[6] mux0sel[6] mux1sel[6] vccxx_lv ip10xddrdll_mcsmuxstage
ximuxcell16 clkmxph0_b[1] clkmxph0_b[0] clkph[8] mux0sel[8] mux1sel[8] vccxx_lv ip10xddrdll_mcsmuxstage
.ends ip10xddrdll_mcsmux
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
** cell name: ip10xddrdll_mcspitop
** view name: schematic
.subckt ip10xddrdll_mcspitop clkph0_b clkph1_b drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picb[2] picb[1] picb[0] piclkout pienable pisel[7] pisel[6] pisel[5] pisel[4] pisel[3] pisel[2] pisel[1] pisel[0] rcvenable vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcspitop schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcspitop/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcspitop symbol 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcspitop/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 68164 
* Version: 1.3 
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
.ends ip10xddrdll_mcspitop
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mc2piana
** view name: schematic
.subckt ip10xddrdll_mc2piana clkinqh[8] clkinqh[7] clkinqh[6] clkinqh[5] clkinqh[4] clkinqh[3] clkinqh[2] clkinqh[1] clkinqh[0] clkpiout[0] clkpiout[1] drvsel[3] drvsel[2] drvsel[1] drvsel[0] mux0selqnnnh[9] mux0selqnnnh[8] mux0selqnnnh[7] mux0selqnnnh[6] mux0selqnnnh[5] mux0selqnnnh[4] mux0selqnnnh[3] mux0selqnnnh[2] mux0selqnnnh[1] mux0selqnnnh[0] mux1selqnnnh[9] mux1selqnnnh[8] mux1selqnnnh[7] mux1selqnnnh[6] mux1selqnnnh[5] mux1selqnnnh[4] mux1selqnnnh[3] mux1selqnnnh[2] mux1selqnnnh[1] mux1selqnnnh[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] picodes0qnnnh[7] picodes0qnnnh[6] picodes0qnnnh[5] picodes0qnnnh[4] picodes0qnnnh[3] picodes0qnnnh[2] picodes0qnnnh[1] picodes0qnnnh[0] picodes1qnnnh[7] picodes1qnnnh[6] picodes1qnnnh[5] picodes1qnnnh[4] picodes1qnnnh[3] picodes1qnnnh[2] picodes1qnnnh[1] picodes1qnnnh[0] pienqnnnh[1] pienqnnnh[0] rcvenqnnnh vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc2piana schematic 1.9 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc2piana/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mc2piana symbol 1.5 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mc2piana/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 74929 
* Version: 1.5 
* INPUT:  clkinqh[0]  clkinqh[1]  clkinqh[2] 
*+ clkinqh[3]  clkinqh[4]  clkinqh[5]  clkinqh[6] 
*+ clkinqh[7]  clkinqh[8]  nbias_a  pienqnnnh[0] 
*+ pienqnnnh[1]  picodes1qnnnh[0]  picodes1qnnnh[1]  picodes1qnnnh[2] 
*+ picodes1qnnnh[3]  picodes1qnnnh[4]  picodes1qnnnh[5]  picodes1qnnnh[6] 
*+ picodes1qnnnh[7]  mux1selqnnnh[0]  mux1selqnnnh[1]  mux1selqnnnh[2] 
*+ mux1selqnnnh[3]  mux1selqnnnh[4]  mux1selqnnnh[5]  mux1selqnnnh[6] 
*+ mux1selqnnnh[7]  mux1selqnnnh[8]  mux1selqnnnh[9]  pbias_a 
*+ drvsel[0]  drvsel[1]  drvsel[2]  drvsel[3] 
*+ mux0selqnnnh[0]  mux0selqnnnh[1]  mux0selqnnnh[2]  mux0selqnnnh[3] 
*+ mux0selqnnnh[4]  mux0selqnnnh[5]  mux0selqnnnh[6]  mux0selqnnnh[7] 
*+ mux0selqnnnh[8]  mux0selqnnnh[9]  picodes0qnnnh[0]  picodes0qnnnh[1] 
*+ picodes0qnnnh[2]  picodes0qnnnh[3]  picodes0qnnnh[4]  picodes0qnnnh[5] 
*+ picodes0qnnnh[6]  picodes0qnnnh[7]  vccxx_lv  rcvenqnnnh 
*+ picbqnnnh[0]  picbqnnnh[1]  picbqnnnh[2] 
* OUTPUT:  clkpiout[1]  clkpiout[0] 
* ----------------------------
*.PININFO  clkinqh[0]:I  clkinqh[1]:I  clkinqh[2]:I 
*.PININFO  clkinqh[3]:I  clkinqh[4]:I  clkinqh[5]:I  clkinqh[6]:I 
*.PININFO  clkinqh[7]:I  clkinqh[8]:I  nbias_a:I  pienqnnnh[0]:I 
*.PININFO  pienqnnnh[1]:I  picodes1qnnnh[0]:I  picodes1qnnnh[1]:I  picodes1qnnnh[2]:I 
*.PININFO  picodes1qnnnh[3]:I  picodes1qnnnh[4]:I  picodes1qnnnh[5]:I  picodes1qnnnh[6]:I 
*.PININFO  picodes1qnnnh[7]:I  mux1selqnnnh[0]:I  mux1selqnnnh[1]:I  mux1selqnnnh[2]:I 
*.PININFO  mux1selqnnnh[3]:I  mux1selqnnnh[4]:I  mux1selqnnnh[5]:I  mux1selqnnnh[6]:I 
*.PININFO  mux1selqnnnh[7]:I  mux1selqnnnh[8]:I  mux1selqnnnh[9]:I  pbias_a:I 
*.PININFO  drvsel[0]:I  drvsel[1]:I  drvsel[2]:I  drvsel[3]:I 
*.PININFO  mux0selqnnnh[0]:I  mux0selqnnnh[1]:I  mux0selqnnnh[2]:I  mux0selqnnnh[3]:I 
*.PININFO  mux0selqnnnh[4]:I  mux0selqnnnh[5]:I  mux0selqnnnh[6]:I  mux0selqnnnh[7]:I 
*.PININFO  mux0selqnnnh[8]:I  mux0selqnnnh[9]:I  picodes0qnnnh[0]:I  picodes0qnnnh[1]:I 
*.PININFO  picodes0qnnnh[2]:I  picodes0qnnnh[3]:I  picodes0qnnnh[4]:I  picodes0qnnnh[5]:I 
*.PININFO  picodes0qnnnh[6]:I  picodes0qnnnh[7]:I  vccxx_lv:I  rcvenqnnnh:I 
*.PININFO  picbqnnnh[0]:I  picbqnnnh[1]:I  picbqnnnh[2]:I 
*.PININFO  clkpiout[1]:O  clkpiout[0]:O 
* ----------------------------

xidllddrsmux clkpiph0_b[1] clkpiph0_b[0] clkpiph1_b[1] clkpiph1_b[0] clkinqh[8] clkinqh[7] clkinqh[6] clkinqh[5] clkinqh[4] clkinqh[3] clkinqh[2] clkinqh[1] clkinqh[0] mux0selqnnnh[8] mux0selqnnnh[7] mux0selqnnnh[6] mux0selqnnnh[5] mux0selqnnnh[4] mux0selqnnnh[3] mux0selqnnnh[2] mux0selqnnnh[1] mux0selqnnnh[0] mux1selqnnnh[8] mux1selqnnnh[7] mux1selqnnnh[6] mux1selqnnnh[5] mux1selqnnnh[4] mux1selqnnnh[3] mux1selqnnnh[2] mux1selqnnnh[1] mux1selqnnnh[0] vccxx_lv ip10xddrdll_mcsmux
xipi[0] clkpiph0_b[0] clkpiph1_b[0] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] clkpiout[0] pienqnnnh[0] picodes0qnnnh[7] picodes0qnnnh[6] picodes0qnnnh[5] picodes0qnnnh[4] picodes0qnnnh[3] picodes0qnnnh[2] picodes0qnnnh[1] picodes0qnnnh[0] rcvenqnnnh vccxx_lv ip10xddrdll_mcspitop
xipi[1] clkpiph0_b[1] clkpiph1_b[1] drvsel[3] drvsel[2] drvsel[1] drvsel[0] nbias_a pbias_a picbqnnnh[2] picbqnnnh[1] picbqnnnh[0] clkpiout[1] pienqnnnh[1] picodes1qnnnh[7] picodes1qnnnh[6] picodes1qnnnh[5] picodes1qnnnh[4] picodes1qnnnh[3] picodes1qnnnh[2] picodes1qnnnh[1] picodes1qnnnh[0] rcvenqnnnh vccxx_lv ip10xddrdll_mcspitop
.ends ip10xddrdll_mc2piana
** end of subcircuit definition.

** library name: e3modules
** cell name: e3yino000af
** view name: schematic
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0bfn000al1n06x5
** view name: schematic
.subckt ec0bfn000al1n06x5 a o vcc
* ----------------------------
* CELLLOG ec0basic nil ec0bfn000al1n06x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n06x5/schematic 
* CELLLOG ec0basic nil ec0bfn000al1n06x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n06x5/symbol 
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
mg101.qpa o n1 vcc vcc psvt l=20e-9 w=204e-9 m=1
mg101.qna o n1 vss vss nsvt l=20e-9 w=204e-9 m=1
mqn1 n1 a vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0bfn000al1n06x5
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
** cell name: ip10xddrdll_mcsdlbwctrl
** view name: schematic
.subckt ip10xddrdll_mcsdlbwctrl bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] en enb nb0en nbw[3] nbw[2] nbw[1] nbw[0] pb0enb pbw[3] pbw[2] pbw[1] pbw[0] segen vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdlbwctrl schematic 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdlbwctrl/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdlbwctrl symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdlbwctrl/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 93570 
* Version: 1.2 
* INPUT:  segen  vccxx_lv  bwctrl[0] 
*+ bwctrl[1]  bwctrl[2]  bwctrl[3] 
* OUTPUT:  en  enb  nb0en 
*+ pbw[0]  pbw[1]  pbw[2]  pbw[3] 
*+ nbw[0]  nbw[1]  nbw[2]  nbw[3] 
*+ pb0enb 
* ----------------------------
*.PININFO  segen:I  vccxx_lv:I  bwctrl[0]:I 
*.PININFO  bwctrl[1]:I  bwctrl[2]:I  bwctrl[3]:I 
*.PININFO  en:O  enb:O  nb0en:O 
*.PININFO  pbw[0]:O  pbw[1]:O  pbw[2]:O  pbw[3]:O 
*.PININFO  nbw[0]:O  nbw[1]:O  nbw[2]:O  nbw[3]:O 
*.PININFO  pb0enb:O 
* ----------------------------

xinv02 enb en vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv03 segen enb vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv00 segen pb0enb vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv01 pb0enb nb0en vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[3] pbw[3] nbw[3] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[2] pbw[2] nbw[2] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[1] pbw[1] nbw[1] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinv1[0] pbw[0] nbw[0] vccxx_lv ip10xddrdll_inv_8dgsvtsp24x_nonadt
xinand[3] segen bwctrl[3] pbw[3] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand[2] segen bwctrl[2] pbw[2] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand[1] segen bwctrl[1] pbw[1] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
xinand[0] segen bwctrl[0] pbw[0] vccxx_lv ip10xddrdll_nand2_4dgsvtsp24x_nonadt
.ends ip10xddrdll_mcsdlbwctrl
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
** cell name: ip10xddrdll_mcsdllana
** view name: schematic
.subckt ip10xddrdll_mcsdllana bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] ch0clkph[8] ch0clkph[7] ch0clkph[6] ch0clkph[5] ch0clkph[4] ch0clkph[3] ch0clkph[2] ch0clkph[1] ch0clkph[0] ch0drven ch1clkqh ddrrcvenpreqnnnh dllparkvalueqnnnh dqsiqnnnh nbias_a pbias_a sega_enqnnnh segc_enqnnnh sege_enqnnnh segg_enqnnnh vccxx_lv 
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdllana schematic 1.10 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdllana/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdllana symbol 1.6 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdllana/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 377969 
* Version: 1.6 
* INPUT:  bwctrl[0]  bwctrl[1]  bwctrl[2] 
*+ bwctrl[3]  sega_enqnnnh  sege_enqnnnh  segc_enqnnnh 
*+ nbias_a  pbias_a  ch0drven  segg_enqnnnh 
*+ ddrrcvenpreqnnnh  vccxx_lv  dqsiqnnnh  dllparkvalueqnnnh 
* OUTPUT:  ch0clkph[0]  ch0clkph[1]  ch0clkph[2] 
*+ ch0clkph[3]  ch0clkph[4]  ch0clkph[5]  ch0clkph[6] 
*+ ch0clkph[7]  ch0clkph[8]  ch1clkqh 
* ----------------------------
*.PININFO  bwctrl[0]:I  bwctrl[1]:I  bwctrl[2]:I 
*.PININFO  bwctrl[3]:I  sega_enqnnnh:I  sege_enqnnnh:I  segc_enqnnnh:I 
*.PININFO  nbias_a:I  pbias_a:I  ch0drven:I  segg_enqnnnh:I 
*.PININFO  ddrrcvenpreqnnnh:I  vccxx_lv:I  dqsiqnnnh:I  dllparkvalueqnnnh:I 
*.PININFO  ch0clkph[0]:O  ch0clkph[1]:O  ch0clkph[2]:O 
*.PININFO  ch0clkph[3]:O  ch0clkph[4]:O  ch0clkph[5]:O  ch0clkph[6]:O 
*.PININFO  ch0clkph[7]:O  ch0clkph[8]:O  ch1clkqh:O 
* ----------------------------

xidlylinefront dqsiqnnnh net89 ddrrcvenpreqnnnh a_en a_enb nb0en nbias_a nbw[3] nbw[2] nbw[1] nbw[0] park_b pb0enb pbias_a pbw[3] pbw[2] pbw[1] pbw[0] taprefclk vccxx_lv ip10xddrdll_mcmdlyfrontbwcb
xibwctrl2 bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] e_en e_enb nb0een nbwe[3] nbwe[2] nbwe[1] nbwe[0] pb0eenb pbwe[3] pbwe[2] pbwe[1] pbwe[0] sege_enqnnnh vccxx_lv ip10xddrdll_mcsdlbwctrl
xibwctrl1 bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] c_en c_enb nb0enc nbwc[3] nbwc[2] nbwc[1] nbwc[0] pb0enbc pbwc[3] pbwc[2] pbwc[1] pbwc[0] segc_enqnnnh vccxx_lv ip10xddrdll_mcsdlbwctrl
xibwctrl3 bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] g_en g_enb nb0genc nbwg[3] nbwg[2] nbwg[1] nbwg[0] pb0genb pbwg[3] pbwg[2] pbwg[1] pbwg[0] segg_enqnnnh vccxx_lv ip10xddrdll_mcsdlbwctrl
xibwctrl0 bwctrl[3] bwctrl[2] bwctrl[1] bwctrl[0] a_en a_enb nb0en nbw[3] nbw[2] nbw[1] nbw[0] pb0enb pbw[3] pbw[2] pbw[1] pbw[0] sega_enqnnnh vccxx_lv ip10xddrdll_mcsdlbwctrl
xiparkbu4 park_d park_d1 vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf5 park_bd1 park_bd2 vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf1 park_b park_bd vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xipark_bbuf dllparkvalueqnnnh park_b vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf3 park_bd park_bd1 vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf6 park_d1 park_d2 vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf2 park park_d vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xiparkbuf parkinv park vccxx_lv ip10xddrdll_buf_4dgsvtsp24x_nonadt
xinv1 dllparkvalueqnnnh parkinv vccxx_lv ip10xddrdll_inv_4dgsvtsp24x_nonadt
xdelaycell8 ch0clkph[8] ch0drven ch1clkph[8] vss g_en g_enb nb0genc nbias_a nbwg[0] nbwg[1] nbwg[2] nbwg[3] park_d2 park_bd2 pb0genb pbias_a pbwg[0] pbwg[1] pbwg[2] pbwg[3] tap8 tap9 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell7 ch0clkph[7] ch0drven ch1clkph[7] vss e_en e_enb nb0een nbias_a nbwe[0] nbwe[1] nbwe[2] nbwe[3] park_d2 park_bd2 pb0eenb pbias_a pbwe[0] pbwe[1] pbwe[2] pbwe[3] tap7 tap8 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell0 ch0clkph[0] ch0drven ch1clkqh ch0drven a_en a_enb nb0en nbias_a nbw[3] nbw[2] nbw[1] nbw[0] park park_b pb0enb pbias_a pbw[3] pbw[2] pbw[1] pbw[0] taprefclk tap1 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell1 ch0clkph[1] ch0drven ch1clkph[1] vss a_en a_enb nb0en nbias_a nbw[3] nbw[2] nbw[1] nbw[0] park park_b pb0enb pbias_a pbw[3] pbw[2] pbw[1] pbw[0] tap1 tap2 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell2 ch0clkph[2] ch0drven ch1clkph[2] vss a_en a_enb nb0en nbias_a nbw[3] nbw[2] nbw[1] nbw[0] park_d park_bd pb0enb pbias_a pbw[3] pbw[2] pbw[1] pbw[0] tap2 tap3 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell3 ch0clkph[3] ch0drven ch1clkph[3] vss a_en a_enb nb0en nbias_a nbw[3] nbw[2] nbw[1] nbw[0] park_d park_bd pb0enb pbias_a pbw[3] pbw[2] pbw[1] pbw[0] tap3 tap4 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell4 ch0clkph[4] ch0drven ch1clkph[4] vss c_en c_enb nb0enc nbias_a nbwc[0] nbwc[1] nbwc[2] nbwc[3] park_d1 park_bd1 pb0enbc pbias_a pbwc[0] pbwc[1] pbwc[2] pbwc[3] tap4 tap5 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell5 ch0clkph[5] ch0drven ch1clkph[5] vss c_en c_enb nb0enc nbias_a nbwc[0] nbwc[1] nbwc[2] nbwc[3] park_d1 park_bd1 pb0enbc pbias_a pbwc[0] pbwc[1] pbwc[2] pbwc[3] tap5 tap6 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xdelaycell6 ch0clkph[6] ch0drven ch1clkph[6] vss e_en e_enb nb0een nbias_a nbwe[0] nbwe[1] nbwe[2] nbwe[3] park_d2 park_bd2 pb0eenb pbias_a pbwe[0] pbwe[1] pbwe[2] pbwe[3] tap6 tap7 vccxx_lv ip10xddrdll_mcmdlystagebwcb
xifbclkbuff net98 g_en g_enb nb0genc nbias_a nbwg[0] nbwg[1] nbwg[2] nbwg[3] pb0genb pbias_a pbwg[0] pbwg[1] pbwg[2] pbwg[3] tap9 vccxx_lv ip10xddrdll_mcmdlyendstagedummy
.ends ip10xddrdll_mcsdllana
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02al1n05x5
** view name: schematic
.subckt ec0nand02al1n05x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n05x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n05x5/schematic 
* CELLLOG ec0basic nil ec0nand02al1n05x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n05x5/symbol 
* TAG: schematic 
* COUNTER: 43378 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=136e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=136e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=170e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=170e-9 m=1
.ends ec0nand02al1n05x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02al1n03x7
** view name: schematic
.subckt ec0nand02al1n03x7 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n03x7 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n03x7/schematic 
* CELLLOG ec0basic nil ec0nand02al1n03x7 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n03x7/symbol 
* TAG: schematic 
* COUNTER: 47958 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=102e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=102e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=102e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=102e-9 m=1
.ends ec0nand02al1n03x7
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcmdeccell
** view name: schematic
.subckt ip10xddrdll_mcmdeccell banksel mxlsb prevsel sel0 sel1 vccxx
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdeccell schematic 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdeccell/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcmdeccell symbol 1.1 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcmdeccell/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 8570 
* Version: 1.1 
* INPUT:  mxlsb  prevsel  vccxx 
*+ banksel 
* OUTPUT:  sel1  sel0 
* ----------------------------
*.PININFO  mxlsb:I  prevsel:I  vccxx:I 
*.PININFO  banksel:I 
*.PININFO  sel1:O  sel0:O 
* ----------------------------

xnand2 prop0_b sel0_b sel0 vccxx ec0nand02al1n05x5
xnand4 sel0_b sel1_b sel1 vccxx ec0nand02al1n05x5
xnand0 prevsel mxlsb prop0_b vccxx ec0nand02al1n03x7
xnand1 banksel lsb_b sel0_b vccxx ec0nand02al1n03x7
xnand3 banksel mxlsb sel1_b vccxx ec0nand02al1n03x7
xinv0 mxlsb lsb_b vccxx ec0inv000al1n02x5
.ends ip10xddrdll_mcmdeccell
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcsdecdrv
** view name: schematic
.subckt ip10xddrdll_mcsdecdrv mx0banksel mx0lsb mx0prevsel mx0sel[1] mx0sel[0] mx1banksel mx1lsb mx1prevsel mx1sel[1] mx1sel[0] vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdecdrv schematic 1.3 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdecdrv/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdecdrv symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdecdrv/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 11233 
* Version: 1.2 
* INPUT:  vccxx_lv  mx0banksel  mx0lsb 
*+ mx0prevsel  mx1banksel  mx1prevsel  mx1lsb 
* OUTPUT:  mx0sel[0]  mx0sel[1]  mx1sel[0] 
*+ mx1sel[1] 
* ----------------------------
*.PININFO  vccxx_lv:I  mx0banksel:I  mx0lsb:I 
*.PININFO  mx0prevsel:I  mx1banksel:I  mx1prevsel:I  mx1lsb:I 
*.PININFO  mx0sel[0]:O  mx0sel[1]:O  mx1sel[0]:O 
*.PININFO  mx1sel[1]:O 
* ----------------------------

xmx0drv mx0banksel mx0lsb mx0prevsel mx0sel[0] mx0sel[1] vccxx_lv ip10xddrdll_mcmdeccell
xmx1drv mx1banksel mx1lsb mx1prevsel mx1sel[0] mx1sel[1] vccxx_lv ip10xddrdll_mcmdeccell
.ends ip10xddrdll_mcsdecdrv
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
** cell name: ip10xddrdll_mcsdecoder
** view name: schematic
.subckt ip10xddrdll_mcsdecoder mux0sel[9] mux0sel[8] mux0sel[7] mux0sel[6] mux0sel[5] mux0sel[4] mux0sel[3] mux0sel[2] mux0sel[1] mux0sel[0] mux1sel[9] mux1sel[8] mux1sel[7] mux1sel[6] mux1sel[5] mux1sel[4] mux1sel[3] mux1sel[2] mux1sel[1] mux1sel[0] pi0code[5] pi0code[4] pi0code[3] pi0code[2] pi0code[1] pi0code[0] pi0enable pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] pi1code[5] pi1code[4] pi1code[3] pi1code[2] pi1code[1] pi1code[0] pi1enable pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] pien vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdecoder schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdecoder/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdecoder symbol 1.7 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdecoder/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 96480 
* Version: 1.7 
* INPUT:  vccxx_lv  pien  pi0code[0] 
*+ pi0code[1]  pi0code[2]  pi0code[3]  pi0code[4] 
*+ pi0code[5]  pi1code[0]  pi1code[1]  pi1code[2] 
*+ pi1code[3]  pi1code[4]  pi1code[5] 
* OUTPUT:  mux0sel[0]  mux0sel[1]  mux0sel[2] 
*+ mux0sel[3]  mux0sel[4]  mux0sel[5]  mux0sel[6] 
*+ mux0sel[7]  mux0sel[8]  mux0sel[9]  pi0thcode[0] 
*+ pi0thcode[1]  pi0thcode[2]  pi0thcode[3]  pi0thcode[4] 
*+ pi0thcode[5]  pi0thcode[6]  pi0thcode[7]  mux1sel[0] 
*+ mux1sel[1]  mux1sel[2]  mux1sel[3]  mux1sel[4] 
*+ mux1sel[5]  mux1sel[6]  mux1sel[7]  mux1sel[8] 
*+ mux1sel[9]  pi1thcode[0]  pi1thcode[1]  pi1thcode[2] 
*+ pi1thcode[3]  pi1thcode[4]  pi1thcode[5]  pi1thcode[6] 
*+ pi1thcode[7]  pi0enable  pi1enable 
* ----------------------------
*.PININFO  vccxx_lv:I  pien:I  pi0code[0]:I 
*.PININFO  pi0code[1]:I  pi0code[2]:I  pi0code[3]:I  pi0code[4]:I 
*.PININFO  pi0code[5]:I  pi1code[0]:I  pi1code[1]:I  pi1code[2]:I 
*.PININFO  pi1code[3]:I  pi1code[4]:I  pi1code[5]:I 
*.PININFO  mux0sel[0]:O  mux0sel[1]:O  mux0sel[2]:O 
*.PININFO  mux0sel[3]:O  mux0sel[4]:O  mux0sel[5]:O  mux0sel[6]:O 
*.PININFO  mux0sel[7]:O  mux0sel[8]:O  mux0sel[9]:O  pi0thcode[0]:O 
*.PININFO  pi0thcode[1]:O  pi0thcode[2]:O  pi0thcode[3]:O  pi0thcode[4]:O 
*.PININFO  pi0thcode[5]:O  pi0thcode[6]:O  pi0thcode[7]:O  mux1sel[0]:O 
*.PININFO  mux1sel[1]:O  mux1sel[2]:O  mux1sel[3]:O  mux1sel[4]:O 
*.PININFO  mux1sel[5]:O  mux1sel[6]:O  mux1sel[7]:O  mux1sel[8]:O 
*.PININFO  mux1sel[9]:O  pi1thcode[0]:O  pi1thcode[1]:O  pi1thcode[2]:O 
*.PININFO  pi1thcode[3]:O  pi1thcode[4]:O  pi1thcode[5]:O  pi1thcode[6]:O 
*.PININFO  pi1thcode[7]:O  pi0enable:O  pi1enable:O 
* ----------------------------

xidrv2 mx0banksel[2] mx0lsb mx0banksel[1] mux0sel[5] mux0sel[4] mx1banksel[2] mx1lsb mx1banksel[1] mux1sel[5] mux1sel[4] vccxx_lv ip10xddrdll_mcsdecdrv
xidrv3 mx0banksel[3] mx0lsb mx0banksel[2] mux0sel[7] mux0sel[6] mx1banksel[3] mx1lsb mx1banksel[2] mux1sel[7] mux1sel[6] vccxx_lv ip10xddrdll_mcsdecdrv
xidrv1 mx0banksel[1] mx0lsb mx0banksel[0] mux0sel[3] mux0sel[2] mx1banksel[1] mx1lsb mx1banksel[0] mux1sel[3] mux1sel[2] vccxx_lv ip10xddrdll_mcsdecdrv
xidrv0 mx0banksel[0] mx0lsb vss mux0sel[1] mux0sel[0] mx1banksel[0] mx1lsb vss mux1sel[1] mux1sel[0] vccxx_lv ip10xddrdll_mcsdecdrv
xidrv4 vss mx0lsb mx0banksel[3] mux0sel[9] mux0sel[8] vss mx1lsb mx1banksel[3] mux1sel[9] mux1sel[8] vccxx_lv ip10xddrdll_mcsdecdrv
xidec0 mx0banksel[3] mx0banksel[2] mx0banksel[1] mx0banksel[0] mx0lsb pi0code[5] pi0code[4] pi0code[3] pi0code[2] pi0code[1] pi0code[0] pien pi0enable pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] vss vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
xidec1 mx1banksel[3] mx1banksel[2] mx1banksel[1] mx1banksel[0] mx1lsb pi1code[5] pi1code[4] pi1code[3] pi1code[2] pi1code[1] pi1code[0] pien pi1enable pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] vss vccxx_lv ip10xddrdll_mcmpredec_x4pi_skl
.ends ip10xddrdll_mcsdecoder
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nor002al1n04x5
** view name: schematic
.subckt ec0nor002al1n04x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nor002al1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor002al1n04x5/schematic 
* CELLLOG ec0basic nil ec0nor002al1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nor002al1n04x5/symbol 
* TAG: schematic 
* COUNTER: 42008 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp1 o1 a n1 vcc psvt l=20e-9 w=170e-9 m=1
mqp2 n1 b vcc vcc psvt l=20e-9 w=170e-9 m=1
mqn1 o1 a vss vss nsvt l=20e-9 w=136e-9 m=1
mqn2 o1 b vss vss nsvt l=20e-9 w=136e-9 m=1
.ends ec0nor002al1n04x5
** end of subcircuit definition.

** library name: e9prim
** cell name: e9yna2ft
** view name: schematic
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0fan003al1n02x5
** view name: schematic
.subckt ec0fan003al1n02x5 clk d o rb vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0fan003al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fan003al1n02x5/schematic 
* CELLLOG ec0sequential nil ec0fan003al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fan003al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 182158 
* Version: Unmanaged 
* INPUT:  clk  d  rb 
*+ vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  clk:I  d:I  rb:I 
*.PININFO  vcc:I 
*.PININFO  o:O 
* ----------------------------

mgd1.qnd gd1.n2 nk4 vss vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qnck nk3 nc8 gd1.n2 vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qpd gd1.n1 nk4 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1.qpckb nk3 nc1 gd1.n1 vcc psvt l=20e-9 w=68e-9 m=1
mgtd2.qns nk5 clk nk4 vss nsvt l=20e-9 w=34e-9 m=1
mgtd2.qpsb nk5 nc1 nk4 vcc psvt l=20e-9 w=68e-9 m=1
mgtd2k.qns nk5 nc1 nk9 vss nsvt l=20e-9 w=34e-9 m=1
mgtd2k.qpsb nk5 clk nk9 vcc psvt l=20e-9 w=68e-9 m=1
mgtd1.qns nk3 nc1 d vss nsvt l=20e-9 w=34e-9 m=1
mgtd1.qpsb nk3 nc8 d vcc psvt l=20e-9 w=68e-9 m=1
mgclkdd.qna nc8 nc1 vss vss n l=20e-9 w=34e-9 m=1
mgclkdd.qpa nc8 nc1 vcc vcc p l=20e-9 w=68e-9 m=1
mg99.qna nk6 nk5 vss vss nsvt l=20e-9 w=34e-9 m=1
mg99.qpa nk6 nk5 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgclkn.qna nc1 clk vss vss n l=20e-9 w=68e-9 m=1
mgclkn.qpa nc1 clk vcc vcc p l=20e-9 w=68e-9 m=1
mg101.qpa o nk5 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qna o nk5 vss vss nsvt l=20e-9 w=68e-9 m=1
mgnaf.qpa nk9 nk6 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgnaf.qpb nk9 rb vcc vcc psvt l=20e-9 w=68e-9 m=1
mgnaf.qnb gnaf.n1 rb vss vss nsvt l=20e-9 w=68e-9 m=1
mgnaf.qna nk9 nk6 gnaf.n1 vss nsvt l=20e-9 w=68e-9 m=1
mgd1n.qpa nk4 nk3 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1n.qpb nk4 rb vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1n.qnb gd1n.n1 rb vss vss nsvt l=20e-9 w=68e-9 m=1
mgd1n.qna nk4 nk3 gd1n.n1 vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0fan003al1n02x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0bfm201al1n02x5
** view name: schematic
.subckt ec0bfm201al1n02x5 a o vcc
* ----------------------------
* CELLLOG ec0basic nil ec0bfm201al1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfm201al1n02x5/schematic 
* CELLLOG ec0basic nil ec0bfm201al1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfm201al1n02x5/symbol 
* TAG: schematic 
* COUNTER: 52462 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mqp2 n1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp1 n2 a n1 vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o n2 vcc vcc psvt l=20e-9 w=68e-9 m=1
mg101.qna o n2 vss vss nsvt l=20e-9 w=68e-9 m=1
mqn2 n0 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn1 n2 a n0 vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0bfm201al1n02x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0nand02al1n12x5
** view name: schematic
.subckt ec0nand02al1n12x5 a b o1 vcc
* ----------------------------
* CELLLOG ec0basic nil ec0nand02al1n12x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n12x5/schematic 
* CELLLOG ec0basic nil ec0nand02al1n12x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0nand02al1n12x5/symbol 
* TAG: schematic 
* COUNTER: 43393 
* Version: Unmanaged 
* INPUT:  a  b  vcc 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  a:I  b:I  vcc:I 
*.PININFO  o1:O 
* ----------------------------

mqp2 o1 b vcc vcc psvt l=20e-9 w=306e-9 m=1
mqp1 o1 a vcc vcc psvt l=20e-9 w=306e-9 m=1
mqn2 n1 b vss vss nsvt l=20e-9 w=408e-9 m=1
mqn1 o1 a n1 vss nsvt l=20e-9 w=408e-9 m=1
.ends ec0nand02al1n12x5
** end of subcircuit definition.

** library name: ec0basic
** cell name: ec0bfm201al1n04x5
** view name: schematic
.subckt ec0bfm201al1n04x5 a o vcc
* ----------------------------
* CELLLOG ec0basic nil ec0bfm201al1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfm201al1n04x5/schematic 
* CELLLOG ec0basic nil ec0bfm201al1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfm201al1n04x5/symbol 
* TAG: schematic 
* COUNTER: 52462 
* Version: Unmanaged 
* INPUT:  a  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  a:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mqp2 n1 a vcc vcc psvt l=20e-9 w=68e-9 m=1
mqp1 n2 a n1 vcc psvt l=20e-9 w=68e-9 m=1
mg101.qpa o n2 vcc vcc psvt l=20e-9 w=136e-9 m=1
mg101.qna o n2 vss vss nsvt l=20e-9 w=136e-9 m=1
mqn2 n0 a vss vss nsvt l=20e-9 w=68e-9 m=1
mqn1 n2 a n0 vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0bfm201al1n04x5
** end of subcircuit definition.

** library name: e3modules
** cell name: e3ylmcno2af
** view name: schematic
** end of subcircuit definition.

** library name: e3modules
** cell name: e3ylmkp80af
** view name: schematic
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0lmn012an1n01x5
** view name: schematic
.subckt ec0lmn012an1n01x5 a b clka clkb o1 vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0lmn012an1n01x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lmn012an1n01x5/schematic 
* CELLLOG ec0sequential nil ec0lmn012an1n01x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0lmn012an1n01x5/symbol 
* TAG: schematic 
* COUNTER: 314077 
* Version: Unmanaged 
* INPUT:  b  clkb  clka 
*+ vcc  a 
* OUTPUT:  o1 
* ----------------------------
*.PININFO  b:I  clkb:I  clka:I 
*.PININFO  vcc:I  a:I 
*.PININFO  o1:O 
* ----------------------------

mg1.qna nc2 clka vss vss n l=20e-9 w=34e-9 m=1
mg1.qpa nc2 clka vcc vcc p l=20e-9 w=68e-9 m=1
mg2.qna nc3 clkb vss vss n l=20e-9 w=34e-9 m=1
mg2.qpa nc3 clkb vcc vcc p l=20e-9 w=68e-9 m=1
mg8.qna n1 a vss vss n l=20e-9 w=34e-9 m=1
mg8.qpa n1 a vcc vcc p l=20e-9 w=68e-9 m=1
mg9.qna n2 b vss vss n l=20e-9 w=34e-9 m=1
mg9.qpa n2 b vcc vcc p l=20e-9 w=68e-9 m=1
mg6.qnb nc1 clkb vss vss n l=20e-9 w=34e-9 m=1
mg6.qna nc1 clka vss vss n l=20e-9 w=34e-9 m=1
mg6.qpa nc1 clka g6.n1 vcc p l=20e-9 w=68e-9 m=1
mg6.qpb g6.n1 clkb vcc vcc p l=20e-9 w=68e-9 m=1
mg3.qns o1 clka n1 vss n l=20e-9 w=34e-9 m=1
mg3.qpsb o1 nc2 n1 vcc p l=20e-9 w=68e-9 m=1
mg4.qns o1 clkb n2 vss n l=20e-9 w=34e-9 m=1
mg4.qpsb o1 nc3 n2 vcc p l=20e-9 w=68e-9 m=1
mg7.g4.qnd g7.g4.n2 g7.nk1 vss vss n l=20e-9 w=34e-9 m=1
mg7.g4.qnck o1 nc1 g7.g4.n2 vss n l=20e-9 w=34e-9 m=1
mg7.g4.qpd g7.g4.n1 g7.nk1 vcc vcc p l=20e-9 w=68e-9 m=1
mg7.g4.qpckb o1 g7.nc1 g7.g4.n1 vcc p l=20e-9 w=68e-9 m=1
mg7.g2.qna g7.nc1 g7.nc1 vss vss n l=20e-9 w=34e-9 m=1
mg7.g2.qpa g7.nc1 g7.nc1 vcc vcc p l=20e-9 w=34e-9 m=1
mg7.g99.qna g7.nk1 o1 vss vss n l=20e-9 w=34e-9 m=1
mg7.g99.qpa g7.nk1 o1 vcc vcc p l=20e-9 w=68e-9 m=1
.ends ec0lmn012an1n01x5
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cnan02an1n02x5
** view name: schematic
.subckt ec0cnan02an1n02x5 clk clkout en vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cnan02an1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnan02an1n02x5/schematic 
* CELLLOG ec0clock nil ec0cnan02an1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnan02an1n02x5/symbol 
* TAG: schematic 
* COUNTER: 52174 
* Version: Unmanaged 
* INPUT:  clk  en  vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  en:I  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk n0 vss n l=20e-9 w=68e-9 m=1
mqn2 n0 en vss vss n l=20e-9 w=102e-9 m=1
mqp1 clkout clk vcc vcc p l=20e-9 w=102e-9 m=1
mqp2 clkout en vcc vcc p l=20e-9 w=102e-9 m=1
.ends ec0cnan02an1n02x5
** end of subcircuit definition.

** library name: ec0clock
** cell name: ec0cinv00an1n02x5
** view name: schematic
.subckt ec0cinv00an1n02x5 clk clkout vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cinv00an1n02x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n02x5/schematic 
* CELLLOG ec0clock nil ec0cinv00an1n02x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cinv00an1n02x5/symbol 
* TAG: schematic 
* COUNTER: 25532 
* Version: Unmanaged 
* INPUT:  clk  vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk vss vss n l=20e-9 w=68e-9 m=1
mqp1 clkout clk vcc vcc p l=20e-9 w=102e-9 m=1
.ends ec0cinv00an1n02x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0fsn000an1n05x5
** view name: schematic
.subckt ec0fsn000an1n05x5 clk d o vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0fsn000an1n05x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fsn000an1n05x5/schematic 
* CELLLOG ec0sequential nil ec0fsn000an1n05x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fsn000an1n05x5/symbol 
* TAG: schematic 
* COUNTER: 160960 
* Version: Unmanaged 
* INPUT:  clk  d  vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  clk:I  d:I  vcc:I 
*.PININFO  o:O 
* ----------------------------

mgtd2.qns nk5 clk nk4 vss n l=20e-9 w=68e-9 m=1
mgtd2.qpsb nk5 nc1 nk4 vcc p l=20e-9 w=68e-9 m=1
mgtd1.qns nk3 nc1 d vss n l=20e-9 w=68e-9 m=1
mgtd1.qpsb nk3 nc8 d vcc p l=20e-9 w=68e-9 m=1
mgd1.qnd gd1.n2 nk4 vss vss n l=20e-9 w=34e-9 m=1
mgd1.qnck nk3 nc8 gd1.n2 vss n l=20e-9 w=34e-9 m=1
mgd1.qpd gd1.n1 nk4 vcc vcc p l=20e-9 w=68e-9 m=1
mgd1.qpckb nk3 nc1 gd1.n1 vcc p l=20e-9 w=68e-9 m=1
mgd2.qnd gd2.n2 nk6 vss vss n l=20e-9 w=34e-9 m=1
mgd2.qnck nk5 nc1 gd2.n2 vss n l=20e-9 w=34e-9 m=1
mgd2.qpd gd2.n1 nk6 vcc vcc p l=20e-9 w=68e-9 m=1
mgd2.qpckb nk5 clk gd2.n1 vcc p l=20e-9 w=68e-9 m=1
mgclkn.qna nc1 clk vss vss n l=20e-9 w=68e-9 m=1
mgclkn.qpa nc1 clk vcc vcc p l=20e-9 w=68e-9 m=1
mgclkdd.qna nc8 nc1 vss vss n l=20e-9 w=34e-9 m=1
mgclkdd.qpa nc8 nc1 vcc vcc p l=20e-9 w=68e-9 m=1
mg99.qna nk6 nk5 vss vss n l=20e-9 w=34e-9 m=1
mg99.qpa nk6 nk5 vcc vcc p l=20e-9 w=68e-9 m=1
mgd1n.qna nk4 nk3 vss vss n l=20e-9 w=102e-9 m=1
mgd1n.qpa nk4 nk3 vcc vcc p l=20e-9 w=102e-9 m=1
mg101.qpa o nk5 vcc vcc p l=20e-9 w=170e-9 m=1
mg101.qna o nk5 vss vss n l=20e-9 w=170e-9 m=1
.ends ec0fsn000an1n05x5
** end of subcircuit definition.

** library name: ec0sequential
** cell name: ec0fan003al1n03x5
** view name: schematic
.subckt ec0fan003al1n03x5 clk d o rb vcc
* ----------------------------
* CELLLOG ec0sequential nil ec0fan003al1n03x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fan003al1n03x5/schematic 
* CELLLOG ec0sequential nil ec0fan003al1n03x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0sequential/ec0fan003al1n03x5/symbol 
* TAG: schematic 
* COUNTER: 182154 
* Version: Unmanaged 
* INPUT:  clk  d  rb 
*+ vcc 
* OUTPUT:  o 
* ----------------------------
*.PININFO  clk:I  d:I  rb:I 
*.PININFO  vcc:I 
*.PININFO  o:O 
* ----------------------------

mgd1.qnd gd1.n2 nk4 vss vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qnck nk3 nc8 gd1.n2 vss nsvt l=20e-9 w=34e-9 m=1
mgd1.qpd gd1.n1 nk4 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgd1.qpckb nk3 nc1 gd1.n1 vcc psvt l=20e-9 w=68e-9 m=1
mgtd2.qns nk5 clk nk4 vss nsvt l=20e-9 w=68e-9 m=1
mgtd2.qpsb nk5 nc1 nk4 vcc psvt l=20e-9 w=68e-9 m=1
mgtd2k.qns nk5 nc1 nk9 vss nsvt l=20e-9 w=34e-9 m=1
mgtd2k.qpsb nk5 clk nk9 vcc psvt l=20e-9 w=68e-9 m=1
mgtd1.qns nk3 nc1 d vss nsvt l=20e-9 w=34e-9 m=1
mgtd1.qpsb nk3 nc8 d vcc psvt l=20e-9 w=68e-9 m=1
mgclkdd.qna nc8 nc1 vss vss n l=20e-9 w=34e-9 m=1
mgclkdd.qpa nc8 nc1 vcc vcc p l=20e-9 w=68e-9 m=1
mg99.qna nk6 nk5 vss vss nsvt l=20e-9 w=34e-9 m=1
mg99.qpa nk6 nk5 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgclkn.qna nc1 clk vss vss n l=20e-9 w=68e-9 m=1
mgclkn.qpa nc1 clk vcc vcc p l=20e-9 w=68e-9 m=1
mg101.qpa o nk5 vcc vcc psvt l=20e-9 w=102e-9 m=1
mg101.qna o nk5 vss vss nsvt l=20e-9 w=102e-9 m=1
mgnaf.qpa nk9 nk6 vcc vcc psvt l=20e-9 w=68e-9 m=1
mgnaf.qpb nk9 rb vcc vcc psvt l=20e-9 w=68e-9 m=1
mgnaf.qnb gnaf.n1 rb vss vss nsvt l=20e-9 w=68e-9 m=1
mgnaf.qna nk9 nk6 gnaf.n1 vss nsvt l=20e-9 w=68e-9 m=1
mgd1n.qpa nk4 nk3 vcc vcc psvt l=20e-9 w=102e-9 m=1
mgd1n.qpb nk4 rb vcc vcc psvt l=20e-9 w=102e-9 m=1
mgd1n.qnb gd1n.n1 rb vss vss nsvt l=20e-9 w=102e-9 m=1
mgd1n.qna nk4 nk3 gd1n.n1 vss nsvt l=20e-9 w=102e-9 m=1
.ends ec0fan003al1n03x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcsdlrcvena
** view name: schematic
.subckt ip10xddrdll_mcsdlrcvena clkch1[0] ddrdqsnpiout ddrrcvenpilsqnn4h ddrrcvenpost ddrrcvenpre ddrreadlevphsdetqnnnh ddrtrainrst dqsiqnnnh vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdlrcvena schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdlrcvena/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdlrcvena symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdlrcvena/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 82082 
* Version: 1.2 
* INPUT:  ddrrcvenpre  clkch1[0]  ddrdqsnpiout 
*+ ddrtrainrst  vccxx_lv  dqsiqnnnh  ddrrcvenpilsqnn4h 
* OUTPUT:  ddrrcvenpost  ddrreadlevphsdetqnnnh 
* ----------------------------
*.PININFO  ddrrcvenpre:I  clkch1[0]:I  ddrdqsnpiout:I 
*.PININFO  ddrtrainrst:I  vccxx_lv:I  dqsiqnnnh:I  ddrrcvenpilsqnn4h:I 
*.PININFO  ddrrcvenpost:O  ddrreadlevphsdetqnnnh:O 
* ----------------------------

xiarstflop[1] ddrdqsnpiout rcvennocntd[0] ddrrcvendqsnocnt[1] trainrstb vccxx_lv ec0fan003al1n02x5
xinv8 ddrrcvendqsnocnt[0] rcvennocntd[0] vccxx_lv ec0bfm201al1n02x5
xinv6 ddrrcvendqsnocnt[1] rcvennocntd[1] vccxx_lv ec0bfm201al1n02x5
xinand1 n0 rcvenmidb ddrrcvenpost vccxx_lv ec0nand02al1n12x5
xinv1 ddrrcvenpre ddrrcvenpre_b vccxx_lv ec0inv000al1n02x5
xinv ddrtrainrst trainrstb vccxx_lv ec0inv000al1n02x5
xinv7 rcvennocntd[1] rcvennocntb[1] vccxx_lv ec0inv000al1n02x5
xinv9 rcvenmid rcvenmidb vccxx_lv ec0inv000al1n02x5
xbfm20 ddrreadlevphsdetx ddrreadlevphsdetqnnnh vccxx_lv ec0bfm201al1n04x5
xno0 ddrrcvendqsnocnt[0] rcvennocntd[1] n0 vccxx_lv ec0nor002al1n02x5
ximuxlatch5h vss hisig ddrrcvenpre_b clkpreandrcven rcvenmid vccxx_lv ec0lmn012an1n01x5
xiclknand clkch1[0] clkpreandrcvenb ddrrcvenpre vccxx_lv ec0cnan02an1n02x5
xiclkinv clkpreandrcvenb clkpreandrcven vccxx_lv ec0cinv00an1n02x5
xinvhisig vss hisig vccxx_lv ec0inv000al1n02x5
xipfd ddrrcvenpilsqnn4h dqsiqnnnh ddrreadlevphsdetx vccxx_lv ec0fsn000an1n05x5
xiarstflop[0] ddrdqsnpiout rcvennocntb[1] ddrrcvendqsnocnt[0] trainrstb vccxx_lv ec0fan003al1n03x5
.ends ip10xddrdll_mcsdlrcvena
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

** library name: ec0clock
** cell name: ec0cnor02an1n04x5
** view name: schematic
.subckt ec0cnor02an1n04x5 clk clkout enb vcc
* ----------------------------
* CELLLOG ec0clock nil ec0cnor02an1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnor02an1n04x5/schematic 
* CELLLOG ec0clock nil ec0cnor02an1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0clock/ec0cnor02an1n04x5/symbol 
* TAG: schematic 
* COUNTER: 55599 
* Version: Unmanaged 
* INPUT:  clk  enb  vcc 
* OUTPUT:  clkout 
* ----------------------------
*.PININFO  clk:I  enb:I  vcc:I 
*.PININFO  clkout:O 
* ----------------------------

mqn1 clkout clk vss vss n l=20e-9 w=136e-9 m=1
mqn2 clkout enb vss vss n l=20e-9 w=136e-9 m=1
mqp1 clkout clk n0 vcc p l=20e-9 w=306e-9 m=1
mqp2 n0 enb vcc vcc p l=20e-9 w=408e-9 m=1
.ends ec0cnor02an1n04x5
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
** cell name: ip10xddrdll_mcdllsdlsegenencoder
** view name: schematic
.subckt ip10xddrdll_mcdllsdlsegenencoder a b c d e f g h i[0] i[1] i[2] reset vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllsdlsegenencoder schematic 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllsdlsegenencoder/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcdllsdlsegenencoder symbol 1.2 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcdllsdlsegenencoder/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 41847 
* Version: 1.2 
* INPUT:  vccxx_lv  i[2]  i[0] 
*+ i[1]  reset 
* OUTPUT:  a  b  c 
*+ d  e  f  g 
*+ h 
* ----------------------------
*.PININFO  vccxx_lv:I  i[2]:I  i[0]:I 
*.PININFO  i[1]:I  reset:I 
*.PININFO  a:O  b:O  c:O 
*.PININFO  d:O  e:O  f:O  g:O 
*.PININFO  h:O 
* ----------------------------

xinor10 in1b in0b i1nor2 vccxx_lv ec0nor022al1n02x5
xinor4 i1nor2 i2b o4 vccxx_lv ec0nor022al1n02x5
xinor6 i1nand2 i2b o6 vccxx_lv ec0nor022al1n02x5
xinor5 i1_b i2b o5 vccxx_lv ec0nor022al1n02x5
xinv1 in2b i2b vccxx_lv ec0inv000al1n02x5
xinvrst reset a vccxx_lv ec0inv000al1n02x5
xinvo3 e_b e vccxx_lv ec0inv000al1n02x5
xinvo0 b_b b vccxx_lv ec0inv000al1n02x5
xinvo4 f_b f vccxx_lv ec0inv000al1n02x5
xinvo1 c_b c vccxx_lv ec0inv000al1n02x5
xinvo5 g_b g vccxx_lv ec0inv000al1n02x5
xinvo2 d_b d vccxx_lv ec0inv000al1n02x5
xinvo6 h_b h vccxx_lv ec0inv000al1n02x5
xinv2 i2b o3 vccxx_lv ec0inv000al1n02x5
xinv3 in1b i1_b vccxx_lv ec0inv000al1n02x5
xinvin1 i[1] in1b vccxx_lv ec0inv000al1n02x5
xinvin0 i[0] in0b vccxx_lv ec0inv000al1n02x5
xinvin2 i[2] in2b vccxx_lv ec0inv000al1n02x5
xinan2 in1b in0b i1nand2 vccxx_lv ec0nand02al1n02x5
xi20 o3 a e_b vccxx_lv ec0nand02al1n02x5
xi19 o6 a h_b vccxx_lv ec0nand02al1n02x5
xi18 o2 a d_b vccxx_lv ec0nand02al1n02x5
xi17 o5 a g_b vccxx_lv ec0nand02al1n02x5
xi16 o1 a c_b vccxx_lv ec0nand02al1n02x5
xi15 o4 a f_b vccxx_lv ec0nand02al1n02x5
xi14 o0 a b_b vccxx_lv ec0nand02al1n02x5
xinand0 i1nor2 i2b o0 vccxx_lv ec0nand02al1n02x5
xinand1 i1_b i2b o1 vccxx_lv ec0nand02al1n02x5
xinand2 i1nand2 i2b o2 vccxx_lv ec0nand02al1n02x5
.ends ip10xddrdll_mcdllsdlsegenencoder
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

** library name: ec0basic
** cell name: ec0bfn000al1n04x5
** view name: schematic
.subckt ec0bfn000al1n04x5 a o vcc
* ----------------------------
* CELLLOG ec0basic nil ec0bfn000al1n04x5 schematic Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n04x5/schematic 
* CELLLOG ec0basic nil ec0bfn000al1n04x5 symbol Unmanaged /nfs/site/disks/hdk.stdroot.2/stdcells/ec0/14ww24.2_ec0_prj_alpham1.v1/schematic/ec0basic/ec0bfn000al1n04x5/symbol 
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
mg101.qpa o n1 vcc vcc psvt l=20e-9 w=136e-9 m=1
mg101.qna o n1 vss vss nsvt l=20e-9 w=136e-9 m=1
mqn1 n1 a vss vss nsvt l=20e-9 w=68e-9 m=1
.ends ec0bfn000al1n04x5
** end of subcircuit definition.

** library name: ip10xddrdll_ihdk_sch
** cell name: ip10xddrdll_mcsdl2pi
** view name: schematic
.subckt ip10xddrdll_mcsdl2pi i_dqsin i_drvsel[2] i_drvsel[1] i_drvsel[0] i_nbias_a i_pbias_a i_pi0code[5] i_pi0code[4] i_pi0code[3] i_pi0code[2] i_pi0code[1] i_pi0code[0] i_pi1code[5] i_pi1code[4] i_pi1code[3] i_pi1code[2] i_pi1code[1] i_pi1code[0] i_picb[2] i_picb[1] i_picb[0] i_pienable i_rcvenpi i_rcvenpre i_reset i_sdlparkvalue i_sdlsegdisable[2] i_sdlsegdisable[1] i_sdlsegdisable[0] i_trainreset o_dqsn o_dqsp o_rcvenpost o_readlevphsdet vccxx_lv
* ----------------------------
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdl2pi schematic 1.22 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdl2pi/schematic 
* CELLLOG ip10xddrdll_ihdk_sch nil ip10xddrdll_mcsdl2pi symbol 1.8 /nfs/site/disks/ihdk.db.001/sch/ip10xddrdll/P_ihdk_ADR1/ip10xddrdll_ihdk_sch/ip10xddrdll_mcsdl2pi/symbol 
* TAG: P_ihdk_ADR1 
* COUNTER: 540874 
* Version: 1.8 
* INPUT:  i_pbias_a  i_rcvenpi  i_pienable 
*+ i_picb[0]  i_picb[1]  i_picb[2]  i_nbias_a 
*+ i_trainreset  vccxx_lv  i_sdlparkvalue  i_reset 
*+ i_rcvenpre  i_pi1code[0]  i_pi1code[1]  i_pi1code[2] 
*+ i_pi1code[3]  i_pi1code[4]  i_pi1code[5]  i_drvsel[0] 
*+ i_drvsel[1]  i_drvsel[2]  i_dqsin  i_pi0code[0] 
*+ i_pi0code[1]  i_pi0code[2]  i_pi0code[3]  i_pi0code[4] 
*+ i_pi0code[5]  i_sdlsegdisable[0]  i_sdlsegdisable[1]  i_sdlsegdisable[2] 
* OUTPUT:  o_dqsn  o_readlevphsdet  o_rcvenpost 
*+ o_dqsp 
* ----------------------------
*.PININFO  i_pbias_a:I  i_rcvenpi:I  i_pienable:I 
*.PININFO  i_picb[0]:I  i_picb[1]:I  i_picb[2]:I  i_nbias_a:I 
*.PININFO  i_trainreset:I  vccxx_lv:I  i_sdlparkvalue:I  i_reset:I 
*.PININFO  i_rcvenpre:I  i_pi1code[0]:I  i_pi1code[1]:I  i_pi1code[2]:I 
*.PININFO  i_pi1code[3]:I  i_pi1code[4]:I  i_pi1code[5]:I  i_drvsel[0]:I 
*.PININFO  i_drvsel[1]:I  i_drvsel[2]:I  i_dqsin:I  i_pi0code[0]:I 
*.PININFO  i_pi0code[1]:I  i_pi0code[2]:I  i_pi0code[3]:I  i_pi0code[4]:I 
*.PININFO  i_pi0code[5]:I  i_sdlsegdisable[0]:I  i_sdlsegdisable[1]:I  i_sdlsegdisable[2]:I 
*.PININFO  o_dqsn:O  o_readlevphsdet:O  o_rcvenpost:O 
*.PININFO  o_dqsp:O 
* ----------------------------
xidllddr2pi ch0clkph[8] ch0clkph[7] ch0clkph[6] ch0clkph[5] ch0clkph[4] ch0clkph[3] ch0clkph[2] ch0clkph[1] ch0clkph[0] o_dqsp o_dqsn bwctrld[3] bwctrld[2] bwctrld[1] bwctrld[0] ch0muxsel[9] ch0muxsel[8] ch0muxsel[7] ch0muxsel[6] ch0muxsel[5] ch0muxsel[4] ch0muxsel[3] ch0muxsel[2] ch0muxsel[1] ch0muxsel[0] ch1muxsel[9] ch1muxsel[8] ch1muxsel[7] ch1muxsel[6] ch1muxsel[5] ch1muxsel[4] ch1muxsel[3] ch1muxsel[2] ch1muxsel[1] ch1muxsel[0] i_nbias_a i_pbias_a picb_ioag[2] picb_ioag[1] picb_ioag[0] pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] pienableo[1] pienableo[0] rcvenpost_ioag vccxx_lv ip10xddrdll_mc2piana 
xircvenpost_ls rcvenpost_ioag o_rcvenpost vccxx_lv ec0bfn000al1n06x5
xi110 pien_ls pien_lsb vccxx_lv ec0inv000al1n02x5
xidllddrsdlyline bwctrld[3] bwctrld[2] bwctrld[1] bwctrld[0] ch0clkph[8] ch0clkph[7] ch0clkph[6] ch0clkph[5] ch0clkph[4] ch0clkph[3] ch0clkph[2] ch0clkph[1] ch0clkph[0] b_en clkch1[0] rcven_ioag ddrsdllparkvalioag i_dqsin i_nbias_a i_pbias_a a_en c_en e_en g_en vccxx_lv ip10xddrdll_mcsdllana 
xpidecoder ch0muxsel[9] ch0muxsel[8] ch0muxsel[7] ch0muxsel[6] ch0muxsel[5] ch0muxsel[4] ch0muxsel[3] ch0muxsel[2] ch0muxsel[1] ch0muxsel[0] ch1muxsel[9] ch1muxsel[8] ch1muxsel[7] ch1muxsel[6] ch1muxsel[5] ch1muxsel[4] ch1muxsel[3] ch1muxsel[2] ch1muxsel[1] ch1muxsel[0] dqsppidelayqnnl_ioag[5] dqsppidelayqnnl_ioag[4] dqsppidelayqnnl_ioag[3] dqsppidelayqnnl_ioag[2] dqsppidelayqnnl_ioag[1] dqsppidelayqnnl_ioag[0] pienableo[0] pi0thcode[7] pi0thcode[6] pi0thcode[5] pi0thcode[4] pi0thcode[3] pi0thcode[2] pi0thcode[1] pi0thcode[0] dqsnpidelayqnnl_ioag[5] dqsnpidelayqnnl_ioag[4] dqsnpidelayqnnl_ioag[3] dqsnpidelayqnnl_ioag[2] dqsnpidelayqnnl_ioag[1] dqsnpidelayqnnl_ioag[0] pienableo[1] pi1thcode[7] pi1thcode[6] pi1thcode[5] pi1thcode[4] pi1thcode[3] pi1thcode[2] pi1thcode[1] pi1thcode[0] pien vccxx_lv ip10xddrdll_mcsdecoder
xno1 reset_ioag pien_lsb pien vccxx_lv ec0nor002al1n04x5
xircvenable clkch1[0] dqsrcvenql rcvenpi_ioag rcvenpost_ioag rcven_ioag o_readlevphsdet ddrtrainrst_ioag i_dqsin vccxx_lv ip10xddrdll_mcsdlrcvena
xicappbias[15] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[14] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[13] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[12] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[11] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[10] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[9] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[8] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[7] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[6] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[5] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[4] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[3] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[2] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[1] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xicappbias[0] vccxx_lv i_pbias_a ip10xddrdll_mcpbiascap1
xcnor0 o_dqsn dqsrcvenql o_dqsp vccxx_lv ec0cnor02an1n04x5
xisdlsegen a_en b_en c_en d_en e_en f_en g_en h_en sdlsegdis_ioag[0] sdlsegdis_ioag[1] sdlsegdis_ioag[2] reset_ioag vccxx_lv ip10xddrdll_mcdllsdlsegenencoder
xicapnbias1[15] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[14] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[13] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[12] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[11] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[10] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[9] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[8] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[7] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[6] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[5] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[4] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[3] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[2] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[1] i_nbias_a ip10xddrdll_mcnbiascap1top
xicapnbias1[0] i_nbias_a ip10xddrdll_mcnbiascap1top
xidllreset_ls i_reset reset_ioag vccxx_lv ec0bfn000al1n04x5
xi107 i_trainreset ddrtrainrst_ioag vccxx_lv ec0bfn000al1n04x5
xipien_ls i_pienable pien_ls vccxx_lv ec0bfn000al1n04x5
xisegen_ls[2] i_sdlsegdisable[2] sdlsegdis_ioag[2] vccxx_lv ec0bfn000al1n04x5
xisegen_ls[1] i_sdlsegdisable[1] sdlsegdis_ioag[1] vccxx_lv ec0bfn000al1n04x5
xisegen_ls[0] i_sdlsegdisable[0] sdlsegdis_ioag[0] vccxx_lv ec0bfn000al1n04x5
xircven_ls i_rcvenpre rcven_ioag vccxx_lv ec0bfn000al1n04x5
xircvenpi_ls i_rcvenpi rcvenpi_ioag vccxx_lv ec0bfn000al1n04x5
xils_park i_sdlparkvalue ddrsdllparkvalioag vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[5] i_pi0code[5] dqsppidelayqnnl_ioag[5] vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[4] i_pi0code[4] dqsppidelayqnnl_ioag[4] vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[3] i_pi0code[3] dqsppidelayqnnl_ioag[3] vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[2] i_pi0code[2] dqsppidelayqnnl_ioag[2] vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[1] i_pi0code[1] dqsppidelayqnnl_ioag[1] vccxx_lv ec0bfn000al1n04x5
xich0picode_ls[0] i_pi0code[0] dqsppidelayqnnl_ioag[0] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[5] i_pi1code[5] dqsnpidelayqnnl_ioag[5] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[4] i_pi1code[4] dqsnpidelayqnnl_ioag[4] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[3] i_pi1code[3] dqsnpidelayqnnl_ioag[3] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[2] i_pi1code[2] dqsnpidelayqnnl_ioag[2] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[1] i_pi1code[1] dqsnpidelayqnnl_ioag[1] vccxx_lv ec0bfn000al1n04x5
xich1picode_ls[0] i_pi1code[0] dqsnpidelayqnnl_ioag[0] vccxx_lv ec0bfn000al1n04x5
xipi0mixcb_ls[2] i_picb[2] picb_ioag[2] vccxx_lv ec0bfn000al1n04x5
xipi0mixcb_ls[1] i_picb[1] picb_ioag[1] vccxx_lv ec0bfn000al1n04x5
xipi0mixcb_ls[0] i_picb[0] picb_ioag[0] vccxx_lv ec0bfn000al1n04x5
xslg0[3] vss bwctrld[3] vccxx_lv ec0bfn000al1n04x5
xslg0[2] i_drvsel[2] bwctrld[2] vccxx_lv ec0bfn000al1n04x5
xslg0[1] i_drvsel[1] bwctrld[1] vccxx_lv ec0bfn000al1n04x5
xslg0[0] i_drvsel[0] bwctrld[0] vccxx_lv ec0bfn000al1n04x5
.ends ip10xddrdll_mcsdl2pi
** end of subcircuit definition.
.end

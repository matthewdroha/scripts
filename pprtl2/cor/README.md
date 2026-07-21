# COR PPRTL2 Workflow

## Reference Model Lookup

### IMH

/nfs/site/disks/corhub_fe_mod_0000/corhub_oks/corhub_oks-a0-corhub_oks-26ww29m  
/nfs/site/disks/corimh.arc.proj_archive/arc/parsocnorthcap0a/clock_collateral  
DUT=imh  
TOP_IP_NAME=imh
H2B_PASS=trial

### IOH

/nfs/site/disks/dmr_fe_mod_0000/dmrhub2/dmrhub2-a0-corioh-26ww29c
/nfs/site/disks/dmr2_arc_proj_archive/arc/parcgu/clock_collateral  
DUT=ioh  
TOP_IP_NAME=ioh  
H2B_PASS=trial

### CBBP

/nfs/site/disks/corcbb_fe_mod_0000/corcbbp/corcbbp-a0-corcbbp-26ww29g
/nfs/site/disks/corcbbp.arc.proj_archive/arc/par_base_ese_cse/clock_collateral  
DUT=cbb0  
TOP_IP_NAME=soc        # mroha: Why...
H2B_PASS=cbb0

Confirmed with Remi this is a dead archive area, not used by IOH
/nfs/site/disks/corimh.arc.proj_archive/arc


**Note:** activity_dir.map is still required for all 3 dies

- IMH is on a 2025 CTH release that does not have pprtl2
- IOH is on a 2023 CTH release that does not have pprtl2
- CBBP is on a 2026 CTH release, but their setup is incorrect for CENTRAL_TOOL_ORDER (see $WORKAREA/tool.cth)

## COR IMH

### COR IMH Setup

```sh
/p/cth/bin/cth_psetup -p cor_fe -cfg cor_fe.cth -read_only
git config --global --add safe.directory /nfs/site/disks/corhub_fe_git_0001/corhub_oks-a0
git clone $GIT_REPOS/corhub_oks-a0 corhub_oks-a0-pprtl2-partitions
# rsync is temporary until scripts areas is turned in to $WORKAREA/power/pprtl2/scripts
rsync -av /nfs/site/disks/xpg_dmrhub2_0053/mroha/corpower/scripts .
cd corhub_oks-a0-pprtl2-partitions

# bash
export WORKAREA=`realpath .`
export FE_ACTIVITY_MAPPING=$WORKAREA/power/pprtl2/activity_dir.map

# tcsh
setenv WORKAREA `realpath .`
setenv FE_ACTIVITY_MAPPING $WORKAREA/power/pprtl2/activity_dir.map

# Create pprtl2 workdir
mkdir -p $WORKAREA/power/pprtl2 
cd $WORKAREA/power/pprtl2

# Create symlinks to reference model and SDC archive
# This is a human action
# Typically I look at the "latest" model and link to that version.
# Fill in YOUR_MODEL_VERSION_HERE with the one you selected
ln -sfn /nfs/site/disks/corhub_fe_mod_0000/corhub_oks/YOUR_MODEL_VERSION_HERE REF_MODEL
ln -sfn /nfs/site/disks/corimh.arc.proj_archive/arc SDC_ARCHIVE

# mroha: TODO: Turnin scripts/ to $WORKAREA/power/pprtl2
# Generate pprtl2 workarea
python3 $WORKAREA/../scripts/pprtl2/prep_pprtl2.py --force --dut imh
```

### COR IMH Workflow

```sh
# Run one partition locally
grdlbuild :power:parfws --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=imh -Ptopip=imh -Ph2b_pass=trial

# Run two partitions locally via netbatch
grdlbuild :power:parfws :power:pars3m --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=imh -Ptopip=imh -Ph2b_pass=trial -nb

# Run all partitions via netbatch
grdlbuild :power --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=imh -Ptopip=imh -Ph2b_pass=trial -nb
```

## COR IOH

### COR IOH Setup

```sh
/p/cth/bin/cth_psetup -p dmr_fe -cfg dmr_fe_dmrhub2.cth -read_only
git clone $GIT_REPOS/dmrhub2-a0 -b corioh dmrhub2-a0-corioh-pprtl2-partitions
rsync -av /nfs/site/disks/xpg_dmrhub2_0053/mroha/corpower/scripts .
cd dmrhub2-a0-corioh-pprtl2-partitions

# bash
export WORKAREA=`realpath .`
export FE_ACTIVITY_MAPPING=$WORKAREA/power/pprtl2/activity_dir.map

# tcsh
setenv WORKAREA `realpath .`
setenv FE_ACTIVITY_MAPPING $WORKAREA/power/pprtl2/activity_dir.map

# Create pprtl2 workdir
mkdir -p $WORKAREA/power/pprtl2
cd $WORKAREA/power/pprtl2


# Create symlinks to reference model and SDC archive
# This is a human action
# Typically I look at the "latest" model and link to that version.
# Fill in YOUR_MODEL_VERSION_HERE with the one you selected
ln -sfn /nfs/site/disks/dmr_fe_mod_0000/dmrhub2/YOUR_MODEL_VERSION_HERE REF_MODEL
ln -sfn /nfs/site/disks/dmr2_arc_proj_archive/arc SDC_ARCHIVE

# mroha: TODO: Turnin scripts/ to $WORKAREA/power/pprtl2
# Generate pprtl2 workarea
python3 $WORKAREA/../scripts/pprtl2/prep_pprtl2.py --force --dut ioh
```

### COR IOH Workflow

```sh
# Run one partition locally
grdlbuild :power:parfws --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=ioh -Ptopip=ioh -Ph2b_pass=trial

# Run two partitions locally via netbatch
grdlbuild :power:parfws :power:pars3m --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=ioh -Ptopip=ioh -Ph2b_pass=trial -nb

# Run all partitions via netbatch
grdlbuild :power --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=ioh -Ptopip=ioh -Ph2b_pass=trial -nb
```

## COR CBBP

### COR CBBP Setup

```sh
/p/cth/bin/cth_psetup -p cor_fe -cfg corcbbp_fe.cth -read_only
git clone $GIT_REPOS/corcbbp-a0 corcbbp-a0-pprtl2-partitions
rsync -av /nfs/site/disks/xpg_dmrhub2_0053/mroha/corpower/scripts .
cd corcbbp-a0-pprtl2-partitions

# bash
export WORKAREA=`realpath .`
export FE_ACTIVITY_MAPPING=$WORKAREA/power/pprtl2/activity_dir.map

# tcsh
setenv WORKAREA `realpath .`
setenv FE_ACTIVITY_MAPPING $WORKAREA/power/pprtl2/activity_dir.map

# Create pprtl2 workdir
mkdir -p $WORKAREA/power/pprtl2
cd $WORKAREA/power/pprtl2

# Create symlinks to reference model and SDC archive
# This is a human action
# Typically I look at the "latest" model and link to that version.
# Fill in YOUR_MODEL_VERSION_HERE with the one you selected
ln -sfn /nfs/site/disks/corcbb_fe_mod_0000/corcbbp/YOUR_MODEL_VERSION_HERE REF_MODEL
ln -sfn /nfs/site/disks/corcbbp.arc.proj_archive/arc SDC_ARCHIVE

# mroha: TODO: Turnin scripts/ to $WORKAREA/power/pprtl2
# Generate pprtl2 workarea
python3 $WORKAREA/../scripts/pprtl2/prep_pprtl2.py --force --dut cbb0
```

### COR CBBP Workflow

```sh
# Run one partition locally
grdlbuild :power:par_base_ese_cse --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=cbb0 -Ptopip=soc -Ph2b_pass=cbb0

# Run two partitions locally via netbatch
grdlbuild :power:par_base_ese_cse :power:par_compute_fabric --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=cbb0 -Ptopip=soc -Ph2b_pass=cbb0 -nb

# Run all partitions via netbatch
grdlbuild :power --project-dir $WORKAREA/power/pprtl2/grdlbuild -Pdut=cbb0 -Ptopip=soc -Ph2b_pass=cbb0 -nb
```

## Backup notes

### How To: Run pprtl2 on a single partition outside of grdlbuild

```sh

# IMH example
make -C $WORKAREA/power/pprtl2 elab DUT=imh TOP_IP_NAME=imh TOP_MODULE_NAME=pars3m CONFIG=partition/pars3m.flow.cfg

# IOH example
make -C $WORKAREA/power/pprtl2 elab DUT=ioh TOP_IP_NAME=ioh TOP_MODULE_NAME=pars3m CONFIG=partition/pars3m.flow.cfg

# CBBP example
make -C $WORKAREA/power/pprtl2 elab DUT=cbb0 TOP_IP_NAME=soc TOP_MODULE_NAME=par_base_ese_cse CONFIG=partition/par_base_ese_cse.flow.cfg
```

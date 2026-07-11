#!/usr/intel/pkgs/perl/5.34.0/bin/perl

# basic.t
# (C) Copyright Intel Corporation, 2019, Matthew Roha, matthew.d.roha@intel.com
#
# Documentation after __END__
#

use v5.34.0;
use strict;
use warnings;
use English;
use IO::File;
use File::Basename;
use File::Spec;
use Getopt::Long;
use Test::More;

my ($tfile, $tdir, $WORKAREA);

BEGIN {
  $tfile = File::Spec->rel2abs(__FILE__);
  $tdir = dirname($tfile);
  push (@INC, $tdir);  # not used yet
  $ENV{WORKAREA} = $WORKAREA = "${tdir}/alu";
}

Getopt::Long::Configure("prefix_pattern=(--)");
our ($opt_proj, $opt_proj_version, $opt_cfg, $opt_grp, $opt_baseline_version);
my $options_ok = GetOptions("proj=s", "proj_version=s", "cfg=s", "grp=s", "baseline_version=s");

plan tests => 17;

my $cfg_switch = qq();
if ($opt_cfg) {
 $cfg_switch = qq(-cfg $opt_cfg);
}

my $grp_switch = qq();
if ($opt_grp) {
  $grp_switch = qq(-grp $opt_grp);
}

system(qq(rm -rf ${WORKAREA}/subip));
system(qq(rm -rf ${WORKAREA}/output));

is(system("/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd \'moab update' >& ${WORKAREA}/${opt_proj}.prove.moab")/256, 0, "cth_psetup moab update $opt_proj") or BAIL_OUT("DOA check moab update for -p ${opt_proj}/${opt_proj_version}");

is(system("/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd \'make -C $WORKAREA/gen_filelist gen_filelist' >& ${WORKAREA}/${opt_proj}.prove.gen_filelist")/256, 0, "cth_psetup gen_filelist $opt_proj") or BAIL_OUT("DOA check gen_filelist for -p ${opt_proj}/${opt_proj_version}");

is(system("/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd \'make -C $WORKAREA/verif/vcs vcs_elab' >& ${WORKAREA}/${opt_proj}.prove.vcs_elab")/256, 0, "cth_psetup vcs_elab $opt_proj") or BAIL_OUT("DOA check vcs_elab for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA vcssim' >& ${WORKAREA}/${opt_proj}.prove.vcssim))/256, 0, "cth_psetup vcssim $opt_proj") or BAIL_OUT("DOA check vcssim for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA xceliumsim' >& ${WORKAREA}/${opt_proj}.prove.xceliumsim))/256, 0, "cth_psetup xceliumsim $opt_proj") or BAIL_OUT("DOA check xceliumsim for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/verif/vcs vcs_elab ELAB_OPTS_SWITCH="-Xctdiag=vhdl,cfgverbose" DUMP_ANALYZE_JSON=false PASS=vcs4h2b' >& ${WORKAREA}/${opt_proj}.prove.vcs4h2b))/256, 0, "cth_psetup vcs4h2b $opt_proj") or BAIL_OUT("DOA check vcs4h2b for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/handoff/h2b v2k_config PASS=vcs4h2b' >& ${WORKAREA}/${opt_proj}.prove.v2k_config))/256, 0, "cth_psetup v2k_config $opt_proj") or BAIL_OUT("DOA check v2k_config for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/handoff/h2b h2b PASS=vcs4h2b' >& ${WORKAREA}/${opt_proj}.prove.h2b))/256, 0, "cth_psetup h2b $opt_proj") or BAIL_OUT("DOA check h2b for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/static/jasper jg_compile' >& ${WORKAREA}/${opt_proj}.prove.jasper))/256, 0, "cth_psetup jasper $opt_proj") or BAIL_OUT("DOA check jasper for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/static/sgcdc sgcdc_compile' >& ${WORKAREA}/${opt_proj}.prove.sgcdc_cdc))/256, 0, "cth_psetup sgcdc $opt_proj") or BAIL_OUT("DOA check sgcdc for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/static/vc_cdc compile' >& ${WORKAREA}/${opt_proj}.prove.vc_cdc))/256, 0, "cth_psetup vc_cdc $opt_proj") or BAIL_OUT("DOA check vc_cdc for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/static/sglint compile' >& ${WORKAREA}/${opt_proj}.prove.sglint))/256, 0, "cth_psetup sglint $opt_proj") or BAIL_OUT("DOA check sglint for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/static/vc_lint compile' >& ${WORKAREA}/${opt_proj}.prove.vc_lint))/256, 0, "cth_psetup vc_lint $opt_proj") or BAIL_OUT("DOA check vc_lint for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/power/pprtl elab' >& ${WORKAREA}/${opt_proj}.prove.pprtl))/256, 0, "cth_psetup pprtl $opt_proj") or BAIL_OUT("DOA check pprtl for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'r2g_lite --version' >& ${WORKAREA}/${opt_proj}.prove.r2glite_proj_bin))/256, 0, "cth_psetup r2g_lite proj_bin $opt_proj") or BAIL_OUT("DOA check r2g_lite proj_bin for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA/iflow iflow_list_stages' >& ${WORKAREA}/${opt_proj}.prove.iflow_proj_bin))/256, 0, "cth_psetup iflow proj_bin $opt_proj") or BAIL_OUT("DOA check iflow proj_bin for -p ${opt_proj}/${opt_proj_version}");

is(system(qq(/p/hdk/bin/cth_psetup -p ${opt_proj}/${opt_proj_version} ${cfg_switch} ${grp_switch} -read_only -force -verbose -cmd 'make -C $WORKAREA passing_branch_A_job4' >& ${WORKAREA}/${opt_proj}.prove.iflow_run))/256, 0, "cth_psetup iflow_run $opt_proj") or BAIL_OUT("DOA check iflow_run for -p ${opt_proj}/${opt_proj_version}");


__END__

=pod

=head1 DESCRIPTION

Contains basic DOA test to make sure Synopsys (vcs) and Cadence (jasper) licenses are configured in target liteinfra environment

=cut

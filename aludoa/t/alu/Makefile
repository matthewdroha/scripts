# $WORKAREA/Makefile
# mroha: This template is for combined iflow and DV usage.  The caveat is iflow and DV stage/target names can't conflict
# mroha: For example, in iflow use vcssim_dut1 instead of vcssim
# Other options: Use $WORKAREA/iflow/Makefile for iflow,  top level Makefile for DV (linked from verif/vcssim)
# or 
# Use top level Makefile for iflow and the DV Makefile can reside in verif/vcssim, other DV flows link to that


# WORKAREA should always be set
ifndef WORKAREA
  $(error WORKAREA not set.  Exiting.)
endif

# Set DUT if not already set.  Set your default here. 
export DUT ?= alu

# Set Cheetah RTL if not already set. Don't export, want downstream flows to control their Cheetah RTL version
CHEETAH_RTL_ROOT ?= $(shell cth_query -tool cheetah-rtl ENVS CHEETAH_RTL_ROOT -resolve)

# Set CRB if you want to use this Makefile to run DV (i.e. point verif/vcssim/Makefile to here)
# iflow stages and DV stages can not be named the same (i.e. name iflow stage something like vcssim_dut) 
export CRB ?= $(shell cth_query -tool crb params crb_path -resolve)

# Adjust for your project
IFLOW_INI := $(WORKAREA)/iflow/iflow.ini

IFLOW_MAKEFILE := $(WORKAREA)/output/iflow/Makefile.iflow
IFLOW_EXEC := $(CHEETAH_RTL_ROOT)/iflow/scripts/iflow_run.py
IFLOW_ARGS ?=

# iflow -gen_only call to generate makefile or nb taskfile if any .ini is edited
$(IFLOW_MAKEFILE) : $(wildcard $(WORKAREA)/iflow/*.ini)
	$(IFLOW_EXEC) -ini $(IFLOW_INI) -gen_only --force --outdir $(WORKAREA)/output/iflow

# If using for DV, leave "make help" for DV help. Alternate called "top_help" here
top_help:
	$(info )
	$(info  To list all iflow stages:)
	$(info  > make list_all_stages)
	$(info )
	$(info  To remove all output areas:)
	$(info  > make rm_output)
	$(info )
	$(info  To run iflow -help:)
	$(info  > make iflow_help)
	$(info )
	$(info  To run iflow locally:)
	$(info  > make iflow IFLOW_ARGS='iflow_switches_here')
	$(info  Example: > make iflow IFLOW_ARGS='-list_stages')
	$(info  Example: > make iflow IFLOW_ARGS='-stage vcs_elab,vcssim')
	$(info )
	$(info  To run iflow with nbfeeder:)
	$(info  > make iflow_nb IFLOW_ARGS='iflow_switches_here')
	$(info  Example: Run iflow in batch mode but don't return prompt until run is done)
	$(info  Example: > make iflow_nb IFLOW_ARGS='-stage vcs_elab,vcssim -block')
	$(info )
	$(info  To run iflow with nbfeeder but internal Cheetah feeders are supressed)
	$(info  > make iflow_nb_gk IFLOW_ARGS='iflow_switches_here')
	$(info )
	$(info  To run iflow clean:)
	$(info  > make iflow_clean)
	$(info )

rm_output:
	/bin/rm -rf $(WORKAREA)/output
	/bin/rm -rf $(WORKAREA)/subip
	/bin/rm -rf $(WORKAREA)/regression
	/bin/rm -rf $(WORKAREA)/src/codegen
	/bin/rm ${WORKAREA}/*/*/output

iflow_help:
	$(IFLOW_EXEC) -help

iflow: 
	$(IFLOW_EXEC) -ini $(IFLOW_INI) $(IFLOW_ARGS)

iflow_incr:
	$(IFLOW_EXEC) -ini $(IFLOW_INI) -incr $(IFLOW_ARGS)

# [COMPUTE] _default or iflow name sets feeder settings
iflow_nb: 
	$(IFLOW_EXEC) -ini $(IFLOW_INI) -local false $(IFLOW_ARGS)

iflow_nb_gk:
	$(MAKE) iflow_nb CTH_GK_MODE=true

# Removes iflow touch files but leaves output area
iflow_clean:
	@$(MAKE) -s -f $(IFLOW_MAKEFILE) clean_all_stages
	@touch $(IFLOW_INI)

-include $(IFLOW_MAKEFILE)

include $(CRB)/Makefile.liteinfra
include $(CRB)/Makefile.crb

.PHONY : iflow iflow_nb iflow_nb_gk top_help iflow_clean iflow_help rm_output

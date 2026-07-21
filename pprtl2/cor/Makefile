export CONFIG     = flow.cfg

# Set from $WORKAREA/power/pprtl2/tool.cth
export CHEETAH_RTL_ROOT := $(shell cth_query -tool pprtl2 ENVS CHEETAH_RTL_ROOT -resolve)
export PATH             := $(shell echo "${PATH}"           | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/2.3/commonFlow@g' )
export CTH_SETUP_CMD    := $(shell echo "${CTH_SETUP_CMD}"  | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/2.3/commonFlow@g' )
export CTH_PERL5LIB     := $(shell echo "${CTH_PERL5LIB}"   | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/2.3/commonFlow@g' )
export PERL5LIB         := $(shell echo "${PERL5LIB}"       | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/2.3/commonFlow@g' )
export CTH_PYTHONPATH   := $(shell echo "${CTH_PYTHONPATH}" | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/2.3/commonFlow@g' )

## Dont edit the below lines
#ifeq ($(CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
#   export CHEETAH_RTL_ROOT := $(shell cth_query -tool pprtl2 ENVS CHEETAH_RTL_ROOT -resolve)
#endif

export FLOW            = pprtl2
export FLOW_ROOT       = ${CHEETAH_RTL_ROOT}/lowpower/${FLOW}
export RTL_UTIL_ROOT   = ${CHEETAH_RTL_ROOT}/rtlutils
include ${FLOW_ROOT}/Makefile.${FLOW}
export CONFIG     = flow.cfg

export FLOW              = sglint
ifeq ($(CHEETAH_RTL_ROOT),) # use shell value, if set; otw use := so we only call cth_query once
   export CHEETAH_RTL_ROOT := $(shell cth_query -tool sglint ENVS CHEETAH_RTL_ROOT -resolve)
endif

# mroha: Hardcode sglint Cheetah RTL and supporting liteinfra
# mroha: sglint cheetah rtl is set in baseline_tools/static/sglint/tool.cth
export PATH             := $(shell echo "${PATH}"           | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/1.12.SP1/commonFlow@g' )
export CTH_SETUP_CMD    := $(shell echo "${CTH_SETUP_CMD}"  | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/1.12.SP1/commonFlow@g' )
export CTH_PERL5LIB     := $(shell echo "${CTH_PERL5LIB}"   | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/1.12.SP1/commonFlow@g' )
export PERL5LIB         := $(shell echo "${PERL5LIB}"       | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/1.12.SP1/commonFlow@g' )
export CTH_PYTHONPATH   := $(shell echo "${CTH_PYTHONPATH}" | /usr/bin/sed 's@liteinfra/[A-Za-z0-9\.]*/commonFlow@liteinfra/1.12.SP1/commonFlow@g' )


export FLOW_ROOT        = ${CHEETAH_RTL_ROOT}/lint/${FLOW}
export RTL_UTIL_ROOT    = ${CHEETAH_RTL_ROOT}/rtlutils

include ${FLOW_ROOT}/Makefile.${FLOW}

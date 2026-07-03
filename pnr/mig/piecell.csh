cd $WORK_AREA_ROOT_DIR
${PIE_DIR}/bin/runpie -top ${1} -gds ${PDSSTM}/${1}.stm -process 1266 -nonmanhattan -writelnf -lowerCase -setwiredir -skipannotations
mkdir ${WORK_AREA_ROOT_DIR}/pie/lnf/${1}_lnf
mv ${WORK_AREA_ROOT_DIR}/pie/lnf/*.lnf ${WORK_AREA_ROOT_DIR}/pie/lnf/${1}_lnf

#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Make sure we are root
if [ `whoami` != 'root' ] ; then
  echo "You must run this script as root."
  exit 1
fi

rm -f /tmp/_hq-was-tuned

SYSCTL=/etc/sysctl.conf
SHMMAX_VAL=2147483648

if [ ! -f ${SYSCTL} ] ; then
  echo "${SYSCTL} does not exist, creating it"
  echo "# sysctl.conf created by Hyperic HQ installer" >> ${SYSCTL}
  echo "kernel.shmmax=${SHMMAX_VAL}" >> ${SYSCTL}
else

SHMMAX=`cat ${SYSCTL} | grep -v '#' | grep kernel.shmmax | tr '=' ' ' | awk '{print $2}' | tr -d ' '`
if [ "x${SHMMAX}" = "x" ] ; then
  echo "${SYSCTL} does not define kernel.shmmax, adding it"
  echo "" >> ${SYSCTL}
  echo "# Added by Hyperic HQ installer" >> ${SYSCTL}
  echo "kernel.shmmax=${SHMMAX_VAL}" >> ${SYSCTL}
  echo ${SHMMAX_VAL} > /proc/sys/kernel/shmmax
elif [ `echo "${SHMMAX} "'<'" ${SHMMAX_VAL}" | bc` -gt 0 ] ; then
  echo "${SYSCTL} defines kernel.shmmax too low (was ${SHMMAX}, must be at least ${SHMMAX_VAL}), increasing it"
  EXISTING_SHMMAX=`cat ${SYSCTL} | grep -v '#' | grep kernel.shmmax`
  sed "s|^${EXISTING_SHMMAX}|"'\
#'" Changed by Hyperic HQ installer"'\
#'"${EXISTING_SHMMAX}"'\
'"kernel.shmmax=${SHMMAX_VAL}"'\
'"|g" ${SYSCTL} > /tmp/_sysctl.conf
  mv ${SYSCTL} ${SYSCTL}.bak
  mv /tmp/_sysctl.conf ${SYSCTL}
  echo "${SYSCTL} updated, previous file backed up to ${SYSCTL}.bak"
  echo ${SHMMAX_VAL} > /proc/sys/kernel/shmmax  
else
  echo "${SYSCTL} defined an adequate kernel.shmmax, not changing anything"
fi

fi

# done!
touch /tmp/_hq-was-tuned

echo ""
echo "Tuning completed successfully!"
echo ""

#!/bin/sh
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server installation preflight script for OSX

# Check we have at least 32MB of shared memory, and that the configuration is sane
SHMMAX=`sysctl -a 2> /dev/null |grep kern.sysv.shmmax | awk '{ print $2; }'`
SHMALL=`sysctl -a 2> /dev/null |grep kern.sysv.shmall | awk '{ print $2 * 4096; }'`

if [ $SHMMAX -lt 33554432 ];
then
    if [ -f /etc/sysctl.conf ];
    then
        echo "Your system seems to be configured with less than 32MB of shared memory, which is required for this application. Please see the installer README file for more information on how to configure shared memory settings."
        exit 1
    else
        echo 'kern.sysv.shmmax=33554432' >> /etc/sysctl.conf
        echo 'kern.sysv.shmmin=1' >> /etc/sysctl.conf
        echo 'kern.sysv.shmmni=256' >> /etc/sysctl.conf
        echo 'kern.sysv.shmseg=64' >> /etc/sysctl.conf
        echo 'kern.sysv.shmall=8192' >> /etc/sysctl.conf
        echo "Your shared memory configuration has been adjusted with new settings in /etc/sysctl.conf. Please reboot the system to allow the new settings to take effect and re-run the installer. If you wish to restore the default settings in the future, simply delete /etc/sysctl.conf and reboot."
        exit 2
    fi
    
elif [ $SHMALL -lt $SHMMAX ];
then
    if [ -f /etc/sysctl.conf ];
    then
        echo "Your system seems to be configured with a setting for SHMALL which is less than SHMMAX/4096. Please see the installer README file for more information on how to configure shared memory settings."
	exit 3
    else
        echo 'kern.sysv.shmmax=33554432' >> /etc/sysctl.conf
        echo 'kern.sysv.shmmin=1' >> /etc/sysctl.conf
        echo 'kern.sysv.shmmni=256' >> /etc/sysctl.conf
        echo 'kern.sysv.shmseg=64' >> /etc/sysctl.conf
        echo 'kern.sysv.shmall=8192' >> /etc/sysctl.conf
        echo "Your shared memory configuration has been adjusted with new settings in /etc/sysctl.conf. Please reboot the system to allow the new settings to take effect and re-run the installer. If you wish to restore the default settings in the future, simply delete /etc/sysctl.conf and reboot."
        exit 4
    fi
fi

echo "Shared memory looks OK (SHMALL: $SHMALL, SHMMAX: $SHMMAX)."
exit 0

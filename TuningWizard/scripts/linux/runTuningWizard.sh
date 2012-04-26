#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL tuning-wizard runner script for Linux
LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while the Tuning Wizard is running."
echo ""

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then

    USE_SUDO=0

    if [ -f /etc/lsb-release ];
    then
        if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
        then
            USE_SUDO=1
        fi
    fi

    if [ $USE_SUDO != "1" ];
    then
        echo "Please enter the root password when requested."
    else
        echo "Please enter your password if requested."
    fi

    if [ $USE_SUDO = "1" ];
    then
        sudo su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard""
    elif [ $USE_SUDO != "1" ];
    then
        su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard""
    fi

else
    LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard"
fi


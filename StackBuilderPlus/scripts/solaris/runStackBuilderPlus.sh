#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL stackbuilder runner script for Linux

# Record the calling shell pid in the pid file.
echo $$ > /tmp/runsbp.pid

LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while StackBuilder Plus is running."
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
        sudo su - -c "LD_LIBRARY_PATH="INSTALL_DIR/lib":/usr/sfw/lib/64:$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*"
    else
        su root -c "LD_LIBRARY_PATH="INSTALL_DIR/lib":/usr/sfw/lib/64:$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*"
    fi

else
    LD_LIBRARY_PATH="INSTALL_DIR/lib":/usr/sfw/lib/64:$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

# Remove the pid file now.
rm -f /tmp/runsbp.pid


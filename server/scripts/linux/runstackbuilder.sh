#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB
LOADINGUSER=`whoami`

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then

    echo "NOTE: Graphical administrator tool for su/sudo could not be located on your system! This window must be kept open, while the Stack Builder is running."
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
        if [ x"$LOADINGUSER" != x"root" ];
        then
            echo "Please enter the root password when requested."
        fi
    else
        echo "Please enter your password if requested."
    fi

    if [ $USE_SUDO = "1" ];
    then
        sudo su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    else [ $USE_SUDO != "1" ];
    then
        su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    fi

else
    LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder"
fi


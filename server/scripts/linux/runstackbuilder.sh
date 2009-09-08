#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB
LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while Stack Builder is running."
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
        sudo su - -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    else
        su - -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    fi

else
    LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder"
fi


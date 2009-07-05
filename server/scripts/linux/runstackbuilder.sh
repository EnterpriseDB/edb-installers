#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB
LOADUSER=`whoami`

# You're not running this script as root user
if [ x"$LOADUSER" != x"root" ];
then

    echo "NOTE: Graphical administrator tool for su/sudo could not be located on your system!"
    echo "      This window must kept open, while The Stack Builder is running."
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
        if [ `whoami` != "root" ];
        then
            echo "Please enter the root password when requested."
        fi
    else
        echo "Please enter your password if requested."
    fi

    NOHUP=`which nohup 2>/dev/null`
    if [ $USE_SUDO = "1" -a x"$NOHUP" = x"" ];
    then
        sudo su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    elif  [ $USE_SUDO != "1" -a x"$NOHUP" = x"" ];
    then
        su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder""
    elif  [ $USE_SUDO = "1" -a x"$NOHUP" != x"" ];
    then
        su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc $NOHUP "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" > /dev/null 2>&1 &"
    else
        sudo su -c "LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc $NOHUP "PG_INSTALLDIR/stackbuilder/bin/stackbuilder"  > /dev/null 2>&1 &"
    fi

    if [ x"$NOHUP" != x"" ];
    then
        echo "Wait for sometime to get StackBuilder initialized completely"
        sleep 2
    fi
    
else
     LD_LIBRARY_PATH="PG_INSTALLDIR/pgAdmin3/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder"
fi


#!/bin/sh

# PostgreSQL tuning-wizard runner script for Linux
# Dave Page, EnterpriseDB
LOADUSER=`whoami`

# You're not running this script as root user
if [ x"$LOADUSER" != x"root" ];
then

    echo "NOTE: Graphical administrator tool for su/sudo could not be located on your system!"
    echo "      This window must kept open, while the Tuning Wizard is running."
    USE_SUDO=0

    if [ -f /etc/lsb-release ];
    then
        if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
        then
            USE_SUDO=1
        fi
    fi

    if [ x"$USE_SUDO" != x"1" ];
    then
        if [ x"$LOADUSER" != x"root" ];
        then
            echo "Please enter the root password when requested."
        fi
    else
        echo "Please enter your password if requested."
    fi

    NOHUP=`which nohup 2>/dev/null`
    if [ x"$USE_SUDO" = x"1" -a x"$NOHUP" = x"" ];
    then
        sudo su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard""
    elif [ x"$USE_SUOD" != x"1" -a x"$NOHUP" = x"" ];
    then
        su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard""
    elif [ x"$USE_SUOD" != x"1" -a x"$NOHUP" = x"" ];
    then
        su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc $NOHUP "INSTALLDIR/TuningWizard" > /tmp/TuningWizard.log 2>&1 &"
    else
        sudo su -c "LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc $NOHUP "INSTALLDIR/TuningWizard" > /tmp/TuningWizard.log 2>&1 &"
    fi

    if [ x"$NOHUP" != x"" ];
    then
        echo "Wait for sometime to get the TuningWizard initialized completely"
        sleep 2
    fi
    
else

    LD_LIBRARY_PATH="INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALLDIR/TuningWizard"
    
fi


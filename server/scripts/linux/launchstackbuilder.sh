#!/bin/sh

# PostgreSQL stackbuilder launch script for Linux
# Dave Page, EnterpriseDB

CMD=""

LD_LIBRARY_PATH=PG_INSTALLDIR/lib:$LD_LIBRARY_PATH

# KDESU
if [ x"$KDE_FULL_SESSION" = x"true" ];
then
    KDESU=`which kdesu 2> /dev/null`
    if [ $? -eq 0 ];
    then
        CMD="$KDESU -c"
    fi

# GNOMESU
elif [ x"$GNOME_DESKTOP_SESSION_ID" != x"" ];
then
    GNOMESU=`which gnomesu 2> /dev/null`
    if [ $? -ne 0 ];
    then
        GNOMESU=`which xsu 2> /dev/null`
    fi

    if [ $? -eq 0 ];
    then
        CMD="$GNOMESU -c"
    fi
fi

# If we still have nothing, look for gksu
if [ x"$CMD" = x"" ];
then
    GKSU=`which gksu 2> /dev/null`
    if [ $? -eq 0 ];
    then
        CMD="$GKSU -u root -D StackBuilder"
    fi
fi

# On newer version of Fedora, neither of gksu/gnomesu/kdesu is available
if [ x"$CMD" = x"" ];
then
    for shell in xterm konsole gnome-terminal x-terminal-emulator
    do
        which $shell > /dev/null 2>&1
        if [ $? -eq 0 ];
        then
            CMD="`which $shell` -e "
            break
        fi
    done
fi

$CMD "PG_INSTALLDIR/scripts/runstackbuilder.sh"



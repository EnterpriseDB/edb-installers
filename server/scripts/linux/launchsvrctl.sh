#!/bin/sh
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server control launch script for Linux

# Check the command line
if [ $# -ne 1 ];
then
    echo "Usage: $0 start|stop|restart|reload"
    exit 127
fi

for shell in xterm konsole gnome-terminal
do
    which $shell > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        if [ x"$shell" = x"konsole" ]
        then
            `which $shell` -e "PG_INSTALLDIR/scripts/serverctl.sh" $1 wait
        else
            `which $shell` -e "PG_INSTALLDIR/scripts/serverctl.sh $1 wait"
        fi
        exit 0
    fi
done


#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Postgres Plus HQ agent control launch script for Linux

# Check the command line
if [ $# -ne 1 ];
then
    echo "Usage: $0 start|stop"
    exit 127
fi

for shell in xterm konsole gnome-terminal
do
    which $shell > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        if [ x"$shell" = x"konsole" ]
        then
            `which $shell` -e "HQAGENT_INSTALLDIR/scripts/agentctl.sh" $1 wait
        else
            `which $shell` -e "HQAGENT_INSTALLDIR/scripts/agentctl.sh $1 wait"
        fi
        exit 0
    fi
done


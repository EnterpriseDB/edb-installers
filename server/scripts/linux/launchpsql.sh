#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL psql launch script for Linux

for shell in xterm konsole gnome-terminal
do
    which $shell > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        if [ x"$shell" = x"konsole" ]
        then
            `which konsole` -e "PG_INSTALLDIR/scripts/runpsql.sh" wait
        else
            `which $shell` -e "PG_INSTALLDIR/scripts/runpsql.sh wait"
        fi
        exit 0
    fi
done


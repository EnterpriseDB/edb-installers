#!/bin/sh

# PostgreSQL server control launch script for Linux
# Dave Page, EnterpriseDB

for shell in xterm konsole gnome-terminal
do
    which $shell > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        `which $shell` -e "PG_INSTALLDIR/scripts/serverctl.sh" $1 wait
        exit 0
    fi
done


#!/bin/sh

# PostgreSQL psql launch script for Linux
# Dave Page, EnterpriseDB

for shell in xterm konsole gnome-terminal
do
    which $shell > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        `which $shell` -e "PG_INSTALLDIR/scripts/runpsql.sh" wait
        exit 0
    fi
done


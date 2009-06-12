#!/bin/sh

# PostgreSQL server control launch script for Linux
# Dave Page, EnterpriseDB

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
        `which $shell` -e "PG_INSTALLDIR/scripts/serverctl.sh" $1 wait
        exit 0
    fi
done


#!/bin/sh

# PostgreSQL stackbuilder launch script for Linux
# Dave Page, EnterpriseDB

which gksu 1> /dev/null 
if [ $? -eq 0 ];
then
    GKSU=`which gksu`
    GKSU="$GKSU -u root -D StackBuilder"
fi

$GKSU "PG_INSTALLDIR/scripts/runstackbuilder.sh"



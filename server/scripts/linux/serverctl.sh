#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server control script for Linux

# Check the command line
if [ $# -ne 1 -a $# -ne 2 ]; 
then
    echo "Usage: $0 start|stop|restart|reload [wait]"
    exit 127
fi

case $1 in
    start)
        action=start     
        ;;
    stop) 
        action=stop
        ;;
    restart) 
        action=restart     
        ;;
    reload)  
        action=reload
        ;;
    *)
        echo "Usage: $0 start|stop|restart|reload"
        exit 127
        ;;
esac

# Try to figure out if this is a 'sudo' platform such as Ubuntu
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

if  [ "$action" = "reload" ];
then
    if [ $USE_SUDO != "1" ];
    then
        su - -c 'su - PG_OSUSERNAME -c "LD_LIBRARY_PATH=PG_INSTALLDIR/lib ""PG_INSTALLDIR/bin/pg_ctl"" -D ""PG_DATADIR"" reload"'
    else
        sudo su - PG_OSUSERNAME -c "LD_LIBRARY_PATH=PG_INSTALLDIR/lib ""PG_INSTALLDIR/bin/pg_ctl"" -D ""PG_DATADIR"" reload"
    fi
else
    if [ $USE_SUDO != "1" ];
    then
        su - -c "/etc/init.d/PG_SERVICENAME $action"
    else
        sudo /etc/init.d/PG_SERVICENAME $action
    fi
fi

if [ "$2" = "wait" ];
then
    echo
    echo -n "Press <return> to continue..."
    read dummy
fi


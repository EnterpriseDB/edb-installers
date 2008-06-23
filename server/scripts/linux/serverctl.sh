#!/bin/sh

# PostgreSQL server control script for Linux
# Dave Page, EnterpriseDB

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

if [ `whoami` != "root" ];
then
    echo "Please enter the root password when requested."
fi

if  [ "$action" = "reload" ];
then
    su - -c 'su - postgres -c """PG_INSTALLDIR/bin/pg_ctl"" -D ""PG_DATADIR reload"""'
else
    su - -c "/etc/init.d/postgresql-PG_MAJOR_VERSION $action"
fi

if [ "$2" = "wait" ];
then
    echo
    echo -n "Press <return> to continue..."
    read dummy
fi


#!/bin/bash

function start()
{
    echo "Starting pgbouncer"
    PID=`ps aux | grep 'INSTALL_DIR/bin/pgbouncer -d INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print $2}'`

    if [ "x$PID" = "x" ];
    then
       su SYSTEM_USER -c "INSTALL_DIR/bin/pgbouncer -d INSTALL_DIR/share/pgbouncer.ini"
    else
       echo "pgbouncer already running"
       exit -1
    fi
}

function stop()
{
    echo "Shutting Down pgbouncer"
    PID=`ps aux | grep 'INSTALL_DIR/bin/pgbouncer -d INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print $2}'`

    if [ "x$PID" = "x" ];
    then
        echo "pgbouncer not running"
        exit -1
    else
        kill -9 $PID
    fi

}

# Check the command line
if [ $# -ne 1 ];
then
    echo "Usage: $0 stop|start"
    exit 127
fi

case $1 in
    stop)
        stop
        ;;
    start)
        start
        ;;
    restart)
        stop
        sleep 3
        start
        ;;
    *)
        echo "Usage: $0 stop|start"
        exit 127
        ;;
esac


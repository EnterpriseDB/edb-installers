#!/bin/bash

function start()
{
    date
    echo "Starting pgAgent schedular"
    PID=`ps -aef | grep 'INSTALL_DIR/bin/pgagent -l2 -s INSTALL_DIR/service.log host=localhost port=PG_PORT dbname=postgres user=PG_USER' | grep -v grep | awk '{print $2}'`

    if [ "x$PID" = "x" ];
    then
       su SYSTEM_USER -c "INSTALL_DIR/bin/pgagent -l2 -s INSTALL_DIR/service.log host=localhost port=PG_PORT dbname=postgres user=PG_USER"
    else
       echo "pgAgent already running"
       exit -1
    fi
}

function stop()
{
    date 
    echo "Shuttinh Down pgAgent schedular"
    PID=`ps -aef | grep 'INSTALL_DIR/bin/pgagent -l2 -s INSTALL_DIR/service.log host=localhost port=PG_PORT dbname=postgres user=PG_USER' | grep -v grep | awk '{print $2}'`

    if [ "x$PID" = "x" ];
    then
        echo "pgAgent not running"
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


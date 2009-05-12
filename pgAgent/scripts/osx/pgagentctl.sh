#!/bin/bash

function start()
{
    date
    echo "Starting pgAgent scheduler"
    PID=`ps aux | grep 'INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=PG_HOST port=PG_PORT dbname=PG_DATABASE user=PG_USER' | grep -v grep | awk '{print $2}'`

    if [ "x$PID" = "x" ];
    then
       su SYSTEM_USER -c "INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=PG_HOST port=PG_PORT dbname=PG_DATABASE user=PG_USER"
    else
       echo "pgAgent already running"
       exit -1
    fi
}

function stop()
{
    date 
    echo "Shutting Down pgAgent scheduler"
    PID=`ps aux | grep 'INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=PG_HOST port=PG_PORT dbname=PG_DATABASE user=PG_USER' | grep -v grep | awk '{print $2}'`

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

if [ ! -f /var/log/pgagent.log ];
then
  touch /var/log/pgagent.log
  chown SYSTEM_USER /var/log/pgagent.log
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


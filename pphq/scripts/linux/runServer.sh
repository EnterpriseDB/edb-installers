#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Postgres Plus HQ server script for Linux

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 start|stop|restart"
    exit 127
fi

RESTART=0

ACTIONMSG=

case $1 in
    start)
        action=start
        ACTIONMSG="Starting HQ Server..."
        ;;
    stop) 
        action=stop
        ACTIONMSG="Stopping HQ Server..."
        ;;
    restart)
        action=stop
        ACTIONMSG="Restarting HQ Server..."
        RESTART=1
        ;;
    *)
        echo "Usage: $0 start|stop"
        exit 127
        ;;
esac

if [ "`whoami`" != "@@SERVICEUSER@@" ];
then
  echo ""
  echo "This script must be run by the '@@SERVICEUSER@@' user."
  echo ""
  exit 1;
fi

echo $ACTIONMSG
JAVA_HOME=@@JAVAHOME@@
export JAVA_HOME
"@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/pphq-server.sh" $action

if [ $RESTART -eq 1 ]; then
  sleep 3
  echo "Starting HQ Server..."
  "@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/pphq-server.sh" start
fi



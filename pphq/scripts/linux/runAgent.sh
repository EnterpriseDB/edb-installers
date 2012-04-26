#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Postgres Plus HQ agent control script for Linux

if [ "`whoami`" != "@@AGENTSERVICEUSER@@" ];
then
     echo ""
     echo "This script must be run by the '@@AGENTSERVICEUSER@@' user."
     echo ""
     exit 1;
fi



# Check the command line
if [ $# -ne 1 ];
then
    echo "Usage: $0 start|stop|restart|status"
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
    status)
        action=status
        ;;
    *)
        echo "Usage: $0 start|stop|restart|status"
        exit 127
        ;;
esac

JAVA_HOME=@@JAVAHOME@@
HQ_JAVA_HOME=@@JAVAHOME@@
export JAVA_HOME
"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/pphq-agent.sh" $action


#!/bin/sh

# Postgres Plus HQ agent control script for Linux
# Dave Page, EnterpriseDB

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
        echo "Usage: $0 start|stop"
        exit 127
        ;;
esac

if [ "\$USER" = "root" -o "\$UID" = "0" -o "\$EUID" = "0" ];
then
     echo "Running the runAgent.sh script: Action(\$1).."
elif [ "$USER" != "@@SERVICEUSER@@" ];
then
     echo ""
     echo "This script must be run by the root user."
     echo ""
     exit 1;
fi

# Try to figure out if this is a 'sudo' platform such as Ubuntu
USE_SUDO=0
if [ -f /etc/lsb-release ];
then
    if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
    then
        USE_SUDO=1
    fi
fi

CURRUSER=`whoami`

if [ "$CURRUSER" != "@@SERVICEUSER@@" ];
then
  su - @@SERVICEUSER@@ -c "JAVA_HOME=@@JAVAHOME@@; \"@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/@@PPHQAGENTSCRIPT@@\" $action"
else
  JAVA_HOME=@@JAVAHOME@@; "@@INSTALLDIR@@/agent-@@PPHQVERSION@@/bin/@@PPHQAGENTSCRIPT@@" $action
fi


#!/bin/sh

# Hyperic agent control script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 1 -a $# -ne 2 ]; 
then
    echo "Usage: $0 start|stop"
    exit 127
fi

case $1 in
    start)
        action=start     
        ;;
    stop) 
        action=stop
        ;;
    *)
        echo "Usage: $0 start|stop"
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

if [ $USE_SUDO != "1" ];
then
    su - -c "HQAGENT_INSTALLDIR/agent-HQAGENT_VERSION_STR/bin/hq-agent.sh $action"
else
    sudo  HQAGENT_INSTALLDIR/agent-HQAGENT_VERSION_STR/bin/hq-agent.sh $action
fi

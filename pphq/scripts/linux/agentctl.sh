#!/bin/bash

# Postgres Plus HQ agent control script for Linux
# Ashesh Vashi, EnterpriseDB

# Check the command line
usage()
{
    echo "Usage: $0 [--no-wait] <start|stop|restart|status>"
    exit 127
}

if [ $# -lt 1  -o $# -gt 2 ]; 
then
  usage
fi

WAIT=1

if [ x"$1" == x"--no-wait" ];
then
  WAIT=0
  shift
elif [ $# -gt 1 ];
then
  usage
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
        usage
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

CURRUSER=`whoami`

if [ "$CURRUSER" != "@@AGENTSERVICEUSER@@" ];
then
  if [ $USE_SUDO != "1" ];
  then
    if [ "$CURRUSER" != "root" ];
    then
        echo "Please enter the root password when requested."
    fi
  else
    echo "Please enter your password if requested."
  fi

  if [ $USE_SUDO != "1" ];
  then
      su - -c "su @@AGENTSERVICEUSER@@ -c \"\\\"@@INSTALLDIR@@/scripts/runAgent.sh\\\" $action\""
  else
      sudo su @@AGENTSERVICEUSER@@ -c "\"@@INSTALLDIR@@/scripts/runAgent.sh\" $action"
  fi
else
  "@@INSTALLDIR@@/scripts/runAgent.sh" $action
fi

if [ $WAIT -eq 1 ];
then
  echo
  echo -n "Press <return> to continue..."
  read dummy
fi

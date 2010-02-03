#!/bin/sh

# Postgres Plus HQ agent control script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -lt 1  -o $# -gt 2 ]; 
then
    echo "Usage: $0 start|stop|restart|status [wait]"
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

CURRUSER=`whoami`

if [ "$CURRUSER" != "@@SERVICEUSER@@" ];
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
      su - -c "\"@@INSTALLDIR@@/scripts/runAgent.sh\" $action"
  else
      sudo "@@INSTALLDIR@@/scripts/runAgent.sh" $action
  fi
else
  "@@INSTALLDIR@@/scripts/runAgent.sh" $action
fi

if [ x"$2" = x"wait" ];
then
  echo
  echo -n "Press <return> to continue..."
  read dummy
fi

#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 5 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <SubPort> <Java Executable> <DBSERVER_VER>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
SUBPORT=$3
JAVA=$4
XDB_SERVICE_VER=$5

# Exit code
WARN=0

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Write the startup script
cat <<EOT > "/etc/init.d/edb-xdbsubserver-$XDB_SERVICE_VER"
#!/bin/bash
#
# chkconfig: 2345 90 10
# description: Subscription Server Service script for Linux

### BEGIN INIT INFO
# Provides:          edb-xdbsubserver-$XDB_SERVICE_VER
# Required-Start:    \$syslog 
# Required-Stop:     \$syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: edb-xdbsubserver-$XDB_SERVICE_VER 
# Description:       edb-xdbsubserver-$XDB_SERVICE_VER
### END INIT INFO

check_pid()
{
    export PIDS=\`ps -aef | grep 'java -Djava.awt.headless=true -jar edb-repserver.jar subserver $SUBPORT' | grep -v grep | awk '{print \$2}'\`
}

start()
{
    check_pid;

    if [ "x\$PIDS" = "x" ];
    then
       su $SYSTEM_USER -c "cd $INSTALL_DIR/bin; $JAVA -Djava.awt.headless=true -jar edb-repserver.jar subserver $SUBPORT > /dev/null 2>&1 &"

       check_pid;

       if [ "x\$PIDS" = "x" ];
       then
           echo "Subscription Service $XDB_SERVICE_VER not started"
           exit 1
       else
           echo "Subscription Service $XDB_SERVICE_VER started"
       fi
    else
       echo "Subscription Service $XDB_SERVICE_VER already running"
       exit 0
    fi
}

stop()
{
    check_pid;

    if [ "x\$PIDS" = "x" ];
    then
        echo "Subscription Service $XDB_SERVICE_VER not running"
    else
        kill -9 \$PIDS
	echo "Subscription Service $XDB_SERVICE_VER stopped"
    fi
}

status()
{
    check_pid;

    if [ "x\$PIDS" = "x" ];
    then
        echo "Subscription Service $XDB_SERVICE_VER not running"
        exit 1
    else
        echo "Subscription Service $XDB_SERVICE_VER (PID:\$PIDS) is running"
        exit 0
    fi

}

# See how we were called.
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 3
        start
        ;;
  status)
        status
        ;; 
  *)
        echo \$"Usage: \$0 {start|stop|restart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/edb-xdbsubserver-$XDB_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/etc/init.d/edb-xdbsubserver-$XDB_SERVICE_VER)"

#Create directory for logs
if [ ! -e /var/log/xdb-rep ];
then
    mkdir -p /var/log/xdb-rep
    chown $SYSTEM_USER /var/log/xdb-rep
    chmod 777 /var/log/xdb-rep
fi

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add edb-xdbsubserver-$XDB_SERVICE_VER
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d edb-xdbsubserver-$XDB_SERVICE_VER defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

echo "$0 ran to completion"
exit $WARN

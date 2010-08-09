#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <SubPort> <Java Executable>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
SUBPORT=$3
JAVA=$4

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
cat <<EOT > "/etc/init.d/edb-xdbsubserver"
#!/bin/bash
#
# chkconfig: 2345 90 10
# description: Subscription Server Service script for Linux

### BEGIN INIT INFO
# Provides:          edb-xdbsubserver
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: edb-xdbsubserver 
# Description:       edb-xdbsubserver
### END INIT INFO

start()
{
    PID=\`ps -aef | grep 'java -jar edb-repserver.jar subserver $SUBPORT' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "cd $INSTALL_DIR/bin; $JAVA -jar edb-repserver.jar subserver $SUBPORT > /dev/null 2>&1 &"
       exit 0
    else
       echo "Subscription Service already running"
       exit 1
    fi
}

stop()
{
    PID=\`ps -aef | grep 'java -jar edb-repserver.jar subserver $SUBPORT' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "Subscription Service not running"
        exit 2
    else
        kill -9 \$PID
    fi
}

status()
{
    PID=\`ps -aef | grep 'java -jar edb-repserver.jar subserver $SUBPORT' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "Subscription Service not running"
        exit 2
    else
        echo "Subscription Service (PID:\$PID) is running"
        exit 2
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
chmod 0755 "/etc/init.d/edb-xdbsubserver" || _warn "Failed to set the permissions on the startup script (/etc/init.d/edb-xdbsubserver)"

#Create directories for logs
if [ ! -e $INSTALL_DIR/bin/logs ];
then
    mkdir -p $INSTALL_DIR/bin/logs
    chown $SYSTEM_USER $INSTALL_DIR/bin/logs
fi

if [ ! -e /var/log/xdb ];
then
    mkdir -p /var/log/xdb
    chown $SYSTEM_USER /var/log/xdb
fi

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add edb-xdbsubserver
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d edb-xdbsubserver defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

echo "$0 ran to completion"
exit $WARN

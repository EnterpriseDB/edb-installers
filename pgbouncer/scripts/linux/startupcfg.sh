#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 2 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2

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
cat <<EOT > "/etc/init.d/pgbouncer"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: pgbouncer Service script for Linux

### BEGIN INIT INFO
# Provides:          edb-pgbouncer
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: pgbouncer 
# Description:       pgbouncer
### END INIT INFO

check_pid()
{
    export PIDB=\`ps -aef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`
}

start()
{
    check_pid;

    if [ "x\$PIDB" = "x" ];
    then
       # Service Owner should be able to start the service without root password.
       if [ "\$USER" = "$SYSTEM_USER" ];
       then
           LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini 

           check_pid;

           if [ "x\$PIDB" = "x" ];
           then
               echo "pgbouncer not started"
               exit 1
           else
              exit 0 
          fi
       else
           su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini "

           check_pid;

           if [ "x\$PIDB" = "x" ];
           then
               echo "pgbouncer not started"
               exit 1
           else
               exit 0
           fi 
       fi
    else
       echo "pgbouncer already running"
       exit 1
    fi
}

stop()
{
    check_pid;

    if [ "x\$PIDB" = "x" ];
    then
        echo "pgbouncer not running"
        exit 2
    else
        kill \$PIDB
    fi
}
status()
{
    check_pid;

    if [ "x\$PIDB" = "x" ];
    then
        echo "pgbouncer not running"
    else
        echo "pgbouncer is running (PID: \$PIDB)"
    fi
    exit 0
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
        echo \$"Usage: \$0 {start|stop|status|restart}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/pgbouncer" || _warn "Failed to set the permissions on the startup script (/etc/init.d/pgbouncer/)"

mkdir /var/log/pgbouncer
chown $SYSTEM_USER /var/log/pgbouncer

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add pgbouncer
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d pgbouncer defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

echo "$0 ran to completion"
exit $WARN

#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 3 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <DBSERVER_VER>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
PGBOUNCER_SERVICE_VER=$3

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
cat <<EOT > "/etc/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER"
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
       if [ "\`id -un\`" = "$SYSTEM_USER" ];
       then
           LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini

	   sleep 3;
           check_pid;

           if [ "x\$PIDB" = "x" ];
           then
               echo "pgbouncer-$PGBOUNCER_SERVICE_VER not started"
               exit 1
           else
	       echo "pgbouncer-$PGBOUNCER_SERVICE_VER started" 
           fi
       else
           su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini "
           
	   sleep 3;
           check_pid;

           if [ "x\$PIDB" = "x" ];
           then
               echo "pgbouncer-$PGBOUNCER_SERVICE_VER not started"
               exit 1
           else 
	       echo "pgbouncer-$PGBOUNCER_SERVICE_VER started" 
	   fi
       fi
    else
       echo "pgbouncer-$PGBOUNCER_SERVICE_VER already running"
       exit 0
    fi
}

stop()
{
    check_pid;

    if [ "x\$PIDB" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
    else
        kill \$PIDB
	echo "pgbouncer-$PGBOUNCER_SERVICE_VER stopped" 
    fi
}
status()
{
    check_pid;

    if [ "x\$PIDB" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
	exit 1
    else
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER is running (PID: \$PIDB)"
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
        echo \$"Usage: \$0 {start|stop|status|restart}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/etc/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER)"

mkdir /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER
chown -R $SYSTEM_USER /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add pgbouncer-$PGBOUNCER_SERVICE_VER
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d pgbouncer-$PGBOUNCER_SERVICE_VER defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

echo "$0 ran to completion"
exit $WARN

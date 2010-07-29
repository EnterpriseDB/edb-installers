#!/bin/sh

# PostgreSQL startup configuration script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Install dir> <Data dir> <ServiceName>"
    exit 127
fi

VERSION=$1
USERNAME=$2
INSTALLDIR=$3
DATADIR=$4
SERVICENAME=$5

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
cat <<EOT > "/etc/init.d/$SERVICENAME"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: Starts and stops the PostgreSQL $VERSION database server

# Source function library.
if [ -f /etc/rc.d/functions ];
then
    . /etc/init.d/functions
fi

# PostgreSQL Service script for Linux

start()
{
	echo \$"Starting PostgreSQL $VERSION: "
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl -w start -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\""
	
	if [ \$? -eq 0 ];
	then
		echo "PostgreSQL $VERSION started successfully"
                exit 0
	else
		echo "PostgreSQL $VERSION did not start in a timely fashion, please see $DATADIR/pg_log/startup.log for details"
                exit 1
	fi
}

stop()
{
	echo \$"Stopping PostgreSQL $VERSION: "
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl stop -m fast -w -D \"$DATADIR\""
}

restart()
{
	echo \$"Restarting PostgreSQL $VERSION: "
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl -w restart -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\" -m fast"
	
	if [ \$? -eq 0 ];
	then
		echo "PostgreSQL $VERSION restarted successfully"
                exit 0
	else
		echo "PostgreSQL $VERSION did not start in a timely fashion, please see $DATADIR/pg_log/startup.log for details"
                exit 1
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
  restart|reload)
        restart
        ;;
  condrestart)
        if [ -f "$DATADIR/postmaster.pid" ]; then
            restart
        fi
        ;;
  status)
        su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl status -D \"$DATADIR\""
        ;;
  *)
        echo \$"Usage: $0 {start|stop|restart|condrestart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/$SERVICENAME" || _warn "Failed to set the permissions on the startup script (/etc/init.d/$SERVICENAME)"

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
RET=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /sbin/chkconfig --add $SERVICENAME
	if [ $? -ne 0 ]; then
	    _warn "Failed to configure the service startup with chkconfig"
	fi
fi

RET=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /usr/sbin/update-rc.d $SERVICENAME defaults
	if [ $? -ne 0 ]; then
	    _warn "Failed to configure the service startup with update-rc.d"
	fi
fi

ldconfig || _warn "Failed to run ldconfig"

echo "$0 ran to completion"
exit $WARN

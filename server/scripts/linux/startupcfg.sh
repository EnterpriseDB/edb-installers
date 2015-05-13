#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL startup configuration script for Linux

# Check the command line
if [ $# -ne 6 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Install dir> <Data dir> <ServiceName> <initSystem>"
    exit 127
fi

VERSION=$1
USERNAME=$2
INSTALLDIR=$3
DATADIR=$4
SERVICENAME=$5
INIT=$6

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

determine_services_path() {
        echo "==>> Checking systemd services path..."
        echo "Running: /usr/bin/pkg-config --variable=systemdsystemunitdir systemd"
        SYSTEMD_SERVICES_PATH=`/usr/bin/pkg-config --variable=systemdsystemunitdir systemd`

        if [ -z $SYSTEMD_SERVICES_PATH ]; then
            SYSTEMD_SERVICES_PATH=/usr/lib/systemd/system
        fi
        echo "SYSTEMD_SERVICES_PATH:$SYSTEMD_SERVICES_PATH"
}

if [ "$INIT" = "systemd" ]; then
determine_services_path
    cat <<EOT > "$SYSTEMD_SERVICES_PATH/$SERVICENAME.service"
[Unit]
Description=PostgreSQL $VERSION database server
After=syslog.target network.target

[Service]
Type=forking
TimeoutSec=120

User=$USERNAME

Environment=PGDATA=$DATADIR
PIDFILE=$DATADIR/postmaster.pid

ExecStart=$INSTALLDIR/bin/pg_ctl -w start -D "$DATADIR" -l "$DATADIR/pg_log/startup.log -w -t ${TimeoutSec}"
ExecStop=$INSTALLDIR/bin/pg_ctl stop -m fast -w -D "$DATADIR"
ExecReload=$INSTALLDIR/bin/pg_ctl reload -D "$DATADIR"

[Install]
WantedBy=multi-user.target

EOT

$SYSTEMD_PATH/bin/systemctl daemon-reload
$SYSTEMD_PATH/bin/systemctl enable $SERVICENAME.service

else
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

NAME=$SERVICENAME
LOCKFILE=/var/lock/subsys/\$NAME

source $INSTALLDIR/etc/sysconfig/loadplLanguages.sh $INSTALLDIR

# PostgreSQL Service script for Linux

start()
{
	su - $USERNAME -c "touch $DATADIR/pg_log/startup.log"
	echo \$"Starting PostgreSQL $VERSION: "

	echo
	VerifyPLPaths &> $DATADIR/pg_log/startup.log
	LoadPLPaths
	echo

	su -s /bin/sh - $USERNAME -c "PATH=$INSTALLDIR/bin:\$PATH_PL_LANGUAGES:\$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH_PL_LANGUAGES:\$LD_LIBRARY_PATH $INSTALLDIR/bin/pg_ctl -w start -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\""

	if [ \$? -eq 0 ];
	then
		touch \$LOCKFILE
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
	su -s /bin/sh - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH $INSTALLDIR/bin/pg_ctl stop -m fast -w -D \"$DATADIR\""
	if [ \$? -eq 0 ];
	then
		rm -f \$LOCKFILE
	fi
}

restart()
{
	su - $USERNAME -c "touch $DATADIR/pg_log/startup.log"
	echo \$"Restarting PostgreSQL $VERSION: "

        echo
        VerifyPLPaths &> $DATADIR/pg_log/startup.log
        LoadPLPaths
        echo

	su -s /bin/sh - $USERNAME -c "PATH=$INSTALLDIR/bin:\$PATH_PL_LANGUAGES:\$PATH LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH_PL_LANGUAGES:\$LD_LIBRARY_PATH $INSTALLDIR/bin/pg_ctl -w restart -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\" -m fast"
	
	if [ \$? -eq 0 ];
	then
		touch \$LOCKFILE
		echo "PostgreSQL $VERSION restarted successfully"
                exit 0
	else
		echo "PostgreSQL $VERSION did not start in a timely fashion, please see $DATADIR/pg_log/startup.log for details"
                exit 1
	fi
}

reload()
{
	echo \$"Reloading PostgreSQL $VERSION: "
	su -s /bin/sh - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH $INSTALLDIR/bin/pg_ctl reload -D \"$DATADIR\""
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
        restart
        ;;
  reload)
	reload
	;;
  condrestart)
        if [ -f "$DATADIR/postmaster.pid" ]; then
            restart
        fi
        ;;
  status)
        su -s /bin/sh - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH $INSTALLDIR/bin/pg_ctl status -D \"$DATADIR\""
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

fi

echo "$0 ran to completion"
exit $WARN

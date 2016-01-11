#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 3 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <initSystem>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
INIT=$3

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
cat <<EOT > "/usr/lib/tmpfiles.d/pgbouncer.conf"
d /var/log/pgbouncer 0755 $SYSTEM_USER $SYSTEM_USER - 
d /var/pgbouncer-$SYSTEM_USER 0755 $SYSTEM_USER $SYSTEM_USER - 

EOT
systemd-tmpfiles --create
    cat <<EOT > "$SYSTEMD_SERVICES_PATH/pgbouncer.service"
[Unit]
Description=PgBouncer daemon
After=syslog.target network.target

[Service]
TimeoutSec=20
Type=forking
User=$SYSTEM_USER
SuccessExitStatus=1
PIDFile=/var/pgbouncer-$SYSTEM_USER/pgbouncer.pid
StandardError=syslog

Environment=LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH
ExecStart=$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini

[Install]
WantedBy=multi-user.target

EOT

$SYSTEMD_PATH/bin/systemctl daemon-reload
$SYSTEMD_PATH/bin/systemctl enable pgbouncer.service

else
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

start()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       # Service Owner should be able to start the service without root password.
       if [ "\$USER" = "$SYSTEM_USER" ];
       then
           LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini 
       else
           su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini " 
       fi
       exit 0
    else
       echo "pgbouncer already running"
       exit 1
    fi
}

stop()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer not running"
        exit 2
    else
        kill \$PID
    fi
}
status()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer not running"
    else
        echo "pgbouncer is running (PID: \$PID)"
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
mkdir -p /var/pgbouncer-$SYSTEM_USER
chown -R $SYSTEM_USER /var/pgbouncer-$SYSTEM_USER

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

fi
echo "$0 ran to completion"
exit $WARN

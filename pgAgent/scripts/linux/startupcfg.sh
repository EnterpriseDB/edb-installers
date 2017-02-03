#!/bin/sh
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 7 ]; 
then
echo "Usage: $0 <PG_HOST> <PG_PORT> <PG_USER> <SYSTEMUSER> <Install dir> <PG_DATABASE> <initSystem>"
    exit 127
fi

PG_HOST=$1
PG_PORT=$2
PG_USER=$3
SYSTEM_USER=$4
INSTALL_DIR=$5
PG_DATABASE=$6
INIT=$7

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

USER_HOME_DIR=`cat /etc/passwd | grep "^$SYSTEM_USER:" | cut -d":" -f6`
touch /var/log/pgagent.log
chown $SYSTEM_USER:$SYSTEM_USER /var/log/pgagent.log
if [ -f $USER_HOME_DIR/.pgpass ];
then
    chk=`grep -c ^$PG_HOST:$PG_PORT:$PG_DATABASE:$PG_USER $USER_HOME_DIR/.pgpass`
    if [ "$chk" != "0" ];
    then
       # Remove existing line and add new one
       sed /$PG_HOST:$PG_PORT:$PG_DATABASE:$PG_USER:.*/d $USER_HOME_DIR/.pgpass >$USER_HOME_DIR/.pgpass1
       mv $USER_HOME_DIR/.pgpass1 $USER_HOME_DIR/.pgpass
    fi
fi
cat $INSTALL_DIR/installer/pgAgent/pgpass >> $USER_HOME_DIR/.pgpass

chmod 0600 $USER_HOME_DIR/.pgpass
chown $SYSTEM_USER:$SYSTEM_USER $USER_HOME_DIR/.pgpass

if [ "$INIT" = "systemd" ]; then
determine_services_path
    cat <<EOT > "$SYSTEMD_SERVICES_PATH/pgagent.service"
[Unit]
Description=pgAgent
After=syslog.target network.target

[Service]
Type=forking
TimeoutSec=120

User=$SYSTEM_USER

Environment=LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH

ExecStart=$INSTALL_DIR/bin/pgagent -l 1 -s /var/log/pgagent.log hostaddr=$PG_HOST port=$PG_PORT dbname=$PG_DATABASE user=$PG_USER

[Install]
WantedBy=multi-user.target

EOT

$SYSTEMD_PATH/bin/systemctl daemon-reload
$SYSTEMD_PATH/bin/systemctl enable pgagent.service

else
# Write the startup script
cat <<EOT > "/etc/init.d/pgagent"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: pgAgent Service script for Linux

### BEGIN INIT INFO
# Provides:          edb-pgAgent
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: pgAgent 
# Description:       pgAgent
### END INIT INFO

export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH

start()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=$PG_HOST port=$PG_PORT dbname=$PG_DATABASE user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "export LD_LIBRARY_PATH=$INSTALL_DIR/lib;$INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=$PG_HOST port=$PG_PORT dbname=$PG_DATABASE user=$PG_USER > /dev/null 2>&1 &"
       exit 0
    else
       echo "pgAgent already running"
       exit 1
    fi
}

stop()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=$PG_HOST port=$PG_PORT dbname=$PG_DATABASE user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgAgent not running"
        exit 2
    else
        kill -9 \$PID
    fi
}
status()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgagent -l1 -s /var/log/pgagent.log host=$PG_HOST port=$PG_PORT dbname=$PG_DATABASE user=$PG_USER' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgAgent not running"
    else
        echo "pgAgent is running (PID: \$PID)"
    fi
    exit 0
}

if [ ! -f /var/log/pgagent.log ];
then
    touch /var/log/pgagent.log
    chown $SYSTEM_USER:$SYSTEM_USER /var/log/pgagent.log
fi

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
chmod 0755 "/etc/init.d/pgagent" || _warn "Failed to set the permissions on the startup script (/etc/init.d/pgagent/)"

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $CHKCONFIG ];
then
    /sbin/chkconfig --add pgagent
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $UPDATECONFIG ];
then
    /usr/sbin/update-rc.d pgagent defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi


#SERVICE=`which service`
#echo "Starting pgagent"
#if [ ! "x$SERVICE" = "x" ]; then
#    $SERVICE pgagent start
#    if [ $? -ne 0 ]; then
#        _warn "Failed to start pgagent"
#    fi
#elif [ -f /sbin/service ]; then
#    /sbin/service pgagent start    
#else
#    /etc/init.d/pgagent start
#fi
fi
echo "$0 ran to completion"
exit $WARN

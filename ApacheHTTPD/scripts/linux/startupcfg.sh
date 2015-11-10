#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Install dir> <initSystem>"
    exit 127
fi

INSTALLDIR=$1
INIT=$2

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
    cat <<EOT > "$SYSTEMD_SERVICES_PATH/EnterpriseDBApacheHTTPD.service"
[Unit]
Description=Starts and stops the Apache Server
After=syslog.target network.target

[Service]
TimeoutSec=20
Type=forking
SuccessExitStatus=1
StandardError=syslog

Environment=LD_LIBRARY_PATH=$INSTALLDIR/lib:\$LD_LIBRARY_PATH
ExecStart=$INSTALLDIR/apache/bin/apachectl start

[Install]
WantedBy=multi-user.target

EOT

$SYSTEMD_PATH/bin/systemctl daemon-reload
$SYSTEMD_PATH/bin/systemctl enable EnterpriseDBApacheHTTPD.service

else
# Write the startup script
cat <<EOT > "/etc/init.d/EnterpriseDBApacheHTTPD"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: Starts and stops the Apache Server

# EnterpriseDBApacheHTTPD Service script for Linux

start()
{
    su -c "$INSTALLDIR/apache/bin/apachectl start"
}

stop()
{
    su -c "$INSTALLDIR/apache/bin/apachectl stop"
}
status()
{

    PID=\`ps -aef | grep '$INSTALLDIR/apache/bin/httpd -k start -f $INSTALLDIR/apache/conf/httpd.conf' | grep -v grep | grep root | awk '{print \$2}'\`
    
    if [ "x\$PID" = "x" ];
    then
        echo "httpd not running"
    else
        echo "httpd is running (PID: \$PID)"
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
        echo \$"Usage: $0 {start|stop|restart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/EnterpriseDBApacheHTTPD" || _warn "Failed to set the permissions on the startup script (/etc/init.d/EnterpriseDBApacheHTTPD/)"

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
RET=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /sbin/chkconfig --add EnterpriseDBApacheHTTPD
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

RET=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /usr/sbin/update-rc.d EnterpriseDBApacheHTTPD defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

fi
echo "$0 ran to completion"
exit $WARN

#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir> "
    exit 127
fi

INSTALLDIR=$1

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
cat <<EOT > "/etc/init.d/EnterpriseDBApachePhp"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: Starts and stops the Apache Server

# EnterpriseDBApachePhp Service script for Linux

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
chmod 0755 "/etc/init.d/EnterpriseDBApachePhp" || _warn "Failed to set the permissions on the startup script (/etc/init.d/EnterpriseDBApachePhp/)"

# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
RET=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /sbin/chkconfig --add EnterpriseDBApachePhp
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with chkconfig"
    fi
fi

RET=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /usr/sbin/update-rc.d EnterpriseDBApachePhp defaults
    if [ $? -ne 0 ]; then
        _warn "Failed to configure the service startup with update-rc.d"
    fi
fi

echo "$0 ran to completion"
exit $WARN

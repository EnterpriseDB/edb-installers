#!/bin/sh

if [ $# -ne 1 ];
then
  echo "USAGE: $0 <install_service>"
  exit -1
fi

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

if [ x$1 = x1 ];
then

  # Write the startup script
  cat <<EOT > "/etc/init.d/@@SERVICENAME@@"
#!/bin/bash
#
# chkconfig: 2345 85 25
# description: Postgres Plus HQ Service script for Linux

### BEGIN INIT INFO
# Provides:          pphq
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: @@SERVICENAME@@ 
# Description:       Postgres Plus HQ (version: @@PPHQVERSION@@)
### END INIT INFO

export LD_LIBRARY_PATH=@@INSTALLDIR@@/lib:\$LD_LIBRARY_PATH
export JAVA_HOME=@@JAVAHOME@@

start()
{
    su @@SERVICEUSER@@ -c "@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/@@PPHQSERVERSCRIPT@@ start"
}

stop()
{
    su @@SERVICEUSER@@ -c "@@INSTALLDIR@@/server-@@PPHQVERSION@@/bin/@@PPHQSERVERSCRIPT@@ stop"
}

if [ "\$USER" = "root" -o "\$UID" = "0" -o "\$EUID" = "0" ];
then
     echo "Running Service Script for Postgres Plus HQ: Action(\$1).."
else
     echo ""
     echo "Execution of the service script for the Postgres Plus HQ (@@PPHQVERSION@@) must be done by the root user."
     echo ""
     exit 1;
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
  *)
        echo \$"Usage: \$0 {start|stop|restart}"
        exit 1
esac

exit 0

EOT

  chmod 0755 "/etc/init.d/@@SERVICENAME@@" || _warn "Failed to set the permissions on the startup script (/etc/init.d/@@SERVICENAME@@)"
  
  # Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
  # These utilities aren't entirely standard, so use both from their standard locations on
  # each distro family. 
  CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
  if [ ! $CHKCONFIG ];
  then
      /sbin/chkconfig --add @@SERVICENAME@@
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the service startup with chkconfig"
      fi
  fi
  
  UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
  if [ ! $UPDATECONFIG ];
  then
      /usr/sbin/update-rc.d @@SERVICENAME@@ defaults
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the service startup with update-rc.d"
      fi
  fi
fi

if [ -d "@@INSTALLDIR@@/server-@@PPHQVERSION@@" ];
then
  chown -R @@SERVICEUSER@@ "@@INSTALLDIR@@/server-@@PPHQVERSION@@"
fi

if [ -d "@@INSTALLDIR@@/agent-@@PPHQVERSION@@" ];
then
  chown -R @@SERVICEUSER@@ "@@INSTALLDIR@@/agent-@@PPHQVERSION@@"
fi

echo "$0 ran to completion"
exit $WARN

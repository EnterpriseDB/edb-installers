#!/bin/sh

if [ $# -ne 8 ];
then
  echo "USAGE: $0 <install_server_service:0|1> <install_agent_service:0|1> <Version> <Install-dir> <server-service-name> <agent-service-name> <server-service-user> <agent-service-user>"
  exit -1
fi

INSTALL_SERVER_SERVICE=$1
INSTALL_AGENT_SERVICE=$2
VERSION=$3
INSTALLDIR=$4
SERVERSERVICE=$5
AGENTSERVICE=$6
SERVERUSER=$7
AGENTUSER=$8

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

if [ x$INSTALL_SERVER_SERVICE = x1 ];
then

  # Write the startup script
  cat <<EOT > "/etc/init.d/${SERVERSERVICE}"
#!/bin/bash
#
# chkconfig: 2345 85 22
# description: Postgres Plus HQ Service script for Linux

### BEGIN INIT INFO
# Provides:          pphq
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: ${SERVERSERVICE} 
# Description:       Postgres Plus HQ Server (version: ${VERSION})
### END INIT INFO

if [ "\$USER" = "root" -o "\$UID" = "0" -o "\$EUID" = "0" ];
then
     echo "Running Service Script for Postgres Plus HQ: Action(\$1).."
else
     echo ""
     echo "Execution of the service script for the Postgres Plus HQ (${VERSION}) must be done by the root user."
     echo ""
     exit 1;
fi

# See how we were called.
case "\$1" in
  start)
        action=start
        ;;
  stop)
        action=stop
        ;;
  restart)
        action=restart
        ;;
  *)
        echo \$"Usage: \$0 {start|stop|restart}"
        exit 1
esac

su ${SERVERUSER} -c "\"${INSTALLDIR}/scripts/runServer.sh\" \$action"

exit 0

EOT

  chmod 0755 "/etc/init.d/${SERVERSERVICE}" || _warn "Failed to set the permissions on the startup script (/etc/init.d/${SERVERSERVICE})"
  # Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
  # These utilities aren't entirely standard, so use both from their standard locations on
  # each distro family. 
  CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
  if [ ! $CHKCONFIG ];
  then
      /sbin/chkconfig --add "${SERVERSERVICE}"
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the service startup with chkconfig"
      fi
  fi
  
  UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
  if [ ! $UPDATECONFIG ];
  then
      /usr/sbin/update-rc.d "${SERVERSERVICE}" defaults
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the service startup with update-rc.d"
      fi
  fi

fi

if [ x$INSTALL_AGENT_SERVICE = x1 ];
then
  # Write the startup script for agent
  cat <<EOT > "/etc/init.d/${AGENTSERVICE}"
#!/bin/bash
#
# chkconfig: 2345 85 24
# description: Postgres Plus HQ Agent Service script for Linux

### BEGIN INIT INFO
# Provides:          pphq-agent
# Required-Start:    $syslog
# Required-Stop:     $syslog
# Should-Start:  
# Should-Stop:  
# Default-Start:     2 3 4 5
# Default-Stop:      1 6
# Short-Description: ${AGENTSERVICE} 
# Description:       Postgres Plus HQ Agent (version: ${VERSION})
### END INIT INFO

if [ "\$USER" = "root" -o "\$UID" = "0" -o "\$EUID" = "0" ];
then
     echo "Running Service Script for Postgres Plus HQ Agent: Action(\$1).."
else
     echo ""
     echo "Execution of the service script for the Postgres Plus HQ Agent (${VERSION}) must be done by the root user."
     echo ""
     exit 1;
fi

# See how we were called.
case "\$1" in
  start)
        action=start
        ;;
  stop)
        action=stop
        ;;
  restart)
        action=restart
        ;;
  status)
        action=status
        ;;
  *)
        echo \$"Usage: \$0 {start|stop|restart|status}"
        exit 1
esac

su ${AGENTUSER} -c "\"${INSTALLDIR}/scripts/runAgent.sh\" \$action"

exit 0

EOT

  chmod 0755 "/etc/init.d/${AGENTSERVICE}" || _warn "Failed to set the permissions on the startup script (/etc/init.d/${AGENTSERVICE})"
  
  # Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
  # These utilities aren't entirely standard, so use both from their standard locations on
  # each distro family. 
  CHKCONFIG=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
  if [ ! $CHKCONFIG ];
  then
      /sbin/chkconfig --add "${AGENTSERVICE}"
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the agent service startup with chkconfig"
      fi
  fi
  
  UPDATECONFIG=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
  if [ ! $UPDATECONFIG ];
  then
      /usr/sbin/update-rc.d "${AGENTSERVICE}" defaults
      if [ $? -ne 0 ]; then
          _warn "Failed to configure the agent service startup with update-rc.d"
      fi
  fi
fi

if [ -d "${INSTALLDIR}/server-${VERSION}" ];
then
  chown -R ${SERVERUSER} "${INSTALLDIR}/server-${VERSION}"
fi

if [ -d "${INSTALLDIR}/agent-${VERSION}" ];
then
  chown -R ${AGENTUSER} "${INSTALLDIR}/agent-${VERSION}"
fi

echo "$0 ran to completion"
exit $WARN

#!/bin/sh

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
cat <<EOT > "/sbin/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER"
#!/bin/sh
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

PATH=/usr/sbin:/usr/bin:/sbin
export PATH

function start
{
    PID=\`ps -axef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       # Service Owner should be able to start the service without root password.
       if [ "\`id -un\`" = "$SYSTEM_USER" ];
       then
           LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini
	   echo "pgbouncer-$PGBOUNCER_SERVICE_VER started" 
       else
           su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini " 
	   echo "pgbouncer-$PGBOUNCER_SERVICE_VER started" 
       fi
    else
       echo "pgbouncer-$PGBOUNCER_SERVICE_VER already running"
       exit 0
    fi
}

function _stop
{
    PID=\`ps -axef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
    else
        kill \$PID
	echo "pgbouncer-$PGBOUNCER_SERVICE_VER stopped" 
    fi
}
function status
{
    PID=\`ps -axef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
	exit 1
    else
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER is running (PID: \$PID)"
	exit 0
    fi
}

# See how we were called.
case "\$1" in
  'start_msg')
	echo "Starting pgbouncer-$PGBOUNCER_SERVICE_VER" 
        ;;
  'stop_msg')
	echo "Stopping pgbouncer-$PGBOUNCER_SERVICE_VER" 
        ;;
   start)
        start
        ;;
  stop)
        _stop
        ;;
  restart)
        _stop
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
chmod 0755 "/sbin/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/sbin/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER)"

mkdir /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER
chown -R $SYSTEM_USER /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER

# Create the service initialisation links
INIT_LINKS="/sbin/rc3.d/S86pgbouncer-$PGBOUNCER_SERVICE_VER /sbin/rc0.d/K14pgbouncer-$PGBOUNCER_SERVICE_VER /sbin/rc1.d/K14pgbouncer-$PGBOUNCER_SERVICE_VER /sbin/rc2.d/K14pgbouncer-$PGBOUNCER_SERVICE_VER"
for link_path1 in ${INIT_LINKS} ; do
    rm -f "${link_path1}"
    ln -f -s /sbin/init.d/pgbouncer-$PGBOUNCER_SERVICE_VER "${link_path1}"
done

echo "$0 ran to completion"
exit $WARN

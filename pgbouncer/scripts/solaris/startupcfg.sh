#!/bin/sh
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

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
cat <<EOT > "/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER"
#!/bin/bash

start()
{
    PID=\`/usr/ucb/ps awwx | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:/usr/sfw/lib/64:$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini " 
       exit 0
    else
       echo "pgbouncer-$PGBOUNCER_SERVICE_VER already running"
       exit 1
    fi
}

stop()
{
    PID=\`/usr/ucb/ps awwx | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
        exit 2
    else
        kill \$PID
    fi
}
status()
{
    PID=\`/usr/ucb/ps awwx | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER not running"
    else
        echo "pgbouncer-$PGBOUNCER_SERVICE_VER is running (PID: \$PID)"
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
chmod 0755 "/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER)"

cat /etc/release | grep 'Solaris 10'> /dev/null
if [ $? -eq 0 ]; then
   XML_FILE_PATH=/var/svc/manifest/application/pgbouncer-$PGBOUNCER_SERVICE_VER.xml
else
   XML_FILE_PATH=$INSTALL_DIR/installer/pgbouncer/pgbouncer-$PGBOUNCER_SERVICE_VER.xml
fi

cat <<EOT > "$XML_FILE_PATH"
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">

<service_bundle type='manifest' name='pgbouncer-$PGBOUNCER_SERVICE_VER'>

<service
        name='application/pgbouncer-$PGBOUNCER_SERVICE_VER'
        type='service'
        version='1'>

        <single_instance/>
      
        <!--
           Wait for network interfaces to be initialized.
        -->
        <dependency
                name='network'
                grouping='require_all'
                restart_on='none'
                type='service'>
                <service_fmri value='svc:/milestone/network:default' />
        </dependency>

        <!--
           Wait for all local filesystems to be mounted.
        -->
        <dependency
                name='filesystem-local'
                grouping='require_all'
                restart_on='none'
                type='service'>
                <service_fmri value='svc:/system/filesystem/local:default' />
        </dependency>

        <exec_method
                type='method'
                name='start'
                exec='/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER start'
                timeout_seconds='60' />
        <exec_method
                type='method'
                name='stop'
                exec='/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER stop'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='restart'
                exec='/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER restart'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='status'
                exec='/lib/svc/method/pgbouncer-$PGBOUNCER_SERVICE_VER status'
                timeout_seconds='60' />

        <!--
          Both action_authorization and value_authorization are needed
          to allow the framework general/enabled property to be changed
          when performing action (enable, disable, etc) on the service.
        -->
        <property_group name='general' type='framework'>
                <propval name='value_authorization' type='astring'
                        value='solaris.smf.value.$SYSTEM_USER' />
                <propval name='action_authorization' type='astring'
                        value='solaris.smf.manage.$SYSTEM_USER' />
        </property_group>

        <instance name='default' enabled='true' />

        <template>
                <common_name>
                        <loctext xml:lang='C'>
                           PgBouncer-$PGBOUNCER_SERVICE_VER: Connection Pooler for PostgreSQL RDBMS     
                        </loctext>
                </common_name>
        </template>
</service>

</service_bundle>
EOT

mkdir /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER
chown -R $SYSTEM_USER /var/log/pgbouncer-$PGBOUNCER_SERVICE_VER

svccfg import $XML_FILE_PATH

echo "$0 ran to completion"
exit $WARN

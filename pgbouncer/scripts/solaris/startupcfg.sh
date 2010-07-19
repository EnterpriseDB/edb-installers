#!/bin/sh

# Check the command line
if [ $# -ne 2 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2

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
cat <<EOT > "/lib/svc/method/pgbouncer"
#!/bin/bash

start()
{
    PID=\`ps -aef | grep '$INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini' | grep -v grep | awk '{print \$2}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "LD_LIBRARY_PATH=$INSTALL_DIR/lib:/usr/sfw/lib/64:$LD_LIBRARY_PATH $INSTALL_DIR/bin/pgbouncer -d $INSTALL_DIR/share/pgbouncer.ini " 
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
chmod 0755 "/lib/svc/method/pgbouncer" || _warn "Failed to set the permissions on the startup script (/etc/init.d/pgbouncer/)"


cat <<EOT > "/var/svc/manifest/application/pgbouncer.xml"
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">

<service_bundle type='manifest' name='pgbouncer'>

<service
        name='application/pgbouncer'
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
                exec='/lib/svc/method/pgbouncer start'
                timeout_seconds='60' />
        <exec_method
                type='method'
                name='stop'
                exec='/lib/svc/method/pgbouncer stop'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='restart'
                exec='/lib/svc/method/pgbouncer restart'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='status'
                exec='/lib/svc/method/pgbouncer status'
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
                           PgBouncer: Connection Pooler for PostgreSQL RDBMS     
                        </loctext>
                </common_name>
        </template>
</service>

</service_bundle>
EOT

mkdir /var/log/pgbouncer
chown $SYSTEM_USER /var/log/pgbouncer

svccfg import /var/svc/manifest/application/pgbouncer.xml

echo "$0 ran to completion"
exit $WARN

#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL startup configuration script for Linux

# Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Install dir> <Data dir> <ServiceName>"
    exit 127
fi

VERSION=$1
USERNAME=$2
INSTALLDIR=$3
DATADIR=$4
SERVICENAME=$5

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
cat <<EOT > "/lib/svc/method/$SERVICENAME"
#!/bin/bash
#

# PostgreSQL Service script for Solaris

start()
{
	echo \$"Starting PostgreSQL $VERSION: "
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl -w start -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\""
	
	if [ \$? -eq 0 ];
	then
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
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl stop -m fast -w -D \"$DATADIR\""
}

# See how we were called.
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart|reload)
        stop
        sleep 3
        start
        ;;
  condrestart)
        if [ -f "$DATADIR/postmaster.pid" ]; then
            stop
            sleep 3
            start
        fi
        ;;
  status)
        su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl status -D \"$DATADIR\""
        ;;
  *)
        echo \$"Usage: $0 {start|stop|restart|condrestart|status}"
        exit 1
esac

EOT


cat <<EOT > "/var/svc/manifest/application/database/$SERVICENAME.xml"
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">

<service_bundle type='manifest' name='$SERVICENAME'>

<service
        name='application/database/$SERVICENAME'
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
                exec='/lib/svc/method/$SERVICENAME start'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='stop'
                exec='/lib/svc/method/$SERVICENAME stop'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='restart'
                exec='/lib/svc/method/$SERVICENAME restart'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='condrestart'
                exec='/lib/svc/method/$SERVICENAME condrestart'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='status'
                exec='/lib/svc/method/$SERVICENAME status'
                timeout_seconds='60' />

        <!--
          Both action_authorization and value_authorization are needed
          to allow the framework general/enabled property to be changed
          when performing action (enable, disable, etc) on the service.
        -->
        <property_group name='general' type='framework'>
                <propval name='value_authorization' type='astring'
                        value='solaris.smf.value.$USERNAME' />
                <propval name='action_authorization' type='astring'
                        value='solaris.smf.manage.$USERNAME' />
        </property_group>

        <instance name='default' enabled='true' />

        <template>
                <common_name>
                        <loctext xml:lang='C'>
                           PostgreSQL-$VERSION RDBMS     
                        </loctext>
                </common_name>
        </template>

</service>

</service_bundle>
EOT


# Fixup the permissions on the StartupItems
chmod 0755 "/lib/svc/method/$SERVICENAME" || _warn "Failed to set the permissions on the startup script (/etc/init.d/$SERVICENAME)"

svccfg import /var/svc/manifest/application/database/$SERVICENAME.xml

echo "$0 ran to completion"
exit $WARN

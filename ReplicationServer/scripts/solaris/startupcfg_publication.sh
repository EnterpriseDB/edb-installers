#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 5 ]; 
then
echo "Usage: $0 <Installdir> <SystemUser> <PubPort> <Java Executable> <DBSERVER_VER>"
    exit 127
fi

INSTALL_DIR="$1"
SYSTEM_USER=$2
PUBPORT=$3
JAVA="$4"
XDB_SERVICE_VER=$5

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
cat <<EOT > "/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER"
#!/bin/bash

start()
{
    PID=\`/usr/ucb/ps awwx | grep 'java -XX:-UsePerfData -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
       su $SYSTEM_USER -c "cd '$INSTALL_DIR/bin'; '$JAVA' -XX:-UsePerfData -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT > /dev/null 2>&1 &"
       exit 0
    else
       echo "Publication Service $XDB_SERVICE_VER already running"
       exit 1
    fi
}

stop()
{
    PID=\`/usr/ucb/ps awwx | grep 'java -XX:-UsePerfData -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "Publication Service $XDB_SERVICE_VER not running"
        exit 2
    else
        kill \$PID 
    fi
}

status()
{
    PID=\`/usr/ucb/ps awwx | grep 'java -XX:-UsePerfData -Djava.awt.headless=true -jar edb-repserver.jar pubserver $PUBPORT' | grep -v grep | awk '{print \$1}'\`

    if [ "x\$PID" = "x" ];
    then
        echo "Publication Service $XDB_SERVICE_VER not running"
        exit 2
    else
        echo "Publication Service $XDB_SERVICE_VER (PID:\$PID) is running" 
        exit 2
    fi

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
        echo \$"Usage: \$0 {start|stop|restart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER" || _warn "Failed to set the permissions on the startup script (/lib/svc/method/xdbpubserver-$XDB_SERVICE_VER)"

cat /etc/release | grep 'Solaris 10'> /dev/null
if [ $? -eq 0 ]; then
   XML_FILE_PATH=/var/svc/manifest/application/edb-xdbpubserver-$XDB_SERVICE_VER.xml
else
   XML_FILE_PATH="$INSTALL_DIR/installer/xDBReplicationServer/edb-xdbpubserver-$XDB_SERVICE_VER.xml"
fi

cat <<EOT > "$XML_FILE_PATH"
<?xml version="1.0"?>
<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">

<service_bundle type='manifest' name='edb-xdbpubserver-$XDB_SERVICE_VER'>

<service
        name='application/edb-xdbpubserver-$XDB_SERVICE_VER'
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
                exec='/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER start'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='stop'
                exec='/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER stop'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='restart'
                exec='/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER restart'
                timeout_seconds='60' />

        <exec_method
                type='method'
                name='status'
                exec='/lib/svc/method/edb-xdbpubserver-$XDB_SERVICE_VER status'
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
                           Publication Service $XDB_SERVICE_VER for xDB Replication Server     
                        </loctext>
                </common_name>
        </template>

</service>

</service_bundle>
EOT


#Create directory for logs
if [ ! -e /var/log/xdb-rep ]; 
then
    mkdir -p /var/log/xdb-rep
    chown $SYSTEM_USER /var/log/xdb-rep
fi
chmod 755 /var/log/xdb-rep

svccfg import $XML_FILE_PATH

echo "$0 ran to completion"
exit $WARN

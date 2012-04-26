#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 6 ]; 
then
echo "Usage: $0 <PG_HOST> <PG_PORT> <PG_USER> <SYSTEM_USER> <Install dir> <PG_DATABASE>"
    exit 127
fi

PG_HOST=$1
PG_PORT=$2
PG_USER=$3
SYSTEM_USER=$4
INSTALL_DIR=$5
PG_DATABASE=$6
USER_HOME_DIR=`su $SYSTEM_USER -c "echo ~"`

if [ ! -f $USER_HOME_DIR ]; then
    mkdir -p $USER_HOME_DIR
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

touch /var/log/pgagent.log
chown $SYSTEM_USER /var/log/pgagent.log
pgpassline=`cat $INSTALL_DIR/installer/pgAgent/pgpass`
chk=`grep $pgpassline $USER_HOME_DIR/.pgpass`
if [ "x$chk" = "x" ];
then
    cat $INSTALL_DIR/installer/pgAgent/pgpass >> $USER_HOME_DIR/.pgpass
fi
chown $SYSTEM_USER $USER_HOME_DIR/.pgpass
chmod 0600 $USER_HOME_DIR/.pgpass

# Configure database startup
if [ ! -e /Library/LaunchDaemons ]; then
    mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"
fi

# Write the plist file
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.pgagent.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.pgagent</string>
        <key>ProgramArguments</key>
        <array>
                <string>$INSTALL_DIR/bin/pgagent</string>
                <string>-f</string>
                <string>-l1</string>
                <string>-s</string>
                <string>/var/log/pgagent.log</string>
                <string>host=$PG_HOST</string> 
                <string>port=$PG_PORT</string> 
                <string>dbname=$PG_DATABASE</string> 
                <string>user=$PG_USER</string> 
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
    <string>$SYSTEM_USER</string>
    <key>KeepAlive</key>
    <dict>
         <key>SuccessfulExit</key>
         <false/>
    </dict>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.pgagent.plist" || _warn "Failed to set the ownership of the launchd daemon for pgAgent (/Library/LaunchDaemons/com.edb.launchd.pgagent.plist)"

echo "$0 ran to completion"
exit $WARN

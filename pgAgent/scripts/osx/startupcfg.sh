#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <PGPORT> <PGUSER> <SYSTEM_USER> <Install dir> "
    exit 127
fi

PG_PORT=$1
PG_USER=$2
SYSTEM_USER=$3
INSTALL_DIR=$4
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

touch $INSTALL_DIR/pgAgent/service.log
chown $SYSTEM_USER $INSTALL_DIR/pgAgent/service.log
cat $INSTALL_DIR/pgAgent/installer/pgAgent/pgpass >> $USER_HOME_DIR/.pgpass
chown $SYSTEM_USER $USER_HOME_DIR/.pgpass
chmod 0600 $USER_HOME_DIR/.pgpass

# Configure database startup
mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"

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
                <string>$INSTALL_DIR/pgAgent/installer/pgAgent/pgagentctl.sh</string>
                <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
        <string>root</string>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.pgagent.plist" || _warn "Failed to set the ownership of the launchd daemon for pgAgent (/Library/LaunchDaemons/com.edb.launchd.pgagent.plist)"

echo "$0 ran to completion"
exit $WARN

#!/bin/sh

# Check the command line
if [ $# -ne 2 ]; 
then
echo "Usage: $0 <Install dir> <System User>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Configure database startup
if [ ! -e /Library/LaunchDaemons ]; then
    mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"
fi

# Write the plist file
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.pgbouncer.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.pgbouncer</string>
        <key>ProgramArguments</key>
        <array>
                <string>$INSTALL_DIR/installer/pgbouncer/pgbouncerctl.sh</string>
                <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
        <string>root</string>
</dict>
</plist>
EOT

mkdir /var/run/pgbouncer
chown $SYSTEM_USER /var/run/pgbouncer
mkdir /var/log/pgbouncer
chown $SYSTEM_USER /var/log/pgbouncer

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.pgbouncer.plist" || _warn "Failed to set the ownership of the launchd daemon for pgbouncer (/Library/LaunchDaemons/com.edb.launchd.pgbouncer.plist)"

echo "$0 ran to completion"
exit $WARN

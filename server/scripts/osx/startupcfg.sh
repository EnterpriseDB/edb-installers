#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server startup configuration script for OSX

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

# Configure database startup
if [ ! -e /Library/LaunchDaemons ]; then
    mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"
fi

# Write the plist file
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.$SERVICENAME.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Disabled</key>
    <false/>
        <key>Label</key>
        <string>com.edb.launchd.$SERVICENAME</string>
        <key>ProgramArguments</key>
        <array>
                <string>$INSTALLDIR/bin/postmaster</string>
                <string>-D$DATADIR</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    <key>UserName</key>
    <string>$USERNAME</string>
    <key>KeepAlive</key>
    <dict>
         <key>SuccessfulExit</key>
         <false/>
    </dict>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.$SERVICENAME.plist" || _warn "Failed to set the ownership of the launchd daemon for pgAgent (/Library/LaunchDaemons/com.edb.launchd.$SERVICENAME.plist)"

# Load the LaunchAgent
launchctl load /Library/LaunchDaemons/com.edb.launchd.$SERVICENAME.plist

echo "$0 ran to completion"
exit $WARN

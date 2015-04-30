#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Install dir> "
    exit 127
fi

INSTALLDIR=$1

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
mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"

# Write the plist file
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.apache.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.apache</string>
        <key>ProgramArguments</key>
        <array>
                <string>$INSTALLDIR/apache/bin/httpd</string>
                <string>-D</string>
                <string>FOREGROUND</string>
                <string>-f</string>
                <string>$INSTALLDIR/apache/conf/httpd.conf</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	    <key>UserName</key>
        <string>root</string>
        <key>KeepAlive</key>
        <dict>
             <key>SuccessfulExit</key>
             <false/>
        </dict> 
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.apache.plist" || _warn "Failed to set the ownership of the launchd daemon for apache (/Library/LaunchDaemons/com.edb.launchd.apache.plist)"

# Load the LaunchDaemon
launchctl load /Library/LaunchDaemons/com.edb.launchd.apache.plist

# Start the apache daemon
launchctl start com.edb.launchd.apache

echo "$0 ran to completion"
exit $WARN

#!/bin/sh

# Check the command line
if [ $# -ne 3 ]; 
then
echo "Usage: $0 <Install dir> <System User> <PubPort>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
PUBPORT=$3

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
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.pubserver.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.pubserver</string>
        <key>ProgramArguments</key>
        <array>
                <string>java</string>
                <string>-jar</string>
                <string>$INSTALL_DIR/bin/edb-repserver.jar</string>
                <string>pubserver</string>
                <string>$PUBPORT</string>
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
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.pubserver.plist" || _warn "Failed to set the ownership of the launchd daemon for pubserver (/Library/LaunchDaemons/com.edb.launchd.pubserver.plist)"

#Create directory for logs
if [ ! -e $INSTALL_DIR/bin/logs ];
then
    mkdir -p $INSTALL_DIR/bin/logs
    chown $SYSTEM_USER $INSTALL_DIR/bin/logs
fi

# Load the plist.
launchctl load /Library/LaunchDaemons/com.edb.launchd.pubserver.plist || _warn "Failed to load the pubserver launchd plist"

echo "$0 ran to completion"
exit $WARN

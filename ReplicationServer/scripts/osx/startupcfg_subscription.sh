#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
echo "Usage: $0 <Install dir> <System User> <SubPort> <Java Executable>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
SUBPORT=$3
JAVA=$4

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
cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.xdbsubserver.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.xdbsubserver</string>
        <key>ProgramArguments</key>
        <array>
                <string>$JAVA</string>
                <string>-jar</string>
                <string>$INSTALL_DIR/bin/edb-repserver.jar</string>
                <string>subserver</string>
                <string>$SUBPORT</string>
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
        <key>WorkingDirectory</key> 
        <string>$INSTALL_DIR/bin</string>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.xdbsubserver.plist" || _warn "Failed to set the ownership of the launchd daemon for xdbsubserver (/Library/LaunchDaemons/com.edb.launchd.xdbsubserver.plist)"

#Create directory for logs
if [ ! -e $INSTALL_DIR/bin/logs ];
then
    mkdir -p $INSTALL_DIR/bin/logs
    chown $SYSTEM_USER $INSTALL_DIR/bin/logs
fi

# Load the plist.
launchctl load /Library/LaunchDaemons/com.edb.launchd.xdbsubserver.plist || _warn "Failed to load the xdbsubserver launchd plist"

echo "$0 ran to completion"
exit $WARN

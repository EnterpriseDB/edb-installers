#!/bin/sh

# Check the command line
if [ $# -ne 4 ]; 
then
echo "Usage: $0 <Install dir> <System_User> <PG_Version> <Branding>"
    exit 127
fi

INSTALL_DIR=$1
SYSTEM_USER=$2
VERSION=$3
BRANDING=$4

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
if [ ! -e /Library/LaunchAgents ]; then
    mkdir -p /Library/LaunchAgents || _die "Failed to create directory for stackbuilderplus agent"
fi

# Write the plist file
cat <<EOT > "/Library/LaunchAgents/com.edb.launchd.stackbuilderplus.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>Label</key>
        <string>com.edb.launchd.stackbuilderplus</string>
        <key>WorkingDirectory</key>
        <string>$INSTALL_DIR/UpdateManager.app/Contents/MacOS</string>
        <key>ProgramArguments</key>
        <array>
                <string>$INSTALL_DIR/UpdateManager.app/Contents/MacOS/UpdateManager</string>
                <string>--server</string>
                <string>$VERSION</string>
                <string>--execute</string>
                <string>/Applications/$BRANDING/StackBuilder Plus.app/Contents/MacOS/applet</string> 
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>UserName</key>
        <string>$SYSTEM_USER</string>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchAgents/com.edb.launchd.stackbuilderplus.plist" || _warn "Failed to set the ownership of the launchd Agent for stackbuilderplus (/Library/LaunchAgents/com.edb.launchd.stackbuilderplus.plist)"

# Load the Agent
launchctl load /Library/LaunchAgents/com.edb.launchd.stackbuilderplus.plist || _warn " Failed to load the stackbuilderplus agent"

echo "$0 ran to completion"
exit $WARN

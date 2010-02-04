#!/bin/sh

# Check the command line
if [ $# -ne 1 ]; 
then
  echo "Usage: $0 <install_service>"
  exit 127
fi

# Exit code
WARN=0

_warn() {
    echo $1
    WARN=2
}

# Configure database startup
if [ ! -e /Library/LaunchDaemons ]; then
    mkdir -p /Library/LaunchDaemons || _die "Failed to create directory for root daemons"
fi

if [ x$1 = x1 ]; then
  # Write the plist file
  cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.@@SERVICENAME@@.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.@@SERVICENAME@@</string>
        <key>ProgramArguments</key>
        <array>
                <string>@@INSTALLDIR@@/scripts/serverctl.sh</string>
                <string>--no-debug</string>
                <string>--start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
        <string>@@SERVICEUSER@@</string>
        <key>KeepAlive</key>
    <dict>
         <key>SuccessfulExit</key>
         <false/>
    </dict>
</dict>
</plist>
EOT

# Fixup the permissions on the launchDaemon
chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.@@SERVICENAME@@.plist" || _warn "Failed to set the ownership of the launchd daemon for @@SERVICENAME@@ (/Library/LaunchDaemons/com.edb.launchd.@@SERVICENAME@@.plist)"
fi

if [ -d "@@INSTALLDIR@@/server-@@PPHQVERSION@@" ];
then
  chown -R @@SERVICEUSER@@ "@@INSTALLDIR@@/server-@@PPHQVERSION@@"
fi

if [ -d "@@INSTALLDIR@@/agent-@@PPHQVERSION@@" ];
then
  chown -R @@SERVICEUSER@@ "@@INSTALLDIR@@/agent-@@PPHQVERSION@@"
fi

echo "$0 ran to completion"
exit $WARN

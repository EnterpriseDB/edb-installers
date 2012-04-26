#!/bin/sh 
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

if [ $# -ne 8 ];
then
  echo "USAGE: $0 <install_server_service:0|1> <install_agent_service:0|1> <Version> <Install-dir> <server-service-name> <agent-service-name> <server-service-user> <agent-service-user>"
  exit -1
fi

INSTALL_SERVER_SERVICE=$1
INSTALL_AGENT_SERVICE=$2
VERSION=$3
INSTALLDIR=$4
SERVERSERVICE=$5
AGENTSERVICE=$6
SERVICEUSER=$7
AGENTUSER=$8

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

if [ x$INSTALL_SERVER_SERVICE = x1 ]; then
  # Write the plist file
  cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.${SERVERSERVICE}.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.${SERVERSERVICE}</string>
        <key>ProgramArguments</key>
        <array>
                <string>${INSTALLDIR}/scripts/serverctl.sh</string>
                <string>--no-debug</string>
                <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
        <string>${SERVICEUSER}</string>
        <key>KeepAlive</key>
    <dict>
         <key>SuccessfulExit</key>
         <false/>
    </dict>
</dict>
</plist>
EOT

  # Fixup the permissions on the launchDaemon
  chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.${SERVERSERVICE}.plist" || _warn "Failed to set the ownership of the launchd daemon for ${SERVERSERVICE} (/Library/LaunchDaemons/com.edb.launchd.${SERVERSERVICE}.plist)"
fi

if [ x$INSTALL_AGENT_SERVICE = x1 ]; then
  # Write the plist file
  cat <<EOT > "/Library/LaunchDaemons/com.edb.launchd.${AGENTSERVICE}.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Disabled</key>
	<false/>
        <key>Label</key>
        <string>com.edb.launchd.${AGENTSERVICE}</string>
        <key>ProgramArguments</key>
        <array>
                <string>${INSTALLDIR}/scripts/agentctl.sh</string>
                <string>--no-debug</string>
                <string>start</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
	<key>UserName</key>
        <string>${AGENTSERVICEUSER}</string>
        <key>KeepAlive</key>
    <dict>
         <key>SuccessfulExit</key>
         <false/>
    </dict>
</dict>
</plist>
EOT

  # Fixup the permissions on the launchDaemon
  chown -R root:wheel "/Library/LaunchDaemons/com.edb.launchd.${AGENTSERVICE}.plist" || _warn "Failed to set the ownership of the launchd daemon for ${AGENTSERVICE} (/Library/LaunchDaemons/com.edb.launchd.${AGENTSERVICE}.plist)"
fi

if [ -d "${INSTALLDIR}/server-${VERSION}" ];
then
  chown -R ${SERVICEUSER} "${INSTALLDIR}/server-${VERSION}"
fi

if [ -d "${INSTALLDIR}/agent-${VERSION}" ];
then
  chown -R ${AGENTUSER} "${INSTALLDIR}/agent-${VERSION}"
fi

echo "$0 ran to completion"
exit $WARN

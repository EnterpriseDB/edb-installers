#!/bin/sh

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
mkdir -p "/Library/StartupItems/EnterpriseDB-ApachePhp" || _die "Failed to create the startup directory (/Library/StartupItems/EnterpriseDB-ApachePhp)"

# Write the plist file
cat <<EOT > "/Library/StartupItems/EnterpriseDB-ApachePhp/StartupParameters.plist"
{
  Description   = "EnterpriseDB-ApachePhp";
  Provides      = ("EnterpriseDB-ApachePhp");
  Requires      = ("Resolver");
  Preference    = "Late";
  Messages =
  {
    start = "Starting Apache";
    stop  = "Stopping Apache";
    restart  = "Restarting Apache";
  };
}
EOT

# Write the startup script
cat <<EOT > "/Library/StartupItems/EnterpriseDB-ApachePhp/EnterpriseDBApachePhp"
#!/bin/sh

. /etc/rc.common

# /EnterpriseDB-ApachePhp Service script for OS/X

StartService ()
{
	ConsoleMessage "Starting Apache"
	su -c "$INSTALLDIR/apache/bin/apachectl start"
	ConsoleMessage "Apache started successfully"
}

StopService()
{
	ConsoleMessage "Stopping Apache"
	su -c "$INSTALLDIR/apache/bin/apachectl stop"
	ConsoleMessage "Apache stoped successfully"
}


RestartService ()
{
    StopService
    sleep 2
    StartService
}


RunService "\$1"
EOT

# Fixup the permissions on the StartupItems
chown -R root:wheel "/Library/StartupItems/EnterpriseDB-ApachePhp/" || _warn "Failed to set the ownership of the startup item (/Library/StartupItems/EnterpriseDB-ApachePhp/)"
chmod 0755 "/Library/StartupItems/EnterpriseDB-ApachePhp/" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/EnterpriseDB-ApachePhp/)"
chmod 0755 "/Library/StartupItems/EnterpriseDB-ApachePhp/EnterpriseDBApachePhp" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/EnterpriseDB-ApachePhp/EnterpriseDBApachePhp)"
chmod 0644 "/Library/StartupItems/EnterpriseDB-ApachePhp/StartupParameters.plist" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/EnterpriseDB-ApachePhp/StartupParameters.plist)"

echo "$0 ran to completion"
exit $WARN

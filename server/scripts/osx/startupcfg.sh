#!/bin/sh

# PostgreSQL server startup configuration script for OSX
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Install dir> <Data dir>"
    exit 127
fi

VERSION=$1
USERNAME=$2
INSTALLDIR=$3
DATADIR=$4

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
mkdir -p "/Library/StartupItems/postgresql-$VERSION" || _die "Failed to create the startup directory (/Library/StartupItems/postgresql-$VERSION)"

# Write the plist file
cat <<EOT > "/Library/StartupItems/postgresql-$VERSION/StartupParameters.plist"
{
  Description   = "PostgreSQL $VERSION";
  Provides      = ("postgresql-$VERSION");
  Requires      = ("Resolver");
  Preference    = "Late";
  Messages =
  {
    start = "Starting PostgreSQL $VERSION";
    stop  = "Stopping PostgreSQL $VERSION";
  };
}
EOT

# Write the startup script
cat <<EOT > "/Library/StartupItems/postgresql-$VERSION/postgresql-$VERSION"
#!/bin/sh

. /etc/rc.common

# Postgres Plus Service script for OS/X

StartService ()
{
	ConsoleMessage "Starting PostgreSQL $VERSION"
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl -w start -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\""
	
	if [ -e "$DATADIR/postmaster.pid" ]
	then
		ConsoleMessage "PostgreSQL $VERSION started successfully"
	else
		ConsoleMessage "PostgreSQL $VERSION did not start in a timely fashion, please see $DATADIR/pg_log/startup.log for details"
	fi
}

StopService()
{
	ConsoleMessage "Stopping PostgreSQL $VERSION"
	su - $USERNAME -c "$INSTALLDIR/bin/pg_ctl stop -m fast -w -D \"$DATADIR\""
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
chown -R root:wheel "/Library/StartupItems/postgresql-$VERSION/" || _warn "Failed to set the ownership of the startup item (/Library/StartupItems/postgresql-$VERSION/)"
chmod 0755 "/Library/StartupItems/postgresql-$VERSION/" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/postgresql-$VERSION/)"
chmod 0755 "/Library/StartupItems/postgresql-$VERSION/postgresql-$VERSION" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/postgresql-$VERSION/postgresql-$VERSION)"
chmod 0644 "/Library/StartupItems/postgresql-$VERSION/StartupParameters.plist" || _warn "Failed to set the permissions on the startup item (/Library/StartupItems/postgresql-$VERSION/StartupParameters.plist)"

echo "$0 ran to completion"
exit $WARN

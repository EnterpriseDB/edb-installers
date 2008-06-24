#!/bin/sh

# PostgreSQL cluster init script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 6 ]; 
then
    echo "Usage: $0 <Username> <Password> <Install dir> <Data dir> <Port> <Locale>"
    exit 127
fi

SUPERNAME=$1
SUPERPASSWORD=$2
INSTALLDIR=$3
DATADIR=$4
PORT=$5
LOCALE=$6

# Exit code
WARN=0

# Error handlers
_die() {
    if [ -f /tmp/initdbpw.$$ ];
    then
        rm -rf /tmp/initdbpw.$$
    fi
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Create a password file
touch /tmp/initdbpw.$$ || _die "Failed to create the initdb password file (/tmp/initdbpw.$$)"
chmod 0600 /tmp/initdbpw.$$ || _die "Failed to set the permissions on the initdb password file (/tmp/initdbpw.$$)"
echo "$SUPERPASSWORD" > /tmp/initdbpw.$$ || _die "Failed to write the initdb password file (/tmp/initdbpw.$$)"
chown $SUPERNAME:$SUPERNAME /tmp/initdbpw.$$ || _die "Failed to set the ownership of the initdb password file (/tmp/initdbpw.$$)"

# Create the data directory, and set the appropriate permissions/owership
if [ ! -d "$DATADIR" ];
then
    mkdir "$DATADIR" || _die "Failed to create the data directory ($DATADIR)"
fi
chown $SUPERNAME:$SUPERNAME "$DATADIR" || _die "Failed to set the ownership of the data directory ($DATADIR)"

# Initialise the database cluster
su - $SUPERNAME -c "$INSTALLDIR/bin/initdb --pwfile /tmp/initdbpw.$$ --locale=$LOCALE -A md5 -D \"$DATADIR\"" || _die "Failed to initialise the database cluster with initdb"
if [ ! -d "$INSTALLDIR/logs" ];
then
    mkdir "$INSTALLDIR/logs" || _die "Failed to create the log directory ($INSTALLDIR/logs)"
fi
chown $SUPERNAME:$SUPERNAME "$INSTALLDIR/logs" || _die "Failed to set the ownership of the log directory ($INSTALLDIR/logs)"
rm /tmp/initdbpw.$$ || _warn "Failed to remove the initdb password file (/tmp/initdbpw.$$)"

# Edit the config files.
# Set the following in postgresql.conf:
#      listen_addresses = '*'
#      port = $PORT
#      log_destination = 'stderr'
#      logging_collector = on
su - $SUPERNAME -c "sed -e \"s@\#listen_addresses = \'localhost\'@listen_addresses = \'*\'@g\" \
                        -e \"s@\#port = 5432@port = $PORT@g\" \
                        -e \"s@\#log_destination = \'stderr\'@log_destination = \'stderr\'@g\" \
                        -e \"s@\#logging_collector = off@logging_collector = on@g\" \
                        $DATADIR/postgresql.conf > /tmp/postgresql.conf.$$" || _warn "Failed to modify the postgresql.conf file ($DATADIR/postgresql.conf)"
su - $SUPERNAME -c "mv /tmp/postgresql.conf.$$ $DATADIR/postgresql.conf" || _warn "Failed to update the postgresql.conf file ($DATADIR/postgresql.conf)"

echo "$0 ran to completion"
exit $WARN

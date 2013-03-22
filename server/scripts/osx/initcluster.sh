#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL cluster init script for OSX

#Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <Username> <Install dir> <Data dir> <Port> <Locale>"
    exit 127
fi

SUPERNAME=$1
SUPERPASSWORD=$PGPASSWORD
INSTALLDIR=$2
DATADIR=$3
PORT=$4
LOCALE=$5

# Exit code
WARN=0

# Error handlers
_die() {
    if [ -f $INSTALLDIR/installer/server/initdbpw.$$ ];
    then
        rm -rf $INSTALLDIR/installer/server/initdbpw.$$
    fi
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Create a password file
touch $INSTALLDIR/installer/server/initdbpw.$$ || _die "Failed to create the initdb password file ($INSTALLDIR/installer/server/initdbpw.$$)"
chmod 0600 $INSTALLDIR/installer/server/initdbpw.$$ || _die "Failed to set the permissions on the initdb password file ($INSTALLDIR/installer/server/initdbpw.$$)"
echo "$SUPERPASSWORD" > $INSTALLDIR/installer/server/initdbpw.$$ || _die "Failed to write the initdb password file ($INSTALLDIR/installer/server/initdbpw.$$)"
chown $SUPERNAME:daemon $INSTALLDIR/installer/server/initdbpw.$$ || _die "Failed to set the ownership of the initdb password file ($INSTALLDIR/installer/server/initdbpw.$$)"

# Create the data directory, and set the appropriate permissions/owership
if [ ! -d "$DATADIR" ];
then
    mkdir -p "$DATADIR" || _die "Failed to create the data directory ($DATADIR)"
fi
chown $SUPERNAME:daemon "$DATADIR" || _die "Failed to set the ownership of the data directory ($DATADIR)"

# Initialise the database cluster. Specify the encoding if we're using the default locale, otherwise we'll probably get ASCII
if [ $LOCALE = "DEFAULT" ];
then
    su - $SUPERNAME -c "$INSTALLDIR/bin/initdb --pwfile $INSTALLDIR/installer/server/initdbpw.$$ --encoding=utf8 -A md5 -D \"$DATADIR\"" || _die "Failed to initialise the database cluster with initdb"
else
    su - $SUPERNAME -c "$INSTALLDIR/bin/initdb --pwfile $INSTALLDIR/installer/server/initdbpw.$$ --locale=$LOCALE -A md5 -D \"$DATADIR\"" || _die "Failed to initialise the database cluster with initdb"
fi	
	
if [ ! -d "$DATADIR/pg_log" ];
then
    mkdir "$DATADIR/pg_log" || _die "Failed to create the log directory ($DATADIR/pg_log)"
fi
chown $SUPERNAME:daemon "$DATADIR/pg_log" || _die "Failed to set the ownership of the log directory ($DATADIR/pg_log)"
rm $INSTALLDIR/installer/server/initdbpw.$$ || _warn "Failed to remove the initdb password file ($INSTALLDIR/installer/server/initdbpw.$$)"

# Edit the config files.
# Set the following in postgresql.conf:
#      listen_addresses = '*'
#      port = $PORT
#      log_destination = 'stderr'
#      logging_collector = on
#      log_line_prefix = '%t '
su - $SUPERNAME -c "sed -e \"s@\#listen_addresses = 'localhost'@listen_addresses = '*'@g\" \
                        -e \"s@\#port = 5432@port = $PORT@g\" \
                        -e \"s@\#log_destination = 'stderr'@log_destination = 'stderr'@g\" \
                        -e \"s@\#logging_collector = off@logging_collector = on@g\" \
                        -e \"s@\#log_line_prefix = ''@log_line_prefix = '%t '@g\" \
                        $DATADIR/postgresql.conf > $DATADIR/postgresql.conf.$$" || _warn "Failed to modify the postgresql.conf file ($DATADIR/postgresql.conf)"
su - $SUPERNAME -c "mv $DATADIR/postgresql.conf.$$ $DATADIR/postgresql.conf" || _warn "Failed to update the postgresql.conf file ($DATADIR/postgresql.conf)"

echo "$0 ran to completion"
exit $WARN

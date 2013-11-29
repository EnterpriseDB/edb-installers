#!/bin/sh
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server module load script for OSX

#Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <OSUsername> <SuperUsername> <Install dir> <Port>"
    exit 127
fi
OSUSERNAME=$1
SUPERUSERNAME=$2
PASSWORD=$PGPASSWORD
INSTALLDIR=$3
PORT=$4

# Exit code
WARN=0

# Error handlers
_die() {
    if [ -f $INSTALLDIR/installer/server/pgpass.$$ ];
    then
        rm -rf $INSTALLDIR/installer/server/pgpass.$$
    fi
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Create a password file for later
touch $INSTALLDIR/installer/server/pgpass.$$ || _die "Failed to create the password file ($INSTALLDIR/installer/server/pgpass.$$)"
chmod 0600 $INSTALLDIR/installer/server/pgpass.$$ || _die "Failed to set the permissions on the password file ($INSTALLDIR/installer/server/pgpass.$$)"
echo "localhost:$PORT:*:$SUPERUSERNAME:$PASSWORD" > $INSTALLDIR/installer/server/pgpass.$$ || _die "Failed to write the password file ($INSTALLDIR/installer/server/pgpass.$$)"
chown $OSUSERNAME:daemon $INSTALLDIR/installer/server/pgpass.$$ || _die "Failed to set the ownership of the password file ($INSTALLDIR/installer/server/pgpass.$$)"

# Install adminpack in the postgres database
echo "Installing the adminpack module in the postgres database..."
su - $OSUSERNAME -c "PGPASSFILE=$INSTALLDIR/installer/server/pgpass.$$ $INSTALLDIR/bin/psql -U $SUPERUSERNAME -p $PORT -c \"CREATE EXTENSION adminpack;\" postgres" || _warn "Failed to install the 'adminpack' module in the 'postgres' database"

# Cleanup
if [ -f $INSTALLDIR/installer/server/pgpass.$$ ];
then
    rm $INSTALLDIR/installer/server/pgpass.$$ || _warn "Failed to remove the password file ($INSTALLDIR/installer/server/pgpass.$$)"
fi

echo "$0 ran to completion"
exit $WARN

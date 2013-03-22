#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server module load script for OSX

#Check the command line
if [ $# -ne 5 ]; 
then
    echo "Usage: $0 <OSUsername> <SuperUsername> <Install dir> <Port> <install_plpgsql>"
    exit 127
fi
OSUSERNAME=$1
SUPERUSERNAME=$2
PASSWORD=$PGPASSWORD
INSTALLDIR=$3
PORT=$4
INSTALL_PLPGSQL=$5

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

if [ $INSTALL_PLPGSQL = "1" ];
then 
    # Create the plpgsql language
    echo "Installing pl/pgsql in the template1 database..."
    su - $OSUSERNAME -c "PGPASSFILE=$INSTALLDIR/installer/server/pgpass.$$ $INSTALLDIR/bin/psql -U $SUPERUSERNAME -p $PORT -c 'CREATE LANGUAGE plpgsql;' template1" || _warn "Failed to install pl/pgsql in the 'template1' database"
fi

# Install adminpack in the postgres database
echo "Installing the adminpack module in the postgres database..."
su - $OSUSERNAME -c "PGPASSFILE=$INSTALLDIR/installer/server/pgpass.$$ $INSTALLDIR/bin/psql -U $SUPERUSERNAME -p $PORT postgres < $INSTALLDIR/share/postgresql/contrib/adminpack.sql" || _warn "Failed to install the 'adminpack' module in the 'postgres' database"

# Cleanup
if [ -f $INSTALLDIR/installer/server/pgpass.$$ ];
then
    rm $INSTALLDIR/installer/server/pgpass.$$ || _warn "Failed to remove the password file ($INSTALLDIR/installer/server/pgpass.$$)"
fi

echo "$0 ran to completion"
exit $WARN

#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server module load script for Linux

# Check the command line
if [ $# -ne 6 ]; 
then
    echo "Usage: $0 <OSUsername> <SuperUsername> <Password> <Install dir> <Port> <install_plpgsql>"
    exit 127
fi

OSUSERNAME=$1
SUPERUSERNAME=$2
PASSWORD=$3
INSTALLDIR=$4
PORT=$5
INSTALL_PLPGSQL=$6


# Exit code
WARN=0

# Error handlers
_die() {
    if [ -f /tmp/pgpass.$$ ];
    then
        rm -rf /tmp/pgpass.$$
    fi
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Create a password file for later
touch /tmp/pgpass.$$ || _die "Failed to create the password file (/tmp/pgpass.$$)"
chmod 0600 /tmp/pgpass.$$ || _die "Failed to set the permissions on the password file (/tmp/pgpass.$$)"
echo "localhost:$PORT:*:$SUPERUSERNAME:$PASSWORD" > /tmp/pgpass.$$ || _die "Failed to write the password file (/tmp/pgpass.$$)"
chown $OSUSERNAME:daemon /tmp/pgpass.$$ || _die "Failed to set the ownership of the password file (/tmp/pgpass.$$)"

if [ $INSTALL_PLPGSQL = "1" ];
then 
    # Create the plpgsql language
    echo "Installing pl/pgsql in the template1 database..."
    su - $OSUSERNAME -c "PGPASSFILE=/tmp/pgpass.$$ $INSTALLDIR/bin/psql -U $SUPERUSERNAME -p $PORT -c 'CREATE LANGUAGE plpgsql;' template1" || _warn "Failed to install pl/pgsql in the 'template1' database"
fi

# Install adminpack in the postgres database
echo "Installing the adminpack module in the postgres database..."
su - $OSUSERNAME -c "PGPASSFILE=/tmp/pgpass.$$ $INSTALLDIR/bin/psql -U $SUPERUSERNAME -p $PORT postgres < $INSTALLDIR/share/postgresql/contrib/adminpack.sql" || _warn "Failed to install the 'adminpack' module in the 'postgres' database"

# Cleanup
if [ -f /tmp/pgpass.$$ ];
then
    rm /tmp/pgpass.$$ || _warn "Failed to remove the password file (/tmp/pgpass.$$)"
fi

echo "$0 ran to completion"
exit $WARN

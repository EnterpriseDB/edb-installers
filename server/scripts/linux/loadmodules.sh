#!/bin/sh

# PostgreSQL server module load script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <Username> <Password> <Install dir> <Port>"
    exit 127
fi

USERNAME=$1
PASSWORD=$2
INSTALLDIR=$3
PORT=$4

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
echo "localhost:$PORT:*:$USERNAME:$PASSWORD" > /tmp/pgpass.$$ || _die "Failed to write the password file (/tmp/pgpass.$$)"
chown $USERNAME:daemon /tmp/pgpass.$$ || _die "Failed to set the ownership of the password file (/tmp/pgpass.$$)"

# Create the plpgsql language
echo "Installing pl/pgsql in the template1 database..."
su - $USERNAME -c "PGPASSFILE=/tmp/pgpass.$$ $INSTALLDIR/bin/psql -U $USERNAME -p $PORT -c 'CREATE LANGUAGE plpgsql;' template1" || _warn "Failed to install pl/pgsql in the 'template1' database"

# Install adminpack in the postgres database
echo "Installing the adminpack module in the postgres database..."
su - $USERNAME -c "PGPASSFILE=/tmp/pgpass.$$ $INSTALLDIR/bin/psql -U $USERNAME -p $PORT postgres < $INSTALLDIR/share/postgresql/contrib/adminpack.sql" || _warn "Failed to install the 'adminpack' module in the 'postgres' database"

# Cleanup
if [ -f /tmp/pgpass.$$ ];
then
    rm /tmp/pgpass.$$ || _warn "Failed to remove the password file (/tmp/pgpass.$$)"
fi

echo "$0 ran to completion"
exit $WARN

#!/bin/sh

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5
INSTALL_DIR=$6

PGDATABASE=postgres

echo "Installing pl/pgsql language"
$PG_HOME/bin/createlang plpgsql postgres

echo "creating and configuring pgAgent schema"
$PG_HOME/bin/psql -f $INSTALL_DIR/pgAdmin3/share/pgadmin3/pgagent.sql


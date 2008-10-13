#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5

PGDATABASE=postgres

echo "Creating user for sample application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE ROLE phpbbuser PASSWORD 'phpbbuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for sample application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE DATABASE phpbb OWNER phpBBuser ENCODING 'utf8'"

export PGPASSWORD=$OLD_PGPASSWORD


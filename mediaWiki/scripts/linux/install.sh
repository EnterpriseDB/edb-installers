#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5

PGDATABASE=postgres

echo "Creating user for mediawiki application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE ROLE mediawikiuser PASSWORD 'mediawikiuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for mediawiki application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE DATABASE mediawiki OWNER mediawikiuser"

export PGPASSWORD=$OLD_PGPASSWORD


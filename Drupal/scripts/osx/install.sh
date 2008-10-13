#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5

PGDATABASE=postgres

echo "Creating user for Drupal application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE ROLE drupaluser PASSWORD 'drupaluser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for Drupal application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE DATABASE drupal OWNER drupaluser"

export PGPASSWORD=$OLD_PGPASSWORD


#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
DB=$6
export LD_LIBRARY_PATH=$TEMPDIR

echo "Creating user for Drupal application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE ROLE drupaluser PASSWORD 'drupaluser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for Drupal application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE DATABASE drupal OWNER drupaluser"

export PGPASSWORD=$OLD_PGPASSWORD


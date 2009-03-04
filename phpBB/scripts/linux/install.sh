#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
DB=$6
export LD_LIBRARY_PATH=$TEMPDIR

echo "Creating user for phpbb application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE ROLE phpbbuser PASSWORD 'phpbbuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for phpbb application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE DATABASE phpbb OWNER phpbbuser ENCODING 'utf8'"

export PGPASSWORD=$OLD_PGPASSWORD


#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
DB=$6
export LD_LIBRARY_PATH=$TEMPDIR
cd $TEMPDIR
echo "Creating user for mediawiki application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE ROLE mediawikiuser PASSWORD 'mediawikiuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

echo "Creating database for mediawiki application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE DATABASE mediawiki OWNER mediawikiuser"

export PGPASSWORD=$OLD_PGPASSWORD


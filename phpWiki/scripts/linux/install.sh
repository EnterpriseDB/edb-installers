#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
INSTALL_DIR=$6

DB=$7
export LD_LIBRARY_PATH=$TEMPDIR

echo "Creating user for wiki application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE ROLE phpwikiuser PASSWORD 'phpwikiuser' CREATEDB CREATEROLE INHERIT LOGIN"

echo "Creating database for wiki application"
$TEMPDIR/psql -d $DB -U $PGUSER -c "CREATE DATABASE phpwiki OWNER phpwikiuser"

export PGPASSWORD=phpwikiuser
$TEMPDIR/psql -U phpwikiuser -d phpwiki -f $INSTALL_DIR/phpWiki/wiki.sql

PGPASSWORD=$OLD_PGPASSWORD


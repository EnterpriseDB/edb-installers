#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5
INSTALL_DIR=$6

PGDATABASE=postgres

echo "Creating user for wiki application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE ROLE phpwikiuser PASSWORD 'phpwikiuser' CREATEDB CREATEROLE INHERIT LOGIN"

echo "Creating database for wiki application"
$PG_HOME/bin/psql -U $PGUSER -c "CREATE DATABASE phpwiki OWNER phpwikiuser"

export PGPASSWORD=phpwikiuser
$PG_HOME/bin/psql -U phpwikiuser -d phpwiki -f $INSTALL_DIR/phpWiki/wiki.sql

PGPASSWORD=$OLD_PGPASSWORD


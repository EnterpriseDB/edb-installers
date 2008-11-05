#!/bin/sh

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PG_HOME=$5

PGDATABASE=postgres

locale=`$PG_HOME/bin/psql -U $PGUSER -c "SHOW LC_CTYPE" | grep -v lc_ctype | grep -v row | grep -v '\-\-'`
echo $locale

export PGPASSWORD=$OLD_PGPASSWORD


#!/bin/bash

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
DB=$7
export LD_LIBRARY_PATH=$TEMPDIR
cd $TEMPDIR
"$TEMPDIR/psql" -d $DB -l | grep $6



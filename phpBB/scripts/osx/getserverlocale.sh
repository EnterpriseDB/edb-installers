#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

OLD_PGPASSWORD=$PGPASSWORD

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
TEMPDIR=$5
DB=$6
export LD_LIBRARY_PATH=$TEMPDIR

PGDATABASE=postgres
cd $TEMPDIR
locale=`$TEMPDIR/psql -d $DB -U $PGUSER -c "SHOW LC_CTYPE" | grep -v lc_ctype | grep -v row | grep -v '\-\-'`
echo $locale

export PGPASSWORD=$OLD_PGPASSWORD


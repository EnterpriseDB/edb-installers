#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
PGHOME=$4
INSTALLDIR=$4
PGPASSWORD=$PGPASSWORD

# Creating postgis database
"$PGHOME/bin/createdb" -T template_postgis $5


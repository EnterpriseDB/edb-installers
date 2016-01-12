#!/bin/bash
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PGHOME=$5
INSTALLDIR=$5
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH

# Creating postgis database
"$PGHOME/bin/createdb" -T template_postgis $6 


#!/bin/bash
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PGHOME=$5

$PGHOME/bin/psql -l


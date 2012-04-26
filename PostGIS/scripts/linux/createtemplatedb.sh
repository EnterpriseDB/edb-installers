#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PGHOME=$5
INSTALLDIR=$5

# Creating template postgis database
"$PGHOME/bin/createdb" template_postgis 

# Creating template postgis language
"$PGHOME/bin/createlang" plpgsql template_postgis

# Set the template flag in the pg_database table
"$PGHOME/bin/psql" -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'" 

# Creating template postgis functions
"$PGHOME/bin/psql" -f "$INSTALLDIR/share/lwpostgis.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$INSTALLDIR/share/spatial_ref_sys.sql" -d template_postgis




#!/bin/bash
# Copyright (c) 2012-2020, EnterpriseDB Corporation.  All rights reserved

export PGHOST=$1
export PGPORT=$2
export PGUSER=$3
export PGPASSWORD=$4
PGHOME=$5
INSTALLDIR=$5
SHAREDIR=$6
POSTGIS_MAJOR_VERSION=$7
export LD_LIBRARY_PATH=$PGHOME/lib:$LD_LIBRARY_PATH

# Creating template postgis database
"$PGHOME/bin/createdb" template_postgis 

# Creating template postgis language
"$PGHOME/bin/createlang" plpgsql template_postgis

# Set the template flag in the pg_database table
"$PGHOME/bin/psql" -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'" 

# Creating template postgis functions
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/postgis.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/spatial_ref_sys.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/postgis_comments.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/rtpostgis.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/raster_comments.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/topology.sql" -d template_postgis
"$PGHOME/bin/psql" -f "$SHAREDIR/contrib/postgis/topology_comments.sql" -d template_postgis




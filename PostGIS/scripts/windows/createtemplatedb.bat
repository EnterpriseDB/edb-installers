@ECHO OFF
REM Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

@SET PGHOST=%1
@SET PGPORT=%2
@SET PGUSER=%3
@SET PGPASSWORD=%4
@SET PGHOME=%5

REM Creating template postgis database
"%PGHOME%\bin\createdb.exe" template_postgis

REM Creating template postgis language
"%PGHOME%\bin\createlang.exe" plpgsql template_postgis

REM Set the template flag in the pg_database table
"%PGHOME%\bin\psql.exe" -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'"

REM Creating template postgis functions
"%PGHOME%\bin\psql.exe" -f "@@INSTALL_DIR@@\share\lwpostgis.sql" -d template_postgis
"%PGHOME%\bin\psql.exe" -f "@@INSTALL_DIR@@\share\spatial_ref_sys.sql" -d template_postgis



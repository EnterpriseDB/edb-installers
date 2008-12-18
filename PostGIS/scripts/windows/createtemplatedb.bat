@ECHO OFF

@SET PGHOST=%1
@SET PGPORT=%2
@SET PGUSER=%3
@SET PGPASSWORD=%4
@SET PGHOME=%5

@SET PATH=%PGHOME%\bin;%PATH%

REM Creating template postgis database
createdb template_postgis

REM Creating template postgis language
createlang plpgsql template_postgis

REM Set the template flag in the pg_database table
psql -c "UPDATE pg_database SET datistemplate='t' WHERE datname='template_postgis'"

REM Creating template postgis functions
psql -f "@@INSTALL_DIR@@\share\lwpostgis.sql" -d template_postgis
psql -f "@@INSTALL_DIR@@\share\spatial_ref_sys.sql" -d template_postgis



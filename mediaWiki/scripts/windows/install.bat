@ECHO OFF

SET OLD_PGPASSWORD=%PGPASSWORD%
SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4
SET PG_HOME="%5"

IF "%PG_HOME%"=="" GOTO end
IF "%PGUSER%" == "" SET PGUSER=%USERNAME%
IF "%PGPORT%" == "" SET PGPORT=5432

SET PGDATABASE=postgres


REM Creating user for sample application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE ROLE mediawikiuser PASSWORD 'mediawikiuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for sample application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE DATABASE mediawiki OWNER mediawikiuser"


:end

SET PGPASSWORD=%OLD_PGPASSWORD%

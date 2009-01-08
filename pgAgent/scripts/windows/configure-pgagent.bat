@ECHO off

SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4
SET PG_HOME="%5"

SET PGDATABASE=postgres

REM Creating pl/pgsql language
"%PG_HOME%\bin\createlang.exe" plpgsql postgres

CD "%PG_HOME%\pgAdmin III"
REM Creating and configuring pgAgent Schema
CALL "%PG_HOME%\bin\psql.exe" -f scripts\pgagent.sql

@ECHO off

SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4

SET PGDATABASE=postgres

REM Change Directory to InstallDir
CD "%5"

REM Creating pl/pgsql language
bin\createlang.exe plpgsql postgres

REM Creating and configuring pgAgent Schema
CALL bin\psql.exe -f pgAgent\share\pgagent.sql

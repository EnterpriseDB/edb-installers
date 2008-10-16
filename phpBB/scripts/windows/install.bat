@ECHO OFF

SET OLD_PGPASSWORD=%PGPASSWORD%
SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4
SET PG_HOME="%5"

IF "%PG_HOME%"=="" GOTO end
IF "%PGUSER%" == "" SET PGUSER=%USERNAME%
IF "%PGPORT%" == "" SET PGPORT=6543

SET PGDATABASE=postgres


REM Creating user for phpbb application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE ROLE phpbbuser PASSWORD 'phpbbuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for phpbb application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE DATABASE phpbb OWNER phpbbuser ENCODING 'utf8'"


:end

SET PGPASSWORD=%OLD_PGPASSWORD%

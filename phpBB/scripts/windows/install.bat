@ECHO OFF

SET OLD_PGPASSWORD=%PGPASSWORD%
SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4
SET TEMPDIR="%5"
SET DB=%6

IF "%PG_HOME%"=="" GOTO end
IF "%PGUSER%" == "" SET PGUSER=%USERNAME%
IF "%PGPORT%" == "" SET PGPORT=5432

REM Creating user for phpbb application
"%TEMPDIR%\psql.exe" -d %DB% -U %PGUSER% -c "CREATE ROLE phpbbuser PASSWORD 'phpbbuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for phpbb application
"%TEMPDIR%\psql.exe" -d %DB% -U %PGUSER% -c "CREATE DATABASE phpbb OWNER phpbbuser ENCODING 'utf8'"


:end

SET PGPASSWORD=%OLD_PGPASSWORD%

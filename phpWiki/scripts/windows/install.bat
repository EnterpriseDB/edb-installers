@ECHO off
SET OLD_PGPASSWORD=%PGPASSWORD%

SET PGHOST=%1
SET PGPORT=%2
SET PGUSER=%3
SET PGPASSWORD=%4
SET PG_HOME="%5"
SET INSTALL_DIR="%6"

SET PGDATABASE=postgres

REM Creating user for wiki application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE ROLE phpwikiuser PASSWORD 'phpwikiuser' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN"

REM Creating database for wiki application
"%PG_HOME%\bin\psql.exe" -U %PGUSER% -c "CREATE DATABASE phpwiki OWNER phpwikiuser"

CD %INSTALL_DIR%
IF EXIST phpwiki\wiki.sql GOTO install_schema
ECHO phpwiki\wiki.sql is missing ..."
goto end

:install_schema
    SET PGPASSWORD=phpwikiuser
    CALL "%PG_HOME%\bin\psql.exe" -U phpwikiuser -d phpwiki -f phpwiki\wiki.sql

:end
    SET PGPASSWORD=%OLD_PGPASSWORD%

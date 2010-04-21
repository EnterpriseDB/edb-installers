@ECHO off

SET TEMPDIR="%1"
SET INSTALL_DIR="%2"
SET DB=%3

REM Creating user for wiki application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE ROLE phpwikiuser PASSWORD 'phpwikiuser' CREATEDB CREATEROLE INHERIT LOGIN"

REM Creating database for wiki application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE DATABASE phpwiki OWNER phpwikiuser"

CD /d %INSTALL_DIR%
IF EXIST phpwiki\wiki.sql GOTO install_schema
ECHO phpwiki\wiki.sql is missing ..."
goto end

:install_schema
    SET PGPASSWORD=phpwikiuser
    CALL "%TEMPDIR%\psql.exe" -U phpwikiuser -d phpwiki -f phpwiki\wiki.sql

:end

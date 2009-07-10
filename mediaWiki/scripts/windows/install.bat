@ECHO OFF

SET TEMPDIR="%1"
SET DB=%2

REM Creating user for sample application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE ROLE mediawikiuser PASSWORD 'mediawikiuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for sample application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE DATABASE mediawiki OWNER mediawikiuser"


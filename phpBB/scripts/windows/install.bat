@ECHO OFF

SET TEMPDIR="%1"
SET DB=%2

REM Creating user for phpbb application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE ROLE phpbbuser PASSWORD 'phpbbuser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for phpbb application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE DATABASE phpbb OWNER phpbbuser ENCODING 'utf8'"


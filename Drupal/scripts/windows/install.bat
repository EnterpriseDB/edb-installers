@ECHO OFF

SET TEMPDIR="%1"
SET DB=%2

REM Creating user for Drupal application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE ROLE drupaluser PASSWORD 'drupaluser' NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN"

REM Creating database for Drupal application
"%TEMPDIR%\psql.exe" -d %DB% -c "CREATE DATABASE drupal OWNER drupaluser"


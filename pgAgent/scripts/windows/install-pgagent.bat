@echo off
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.

SET USER_PASSWORD=%1
SET PG_PORT=%2
SET PG_USER=%3
SET PG_PASSWORD=%4
SET INSTALL_DIR="%5"

rem Write PG_PASSWORD to pgpass.conf File
echo localhost:%PG_PORT%:*:%PG_USER%:%PG_PASSWORD% >> "%APPDATA%\postgresql\pgpass.conf"

rem Install the pgAgent service
"%INSTALL_DIR%\bin\pgagent.exe" INSTALL pgagent -l2 -u %PG_USER% -p %USER_PASSWORD% host=localhost port=%PG_PORT% dbname=postgres user=%PG_USER%


@echo off
echo NOTE: You must start this script as a Administrator
echo       or from the Administrator console.
echo       If you have not started this as a administrator,
echo       then it will not run successfully.

SET SYS_USER=%1
SET USER_PASSWORD=%2
SET PG_PORT=%3
SET PG_USER=%4
SET PG_PASSWORD=%5

REM Write PG_PASSWORD to pgpass.conf File
REM echo localhost:%PG_PORT%:*:%PG_USER%:%PG_PASSWORD% >> "%APPDATA%\postgresql\pgpass.conf"

cd "%6"
rem Install the pgAgent service
bin\pgagent.exe INSTALL pgagent -l2 -u %SYS_USER% -p %USER_PASSWORD% host=localhost port=%PG_PORT% dbname=postgres user=%PG_USER%


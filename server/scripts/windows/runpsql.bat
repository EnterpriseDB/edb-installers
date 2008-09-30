@echo off

REM PostgreSQL server psql runner script for Windows
REM Dave Page, EnterpriseDB

SET server=localhost
SET /P server="Server [%server%]: "

SET database=postgres
SET /P database="Database [%database%]: "

SET port=EDB_PORT
SET /P port="Port [%port%]: "

SET username=EDB_USERNAME
SET /P username="Username [%username%]: "

REM Run psql
"PG_INSTALLDIR\bin\psql.exe" -h %server% -U %username% -d %database% -p %port%

pause

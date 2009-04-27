@echo off

:SLONY
if %2==true goto UNINSTALL_SLONY

:PGJDBC
if %3==true goto UNINSTALL_PGJDBC

:POSTGIS
if %4==true goto UNINSTALL_POSTGIS

:PSQLODBC
if %5==true goto UNINSTALL_PSQLODBC

:NPGSQL
if %7==true goto UNINSTALL_NPGSQL

:PGBOUNCER
if %8==true goto UNINSTALL_PGBOUNCER

:PGAGENT
if %9==true goto UNINSTALL_PGAGENT

:PG
if %1==true goto UNINSTALL_PG

goto END

:UNINSTALL_SLONY

%6\Slony\uninstall-slony.exe --mode unattended

goto PGJDBC

:UNINSTALL_PGJDBC

%6\pgJDBC\uninstall-pgjdbc.exe --mode unattended

goto POSTGIS

:UNINSTALL_POSTGIS

%6\PostGIS\uninstall-postgis.exe --mode unattended

goto PSQLODBC

:UNINSTALL_PSQLODBC

%6\psqlODBC\uninstall-psqlodbc.exe --mode unattended

goto NPGSQL

:UNINSTALL_NPGSQL

%6\Npgsql\uninstall-npgsql.exe --mode unattended

goto PGBOUNCER

:UNINSTALL_PGBOUNCER

%6\pgbouncer\uninstall-pgbouncer.exe --mode unattended

goto PGAGENT

:UNINSTALL_PGAGENT

%6\pgagent\uninstall-pgagent.exe --mode unattended

goto PG

:UNINSTALL_PG

%6\uninstall-postgresql.exe --mode unattended

:END

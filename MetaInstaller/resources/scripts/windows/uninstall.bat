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

:PG
if %1==true goto UNINSTALL_PG

goto END

:UNINSTALL_SLONY

%6\Slony\uninstall-slony.exe --mode unattended

goto PGJDBC

:UNINSTALL_PGJDBC

%6\..\pgJDBC\uninstall-pgjdbc.exe --mode unattended

goto POSTGIS

:UNINSTALL_POSTGIS

%6\PostGIS\uninstall-postgis.exe --mode unattended

goto PSQLODBC

:UNINSTALL_PSQLODBC

%6\..\psqlODBC\uninstall-psqlodbc.exe --mode unattended

goto NPGSQL

:UNINSTALL_NPGSQL

%6\..\Npgsql\uninstall-npgsql.exe --mode unattended

goto PG

:UNINSTALL_PG

%6\uninstall-postgresql.exe --mode unattended

:END

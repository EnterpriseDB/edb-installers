@ECHO OFF
REM Copyright (c) 2012-2020, EnterpriseDB Corporation.  All rights reserved

SET WINDIR="%1"
SET INSTALL_DIR="%2"

REM Registering pgbevent.dll
%WINDIR%\System32\regsvr32 /s "%INSTALL_DIR%\bin\pgbevent.dll"

REM Register pgbouncer service

cd "%INSTALL_DIR%"
bin\pgbouncer.exe -regservice  share\pgbouncer.ini

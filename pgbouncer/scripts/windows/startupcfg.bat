@ECHO OFF

SET INSTALL_DIR="%1"

REM Registering pgbevent.dll
regsvr32 /s "%INSTALL_DIR%\bin\pgbevent.dll"


REM Register pgbouncer service

cd "%INSTALL_DIR%"
bin\pgbouncer.exe -regservice  share\pgbouncer.ini

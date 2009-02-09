@ECHO OFF
echo USERPROFILE:%USERPROFILE%

cd /d "%USERPROFILE%"

REM Earlier than Window Vista has Application Data as APPDATA in their USERPROFILE
IF EXIST "%CD%\Application Data" CD "Application Data" && GOTO Next

REM Window Vista & later has APPDATA\Roaming as APPDATA in their USERPROFILE
IF EXIST "%CD%\AppData" CD AppData && CD Roaming && GOTO Next

GOTO ERROR

:Next
  ECHO APPDATA:%CD%
  IF NOT EXIST "postgresql" mkdir postgresql
  CD postgresql
  ECHO PG_HOST:PG_PORT:*:PG_USER:PG_PASSWORD >> pgpass.conf
  ECHO Successfully appended values in %CD%\pgpass.conf
  GOTO END

:ERROR
  ECHO Could not find APPDATA Directory

:END

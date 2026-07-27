@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  PostgreSQL Manual Setup Script
::  Use this after installing with --extract-only mode
::  Must be run as Administrator
::
::  This script auto-detects paths based on its own location.
::  Expected layout: <INSTALL_DIR>\scripts\this-script.bat
::  So it assumes:
::     PGBIN  = <INSTALL_DIR>\bin
::     PGDATA = <INSTALL_DIR>\data
::
::  Optional: pass a custom service name as the first argument.
::     e.g.  setup-postgres.bat "My Postgres Service"
:: ============================================================

:: --------------------------------------------------
:: Resolve install dir from script location (parent of \scripts)
:: --------------------------------------------------
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "INSTALL_DIR=%%~fI"

set "PGBIN=%INSTALL_DIR%\bin"
set "PGDATA=%INSTALL_DIR%\data"
set "LOGFILE=%PGDATA%\server.log"

:: Derive a default service name from the install folder name (e.g. "18")
for %%A in ("%INSTALL_DIR%") do set "VERFOLDER=%%~nxA"
set "SERVICE_NAME=PostgreSQL %VERFOLDER%"
if not "%~1"=="" set "SERVICE_NAME=%~1"

echo ================================================
echo   PostgreSQL Setup Script
echo ================================================
echo Install dir : %INSTALL_DIR%
echo Bin dir     : %PGBIN%
echo Data dir    : %PGDATA%
echo Service name: %SERVICE_NAME%
echo ================================================
echo.

:: --------------------------------------------------
:: Step 0: Check for Administrator privileges
:: --------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click the script and choose "Run as administrator".
    pause
    exit /b 1
)
echo [OK] Running with Administrator privileges.
echo.

:: --------------------------------------------------
:: Step 1: Verify bin folder exists
:: --------------------------------------------------
if not exist "%PGBIN%\initdb.exe" (
    echo [ERROR] Could not find initdb.exe in "%PGBIN%"
    echo Check that this script sits in the "scripts" folder
    echo directly under the PostgreSQL install directory.
    pause
    exit /b 1
)
cd /d "%PGBIN%"
echo [OK] Found PostgreSQL bin folder: %PGBIN%
echo.

:: --------------------------------------------------
:: Step 2: Create data directory
:: --------------------------------------------------
if exist "%PGDATA%" (
    echo [SKIP] Data directory already exists: %PGDATA%
) else (
    mkdir "%PGDATA%"
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create data directory "%PGDATA%"
        pause
        exit /b 1
    )
    echo [OK] Created data directory: %PGDATA%
)
echo.

:: --------------------------------------------------
:: Step 3: Take ownership of the folder
:: --------------------------------------------------
takeown /f "%PGDATA%" /r /d y >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to take ownership of "%PGDATA%"
    pause
    exit /b 1
)
echo [OK] Ownership set on data directory.
echo.

:: --------------------------------------------------
:: Step 4: Grant Administrator full control
:: --------------------------------------------------
icacls "%PGDATA%" /grant Administrator:(OI)(CI)F /t >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to grant permissions on "%PGDATA%"
    pause
    exit /b 1
)
echo [OK] Permissions granted to Administrator.
echo.

:: --------------------------------------------------
:: Step 5: Initialize the database cluster
:: --------------------------------------------------
if exist "%PGDATA%\PG_VERSION" (
    echo [SKIP] Database cluster already initialized.
) else (
    initdb.exe -D "%PGDATA%" -U postgres --auth=trust
    if %errorlevel% neq 0 (
        echo [ERROR] initdb failed. Common cause: initdb must NOT be run
        echo as an Administrator/elevated account. Try running this step
        echo from a non-elevated Command Prompt instead, then re-run this
        echo script for the remaining steps.
        pause
        exit /b 1
    )
    echo [OK] Database cluster initialized.
)
echo.

:: --------------------------------------------------
:: Step 6: Cleanup - kill any stray postgres.exe processes
:: --------------------------------------------------
taskkill /F /IM postgres.exe /T >nul 2>&1
echo [OK] Cleanup done (any stray postgres.exe processes stopped).
echo.

:: --------------------------------------------------
:: Step 7: Register the Windows service (if not already)
:: --------------------------------------------------
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [SKIP] Service "%SERVICE_NAME%" is already registered.
) else (
    set "REG_OUTPUT="
    for /f "delims=" %%L in ('pg_ctl.exe register -N "%SERVICE_NAME%" -D "%PGDATA%" -l "%LOGFILE%" 2^>^&1') do (
        echo %%L
        set "REG_OUTPUT=!REG_OUTPUT! %%L"
    )
    echo !REG_OUTPUT! | findstr /i "already registered" >nul
    if !errorlevel! equ 0 (
        echo [SKIP] Service "%SERVICE_NAME%" was already registered ^(detected from pg_ctl output^).
    ) else (
        sc query "%SERVICE_NAME%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to register the Windows service.
            echo Check "%LOGFILE%" for details.
            pause
            exit /b 1
        )
        echo [OK] Service "%SERVICE_NAME%" registered.
    )
)
echo.

:: --------------------------------------------------
:: Step 8: Start the service
:: --------------------------------------------------
net start "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] "net start" reported an issue. Checking current status...
) else (
    echo [OK] Service start command sent.
)
echo.

:: --------------------------------------------------
:: Step 9: Verify service status
:: --------------------------------------------------
echo Checking service status...
sc query "%SERVICE_NAME%" | findstr /i "RUNNING" >nul
if %errorlevel% equ 0 (
    echo [OK] Service "%SERVICE_NAME%" is RUNNING.
) else (
    echo [ERROR] Service "%SERVICE_NAME%" is NOT running.
    echo Check the log file for details: "%LOGFILE%"
    if exist "%LOGFILE%" (
        echo.
        echo ---- Last lines of server.log ----
        powershell -command "Get-Content -Tail 20 '%LOGFILE%'"
        echo -----------------------------------
    )
    pause
    exit /b 1
)
echo.

echo ================================================
echo   Setup complete. PostgreSQL is running as a
echo   Windows service named "%SERVICE_NAME%".
echo ================================================
echo.
echo You can connect now with:
echo   psql -U postgres
echo.
pause
endlocal

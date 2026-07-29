@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: PostgreSQL Setup Script
:: Completes setup after installing with --extract-only mode:
:: initializes the data directory, registers and starts the
:: Windows service, and creates a Start Menu shortcut.
::
:: Must be run as Administrator.
:: Expected layout: <INSTALL_DIR>\scripts\this-script.bat
:: ============================================================

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "INSTALL_DIR=%%~fI"

set "PGBIN=%INSTALL_DIR%\bin"
set "PGDATA=%INSTALL_DIR%\data"
set "LOGFILE=%PGDATA%\server.log"

for %%A in ("%INSTALL_DIR%") do set "VERFOLDER=%%~nxA"
set "SERVICE_NAME=postgresql-x64-%VERFOLDER%"

echo ================================================
echo   PostgreSQL Setup Script
echo ================================================
echo Install dir : %INSTALL_DIR%
echo Bin dir     : %PGBIN%
echo Data dir    : %PGDATA%
echo Service name: %SERVICE_NAME%
echo ================================================
echo.

:: Step 0: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click the script and choose "Run as administrator".
    pause
    exit /b 1
)
echo [OK] Running with Administrator privileges.
echo.

:: Step 1: Verify bin folder exists
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

:: Step 2: Create data directory
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

:: Step 3: Take ownership of the folder
takeown /f "%PGDATA%" /r /d y >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to take ownership of "%PGDATA%"
    pause
    exit /b 1
)
echo [OK] Ownership set on data directory.
echo.

:: Step 4: Grant Administrator full control
icacls "%PGDATA%" /grant Administrator:(OI)(CI)F /t >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to grant permissions on "%PGDATA%"
    pause
    exit /b 1
)
echo [OK] Permissions granted to Administrator.
echo.

:: Step 5: Initialize the database cluster
:: (initdb refuses to run elevated, so it's launched de-elevated below)
set "STEP5_FAIL="
if exist "%PGDATA%\PG_VERSION" (
    echo [SKIP] Database cluster already initialized.
) else (
    call :init_database
    if "!INIT_RESULT!"=="FAIL" (
        set "STEP5_FAIL=1"
    ) else (
        echo [OK] Database cluster initialized ^(via automatic de-elevation^).
    )
)
echo.
if defined STEP5_FAIL goto :fail

:: Step 6: Cleanup - kill any stray postgres.exe processes
taskkill /F /IM postgres.exe /T >nul 2>&1
echo [OK] Cleanup done (any stray postgres.exe processes stopped).
echo.

:: Step 7: Register the Windows service (if not already)
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
        echo [SKIP] Service "%SERVICE_NAME%" was already registered.
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

:: Step 8: Start the service
net start "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] "net start" reported an issue. Checking current status...
) else (
    echo [OK] Service start command sent.
)
echo.

:: Step 9: Verify service status
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

:: Step 10: Create Start Menu shortcut (SQL Shell / psql)
call :create_shortcut
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
exit /b 0

:: ============================================================
:: Subroutine: init_database
:: Runs initdb at a de-elevated trust level via runas, since
:: initdb refuses to run under an admin token. Waits for
:: completion and reports result via INIT_RESULT ("OK"/"FAIL").
:: ============================================================
:init_database
echo [INFO] initdb cannot run while elevated. Launching it
echo        automatically at a non-elevated trust level...

set "INITDB_WORKER=%TEMP%\pg_initdb_worker_%RANDOM%.bat"
set "INITDB_LOG=%TEMP%\pg_initdb_output_%RANDOM%.log"
set "INITDB_FLAG=%TEMP%\pg_initdb_done_%RANDOM%.flag"

if exist "%INITDB_FLAG%" del /f /q "%INITDB_FLAG%" >nul 2>&1
if exist "%INITDB_LOG%" del /f /q "%INITDB_LOG%" >nul 2>&1

> "%INITDB_WORKER%" echo @echo off
>> "%INITDB_WORKER%" echo cd /d "%PGBIN%"
>> "%INITDB_WORKER%" echo initdb.exe -D "%PGDATA%" -U postgres --auth=trust ^> "%INITDB_LOG%" 2^>^&1
>> "%INITDB_WORKER%" echo echo done ^> "%INITDB_FLAG%"

runas /trustlevel:0x20000 "\"%INITDB_WORKER%\"" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Could not launch de-elevated initdb via runas.
    echo Run this step manually from a non-elevated Command Prompt:
    echo   initdb.exe -D "%PGDATA%" -U postgres --auth=trust
    echo then re-run this script.
    set "INIT_RESULT=FAIL"
    exit /b 1
)

echo [INFO] Waiting for initdb to complete...
set "WAITSECS=0"

:init_database_waitloop
if exist "%INITDB_FLAG%" goto :init_database_wait_done
timeout /t 1 /nobreak >nul
set /a WAITSECS+=1
if %WAITSECS% GEQ 60 (
    echo [ERROR] Timed out waiting for de-elevated initdb to finish.
    echo Run this step manually from a non-elevated Command Prompt:
    echo   initdb.exe -D "%PGDATA%" -U postgres --auth=trust
    echo then re-run this script.
    set "INIT_RESULT=FAIL"
    exit /b 1
)
goto :init_database_waitloop

:init_database_wait_done
if exist "%INITDB_LOG%" (
    echo.
    echo ---- initdb output ----
    type "%INITDB_LOG%"
    echo ------------------------
    echo.
)

del /f /q "%INITDB_WORKER%" >nul 2>&1
del /f /q "%INITDB_FLAG%" >nul 2>&1

if not exist "%PGDATA%\PG_VERSION" (
    echo [ERROR] initdb did not complete successfully. See output above.
    echo Run this step manually from a non-elevated Command Prompt:
    echo   initdb.exe -D "%PGDATA%" -U postgres --auth=trust
    echo then re-run this script.
    set "INIT_RESULT=FAIL"
    exit /b 1
)

set "INIT_RESULT=OK"
exit /b 0

:: ============================================================
:: Subroutine: create_shortcut
:: Creates a "SQL Shell (psql)" Start Menu shortcut under a
:: folder named after the service. Non-fatal on failure.
:: ============================================================
:create_shortcut
echo [INFO] Creating Start Menu shortcut...

set "BUNDLED_RUNPSQL=%SCRIPT_DIR%runpsql.bat"
set "SHORTCUT_ICON=%SCRIPT_DIR%images\pg-psql.ico"
if not exist "%SHORTCUT_ICON%" set "SHORTCUT_ICON=%PGBIN%\psql.exe"

if not exist "%BUNDLED_RUNPSQL%" (
    echo [WARNING] runpsql.bat not found in "%SCRIPT_DIR%". Skipping shortcut ^(non-fatal^).
    exit /b 0
)

set "SHORTCUT_PS1=%TEMP%\pg_shortcut_%RANDOM%.ps1"
set "SHORTCUT_LOG=%TEMP%\pg_shortcut_%RANDOM%.log"
set "SHORTCUT_FOLDER=%ProgramData%\Microsoft\Windows\Start Menu\Programs\%SERVICE_NAME%"

if exist "%SHORTCUT_PS1%" del /f /q "%SHORTCUT_PS1%" >nul 2>&1
if exist "%SHORTCUT_LOG%" del /f /q "%SHORTCUT_LOG%" >nul 2>&1

:: Fill in the bundled runpsql.bat placeholders (normally done by the
:: full installer at install time) - port, username, install dir.
> "%SHORTCUT_PS1%" echo try {
>> "%SHORTCUT_PS1%" echo   $content = Get-Content -Raw "%BUNDLED_RUNPSQL%"
>> "%SHORTCUT_PS1%" echo   $content = $content -replace 'PG_INSTALLDIR', "%INSTALL_DIR%"
>> "%SHORTCUT_PS1%" echo   $content = $content -replace 'PG_PORT', '5432'
>> "%SHORTCUT_PS1%" echo   $content = $content -replace 'PG_USERNAME', 'postgres'
>> "%SHORTCUT_PS1%" echo   Set-Content -Path "%BUNDLED_RUNPSQL%" -Value $content -NoNewline
>> "%SHORTCUT_PS1%" echo   $ws = New-Object -ComObject WScript.Shell
>> "%SHORTCUT_PS1%" echo   $folder = "%SHORTCUT_FOLDER%"
>> "%SHORTCUT_PS1%" echo   if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force ^| Out-Null }
>> "%SHORTCUT_PS1%" echo   $sc = $ws.CreateShortcut((Join-Path $folder 'SQL Shell (psql).lnk'))
>> "%SHORTCUT_PS1%" echo   $sc.TargetPath = "%BUNDLED_RUNPSQL%"
>> "%SHORTCUT_PS1%" echo   $sc.WorkingDirectory = "%PGBIN%"
>> "%SHORTCUT_PS1%" echo   $sc.IconLocation = "%SHORTCUT_ICON%"
>> "%SHORTCUT_PS1%" echo   $sc.Description = "Open a psql session for %SERVICE_NAME%"
>> "%SHORTCUT_PS1%" echo   $sc.Save()
>> "%SHORTCUT_PS1%" echo   Write-Output "SHORTCUT_OK"
>> "%SHORTCUT_PS1%" echo } catch {
>> "%SHORTCUT_PS1%" echo   Write-Output ("SHORTCUT_FAIL: " + $_.Exception.Message)
>> "%SHORTCUT_PS1%" echo   exit 1
>> "%SHORTCUT_PS1%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%SHORTCUT_PS1%" > "%SHORTCUT_LOG%" 2>&1

findstr /c:"SHORTCUT_OK" "%SHORTCUT_LOG%" >nul
if %errorlevel% equ 0 (
    echo [OK] Start Menu shortcut created: "%SHORTCUT_FOLDER%\SQL Shell (psql).lnk"
) else (
    echo [WARNING] Could not create Start Menu shortcut ^(non-fatal^). Details:
    type "%SHORTCUT_LOG%"
)

del /f /q "%SHORTCUT_PS1%" >nul 2>&1
del /f /q "%SHORTCUT_LOG%" >nul 2>&1
exit /b 0

:fail
pause
exit /b 1

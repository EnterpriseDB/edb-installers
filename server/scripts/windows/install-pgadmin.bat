@echo off
setlocal
set "MODE=%~1"

rem --- Use absolute paths for system tools (never rely on PATH / current directory) ---
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "CURL=%SystemRoot%\System32\curl.exe"
if not exist "%PS%" (
    echo ERROR: PowerShell not found at "%PS%".
    exit /b 1
)
if not exist "%CURL%" (
    echo ERROR: curl not found at "%CURL%".
    exit /b 1
)

rem --- Private, per-run work dir (unpredictable name; mkdir fails if it already exists) ---
set "WORKDIR=%TEMP%\pgadmin-install-%RANDOM%%RANDOM%%RANDOM%"
mkdir "%WORKDIR%" 2>nul
if not exist "%WORKDIR%\" (
    echo ERROR: Unable to create work directory "%WORKDIR%".
    exit /b 1
)

rem --- Resolve latest version into VER ---
rem Output goes to a temp file (not "for /f (`command`)") so that the quoted
rem absolute path to powershell.exe and the pipes/parens in the command are
rem not subject to cmd.exe's first/last quote stripping or re-parsing.
set "VER="
set "VERFILE=%WORKDIR%\pgadmin4-latest-version.txt"
del "%VERFILE%" 2>nul
"%PS%" -NoProfile -Command "(Invoke-WebRequest -Uri 'https://www.postgresql.org/ftp/pgadmin/pgadmin4/' -UseBasicParsing).Links.href | ForEach-Object { ($_ -replace '[v/]','') } | Where-Object { $_ -match '^\d+\.\d+' } | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1" > "%VERFILE%" 2>nul
if exist "%VERFILE%" set /p VER=<"%VERFILE%"
del "%VERFILE%" 2>nul

if not defined VER (
    echo ERROR: Unable to determine the latest pgAdmin 4 version.
    rmdir /s /q "%WORKDIR%" 2>nul
    exit /b 1
)
echo Latest pgAdmin 4 version: %VER%

set "EXE=%WORKDIR%\pgadmin4-%VER%-x64.exe"
set "URL=https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v%VER%/windows/pgadmin4-%VER%-x64.exe"

rem --- Download (-f so HTTP errors fail instead of saving an error page) ---
"%CURL%" -sfL "%URL%" -o "%EXE%"
if errorlevel 1 (
    echo ERROR: Failed to download pgAdmin 4 %VER% from %URL%.
    rmdir /s /q "%WORKDIR%" 2>nul
    exit /b 1
)
echo pgAdmin 4 version %VER% downloaded successfully.

rem --- Verify it's signed by a trusted publisher ---
echo Verifying digital signature of pgAdmin 4 installer...
"%PS%" -NoProfile -Command "$sig = Get-AuthenticodeSignature '%EXE%'; if ($sig.Status -ne 'Valid') { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signature verification failed. Aborting pgAdmin 4 installation.'; exit 1 } else { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signer:' $sig.SignerCertificate.Subject; Write-Host 'Signature verified successfully.' }"
if errorlevel 1 (
    echo Signature verification failed. Aborting pgAdmin 4 installation.
    rmdir /s /q "%WORKDIR%" 2>nul
    exit /b 1
)
echo Signature verification passed. Proceeding with installation...

rem --- Install, then check the installer's exit code ---
if /I "%MODE%"=="silent" (
    "%EXE%" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /allusers
) else (
    "%EXE%" /NORESTART /allusers
)
set "RC=%ERRORLEVEL%"
if "%RC%"=="2" (
    echo pgAdmin 4 installation was cancelled by user.
    rmdir /s /q "%WORKDIR%" 2>nul
    exit /b 0
)
if not "%RC%"=="0" (
    echo ERROR: pgAdmin 4 installer exited with code %RC%.
    rmdir /s /q "%WORKDIR%" 2>nul
    exit /b %RC%
)

echo pgAdmin 4 version %VER% installed successfully.
rmdir /s /q "%WORKDIR%" 2>nul
echo Cleanup completed.
exit /b 0

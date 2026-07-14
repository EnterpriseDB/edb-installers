@echo off
setlocal
set "MODE=%~1"

rem --- Resolve latest version into VER (loop only sets the var) ---
set "VER="
for /f "usebackq tokens=1" %%v in (`powershell -NoProfile -Command "(Invoke-WebRequest -Uri \"https://www.postgresql.org/ftp/pgadmin/pgadmin4/\" -UseBasicParsing).Links.href | ForEach-Object { ($_ -replace '[v/]','') } | Where-Object { $_ -match '^\d+\.\d+' } | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1"`) do set "VER=%%v"

if not defined VER (
    echo ERROR: Unable to determine the latest pgAdmin 4 version.
    exit /b 1
)
echo Latest pgAdmin 4 version: %VER%

set "EXE=%TEMP%\pgadmin4-%VER%-x64.exe"
set "URL=https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v%VER%/windows/pgadmin4-%VER%-x64.exe"

rem --- Download (-f so HTTP errors fail instead of saving an error page) ---
curl -sfL "%URL%" -o "%EXE%"
if errorlevel 1 (
    echo ERROR: Failed to download pgAdmin 4 %VER% from %URL%.
    del "%EXE%" 2>nul
    exit /b 1
)
echo pgAdmin 4 version %VER% downloaded successfully.

rem --- Verify it's signed by a trusted publisher ---
echo Verifying digital signature of pgAdmin 4 installer...
powershell -NoProfile -Command "$sig = Get-AuthenticodeSignature '%EXE%'; if ($sig.Status -ne 'Valid') { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signature verification failed. Aborting pgAdmin 4 installation.'; exit 1 } else { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signer:' $sig.SignerCertificate.Subject; Write-Host 'Signature verified successfully.' }"
if errorlevel 1 (
    echo Signature verification failed. Aborting pgAdmin 4 installation.
    del "%EXE%" 2>nul
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
    del "%EXE%" 2>nul
    exit /b 0
)
if not "%RC%"=="0" (
    echo ERROR: pgAdmin 4 installer exited with code %RC%.
    del "%EXE%" 2>nul
    exit /b %RC%
)

echo pgAdmin 4 version %VER% installed successfully.
del "%EXE%" 2>nul
echo Cleanup completed.
exit /b 0

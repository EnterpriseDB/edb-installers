@echo off
set MODE=%1
:: Get latest pgAdmin version using curl
echo Fetching latest pgAdmin 4 version...
curl -s "https://www.postgresql.org/ftp/pgadmin/pgadmin4/" -o "%TEMP%\pgadmin_page.html"
for /f "tokens=2 delims=v/" %%v in ('findstr /r "v[0-9]*\.[0-9]*\/" "%TEMP%\pgadmin_page.html" ^| findstr /n "." ^| findstr "^1:"') do set LATEST=%%v
echo Latest pgAdmin 4 version detected: %LATEST%

:: Download pgAdmin installer
echo Downloading pgAdmin 4 version %LATEST%...
curl -L "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v%LATEST%/windows/pgadmin4-%LATEST%-x64.exe" -o "%TEMP%\pgadmin4-%LATEST%-x64.exe"
echo pgAdmin 4 version %LATEST% downloaded successfully.

:: Verify digital signature
echo Verifying digital signature of pgAdmin 4 installer...
powershell -Command "$sig = Get-AuthenticodeSignature '%TEMP%\pgadmin4-%LATEST%-x64.exe'; if ($sig.Status -ne 'Valid') { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signature verification failed. Aborting pgAdmin 4 installation.'; exit 1 } else { Write-Host 'Signature Status:' $sig.Status; Write-Host 'Signer:' $sig.SignerCertificate.Subject; Write-Host 'Signature verified successfully.' }"
if errorlevel 1 (
    echo Signature verification failed. Aborting pgAdmin 4 installation.
    del "%TEMP%\pgadmin_page.html"
    del "%TEMP%\pgadmin4-%LATEST%-x64.exe"
    exit /b 1
)
echo Signature verification passed. Proceeding with installation...

:: Install pgAdmin
echo Installing pgAdmin 4 version %LATEST%...
if "%MODE%"=="silent" (
    "%TEMP%\pgadmin4-%LATEST%-x64.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /allusers
) else (
    "%TEMP%\pgadmin4-%LATEST%-x64.exe" /NORESTART /allusers
)
echo pgAdmin 4 version %LATEST% installed successfully.

:: Cleanup
del "%TEMP%\pgadmin_page.html"
del "%TEMP%\pgadmin4-%LATEST%-x64.exe"
echo Cleanup completed.

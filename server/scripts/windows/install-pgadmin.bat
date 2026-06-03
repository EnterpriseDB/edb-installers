@echo off
set MODE=%1
for /f "usebackq tokens=1" %%v in (`powershell -Command "(Invoke-WebRequest -Uri \"https://www.postgresql.org/ftp/pgadmin/pgadmin4/\" -UseBasicParsing).Links.href | Where-Object { $_ -match \"v[\d.]+\" } | ForEach-Object { $_ -replace \"v\",\"\" -replace \"/\",\"\" } | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1"`) do (
    curl -L "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v%%v/windows/pgadmin4-%%v-x64.exe" -o "%TEMP%\pgadmin4-%%v-x64.exe"
    echo pgAdmin 4 version %%v downloaded successfully.

    REM Verify digital signature
    echo Verifying digital signature of pgAdmin 4 installer...
    powershell -Command "$sig = Get-AuthenticodeSignature '%TEMP%\pgadmin4-%%v-x64.exe'; if ($sig.Status -ne 'Valid') { Write-Host 'Signature verification failed. Aborting pgAdmin 4 installation.'; exit 1 } else { Write-Host 'Signature verified successfully. Signer:' $sig.SignerCertificate.Subject }"
    if errorlevel 1 (
        echo Signature verification failed. Aborting pgAdmin 4 installation.
        del "%TEMP%\pgadmin4-%%v-x64.exe"
        exit /b 1
    )
    echo Signature verification passed. Proceeding with installation...

    if "%MODE%"=="silent" (
        "%TEMP%\pgadmin4-%%v-x64.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /allusers
    ) else (
        "%TEMP%\pgadmin4-%%v-x64.exe" /NORESTART /allusers
    )
    echo pgAdmin 4 version %%v installed successfully.
    del "%TEMP%\pgadmin4-%%v-x64.exe"
    echo Cleanup completed.
)

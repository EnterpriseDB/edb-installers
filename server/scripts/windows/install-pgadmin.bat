@echo off
for /f "usebackq tokens=1" %%v in (`powershell -Command "(Invoke-WebRequest -Uri \"https://www.postgresql.org/ftp/pgadmin/pgadmin4/\" -UseBasicParsing).Links.href | Where-Object { $_ -match \"v[\d.]+\" } | ForEach-Object { $_ -replace \"v\",\"\" -replace \"/\",\"\" } | Sort-Object { [Version]$_ } -Descending | Select-Object -First 1"`) do (
    curl -L "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v%%v/windows/pgadmin4-%%v-x64.exe" -o "%TEMP%\pgadmin4-latest-x64.exe"
    "%TEMP%\pgadmin4-latest-x64.exe" /SILENT /SUPPRESSMSGBOXES /allusers
    del "%TEMP%\pgadmin4-latest-x64.exe"
)
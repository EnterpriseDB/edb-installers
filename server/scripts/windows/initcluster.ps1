# PowerShell Script for PostgreSQL Cluster Initialization
# Copyright (c) 2012-2022, EnterpriseDB Corporation.  All rights reserved

param (
    [string]$OSUsername,
    [string]$SuperUsername,
    [string]$Password,
    [string]$PasswordDir,
    [string]$InstallDir,
    [string]$DataDir,
    [int]$Port,
    [string]$Locale,
    [string]$CheckACL
)

# Function to log and terminate the script with an error message
function Die {
    param ([string]$Message)
    Write-Host "Called Die($Message)..."
    if (Test-Path $passwordFile) {
        Remove-Item $passwordFile
    }
    Write-Error $Message
    exit 1
}

# Function to log warnings
function Warn {
    param ([string]$Message)
    Write-Warning $Message
}

# Function to execute commands
function DoCmd {
    param ([string]$Command)
    Write-Host "Executing: $Command"
    $output = cmd.exe /c $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        Die "Command failed: $Command`n$output"
    }
    $output
}

# Convert the string CheckACL to a Boolean
$CheckACL = if ($CheckACL -eq 'true' -or $CheckACL -eq '1') { $true } else { $false }

# Validate input arguments
if (-not $OSUsername -or -not $SuperUsername -or -not $Password -or -not $PasswordDir -or -not $InstallDir -or -not $DataDir -or -not $Port -or -not $Locale) {
    Die "All parameters are required."
}

# Normalize DataDir path
$DataDir = $DataDir.TrimEnd('\')

# Ensure DataDir exists
if (-not (Test-Path $DataDir)) {
    Write-Host "Creating data directory: $DataDir"
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# Clear and set ACLs if required
if ($CheckACL) {
    Write-Host "Setting ACLs for $DataDir"
    DoCmd "icacls \"$DataDir\" /inheritance:r"
    DoCmd "icacls \"$DataDir\" /grant \"${OSUsername}:`(OI`)`(CI`)F\" /grant SYSTEM:(OI)(CI)F /grant \"CREATOR OWNER:`(OI`)`(CI`)F\" /grant Administrators:(OI)(CI)F"
}

# Create temporary password file
$passwordFile = Join-Path $PasswordDir "pwfile.txt"
Set-Content -Path $passwordFile -Value $Password -Force

# Run initdb
# If the Locale is set to "DEFAULT", fetch the system's locale dynamically
if ($Locale -eq "DEFAULT") {
	$LocaleName = (Get-WinSystemLocale).Name
}
# Convert "language, country" to "language (country)"
else {
	if ($Locale -match '\(') {
		# String contains a parenthesis, move the closing parenthesis to the end
		$Locale = $Locale -replace '\), ', ', ' -replace '$', ')'
	} else {
		# String does not contain a parenthesis, transform it normally
		$Locale = $Locale -replace ', ', ' (' -replace '$', ')'
	}
	$LocaleName = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) | Where-Object { $_.EnglishName -like "$Locale" } | Select-Object -ExpandProperty Name
}	
$initdbCmd = "`"$InstallDir\\bin\\initdb.exe`" --pgdata=`"$DataDir`" --username=`"$SuperUsername`" --encoding=UTF8 --locale=`"$LocaleName`" --pwfile=`"$passwordFile`" --auth=scram-sha-256"
Write-Host "Initializing PostgreSQL database cluster..."
DoCmd $initdbCmd

# Delete the password file
if (Test-Path $passwordFile) {
    Remove-Item $passwordFile
}

# Update postgresql.conf
$configFile = Join-Path $DataDir "postgresql.conf"
if (-not (Test-Path $configFile)) {
    Die "Configuration file not found: $configFile"
}

Write-Host "Updating postgresql.conf"
(gc $configFile) -replace "^#?listen_addresses =.*", "listen_addresses = '*'" -replace "^#?port =.*", "port = $Port" -replace "^#?logging_collector =.*", "logging_collector = on" | Set-Content -Path $configFile

# Ensure service account has full access
DoCmd "icacls \"$DataDir\" /grant \"${OSUsername}:`(OI`)`(CI`)F\""

# Create log directory
$logDir = Join-Path $DataDir "log"
if (-not (Test-Path $logDir)) {
    Write-Host "Creating log directory: $logDir"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Write-Host "PostgreSQL cluster initialized successfully."
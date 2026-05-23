# PowerShell Script for PostgreSQL Cluster Initialization
# Copyright (c) 2025, EnterpriseDB Corporation.  All rights reserved
# Rewritten to be fully independent of CMD autorun environment

param (
    [string]$OSUsername,
    [string]$SuperUsername,
    [string]$LoggedInUser,
    [string]$Password,
    [string]$PasswordDir,
    [string]$InstallDir,
    [string]$DataDir,
    [int]$Port,
    [string]$Locale,
    [string]$CheckACL
)

# -----------------------------------------------------------------------
# STEP 1: Validate all input arguments exist and are not empty
# -----------------------------------------------------------------------
if (-not $OSUsername -or -not $SuperUsername -or -not $LoggedInUser -or
    -not $Password -or -not $PasswordDir -or -not $InstallDir -or
    -not $DataDir -or -not $Port -or -not $Locale -or -not $CheckACL) {
    Write-Error "Usage: initcluster.ps1 <OSUsername> <SuperUsername> <LoggedInUser> <Password> <PasswordDir> <InstallDir> <DataDir> <Port> <Locale> <CheckACL>"
    exit 1
}

# -----------------------------------------------------------------------
# STEP 2: Resolve all paths to ABSOLUTE paths immediately
#         This makes script immune to broken working directory from CMD autorun
# -----------------------------------------------------------------------
try {
    # Normalize and resolve to absolute paths - does NOT require paths to exist yet
    $InstallDir  = [System.IO.Path]::GetFullPath($InstallDir.TrimEnd('\'))
    $DataDir     = [System.IO.Path]::GetFullPath($DataDir.TrimEnd('\'))
    $PasswordDir = [System.IO.Path]::GetFullPath($PasswordDir.TrimEnd('\'))
} catch {
    Write-Error "Failed to resolve absolute paths. Check InstallDir, DataDir, PasswordDir arguments. Error: $_"
    exit 1
}

# -----------------------------------------------------------------------
# STEP 3: Validate that critical paths actually exist on disk
# -----------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $InstallDir -PathType Container)) {
    Write-Error "InstallDir does not exist: $InstallDir"
    exit 1
}

$initdbExe = Join-Path $InstallDir "bin\initdb.exe"
if (-not (Test-Path -LiteralPath $initdbExe -PathType Leaf)) {
    Write-Error "initdb.exe not found at: $initdbExe — check InstallDir"
    exit 1
}

if (-not (Test-Path -LiteralPath $PasswordDir -PathType Container)) {
    Write-Error "PasswordDir does not exist: $PasswordDir"
    exit 1
}

# -----------------------------------------------------------------------
# STEP 4: Set working directory to InstallDir using absolute path
#         Must be done AFTER path resolution above
# -----------------------------------------------------------------------
try {
    Set-Location -LiteralPath $InstallDir -ErrorAction Stop
} catch {
    Write-Error "Failed to set working directory to InstallDir: $InstallDir. Error: $_"
    exit 1
}

# -----------------------------------------------------------------------
# STEP 5: Fix PATH — purely in PowerShell, no CMD dependency
#         Prepend InstallDir\bin so initdb finds postgres.exe and DLLs
# -----------------------------------------------------------------------
$installBinDir = Join-Path $InstallDir "bin"

# Save original PATH so we can restore it if needed
$originalPath = $env:PATH

# Build a clean PATH: InstallDir\bin first, then existing PATH entries,
# removing any empty or duplicate entries
$cleanPathEntries = @($installBinDir) + ($env:PATH -split ';' |
    Where-Object { $_ -ne '' -and $_ -ne $installBinDir })
$env:PATH = ($cleanPathEntries -join ';')

Write-Host "PATH updated. InstallDir\bin is now first: $installBinDir"

# -----------------------------------------------------------------------
# Utility Functions — pure PowerShell, NO cmd.exe calls
# -----------------------------------------------------------------------

# Password file path — track globally for cleanup in Die
$script:passwordFile = $null

function Die {
    param ([string]$Message)
    Write-Host "`nFATAL ERROR: $Message"
    # Clean up password file if it exists — do this before exit for security
    if ($script:passwordFile -and (Test-Path -LiteralPath $script:passwordFile)) {
        try {
            Remove-Item -LiteralPath $script:passwordFile -Force -ErrorAction Stop
            Write-Host "Cleaned up temporary password file."
        } catch {
            Write-Warning "Could not remove temporary password file: $script:passwordFile"
        }
    }
    Write-Error $Message
    exit 1
}

function Warn {
    param ([string]$Message)
    Write-Warning $Message
}

# DoCmd — rewritten to use pure PowerShell, NOT cmd.exe
# Uses Start-Process with explicit executable so it works even if CMD is broken/misconfigured
function DoCmd {
    param ([string]$Command)

    Write-Host "Executing: $Command"

    # Parse the command string into executable + arguments
    # This avoids invoking cmd.exe entirely
    $parts = $Command -split ' ', 2
    $executable = $parts[0].Trim('"')
    $arguments  = if ($parts.Length -gt 1) { $parts[1] } else { "" }

    try {
        $proc = Start-Process `
            -FilePath $executable `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput "$env:TEMP\pg_stdout.tmp" `
            -RedirectStandardError  "$env:TEMP\pg_stderr.tmp" `
            -ErrorAction Stop

        # Read and display output
        if (Test-Path "$env:TEMP\pg_stdout.tmp") {
            $stdout = Get-Content "$env:TEMP\pg_stdout.tmp" -ErrorAction SilentlyContinue
            if ($stdout) { Write-Host ($stdout -join "`n") }
            Remove-Item "$env:TEMP\pg_stdout.tmp" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "$env:TEMP\pg_stderr.tmp") {
            $stderr = Get-Content "$env:TEMP\pg_stderr.tmp" -ErrorAction SilentlyContinue
            if ($stderr) { Write-Host ($stderr -join "`n") }
            Remove-Item "$env:TEMP\pg_stderr.tmp" -Force -ErrorAction SilentlyContinue
        }

        $exitCode = $proc.ExitCode
        if ($exitCode -ne 0) {
            Write-Host "ERROR: Command failed with exit code $exitCode."
        } else {
            Write-Host "SUCCESS: Command completed."
        }
        return $exitCode

    } catch {
        Write-Host "ERROR: Failed to execute command: $Command. Exception: $_"
        return 1
    }
}

# -----------------------------------------------------------------------
# ACL Functions — use icacls.exe via absolute path, NOT via cmd.exe
# -----------------------------------------------------------------------

function ClearAcl {
    param ([string]$DirectoryPath)
    Write-Host "`nClearAcl: $DirectoryPath"

    # Use absolute path to icacls.exe — immune to PATH being broken
    $icacls = "$env:WINDIR\System32\icacls.exe"

    try {
        $proc = Start-Process -FilePath $icacls `
            -ArgumentList "`"$DirectoryPath`" /inheritance:r" `
            -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -ne 0) {
            Write-Host "Failed to remove inherited ACLs on: $DirectoryPath"
        } else {
            Write-Host "Removed inherited ACLs on: $DirectoryPath"
        }
        return $proc.ExitCode
    } catch {
        Write-Host "ERROR running icacls: $_"
        return 1
    }
}

function AclCheck {
    param (
        [string]$DirectoryPath,
        [string]$UserName,
        [string]$UserSid,
        [int]$Index
    )
    Write-Host "`nAclCheck: $DirectoryPath"

    # Skip system root directories
    if ($DirectoryPath -eq $env:PROGRAMFILES -or $DirectoryPath -eq $env:SYSTEMDRIVE) {
        Write-Host "Skipping ACL check on system path: $DirectoryPath"
        return 0
    }

    $icacls = "$env:WINDIR\System32\icacls.exe"
    $userIdToGrant = if ($UserSid) { "*$UserSid" } else { $UserName }

    if ($Index -ne 0) {
        $arguments = "`"$DirectoryPath`" /grant `"${userIdToGrant}:(NP)(RX)`""
    } else {
        # Drive root — no NP flag, must end with backslash, no surrounding quotes on drive
        $driveRoot = $DirectoryPath.TrimEnd('\') + '\'
        $arguments = "`"$driveRoot`" /grant `"${userIdToGrant}:(RX)`""
    }

    try {
        $proc = Start-Process -FilePath $icacls `
            -ArgumentList $arguments `
            -NoNewWindow -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -ne 0) {
            Write-Host "Failed to set ACL on: $DirectoryPath"
        }
        return $proc.ExitCode
    } catch {
        Write-Host "ERROR running icacls on $DirectoryPath : $_"
        return 1
    }
}

# -----------------------------------------------------------------------
# MAIN LOGIC
# -----------------------------------------------------------------------

$boolCheckACL = ($CheckACL -eq 'true' -or $CheckACL -eq '1')

# Ensure DataDir exists
if (-not (Test-Path -LiteralPath $DataDir)) {
    Write-Host "Creating data directory: $DataDir"
    try {
        New-Item -ItemType Directory -Path $DataDir -Force -ErrorAction Stop | Out-Null
    } catch {
        Die "Failed to create data directory: $DataDir. Error: $_"
    }
}

# Remove inherited ACLs from DataDir
if ((ClearAcl -DirectoryPath $DataDir) -ne 0) {
    Die "Failed to reset ACL on data directory: $DataDir"
}

# Get parent of DataDir
$ParentOfDataDir = Split-Path $DataDir -Parent
Write-Host "Parent of Data Directory: $ParentOfDataDir"

# Get logged-in user info — pure PowerShell, no cmd.exe whoami call
$LoggedInUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Logged in user: $LoggedInUserName"
Write-Host "Logged in user SID: $LoggedInUser"

# Apply ACL checks up the parent directory chain
if ($boolCheckACL) {
    $arrDirs = $ParentOfDataDir.Split('\')
    $nDirs   = $arrDirs.Length - 1
    $strThisDir = ""

    for ($d = 0; $d -le $nDirs; $d++) {
        $strThisDir = $strThisDir + $arrDirs[$d]
        AclCheck -DirectoryPath $strThisDir -UserName $LoggedInUserName -UserSid $LoggedInUser -Index $d
        $strThisDir = $strThisDir + "\"
    }
}

# ACL for DataDir itself
AclCheck -DirectoryPath $DataDir -UserName $LoggedInUserName -UserSid $LoggedInUser -Index 1

# Grant install dir permissions if CheckACL enabled
if ($boolCheckACL) {
    Write-Host "Granting $LoggedInUserName permissions on $InstallDir"
    $icacls = "$env:WINDIR\System32\icacls.exe"
    $proc = Start-Process -FilePath $icacls `
        -ArgumentList "`"$InstallDir`" /T /grant:r `"*${LoggedInUser}:(OI)(CI)(RX)`"" `
        -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "Failed to set install dir permissions: $InstallDir"
    }
}

# Grant full access to logged-in user on DataDir
Write-Host "Granting full access to $LoggedInUserName on $DataDir"
$icacls = "$env:WINDIR\System32\icacls.exe"

foreach ($grant in @(
    "`"$DataDir`" /T /grant:r `"*${LoggedInUser}:(OI)(CI)F`"",
    "`"$DataDir`" /grant `"${OSUsername}:(OI)(CI)F`"",
    "`"$DataDir`" /grant `"*S-1-3-0:(OI)(CI)F`"",   # CREATOR OWNER
    "`"$DataDir`" /grant `"*S-1-5-18:(OI)(CI)F`"",  # SYSTEM
    "`"$DataDir`" /grant `"*S-1-5-32-544:(OI)(CI)F`""  # Administrators
)) {
    $proc = Start-Process -FilePath $icacls -ArgumentList $grant `
        -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "WARNING: icacls grant failed for: $grant"
    }
}

# -----------------------------------------------------------------------
# Create temporary password file securely
# -----------------------------------------------------------------------
$randomFileName = ([guid]::NewGuid().ToString("N").Substring(0,8)) + ".tmp"
$script:passwordFile = Join-Path $PasswordDir $randomFileName

try {
    Set-Content -LiteralPath $script:passwordFile -Value $Password -Force -ErrorAction Stop
} catch {
    Die "Failed to create temporary password file in: $PasswordDir. Error: $_"
}

# -----------------------------------------------------------------------
# Normalize locale: "English, Country" → "English_Country"
# -----------------------------------------------------------------------
if ($Locale -match '^English, (.+)$') {
    $Locale = "English_$($matches[1])"
}

# -----------------------------------------------------------------------
# Run initdb — using absolute path, no PATH dependency
# -----------------------------------------------------------------------
Write-Host "`nInitializing PostgreSQL database cluster..."

$initdbArgs = @(
    "--pgdata=`"$DataDir`"",
    "--username=`"$SuperUsername`"",
    "--encoding=UTF8",
    "--pwfile=`"$($script:passwordFile)`"",
    "--auth=scram-sha-256"
)

if ($Locale -ne "DEFAULT") {
    $initdbArgs += "--locale=`"$Locale`""
}

Write-Host "Executing: $initdbExe $initdbArgs"

try {
    $initdbProcess = Start-Process `
        -FilePath $initdbExe `
        -ArgumentList $initdbArgs `
        -NoNewWindow -Wait -PassThru -ErrorAction Stop

    $initdbExitCode = $initdbProcess.ExitCode
    Write-Host "initdb exit code = $initdbExitCode"

    if ($initdbExitCode -ne 0) {
        Die "initdb failed with exit code $initdbExitCode"
    }
} catch {
    Die "Failed to launch initdb.exe: $_"
}

# -----------------------------------------------------------------------
# Delete password file immediately after initdb — security cleanup
# -----------------------------------------------------------------------
if (Test-Path -LiteralPath $script:passwordFile) {
    Remove-Item -LiteralPath $script:passwordFile -Force
    $script:passwordFile = $null
    Write-Host "Temporary password file removed."
}

# -----------------------------------------------------------------------
# Update postgresql.conf
# -----------------------------------------------------------------------
$configFile = Join-Path $DataDir "postgresql.conf"
if (-not (Test-Path -LiteralPath $configFile)) {
    Die "postgresql.conf not found at: $configFile — initdb may have failed silently"
}

Write-Host "Updating postgresql.conf..."
try {
    (Get-Content -LiteralPath $configFile) `
        -replace "^#?listen_addresses\s*=.*", "listen_addresses = '*'" `
        -replace "^#?port\s*=.*",             "port = $Port" `
        -replace "^#?log_destination\s*=.*",  "log_destination = 'stderr'" `
        -replace "^#?logging_collector\s*=.*","logging_collector = on" `
        -replace "^#?log_line_prefix\s*=.*",  "log_line_prefix = '%t '" |
    Set-Content -LiteralPath $configFile -ErrorAction Stop
    Write-Host "postgresql.conf updated."
} catch {
    Die "Failed to update postgresql.conf: $_"
}

# -----------------------------------------------------------------------
# Post-init ACL checks for service account
# -----------------------------------------------------------------------
if ($boolCheckACL) {
    $arrDirs = $ParentOfDataDir.Split('\')
    $nDirs   = $arrDirs.Length - 1
    $strThisDir = ""

    for ($d = 0; $d -le $nDirs; $d++) {
        $strThisDir = $strThisDir + $arrDirs[$d]
        AclCheck -DirectoryPath $strThisDir -UserName $OSUsername -Index $d
        $strThisDir = $strThisDir + "\"
    }
}

AclCheck -DirectoryPath $DataDir -UserName $OSUsername -Index 1

if ($boolCheckACL) {
    Write-Host "Granting $OSUsername permissions on $InstallDir"
    $proc = Start-Process -FilePath "$env:WINDIR\System32\icacls.exe" `
        -ArgumentList "`"$InstallDir`" /T /grant:r `"${OSUsername}:(OI)(CI)(RX)`"" `
        -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "Failed to grant install dir permissions to $OSUsername"
    }
}

# Create log directory
$logDir = Join-Path $DataDir "log"
if (-not (Test-Path -LiteralPath $logDir)) {
    Write-Host "Creating log directory: $logDir"
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Final service account permissions on DataDir
Write-Host "Granting service account ($OSUsername) full access to data directory..."
$proc = Start-Process -FilePath "$env:WINDIR\System32\icacls.exe" `
    -ArgumentList "`"$DataDir`" /T /C /grant `"${OSUsername}:(OI)(CI)F`"" `
    -NoNewWindow -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Host "WARNING: Failed to grant service account access to: $DataDir"
}

Write-Host "`ninitcluster.ps1 completed successfully."

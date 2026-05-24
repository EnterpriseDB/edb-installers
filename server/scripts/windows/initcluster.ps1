# PowerShell Script for PostgreSQL Cluster Initialization
# Copyright (c) 2025, EnterpriseDB Corporation.  All rights reserved

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

# Validate input arguments
if (-not $OSUsername -or -not $SuperUsername -or -not $LoggedInUser -or -not $Password -or -not $PasswordDir -or -not $InstallDir -or -not $DataDir -or -not $Port -or -not $Locale -or -not $CheckACL) {
    Write-Host "Usage: initcluster.ps1 <OSUsername> <SuperUsername> <LoggedInUser> <Password> <PasswordDir> <Install dir> <Data dir> <Port> <Locale> <CheckACL>"
    exit 1
}

# Create a temporary script file
$scriptFileName = ($([guid]::NewGuid()).ToString("N").Substring(0,8)) + ".ps1"
$outputFileName = ($([guid]::NewGuid()).ToString("N").Substring(0,8)) + ".tmp"

# Function to log and terminate the script with an error message
function Die {
    param ([string]$Message)
    Write-Host "`nCalled Die($Message)..."
    if (Test-Path "$passwordFile") {
        Remove-Item "$passwordFile"
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

    Write-Host "Executing command: $Command"

    # Use a temporary variable to hold the combined output (stdout and stderr)
    # The '2>&1' is crucial. It merges the error stream (2) with the output stream (1).
    # The '( )' ensures the entire command is treated as a single pipeline,
    # allowing us to capture the output and check $LASTEXITCODE reliably.
    $output = & "$env:WINDIR\System32\cmd.exe" /D /C $Command 2>&1

    # Check the exit code of the last executed native command
    $exitCode = $LASTEXITCODE

    # Display the captured output
    if ($output) {
        Write-Host "--- Command Output ---"
        $output | Write-Host
        Write-Host "----------------------"
    } else {
        Write-Host "Command executed, but produced no output."
    }

    # If the command failed, print a clear error message
    if ($exitCode -ne 0) {
        Write-Host "`nERROR: Command failed with exit code $exitCode."
    } else {
        Write-Host "`nSUCCESS: Command completed successfully."
    }

    # Return the exit code for the calling function to use
    return $exitCode
}


# Function to Clear ACL
function ClearAcl {
    param (
        [string]$DirectoryPath
    )
    Write-Host "`nCalled ClearAcl (`"$DirectoryPath`")..."
    # Print current ACL
    #Write-Host "`nCurrent ACL ("$DirectoryPath"):"
    $currentAcl = & "$env:WINDIR\System32\icacls.exe" "`"$DirectoryPath`""
    #$currentAcl | ForEach-Object { Write-Host $_ }

    # Remove inherited ACLs
    Write-Host "`nRemoving inherited ACLs on (`"$DirectoryPath`")..."
    $output = & "$env:WINDIR\System32\icacls.exe" "`"$DirectoryPath`"" /inheritance:r
    #$output | ForEach-Object { Write-Host $_ }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`nFailed to remove inherited ACLs on (`"$DirectoryPath`")"
    } else {
        Write-Host "`nSuccessfully removed inherited ACLs on (`"$DirectoryPath`")"
    }
    return $LASTEXITCODE
}

# Function to check and set ACLs on the given directory
function AclCheck {
    param (
        [string]$DirectoryPath,
        [string]$UserName,
        [string]$UserSid,
        [int]$Index
    )
    Write-Host "`nCalled AclCheck($DirectoryPath)"

    if ($DirectoryPath -eq $env:PROGRAMFILES) {
        Write-Host "`nSkipping the ACL check on $DirectoryPath"
        return 0
    } elseif ($DirectoryPath -eq $env:SYSTEMDRIVE) {
        Write-Host "`nSkipping the ACL check on $DirectoryPath"
        return 0
    } else {
        # Decide whether to use SID or fallback to username
        $userIdToGrant = if ($UserSid) { "*$UserSid" } else { "$UserName" }
        Write-Host "Executing icacls to ensure the $UserName account can read the path $DirectoryPath"

        if ($Index -ne 0) {
            # For directories other than the root drive, grant permissions (NP)(RX)
            $command = "$env:WINDIR\System32\icacls.exe `"$DirectoryPath`" /grant `"$userIdToGrant`:(NP)(RX)`""
        } else {
            # Drive letter must not be surronded by double-quotes and ends with slash (\)
            # "icacls" fails on the drives with (NP) flag
            $command = "$env:WINDIR\System32\icacls.exe `"$DirectoryPath\\`" /grant `"$userIdToGrant`:(NP)(RX)`""
        }
        # Execute the command
        $iRet = DoCmd "$command"

        if ($iRet -ne 0) {
            Write-Host "`nFailed to ensure the path $DirectoryPath is readable"
        }
    }
}

# Convert the string CheckACL to a Boolean
$boolCheckACL = if ($CheckACL -eq 'true' -or $CheckACL -eq '1') { $true } else { $false }

# Normalize DataDir path
$DataDir = $DataDir.TrimEnd('\')

# Change the current directory to the installation directory
# This is important, because initdb will drop Administrative
# permissions and may lose access to the current working directory
Set-Location -Path "$InstallDir"

# Ensure DataDir exists
if (-not (Test-Path "$DataDir")) {
    Write-Host "`nCreating data directory: $DataDir"
    New-Item -ItemType Directory -Path "$DataDir" -Force | Out-Null
}

# Remove inherited ACLs
if ((ClearAcl -DirectoryPath $DataDir) -ne 0) {
    Die "Failed to reset the ACL ($DataDir)"
}

# Get parent dir of Data dir
$ParentOfDataDir = Split-Path $DataDir -Parent
Write-Host "`nParent of Data Directory: $ParentOfDataDir"

# Get logged-in user
$LoggedInUser = $LoggedInUser
$LoggedInUserName = (whoami)
Write-Host "Logged in user: $LoggedInUserName"
Write-Host "Logged in user SID: $LoggedInUser"

if ($boolCheckAcl) {
    # Split the parent directory path into an array
    $arrDirs = $ParentOfDataDir.Split('\')
    $nDirs = $arrDirs.Length - 1
    
    $strThisDir = ""
    
    # Loop through each directory and apply ACL checks
    for ($d = 0; $d -le $nDirs; $d++) {
        $strThisDir = $strThisDir + $arrDirs[$d]
        AclCheck -DirectoryPath "$strThisDir" -UserName $LoggedInUserName -UserSid $LoggedInUser -Index $d
        $strThisDir = $strThisDir + "\"
    }
    
    Write-Host "`nParent of Data Directory: $ParentOfDataDir"
    Write-Host "`nInstall Directory: $InstallDir"
}

# Apply ACL for the data directory
AclCheck -DirectoryPath "$DataDir" -UserName $LoggedInUserName -UserSid $LoggedInUser -Index 1

# If ACL check is enabled, grant permissions on the install directory
if ($boolCheckAcl) {
    Write-Host "`nGranting the $LoggedInUserName permissions on $InstallDir"
    $icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$InstallDir`" /T /grant:r `"*$LoggedInUser`:(OI)(CI)(RX)`""
    $iRet = DoCmd -Command "$icaclsCommand"
    if ($iRet -ne 0) {
        Write-Host "`nFailed to ensure the Install directory is accessible ($InstallDir)"
    }
}

# Grant ACLs for specific users on data directory
Write-Host "`nEnsuring we can write to the data directory (using icacls) for ${LoggedInUserName}:"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /T /grant:r `"*$LoggedInUser`:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to ensure the data directory is accessible ($DataDir)"
}

Write-Host "`nGranting full access to $OSUsername on $DataDir"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /grant `"$OSUsername`:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to grant access to $OSUsername on $DataDir"
}

Write-Host "`nGranting full access to CREATOR OWNER on $DataDir"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /grant `"*S-1-3-0:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to grant access to CREATOR OWNER on $DataDir"
}

Write-Host "`nGranting full access to SYSTEM on $DataDir"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /grant `"*S-1-5-18:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to grant access to SYSTEM on $DataDir"
}

Write-Host "`nGranting full access to Administrators on $DataDir"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /grant `"*S-1-5-32-544:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to grant access to Administrators on $DataDir"
}

# Create temporary password file
$randomFileName = ($([guid]::NewGuid()).ToString("N").Substring(0,8)) + ".tmp"
$passwordFile = Join-Path "$PasswordDir"  $randomFileName
Set-Content -Path "$passwordFile" -Value $Password -Force

# Change English locales: "English, <Country>" â†’ "English_<Country>"
if ($Locale -match '^English, (.+)$') {
    $Locale = "English_$($matches[1])"
}

# Prepend the current bin directory to the PATH so initdb finds the correct postgres.exe
$env:PATH = "$InstallDir\bin;" + $env:PATH

# Run initdb
Write-Host "`nInitializing PostgreSQL database cluster..."
# Set initdb arguments
$initdbArgs = @(
	"--pgdata=`"$DataDir`"",
	"--username=`"$SuperUsername`"", 
	"--encoding=UTF8", 
	"--pwfile=`"$passwordFile`"", 
	"--auth=scram-sha-256"
)

if ($Locale -ne "DEFAULT") {
    $initdbArgs += "--locale=`"$Locale`""
}

# Print the full command
Write-Host "`nExecuting: `"$InstallDir\bin\initdb.exe`" $initdbArgs `n"

# Run the initdb command
$initdbProcess = Start-Process -FilePath "$InstallDir\bin\initdb.exe" -ArgumentList "$initdbArgs" -NoNewWindow -Wait -PassThru
$initdbExitCode = $initdbProcess.ExitCode

Write-Host "initdb exit code =" $initdbExitCode

if ($initdbExitCode -ne 0) {
    Die "Failed to initialise the database cluster with initdb"
}

# Delete the password file
if (Test-Path $passwordFile) {
    Remove-Item "$passwordFile"
}

# Update postgresql.conf
$configFile = Join-Path "$DataDir" "postgresql.conf"
if (-not (Test-Path "$configFile")) {
    Die "Configuration file not found: $configFile"
}

Write-Host "`nUpdating postgresql.conf"
(gc "$configFile") -replace "^#?listen_addresses =.*", "listen_addresses = '*'" `
                 -replace "^#?port =.*", "port = $Port" `
                 -replace "^#?log_destination =.*", "log_destination = 'stderr'" `
                 -replace "^#?logging_collector =.*", "logging_collector = on" `
                 -replace "^#?log_line_prefix =.*", "log_line_prefix = '%t '" | 
    Set-Content -Path "$configFile"

if ($boolCheckAcl) {
    # Loop up the directory path, and ensure the service account has read permissions
    # on the entire path leading to the data directory
    $arrDirs = $ParentOfDataDir.Split('\')
    $nDirs = $arrDirs.Length - 1

    $strThisDir = ""

    # Loop through each directory and apply ACL checks
    for ($d = 0; $d -le $nDirs; $d++) {
        $strThisDir = $strThisDir + $arrDirs[$d]
        AclCheck -DirectoryPath "$strThisDir" -UserName $OSUsername -Index $d
        $strThisDir = $strThisDir + "\"
    }
}  

AclCheck -DirectoryPath "$DataDir" -UserName $OSUsername -Index 1

if ($boolCheckAcl) {
    Write-Host "`nGranting $OSUsername permissions on $InstallDir"
    $icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$InstallDir`" /T /grant:r `"$OSUsername`:(OI)(CI)(RX)`""
    $iRet = DoCmd -Command "$icaclsCommand"
    if ($iRet -ne 0) {
        Write-Host "`nFailed to ensure the Install directory is accessible ($InstallDir)"
    }
}

# Create the <DATA_DIR>\log directory (if not exists)
# Create it before updating the permissions, so that it will also get affected
$logDir = Join-Path "$DataDir" "log"
if (-not (Test-Path "$logDir")) {
    Write-Host "`nCreating log directory: $logDir"
    New-Item -ItemType Directory -Path "$logDir" -Force | Out-Null
}

# Secure the data directory
Write-Host "`nGranting service account access to the data directory (using icacls) to $OSUsername"
$icaclsCommand = "$env:WINDIR\System32\icacls.exe `"$DataDir`" /T /C /grant `"$OSUsername`:(OI)(CI)F`""
$iRet = DoCmd -Command "$icaclsCommand"
if ($iRet -ne 0) {
    Write-Host "`nFailed to grant service account access to the data directory ($DataDir)"
}

Write-Host "`ninitcluster.ps1 ran to completion."

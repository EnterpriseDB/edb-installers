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
    $output = & "$env:WINDIR\System32\cmd.exe" /c $Command 2>&1

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

# Change English locales: "English, <Country>" → "English_<Country>"
if ($Locale -match '^English, (.+)$') {
    $Locale = "English_$($matches[1])"
}

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

# SIG # Begin signature block
# MIIufAYJKoZIhvcNAQcCoIIubTCCLmkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCJJ+ZVihs/CprE
# 8rzLClPvJaJjuncCpJp8xF5k0PqBnqCCEeUwggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZQMIIEuKADAgECAhEAhVZbGY9L7mK/oiv+yHKFPTANBgkq
# hkiG9w0BAQwFADBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2
# MB4XDTI1MTIwMTAwMDAwMFoXDTI4MTEzMDIzNTk1OVowZjELMAkGA1UEBhMCVVMx
# ETAPBgNVBAgMCERlbGF3YXJlMSEwHwYDVQQKDBhFbnRlcnByaXNlREIgQ29ycG9y
# YXRpb24xITAfBgNVBAMMGEVudGVycHJpc2VEQiBDb3Jwb3JhdGlvbjCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBALo30OIsxq0boxIpnG/Ck9vBlfpenXFY
# pmN1CrWfaxFo1HFFRrxfZDhPJDrAcbHNG7W6CERHnPNHQrAN+VlGlppgcF5De6/K
# t5GjO0LO45l3AoVI/zXfYg5vWAcF5mYsFyJH8n8f/oI3X7W7vqNbLtOxcod+YqpH
# JVZoJcncOqj/01iR62k86mYmrtOpu7e7jkSF8uzPvyie26OgayrPT9eFcTXtLuTG
# 2WpQTlAC+lnXYjmZEXuRAUx0P7/kn032aayEth8o+iLsc+u31cf8fi4KObMplB4y
# GGWu2emM4+ic52YBpvhajPDqqRYLqatoZ6rgDFfn2tAcHPcW/WThfN7nmR9sF9bN
# 9WijxrhFsHlFHdzt1dAIDWSscllZaqivviD23AVM8eMFMTJ8DIJqVbr+hUmxatVE
# 9sf/oHTbH7eQ7O3JEjUjpXOMwOr682EHmuz0dWZ8F1sSVtlY6gseavyN4d9/dSWk
# IbKRqqPE87xCrYQizUuRvWWSyN8vVVIMmtCGXz+yZ+jsmg6knLC+GPESe4r/U/LM
# kR2/CxX0a6flkGPxjGnCzqpLLFbr2QRi68tG4sIbzBR7UOi5CmVVFwMBOqMlRcs8
# iszbSoFd3ovPm0j/ITq+5KFnGQCT2v5nD0xAQjFDBQB1n76jJTzuxC9fZ9eQFrEf
# S5t/c52kW+uhAgMBAAGjggGJMIIBhTAfBgNVHSMEGDAWgBQPKssghyi47G9IritU
# pimqF6TNDDAdBgNVHQ4EFgQU/S57h12eEpCRkbrG5zWuUbe4j34wDgYDVR0PAQH/
# BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwSgYDVR0g
# BEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0
# aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqGOGh0dHA6Ly9j
# cmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3Js
# MHkGCCsGAQUFBwEBBG0wazBEBggrBgEFBQcwAoY4aHR0cDovL2NydC5zZWN0aWdv
# LmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcnQwIwYIKwYBBQUH
# MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4IBgQAr
# H7TkUuoNjRnvVgoLUyz0JfA13W/HyylfOGX2YkfOwMF5JYTkv2vOtCTGfCSBdF8e
# u3zzE5Mm4xgRAbwIhYLtF/MqKbe/V9hUeZ7zpecRwnnUfUGC3Hy0MdLAoFFtdYRt
# bwrqkVL7yTv+rU9T6qn6BhR6wyIBaidPch69QnrPhnwXqilbICfEdAjlGZ39sbtO
# zth3wGYhaNKHYqNPi+GL8rcOoZ8SZU4TsRcOdRiS354k962YF674ilesTtF5hFfa
# SWbhuhkwCvFXqRApp5XHXVMRBC1js/Q5YzHte8UUWB3FCbDv6fAL2RbMUs5yrYgC
# Zgdqxf8dAzjSxMDPwngsws0Lji7UsBocLLwe3YUxcag0IjcTm6Je6sVd74u8HeTy
# 1Kic13yEGMc9N8Ef8fHsKWhXfpbsMiDGNukuen/WvgJQnzKU1W106DSacnJWh2xO
# OH/gIN+WAzOVzCVdixHZcy02xwNYWNsjM+pVPYYG3ByRz4tFKLTFMQ6wz3IRTxcx
# ghvtMIIb6QIBATBpMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBS
# MzYCEQCFVlsZj0vuYr+iK/7IcoU9MA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGC
# NwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKQpXqkW/QOyUVK0zGN9
# E/M7Lvctx8hRHhcyyeSOwpRMMA0GCSqGSIb3DQEBAQUABIICAH3Pjj5s9cQEt3Nf
# j2gaTlaf+fu7B5P3t02auB+zFTHd0HuL+MuBibzPI6FdtpFABzf5er354wJp2TL/
# D+BjjMMP1XL9j/gQDz0WQ6FiRZWEcd7YTlQo/uaARQgMq/L3K6YIXKU35jUrH72a
# 1FWw05ZVRSzLQkVR7mB3IvSvEm40aOftVdVvqfYml2VdcrorYv0mA6UC1roEpn39
# Qk1p2nOJxCgk1N6ixtHRmVJYCgxDMUKyFDVjHtSBLyQYq3r7zbJ+U4oc9lecbmui
# 4vqNnKlwOqpQQ/ks5795Xc8QP3/MydnkYAPUP/FuYs3i42+8UDdoiyhtkVG2euj/
# wVLKGi2DSJr2+sxzYyAZw8poMllJO9jla7RaGRHNGtsZ0LGQYMBYeh8qGwxGl+CT
# 9wXODvZ6m0pGlxoJghVX+JEETetwZE/XVS29EHgbaSGyiJfXxMOLMHMArO8eDwAW
# cfFDvgk8f7yz79hgzv47v6x6KhasQOBP8PfCc1ZcUFEk9GybHjd5QO9Uq7I4RZRM
# 6y4NzvFLW7hxfw84C4yC9qlyohzTvcjdfzRbQsWIfHBJZBf360P2D0jDkxr/Kgcb
# bTJOJrp3IXrqfa0h1xJM5mbE/YPX1HEIvxNheGjghMdHce/scTvlDENsVucnpJZB
# ByRjdD/XVGcsYG5LlF2Y3jJ2ff8HoYIY1zCCGNMGCisGAQQBgjcDAwExghjDMIIY
# vwYJKoZIhvcNAQcCoIIYsDCCGKwCAQMxDzANBglghkgBZQMEAgIFADCB9wYLKoZI
# hvcNAQkQAQSggecEgeQwgeECAQEGCisGAQQBsjECAQEwMTANBglghkgBZQMEAgEF
# AAQg+2mltgkKiht5C5XePPxiYPRr2xSAYtvMjM6VajrwBfoCFFQzaMIy/nvSkM9b
# yqlVbAKkBn2DGA8yMDI2MDIwNTE0Mjk1NlqgdqR0MHIxCzAJBgNVBAYTAkdCMRcw
# FQYDVQQIEw5XZXN0IFlvcmtzaGlyZTEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MTAwLgYDVQQDEydTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIFNpZ25lciBS
# MzagghMEMIIGYjCCBMqgAwIBAgIRAKQpO24e3denNAiHrXpOtyQwDQYJKoZIhvcN
# AQEMBQAwVTELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEs
# MCoGA1UEAxMjU2VjdGlnbyBQdWJsaWMgVGltZSBTdGFtcGluZyBDQSBSMzYwHhcN
# MjUwMzI3MDAwMDAwWhcNMzYwMzIxMjM1OTU5WjByMQswCQYDVQQGEwJHQjEXMBUG
# A1UECBMOV2VzdCBZb3Jrc2hpcmUxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEw
# MC4GA1UEAxMnU2VjdGlnbyBQdWJsaWMgVGltZSBTdGFtcGluZyBTaWduZXIgUjM2
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA04SV9G6kU3jyPRBLeBIH
# PNyUgVNnYayfsGOyYEXrn3+SkDYTLs1crcw/ol2swE1TzB2aR/5JIjKNf75QBha2
# Ddj+4NEPKDxHEd4dEn7RTWMcTIfm492TW22I8LfH+A7Ehz0/safc6BbsNBzjHTt7
# FngNfhfJoYOrkugSaT8F0IzUh6VUwoHdYDpiln9dh0n0m545d5A5tJD92iFAIbKH
# QWGbCQNYplqpAFasHBn77OqW37P9BhOASdmjp3IijYiFdcA0WQIe60vzvrk0HG+i
# VcwVZjz+t5OcXGTcxqOAzk1frDNZ1aw8nFhGEvG0ktJQknnJZE3D40GofV7O8Wzg
# aAnZmoUn4PCpvH36vD4XaAF2CjiPsJWiY/j2xLsJuqx3JtuI4akH0MmGzlBUylhX
# vdNVXcjAuIEcEQKtOBR9lU4wXQpISrbOT8ux+96GzBq8TdbhoFcmYaOBZKlwPP7p
# Op5Mzx/UMhyBA93PQhiCdPfIVOCINsUY4U23p4KJ3F1HqP3H6Slw3lHACnLilGET
# XRg5X/Fp8G8qlG5Y+M49ZEGUp2bneRLZoyHTyynHvFISpefhBCV0KdRZHPcuSL5O
# AGWnBjAlRtHvsMBrI3AAA0Tu1oGvPa/4yeeiAyu+9y3SLC98gDVbySnXnkujjhIh
# +oaatsk/oyf5R2vcxHahajMCAwEAAaOCAY4wggGKMB8GA1UdIwQYMBaAFF9Y7Uwx
# eqJhQo1SgLqzYZcZojKbMB0GA1UdDgQWBBSIYYyhKjdkgShgoZsx0Iz9LALOTzAO
# BgNVHQ8BAf8EBAMCBsAwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEBAgEDCDAlMCMGCCsGAQUFBwIBFhdo
# dHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBBAIwSgYDVR0fBEMwQTA/oD2g
# O4Y5aHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljVGltZVN0YW1w
# aW5nQ0FSMzYuY3JsMHoGCCsGAQUFBwEBBG4wbDBFBggrBgEFBQcwAoY5aHR0cDov
# L2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljVGltZVN0YW1waW5nQ0FSMzYu
# Y3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAYEAAoE+pIZyUSH5ZakuPVKK4eWbzEsTRJOEjbIu6r7vmzXXLpJx
# 4FyGmcqnFZoa1dzx3JrUCrdG5b//LfAxOGy9Ph9JtrYChJaVHrusDh9NgYwiGDOh
# yyJ2zRy3+kdqhwtUlLCdNjFjakTSE+hkC9F5ty1uxOoQ2ZkfI5WM4WXA3ZHcNHB4
# V42zi7Jk3ktEnkSdViVxM6rduXW0jmmiu71ZpBFZDh7Kdens+PQXPgMqvzodgQJE
# kxaION5XRCoBxAwWwiMm2thPDuZTzWp/gUFzi7izCmEt4pE3Kf0MOt3ccgwn4Kl2
# FIcQaV55nkjv1gODcHcD9+ZVjYZoyKTVWb4VqMQy/j8Q3aaYd/jOQ66Fhk3NWbg2
# tYl5jhQCuIsE55Vg4N0DUbEWvXJxtxQQaVR5xzhEI+BjJKzh3TQ026JxHhr2fuJ0
# mV68AluFr9qshgwS5SpN5FFtaSEnAwqZv3IS+mlG50rK7W3qXbWwi4hmpylUfygt
# YLEdLQukNEX1jiOKMIIGFDCCA/ygAwIBAgIQeiOu2lNplg+RyD5c9MfjPzANBgkq
# hkiG9w0BAQwFADBXMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMS4wLAYDVQQDEyVTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIFJvb3Qg
# UjQ2MB4XDTIxMDMyMjAwMDAwMFoXDTM2MDMyMTIzNTk1OVowVTELMAkGA1UEBhMC
# R0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UEAxMjU2VjdGlnbyBQ
# dWJsaWMgVGltZSBTdGFtcGluZyBDQSBSMzYwggGiMA0GCSqGSIb3DQEBAQUAA4IB
# jwAwggGKAoIBgQDNmNhDQatugivs9jN+JjTkiYzT7yISgFQ+7yavjA6Bg+OiIjPm
# /N/t3nC7wYUrUlY3mFyI32t2o6Ft3EtxJXCc5MmZQZ8AxCbh5c6WzeJDB9qkQVa4
# 6xiYEpc81KnBkAWgsaXnLURoYZzksHIzzCNxtIXnb9njZholGw9djnjkTdAA83ab
# EOHQ4ujOGIaBhPXG2NdV8TNgFWZ9BojlAvflxNMCOwkCnzlH4oCw5+4v1nssWeN1
# y4+RlaOywwRMUi54fr2vFsU5QPrgb6tSjvEUh1EC4M29YGy/SIYM8ZpHadmVjbi3
# Pl8hJiTWw9jiCKv31pcAaeijS9fc6R7DgyyLIGflmdQMwrNRxCulVq8ZpysiSYNi
# 79tw5RHWZUEhnRfs/hsp/fwkXsynu1jcsUX+HuG8FLa2BNheUPtOcgw+vHJcJ8Hn
# JCrcUWhdFczf8O+pDiyGhVYX+bDDP3GhGS7TmKmGnbZ9N+MpEhWmbiAVPbgkqykS
# kzyYVr15OApZYK8CAwEAAaOCAVwwggFYMB8GA1UdIwQYMBaAFPZ3at0//QET/xah
# bIICL9AKPRQlMB0GA1UdDgQWBBRfWO1MMXqiYUKNUoC6s2GXGaIymzAOBgNVHQ8B
# Af8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcD
# CDARBgNVHSAECjAIMAYGBFUdIAAwTAYDVR0fBEUwQzBBoD+gPYY7aHR0cDovL2Ny
# bC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljVGltZVN0YW1waW5nUm9vdFI0Ni5j
# cmwwfAYIKwYBBQUHAQEEcDBuMEcGCCsGAQUFBzAChjtodHRwOi8vY3J0LnNlY3Rp
# Z28uY29tL1NlY3RpZ29QdWJsaWNUaW1lU3RhbXBpbmdSb290UjQ2LnA3YzAjBggr
# BgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQAD
# ggIBABLXeyCtDjVYDJ6BHSVY/UwtZ3Svx2ImIfZVVGnGoUaGdltoX4hDskBMZx5N
# Y5L6SCcwDMZhHOmbyMhyOVJDwm1yrKYqGDHWzpwVkFJ+996jKKAXyIIaUf5JVKjc
# cev3w16mNIUlNTkpJEor7edVJZiRJVCAmWAaHcw9zP0hY3gj+fWp8MbOocI9Zn78
# xvm9XKGBp6rEs9sEiq/pwzvg2/KjXE2yWUQIkms6+yslCRqNXPjEnBnxuUB1fm6b
# PAV+Tsr/Qrd+mOCJemo06ldon4pJFbQd0TQVIMLv5koklInHvyaf6vATJP4DfPtK
# zSBPkKlOtyaFTAjD2Nu+di5hErEVVaMqSVbfPzd6kNXOhYm23EWm6N2s2ZHCHVhl
# UgHaC4ACMRCgXjYfQEDtYEK54dUwPJXV7icz0rgCzs9VI29DwsjVZFpO4ZIVR33L
# wXyPDbYFkLqYmgHjR3tKVkhh9qKV2WCmBuC27pIOx6TYvyqiYbntinmpOqh/QPAn
# hDgexKG9GX/n1PggkGi9HCapZp8fRwg8RftwS21Ln61euBG0yONM6noD2XQPrFwp
# m3GcuqJMf0o8LLrFkSLRQNwxPDDkWXhW+gZswbaiie5fd/W2ygcto78XCSPfFWve
# UOSZ5SqK95tBO8aTHmEa4lpJVD7HrTEn9jb1EGvxOb1cnn0CMIIGgjCCBGqgAwIB
# AgIQNsKwvXwbOuejs902y8l1aDANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4w
# HAYDVQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVz
# dCBSU0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMjEwMzIyMDAwMDAwWhcN
# MzgwMTE4MjM1OTU5WjBXMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBM
# aW1pdGVkMS4wLAYDVQQDEyVTZWN0aWdvIFB1YmxpYyBUaW1lIFN0YW1waW5nIFJv
# b3QgUjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAiJ3YuUVnnR3d
# 6LkmgZpUVMB8SQWbzFoVD9mUEES0QUCBdxSZqdTkdizICFNeINCSJS+lV1ipnW5i
# hkQyC0cRLWXUJzodqpnMRs46npiJPHrfLBOifjfhpdXJ2aHHsPHggGsCi7uE0awq
# KggE/LkYw3sqaBia67h/3awoqNvGqiFRJ+OTWYmUCO2GAXsePHi+/JUNAax3kpqs
# tbl3vcTdOGhtKShvZIvjwulRH87rbukNyHGWX5tNK/WABKf+Gnoi4cmisS7oSimg
# HUI0Wn/4elNd40BFdSZ1EwpuddZ+Wr7+Dfo0lcHflm/FDDrOJ3rWqauUP8hsokDo
# I7D/yUVI9DAE/WK3Jl3C4LKwIpn1mNzMyptRwsXKrop06m7NUNHdlTDEMovXAIDG
# AvYynPt5lutv8lZeI5w3MOlCybAZDpK3Dy1MKo+6aEtE9vtiTMzz/o2dYfdP0KWZ
# wZIXbYsTIlg1YIetCpi5s14qiXOpRsKqFKqav9R1R5vj3NgevsAsvxsAnI8Oa5s2
# oy25qhsoBIGo/zi6GpxFj+mOdh35Xn91y72J4RGOJEoqzEIbW3q0b2iPuWLA911c
# RxgY5SJYubvjay3nSMbBPPFsyl6mY4/WYucmyS9lo3l7jk27MAe145GWxK4O3m3g
# EFEIkv7kRmefDR7Oe2T1HxAnICQvr9sCAwEAAaOCARYwggESMB8GA1UdIwQYMBaA
# FFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBT2d2rdP/0BE/8WoWyCAi/Q
# Cj0UJTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAK
# BggrBgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/
# aHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRp
# b25BdXRob3JpdHkuY3JsMDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0
# cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEADr5lQe1o
# RLjlocXUEYfktzsljOt+2sgXke3Y8UPEooU5y39rAARaAdAxUeiX1ktLJ3+lgxto
# LQhn5cFb3GF2SSZRX8ptQ6IvuD3wz/LNHKpQ5nX8hjsDLRhsyeIiJsms9yAWnvdY
# OdEMq1W61KE9JlBkB20XBee6JaXx4UBErc+YuoSb1SxVf7nkNtUjPfcxuFtrQdRM
# Ri/fInV/AobE8Gw/8yBMQKKaHt5eia8ybT8Y/Ffa6HAJyz9gvEOcF1VWXG8OMeM7
# Vy7Bs6mSIkYeYtddU1ux1dQLbEGur18ut97wgGwDiGinCwKPyFO7ApcmVJOtlw9F
# VJxw/mL1TbyBns4zOgkaXFnnfzg4qbSvnrwyj1NiurMp4pmAWjR+Pb/SIduPnmFz
# bSN/G8reZCL4fvGlvPFk4Uab/JVCSmj59+/mB2Gn6G/UYOy8k60mKcmaAZsEVkhO
# Fuoj4we8CYyaR9vd9PGZKSinaZIkvVjbH/3nlLb0a7SBIkiRzfPfS9T+JesylbHa
# 1LtRV9U/7m0q7Ma2CQ/t392ioOssXW7oKLdOmMBl14suVFBmbzrt5V5cQPnwtd3U
# OTpS9oCG+ZZheiIvPgkDmA8FzPsnfXW5qHELB43ET7HHFHeRPRYrMBKjkb8/IN7P
# o0d0hQoF4TeMM+zYAJzoKQnVKOLg8pZVPT8xggSSMIIEjgIBATBqMFUxCzAJBgNV
# BAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMTI1NlY3Rp
# Z28gUHVibGljIFRpbWUgU3RhbXBpbmcgQ0EgUjM2AhEApCk7bh7d16c0CIetek63
# JDANBglghkgBZQMEAgIFAKCCAfkwGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEE
# MBwGCSqGSIb3DQEJBTEPFw0yNjAyMDUxNDI5NTZaMD8GCSqGSIb3DQEJBDEyBDDb
# qdMAoAyZfN2gepbjStKvTKpsWXRfU/nmUfQF9svSg9g1jZoxZO2hsPL6R2kzudQw
# ggF6BgsqhkiG9w0BCRACDDGCAWkwggFlMIIBYTAWBBQ4yRSBEES03GY+k9R0S4FB
# hqm1sTCBhwQUxq5U5HiG8Xw9VRJIjGnDSnr5wt0wbzBbpFkwVzELMAkGA1UEBhMC
# R0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEuMCwGA1UEAxMlU2VjdGlnbyBQ
# dWJsaWMgVGltZSBTdGFtcGluZyBSb290IFI0NgIQeiOu2lNplg+RyD5c9MfjPzCB
# vAQUhT1jLZOCgmF80JA1xJHeksFC2scwgaMwgY6kgYswgYgxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwG
# A1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3Qg
# UlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5AhA2wrC9fBs656Oz3TbLyXVoMA0G
# CSqGSIb3DQEBAQUABIICABBF2NQ8XmQO6qDi/8CAis1aOKSnCjl444WafkxkThNd
# X0K6pHnvv8IG0HcjTiI/3OzJdkTwzglaqwn+FT8w95rsE/h1LGPVSCb9x4i8NiTX
# SOmvQ9/ibdtyBVl9AQTl7bj/191sZ/w7Bbe7GDao4sWNxXbLhfui8LpbgIxQDJUt
# 9uWXjNn3GWwWltfxyDTvaI6VLkFDeV5GFMcV70Q5CEg4eOENrZzAe6b6XgA4yolP
# 3VXxfhiWDMZgTGYSoUtrU/Fh0vfCPeEBNJnXhjCvmA8zNjZmTCDCS2DyDzwidfNU
# pi9nvBO/GZkARmdYljD1m58N8RXP7M2FkLi8bZL+Xnic8TgcYhUeTWLuut2VXzQm
# xSXghMcR2EA5FJdB8wORAun0ZgVpjS68XRq9qhQRIU/EUEEsuF5a1z23d2ldZaXd
# fzh6DkT9euyPFXYudHHzw+lGaYlHcMGmXGeXMi+8W3S7YvNEXIKOmOSJWaCaXKJD
# TDr0RTzghkLI7uLPwX/koOOPRoO5P/2z3qxEqUrD/xuLBwaOZFaFUTbvq4V+s8mf
# fYKstT7mlPrQBEm3FWCN98odVIWU08hrkNPBwORiOPnvlQZeMXVs2eT+Xashe08C
# ErBk9TbUURtHF1f2QgpABjwd2eev7hj4oikEP0IoaHtHqJ48KoweBqP3HA45lJNL
# SIG # End signature block

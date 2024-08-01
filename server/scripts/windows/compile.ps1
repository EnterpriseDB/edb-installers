# Powershell script to compile PostgreSQL

param([string]$source_directory,
    [string]$xml_directory,
    [string]$xslt_directory,
    [string]$openssl_directory,
    [string]$zlib_directory,
    [string]$uuid_directory,
    [string]$lz4_directory,
    [string]$zstd_directory,
    [string]$icu_directory,
    [string]$gettext_directory,
    [string]$wxwidgets_directory
    )

if (-Not $source_directory) {
    Write-Host "Missing source directory parameter"
    exit 1
}

$installation_directory = "pgsql"
$temporary_data_location = "temp_pgdata"

# Check for source parameters
if (-Not $source_directory) {
    Write-Host "Missing source directory parameter"
    exit 1
}

if (-Not $xml_directory) {
    Write-Host "Missing XML directory parameter"
    exit 1
}

if (-Not $xslt_directory) {
    Write-Host "Missing XSLT directory parameter"
    exit 1
}

if (-Not $openssl_directory) {
    Write-Host "Missing OpenSSL directory parameter"
    exit 1
}


if (-Not $zlib_directory) {
    Write-Host "Missing zlib directory parameter"
    exit 1
}

if (-Not $uuid_directory) {
    Write-Host "Missing UUID directory parameter"
    exit 1
}

if (-Not $lz4_directory) {
    Write-Host "Missing lz4 directory parameter"
    exit 1
}

if (-Not $zstd_directory) {
    Write-Host "Missing zstd directory parameter"
    exit 1
}

if (-Not $icu_directory) {
    Write-Host "Missing icu directory parameter"
    exit 1
}

# Check for MSVC compiler
if ((Get-Command "cl.exe" -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "This script requires the MSVC environment variables"
    exit 1
}

# Check for packages
if (-Not (Test-Path $source_directory -PathType Container)) {
    Write-Host "Input directory ($source_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $xml_directory -PathType Container)) {
    Write-Host "libxml distribution ($xml_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $xml_directory/include/libxml -PathType Container)) {
    # PostgreSQL build system is expecting to find libxml headers in a folder named
    # "libxml", while the libxml build system writes them in "libxml2".
    Copy-Item $xml_directory/include/libxml2/libxml $xml_directory/include/libxml -Recurse
}

if (-Not (Test-Path $xslt_directory -PathType Container)) {
    Write-Host "libxslt distribution ($xslt_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $openssl_directory -PathType Container)) {
    Write-Host "OpenSSL distribution ($openssl_directory) doesn't exist or isn't a directory"
    exit 1
}


if (-Not (Test-Path $zlib_directory -PathType Container)) {
    Write-Host "zlib distribution ($zlib_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $lz4_directory -PathType Container)) {
    Write-Host "zstd distribution ($lz4_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $zstd_directory -PathType Container)) {
    Write-Host "zstd distribution ($zstd_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $icu_directory -PathType Container)) {
    Write-Host "icu distribution ($icu_directory) doesn't exist or isn't a directory"
    exit 1
}

if (-Not (Test-Path $gettext_directory -PathType Container)) {
    Write-Host "gettext distribution ($gettext_directory) doesn't exist or isn't a directory"
    exit 1
}


if (-Not (Test-Path $wxwidgets_directory -PathType Container)) {
    Write-Host "wxwidgets distribution ($wxwidgets_directory) doesn't exist or isn't a directory"
    exit 1
}

# Let's put these directory in absolute form
$source_directory = ([IO.Path]::GetFullPath($source_directory))
$openssl_directory = ([IO.Path]::GetFullPath($openssl_directory))
$xml_directory = ([IO.Path]::GetFullPath($xml_directory))
$xslt_directory = ([IO.Path]::GetFullPath($xslt_directory))
$zlib_directory = ([IO.Path]::GetFullPath($zlib_directory))
$installation_directory = ([IO.Path]::GetFullPath($installation_directory))
$uuid_directory = ([IO.Path]::GetFullPath($uuid_directory))
$lz4_directory = ([IO.Path]::GetFullPath($lz4_directory))
$zstd_directory = ([IO.Path]::GetFullPath($zstd_directory))
$icu_directory = ([IO.Path]::GetFullPath($icu_directory))
$gettext_directory = ([IO.Path]::GetFullPath($gettext_directory))
$wxwidgets_directory = ([IO.Path]::GetFullPath($wxwidgets_directory))
$temporary_data_location = ([IO.Path]::GetFullPath($temporary_data_location))
$definition_directory = ([IO.Path]::GetFullPath("."))

# Clean the installation directory
if (Test-Path $installation_directory -PathType Container) {
    Remove-Item $installation_directory -Recurse
}
mkdir $installation_directory

if (Test-Path $temporary_data_location -PathType Container) {
    Remove-Item $temporary_data_location -Recurse
}
mkdir $temporary_data_location

$Acl = Get-ACL $temporary_data_location
$AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule("everyone","FullControl","ContainerInherit,Objectinherit","none","Allow")
$Acl.AddAccessRule($AccessRule)
Set-Acl $temporary_data_location $Acl


# So far, so good. Let's start compiling
Write-Host "Executing meson bat file"
Start-Process -FilePath packaging-config/server/scripts/windows/meson.bat -Wait -NoNewWindow

Write-Host " Executing Doc Script "
C:\msys64\usr\bin\sh.exe packaging-config/server/scripts/windows/meson-doc.sh
Write-Host "Meson doc Script execution completed"

Write-Host "copying meson-install content to $installation_directory"
Copy-Item -Path "$source_directory\meson-install\*" -Destination $installation_directory/ -Recurse
Get-ChildItem -Path "$installation_directory"

# Manually copy plpgsql.lib from the PostgreSQL
# build directory to the installation directory, since
# this file is needed to compile plpgsql_check
#Copy-Item $source_directory/Release/plpgsql/plpgsql.lib $installation_directory/lib
Copy-Item $gettext_directory/bin/libintl-9.dll $installation_directory\bin
Copy-Item $icu_directory/bin/*.dll $installation_directory\bin
Copy-Item $openssl_directory/bin/*.dll $installation_directory\bin
Copy-Item $xml_directory/bin/*.dll $installation_directory\bin
Copy-Item $xslt_directory/bin/libxslt.dll $installation_directory\bin
Copy-Item $gettext_directory/bin/libiconv-2.dll $installation_directory\bin
Copy-Item $gettext_directory/bin/libwinpthread-1.dll $installation_directory\bin
Copy-Item $zlib_directory/bin/*.dll $installation_directory\bin
Copy-Item $zstd_directory/bin/*.dll $installation_directory\bin
Copy-Item $lz4_directory/bin/*.dll $installation_directory\bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase324u_net_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase324u_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase324u_xml_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw324u_adv_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw324u_aui_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw324u_core_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw324u_html_vc_x64_custom.dll $installation_directory/bin
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw324u_xrc_vc_x64_custom.dll $installation_directory/bin

# Manually copy some libraries to the installation directory
Copy-Item $lz4_directory/lib/liblz4.lib $installation_directory\lib
Copy-Item $openssl_directory/lib/libssl.lib $installation_directory\lib
Copy-Item $openssl_directory/lib/libcrypto.lib $installation_directory\lib
Copy-Item $gettext_directory/lib/iconv.lib $installation_directory\lib
Copy-Item $gettext_directory/lib/libintl.lib $installation_directory\lib
Copy-Item $xml_directory/lib/libxml2.lib $installation_directory\lib
Copy-Item $xslt_directory/lib/libxslt.lib $installation_directory\lib
Copy-Item $zlib_directory/bin/zlib.lib $installation_directory\lib
Remove-Item $zstd_directory/lib/pkgconfig -Recurse
Copy-Item $zstd_directory/lib/* $installation_directory/lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase32u_net.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase32u.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxbase32u_xml.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_adv.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_aui.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_core.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_html.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_xrc.lib $installation_directory\lib
Copy-Item $wxwidgets_directory/lib/vc_x64_dll/wxmsw32u_adv.lib $installation_directory\lib

Copy-Item $lz4_directory/include/*.h $installation_directory/include
Copy-Item -Path $openssl_directory/include/* -Destination $installation_directory/include -Recurse
Copy-Item -Path $xml_directory/include/libxml  -Destination $installation_directory/include -Recurse
Copy-Item -Path $xslt_directory/include/libxslt -Destination $installation_directory/include -Recurse
Copy-Item $gettext_directory/include/*.h $installation_directory/include
Copy-Item -Path $icu_directory/include/* -Destination $installation_directory/include  -Recurse
Copy-Item $uuid_directory/include/*.h $installation_directory/include
Copy-Item $zlib_directory/include/*.h $installation_directory/include
Copy-Item $zstd_directory/include/*.h $installation_directory/include


# Now we need to start a temporary instance, to run the contrib tests
Push-Location $installation_directory\bin
Write-Host "initdb is beginning"
.\initdb.exe -D $temporary_data_location --data-checksums -U postgres
Write-Host "initdb instance is done"
Write-Host "pg_ctl instance is beginning"
.\pg_ctl.exe -l $temporary_data_location/logfile -D $temporary_data_location -U postgres start
Write-Host "pg_ctl instance is done"
Pop-Location
Write-Host "start a temporary instance is done"

Push-Location $installation_directory\bin
.\pg_ctl.exe -D $temporary_data_location stop
Pop-Location

#!/bin/bash

# set -xeu

mkdir -p packaging-config/installer/server/staging/windows-x64/server
mkdir -p packaging-config/installer/server/staging/windows-x64/server/bin
mkdir -p packaging-config/installer/server/staging/windows-x64/server/lib
mkdir -p packaging-config/installer/server/staging/windows-x64/server/share/extension
mkdir -p packaging-config/installer/server/staging/windows-x64/server/debug_symbols
mkdir -p packaging-config/installer/server/staging/windows-x64/scripts
mkdir -p packaging-config/installer/server/staging/windows-x64/resources
cp -R packaging-config/resources/license.txt packaging-config/installer/server/staging/windows-x64/server/server_license.txt

# server 
cp -r pgsql/bin/* packaging-config/installer/server/staging/windows-x64/server/bin

cp -r ./curl/bin/libcurl.dll packaging-config/installer/server/staging/windows-x64/server/bin
cp -r ./curl/lib/libcurl.lib packaging-config/installer/server/staging/windows-x64/server/bin

cp -r ./gettext/share/locale packaging-config/installer/server/staging/windows-x64/server/share

mkdir 3rdinclude
cp -r pgsql/include/* 3rdinclude
find 3rdinclude/ -name "*.h" -exec grep -rwl "GNU General Public License" {} \; -exec rm  {} \;
mkdir packaging-config/installer/server/staging/windows-x64/server/include
cp -r 3rdinclude/* packaging-config/installer/server/staging/windows-x64/server/include
rm -rf 3rdinclude

cp -r pgsql/lib/* packaging-config/installer/server/staging/windows-x64/server/lib

#system_stats 
cp -r pgsql/share packaging-config/installer/server/staging/windows-x64/server
cp -r packaging-config/server/i18n packaging-config/installer/server/staging/windows-x64/server/share
cp -r $(PWD)/system_stats/system_stats--*.sql packaging-config/installer/server/staging/windows-x64/server/share/extension
cp -r $(PWD)/system_stats/system_stats.control packaging-config/installer/server/staging/windows-x64/server/share/extension

cp -r packaging-config/server/i18n packaging-config/installer/server/staging/windows-x64/

mkdir -p packaging-config/installer/server/staging/windows-x64/server/installer/server
cp -r packaging-config/server/scripts/windows/prerun_checks.vbs packaging-config/installer/server/staging/windows-x64/server/installer/prerun_checks.vbs 
cp -r packaging-config/server/scripts/windows/initcluster.vbs packaging-config/installer/server/staging/windows-x64/server/installer/server/initcluster.vbs 
cp -r packaging-config/server/scripts/windows/startupcfg.vbs packaging-config/installer/server/staging/windows-x64/server/installer/server/startupcfg.vbs 
cp -R "$VCToolsRedistDir"vc_redist.x86.exe packaging-config/installer/server/staging/windows-x64/server/installer/vcredist_x86.exe
cp -R "$VCToolsRedistDir"vc_redist.x64.exe packaging-config/installer/server/staging/windows-x64/server/installer/vcredist_x64.exe

cp -R pgsql/doc packaging-config/installer/server/staging/windows-x64/server
cp -R packaging-config/server/resources/installation-notes.html packaging-config/installer/server/staging/windows-x64/server/doc

cp -r pgsql/symbols/* packaging-config/installer/server/staging/windows-x64/server/debug_symbols
cp -r packaging-config/server/scripts/windows/getlocales/x64/Release/getlocales.exe packaging-config/installer/server/staging/windows-x64/server/installer/server/getlocales.exe
cp -r packaging-config/server/scripts/windows/validateuser/x64/Release/validateuser.exe packaging-config/installer/server/staging/windows-x64/server/installer/server/validateuser.exe
cp -r packaging-config/server/scripts/windows/createuser/x64/Release/createuser.exe packaging-config/installer/server/staging/windows-x64/server/installer/server/createuser.exe
# Copy the launch scripts
mkdir -p packaging-config/installer/server/staging/windows-x64/server/scripts/images
cp packaging-config/server/scripts/windows/serverctl.vbs packaging-config/installer/server/staging/windows-x64/server/scripts/serverctl.vbs      
cp packaging-config/server/scripts/windows/runpsql.bat packaging-config/installer/server/staging/windows-x64/server/scripts/runpsql.bat 
cp packaging-config/server/resources/pg-help.ico packaging-config/installer/server/staging/windows-x64/server/scripts/images
cp packaging-config/server/resources/pg-reload.ico packaging-config/installer/server/staging/windows-x64/server/scripts/images
# commanlinetools 
mkdir -p packaging-config/installer/server/staging/windows-x64/commandlinetools/installer/server

mkdir -p packaging-config/installer/server/staging/windows-x64/commandlinetools/bin
cp -R zlib/bin/zlib1.dll packaging-config/installer/server/staging/windows-x64/commandlinetools/bin 
cp -R ./gettext/bin/libwinpthread-1.dll $(PWD)/packaging-config/installer/server/staging/windows-x64/commandlinetools/bin 
cp -R "$VCToolsRedistDir"vc_redist.x86.exe packaging-config/installer/server/staging/windows-x64/commandlinetools/installer/vcredist_x86.exe
cp -R "$VCToolsRedistDir"vc_redist.x64.exe packaging-config/installer/server/staging/windows-x64/server/installer/vcredist_x64.exe
cp pgsql/bin/createuser.exe packaging-config/installer/server/staging/windows-x64/commandlinetools/installer/server
cp -R pgsql/bin/* packaging-config/installer/server/staging/windows-x64/commandlinetools/bin 
mkdir -p packaging-config/installer/server/staging/windows-x64/commandlinetools/lib

cp -r pgsql/lib/* packaging-config/installer/server/staging/windows-x64/commandlinetools/lib
cp -r packaging-config/server/system_stats.dll packaging-config/installer/server/staging/windows-x64/commandlinetools/lib/system_stats.dll

mkdir -p packaging-config/installer/server/staging/windows-x64/commandlinetools/scripts/images
cp packaging-config/server/resources/pg-psql.ico  packaging-config/installer/server/staging/windows-x64/commandlinetools/scripts/images/
cp packaging-config/server/scripts/windows/runpsql.bat  packaging-config/installer/server/staging/windows-x64/commandlinetools/scripts/
cp packaging-config/resources/edb-side.png  packaging-config/installer/server/staging/windows-x64/resources
cp packaging-config/resources/pg-splash.png  packaging-config/installer/server/staging/windows-x64/resources
cp packaging-config/resources/pg-side.png  packaging-config/installer/server/staging/windows-x64/resources

cp packaging-config/server/installer.xml.in packaging-config/installer/server/installer.xml
cp packaging-config/server/commandlinetools.xml.in packaging-config/installer/server/commandlinetools-windows-x64.xml
cp packaging-config/server/pgadmin.xml.in packaging-config/installer/server/pgadmin-windows-x64.xml
cp packaging-config/server/pgserver.xml.in packaging-config/installer/server/pgserver-windows-x64.xml
cp packaging-config/server/commandlinetools.xml.in packaging-config/installer/server/staging/windows-x64/commandlinetools-windows-x64.xml
cp packaging-config/server/pgserver.xml.in packaging-config/installer/server/staging/windows-x64/pgserver-windows-x64.xml
cp packaging-config/server/stackbuilder.xml.in packaging-config/installer/server/staging/windows-x64/stackbuilder-windows-x64.xml
cp packaging-config/server/pgadmin.xml.in packaging-config/installer/server/staging/windows-x64/pgadmin-windows-x64.xml

# stackbuilder
mkdir -p packaging-config/installer/server/staging/windows-x64/stackbuilder/bin
cp -r $(PWD)/stackbuilder*.exe packaging-config/installer/server/staging/windows-x64/stackbuilder/bin/stackbuilder.exe
cp -r packaging-config/installer/server/staging/windows-x64/server/bin/wx*.dll packaging-config/installer/server/staging/windows-x64/stackbuilder/bin
cp -r ./curl/bin/libcurl.dll packaging-config/installer/server/staging/windows-x64/stackbuilder/bin
cp -r $(PWD)/SB/share packaging-config/installer/server/staging/windows-x64/stackbuilder

#pgAdmin4
mkdir -p "packaging-config/installer/server/staging/windows-x64/pgadmin4/pgAdmin 4"
mv $(PWD)/pgAdmin4-binaries/pgAdmin_license.txt packaging-config/installer/server/staging/windows-x64/pgadmin4/
mv $(PWD)/pgAdmin4-binaries/scripts packaging-config/installer/server/staging/windows-x64/pgadmin4/
cp packaging-config/server/resources/pg-help.ico packaging-config/installer/server/staging/windows-x64/pgadmin4/scripts/images/pgadmin-help.ico
cp -r $(PWD)/pgAdmin4-binaries/* "packaging-config/installer/server/staging/windows-x64/pgadmin4/pgAdmin 4/"
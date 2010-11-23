#!/bin/sh

# PostgreSQL Installer build system configuration. 
# Copy this file to settings.sh, and edit as required for the build setup

# Platforms. Set to 1 to enable a specific platform

PG_ARCH_OSX=1

PG_ARCH_LINUX=1
PG_ARCH_LINUX_X64=1
PG_ARCH_WINDOWS=1
PG_ARCH_WINDOWS_X64=1
PG_ARCH_SOLARIS_X64=1
PG_ARCH_SOLARIS_SPARC=1

# Packages. Set to 1 to enable a specific packages. Note that many packages will be interdependent
#           so you must ensure that all the required dependencies are enabled.

PG_PACKAGE_SERVER=0
PG_PACKAGE_DEVSERVER=0
PG_PACKAGE_APACHEPHP=0
PG_PACKAGE_MEDIAWIKI=0
PG_PACKAGE_PHPWIKI=0
PG_PACKAGE_PHPBB=0
PG_PACKAGE_DRUPAL=0
PG_PACKAGE_PHPPGADMIN=0
PG_PACKAGE_PGJDBC=0
PG_PACKAGE_PSQLODBC=0
PG_PACKAGE_POSTGIS=0
PG_PACKAGE_SLONY=0
PG_PACKAGE_TUNINGWIZARD=0
PG_PACKAGE_MIGRATIONWIZARD=0
PG_PACKAGE_PGPHONEHOME=0
PG_PACKAGE_NPGSQL=0
PG_PACKAGE_PGAGENT=0
PG_PACKAGE_PGMEMCACHE=0
PG_PACKAGE_PGBOUNCER=1
PG_PACKAGE_META=0
PG_PACKAGE_LIBPQ=1
PG_PACKAGE_PGMIGRATOR=0
PG_PACKAGE_SBP=1
PG_PACKAGE_MIGRATIONTOOLKIT=0
PG_PACKAGE_PPHQ=0
PG_PACKAGE_HQAGENT=0
PG_PACKAGE_REPLICATIONSERVER=1
PG_PACKAGE_PLPGSQLO=0
PG_PACKAGE_SQLPROTECT=0

# Path for the build machine (/opt/... must be at the end!)
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/local/bin

# VM config. For each VM we need to know the SSH connection details and the path to the
#            shared firectory on the host machine containing this file.
#            On Windows we don't have a shared directory, so specify a build directory
#            We can also specify additional directorys to include in the path.

PG_SSH_LINUX=buildfarm@bf-linux.ox.uk.enterprisedb.com
PG_PATH_LINUX=/mnt/hgfs/pginstaller-repo
PG_PGHOME_LINUX=$PG_PATH_LINUX/server/staging/linux
PG_EXEC_PATH_LINUX=/usr/java/jdk1.5.0_14/bin
PG_JAVA_HOME_LINUX=/usr/java/jdk1.5.0_14
PG_ANT_HOME_LINUX=/usr/local/apache-ant-1.7.1
PG_QMAKE_LINUX=qmake-qt4

PG_SSH_LINUX_X64=buildfarm@bf-linux-x64.ox.uk.enterprisedb.com
PG_PATH_LINUX_X64=/mnt/hgfs/pginstaller-repo
PG_PGHOME_LINUX_X64=$PG_PATH_LINUX_X64/server/staging/linux-x64
PG_EXEC_PATH_LINUX_X64=/usr/java/jdk1.5.0_14/bin
PG_JAVA_HOME_LINUX_X64=/usr/java/jdk1.5.0_14
PG_ANT_HOME_LINUX_X64=/usr/local/apache-ant-1.7.1
PG_QMAKE_LINUX_X64=qmake-qt4

PG_SSH_WINDOWS=buildfarm@bf-windows.ox.uk.enterprisedb.com
PG_PATH_WINDOWS=C:\\\\pginstaller-repo
PG_VSINSTALLDIR_WINDOWS="C:\\\\Program Files\\\\Microsoft Visual Studio 8"
PG_FRAMEWORKDIR_WINDOWS="C:\\\\WINDOWS\\\\Microsoft.NET\\\\Framework"
PG_FRAMEWORKVERSION_WINDOWS=v2.0.50727
PG_FRAMEWORKSDKDIR_WINDOWS="C:\\\\Program Files\\\\Microsoft Visual Studio 8\\\\SDK\\\\v2.0"
PG_DEVENVDIR_WINDOWS="C:\\\\Program Files\\\\Microsoft Visual Studio 8\\\\Common7\\\\IDE"
PG_PGBUILD_WINDOWS="C:\\\\pgBuild"
PG_WXWIN_WINDOWS="$PG_PGBUILD_WINDOWS\\\\wxWidgets"
PG_CMAKE_WINDOWS="C:\\\\Program Files\\\\CMake 2.6"
PG_ANT_WINDOWS="C:\\\\apache-ant-1.7.1"
PG_PSDK_WINDOWS="C:\\\\Program Files\\\\Microsoft Platform SDK"
PG_MINGW_WINDOWS=C:\\\\MinGW
PG_MSYS_WINDOWS=C:\\\\msys\\\\1.0
# This must not have spaces or quotes:
PG_JAVA_HOME_WINDOWS="C:\\\\Program Files\\\\Java\\\\jdk1.5.0_22"
PG_QTPATH_WINDOWS=C:\\Qt\\2009.03
PG_SIGNTOOL_WINDOWS="C:\\\\Program Files\\\\Microsoft Visual Studio 8\\\\Common7\\\\Tools\\\\Bin\\\\signtool.exe"

PG_SSH_WINDOWS_X64=buildfarm@bf-windows-x64.ox.uk.enterprisedb.com
PG_PATH_WINDOWS_X64=C:\\\\pginstaller-repo
PG_VSINSTALLDIR_WINDOWS_X64="C:\\\\Program Files (x86)\\\\Microsoft Visual Studio 8"
PG_PGBUILD_WINDOWS_X64="C:\\\\pgBuild"

PG_SSH_SOLARIS_X64=buildfarm@bf-solaris-x64.ox.uk.enterprisedb.com
PG_PATH_SOLARIS_X64=/export/home/buildfarm/pginstaller-repo
PG_PGHOME_SOLARIS_X64=$PG_PATH_SOLARIS_X64/server/staging/solaris-x64
PG_EXEC_PATH_SOLARIS_X64=/usr/jdk/jdk1.5.0_16/bin/amd64
PG_JAVA_HOME_SOLARIS_X64=/usr/jdk/jdk1.5.0_16
PG_ANT_HOME_SOLARIS_X64=/opt/apache-ant-1.8.1
PG_QMAKE_SOLARIS_X64=qmake

PG_SSH_SOLARIS_SPARC=buildfarm@suzuka.ox.uk.enterprisedb.com
PG_PATH_SOLARIS_SPARC=/mnt/buildfarm/pginstaller-tanaka
PG_PGHOME_SOLARIS_SPARC=$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc
PG_EXEC_PATH_SOLARIS_SPARC=/usr/jdk/jdk1.5.0_07/bin/sparcv9
PG_JAVA_HOME_SOLARIS_SPARC=/usr/jdk/jdk1.5.0_07
PG_ANT_HOME_SOLARIS_SPARC=/opt/apache-ant-1.8.1
PG_QMAKE_SOLARIS_SPARC=qmake

PG_PATH_OSX=`pwd`
PG_PGHOME_OSX=$PG_PATH_OSX/server/staging/osx
PG_ANT_HOME_OSX=/usr/local/apache-ant-1.7.1
PG_DOCBOOK_OSX=/opt/local/share/xsl/docbook-xsl

# CFLAGS/CPPFLAGS/CXXFLAGS settings for different platforms. The is most important for Mac
# where we may need to use non-default SDKs if we're building on a platform newer than the
# oldest supported

PG_ARCH_OSX_CFLAGS="-isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.4 -headerpad_max_install_names"
PG_ARCH_OSX_CPPFLAGS="-isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.4 -headerpad_max_install_names"
PG_ARCH_OSX_CXXFLAGS="-isysroot /Developer/SDKs/MacOSX10.4u.sdk -mmacosx-version-min=10.4 -headerpad_max_install_names"

# The InstallBuilder main binary.
PG_INSTALLBUILDER_BIN="/Applications/BitRock InstallBuilder for Qt Enterprise 6.5.6/bin/Builder.app/Contents/MacOS/installbuilder.sh"



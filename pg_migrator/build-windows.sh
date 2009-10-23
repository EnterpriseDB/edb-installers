#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_pg_migrator_windows() {

    echo "**************************************"
    echo "* Preparing - pg_migrator (win32)    *"
    echo "**************************************"

    # Enter the source directory and cleanup if required
    cd $WD/pg_migrator/source

    BUILD_PGSQL_MINGW_PGMIGRATOR=`ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION echo YES"`

    if [ x"$BUILD_PGSQL_MINGW_PGMIGRATOR" = x"YES" ]; 
    then 
         echo "Creating postgresql_mingw source directory ($WD/Slony/source/postgresql_mingw.windows)"
         mkdir -p postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't create the postgresql_mingw.windows directory"
         chmod ugo+w postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't set the permissions on the source directory"
         cp -R postgresql-$PG_TARBALL_POSTGRESQL/* postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Failed to copy the source code (source/postgresql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/)"
         if [ ! -e postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip ];
         then
             zip -r postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows/ || _die "Couldn't create archieve of the postgresql_mingw sources (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
         fi
    fi

    if [ -e pg_migrator.windows ];
    then
      echo "Removing existing pg_migrator.windows source directory"
      rm -rf pg_migrator.windows  || _die "Couldn't remove the existing pg_migrator.windows source directory (source/pg_migrator.windows)"
    fi

    echo "Creating staging directory ($WD/pg_migrator/source/pg_migrator.windows)"
    mkdir -p $WD/pg_migrator/source/pg_migrator.windows || _die "Couldn't create the pg_migrator.windows directory"
    mkdir $WD/pg_migrator/source/pg_migrator.windows/userValidation || _die "Failed to create userValidation directory"
    cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $WD/pg_migrator/source/pg_migrator.windows/userValidation/dbserver_guid || _die "Failed to copy dbserver_guid scripts"
    cp -R $WD/MetaInstaller/scripts/windows/validateUser $WD/pg_migrator/source/pg_migrator.windows/userValidation/validateUser || _die "Failed to copy validateUser scripts"

    # Grab a copy of the source tree
    cp -R pg_migrator-$PG_VERSION_PGMIGRATOR/* pg_migrator.windows || _die "Failed to copy the source code (source/pg_migrator-$PG_VERSION_PGMIGRATOR)"
    chmod -R ugo+w pg_migrator.windows || _die "Couldn't set the permissions on the source directory"

    echo "Archieving pg_migrator sources"
    zip -r pg_migrator.zip pg_migrator.windows/ || _die "Couldn't create archieve of the pg_migrator sources (pg_migrator.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pg_migrator/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pg_migrator/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pg_migrator/staging/windows)"
    mkdir -p $WD/pg_migrator/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pg_migrator/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pg_migrator.zip del /S /Q pg_migrator.zip" || _die"Couldn't remove the $PG_PATH_WINDOWS\\pg_migrator.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip del /S /Q postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pg_migrator.windows rd /S /Q pg_migrator.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pg_migrator.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pg_migrator.staging rd /S /Q pg_migrator.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pg_migrator.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-pgmigrator.bat del /S /Q build-pgmigrator.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-pgmigrator.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgresql_mingw.bat del /S /Q build-postgresql_mingw.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgresql_mingw.bat on Windows VM"

    # Copy sources on Windows VM
    if [ x"$BUILD_PGSQL_MINGW_PGMIGRATOR" = x"YES" ]; 
    then 
        echo "Copying postgresql sources to Windows VM"
        scp postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgresql archieve to windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
        ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows unzip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't extract postgresql archieve on windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
    fi
    echo "Copying pg_migrator sources to Windows VM"
    scp pg_migrator.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the pg_migrator archieve to Windows VM (pg_migrator.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pg_migrator.zip" || _die "Couldn't extract pg_migrator archieve on Windows VM (pg_migrator.zip)"

}

################################################################################
# pg_migrator Build
################################################################################

_build_pg_migrator_windows() {

    echo "**************************************"
    echo "* Build - pg_migrator (win32)        *"
    echo "**************************************"

    # build pg_migrator
    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g' | sed -e 's://:/:g'`
    PG_PGHOME_WINDOWS=$PG_PATH_WINDOWS/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION
    PG_PGHOME_MINGW_WINDOWS=$PG_STAGING/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION 
    PG_PATH_MINGW_WINDOWS=`echo $PG_MINGW_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g' | sed -e 's://:/:g'`
    PG_PGBUILD_MINGW_WINDOWS=`echo $PG_PGBUILD_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g' | sed -e 's://:/:g'`
    PG_PGICO_PATH=`echo $PG_PATH_WINDOWS | sed -e 's:\\\\:/:g' | sed -e 's://:/:g'`/postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows/src/port/win32.ico

    cd $WD/pg_migrator/source/pg_migrator.windows

    BUILD_PGSQL_MINGW_PGMIGRATOR=`ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION echo YES"`

    if [ x"$BUILD_PGSQL_MINGW_PGMIGRATOR" = x"YES" ];
    then
        
        cat <<EOT > "build-postgresql_mingw.bat"
    
@ECHO OFF
@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin
@ECHO cd $PG_PATH_WINDOWS\\\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows; ./configure --prefix=$PG_PGHOME_MINGW_WINDOWS --with-libs=$PG_PGBUILD_MINGW_WINDOWS/krb5/lib/i386:$PG_PGBUILD_MINGW_WINDOWS/OpenSSL/lib; make; make install | $PG_MSYS_WINDOWS\\bin\\sh --login -i

EOT
    
        scp build-postgresql_mingw.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
        ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION build-postgresql_mingw.bat" 
        
   fi

   cat <<EOT > "build-pgmigrator.bat"
@ECHO OFF

cd $PG_PATH_WINDOWS
SET SOURCE_PATH=%CD%
SET OLD_PATH=%PATH%

SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin
SET PGICOSTR=IDI_ICON ICON \"$PG_PGICO_PATH\"

ECHO building the pg_migrator source tree
ECHO cd $PG_PATH_WINDOWS/pg_migrator.windows; make top_builddir=$PG_STAGING/postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows PGICOSTR="%PGICOSTR%" | $PG_MSYS_WINDOWS\\bin\\sh.exe --login -i

cd %SOURCE_PATH%
mkdir pg_migrator.staging\bin
mkdir pg_migrator.staging\lib
copy pg_migrator.windows\src\pg_migrator.exe pg_migrator.staging\bin || (echo couldn't copy pg_migrator.exe && exit -1)
copy pg_migrator.windows\func\pg_migrator.dll pg_migrator.staging\lib || (echo couldn't copy pg_migrator.dll && exit -1)
copy pg_migrator.windows\CHANGES           pg_migrator.staging\CHANGES.pg_migrator || (echo couldn't copy CHANGES && exit -1)
copy pg_migrator.windows\DEVELOPERS        pg_migrator.staging\DEVELOPERS.pg_migrator || (echo couldn't copy DEVELOPERS && exit -1)
copy pg_migrator.windows\IMPLEMENTATION    pg_migrator.staging\IMPLEMENTATION.pg_migrator || (echo couldn't copy IMPLEMENTATION && exit -1)
copy pg_migrator.windows\IMPLEMENTATION.jp pg_migrator.staging\IMPLEMENTATION_jp.pg_migrator || (echo couldn't copy IMPLEMENTATION.jp && exit -1)
copy pg_migrator.windows\INSTALL           pg_migrator.staging\INSTALL.pg_migrator || (echo couldn't copy INSTALL && exit -1)
copy pg_migrator.windows\INSTALL.jp        pg_migrator.staging\INSTALL_jp.pg_migrator || (echo couldn't copy INSTALL.jp && exit -1)
copy pg_migrator.windows\LICENSE           pg_migrator.staging\LICENSE.pg_migrator || (echo couldn't copy LICENSE && exit -1)
copy pg_migrator.windows\README            pg_migrator.staging\README.pg_migrator || (echo couldn't copy README && exit -1)

cd %SOURCE_PATH%
@SET VSINSTALLDIR=$PG_VSINSTALLDIR_WINDOWS
@SET VCINSTALLDIR=$PG_VSINSTALLDIR_WINDOWS\VC
@SET FrameworkDir=$PG_FRAMEWORKDIR_WINDOWS
@SET FrameworkVersion=$PG_FRAMEWORKVERSION_WINDOWS
@SET FrameworkSDKDir=$PG_FRAMEWORKSDKDIR_WINDOWS
@set DevEnvDir=$PG_DEVENVDIR_WINDOWS
@set INCLUDE=%VCINSTALLDIR%\ATLMFC\INCLUDE;%VCINSTALLDIR%\INCLUDE;%VCINSTALLDIR%\PlatformSDK\include;%FrameworkSDKDir%\include;%INCLUDE%
@set LIB=%VCINSTALLDIR%\ATLMFC\LIB;%VCINSTALLDIR%\LIB;%VCINSTALLDIR%\PlatformSDK\lib;%FrameworkSDKDir%\lib;%LIB%
@set LIBPATH=$PG_FRAMEWORKDIR_WINDOWS\$PG_FRAMEWORKVERSION_WINDOWS;%VCINSTALLDIR%\ATLMFC\LIB

@SET PGBUILD=C:\pgBuild
@SET WXWIN=%PGBUILD%\wxWidgets

@set PATH=%WXWIN%;%WXWIN%\include;%WXWIN%\lib\vc_lib;$PG_CMAKE_WINDOWS\bin;%VSINSTALLDIR%\Common7\IDE;%VCINSTALLDIR%\BIN;%VSINSTALLDIR%\Common7\Tools;%VSINSTALLDIR%\Common7\Tools\bin;%VCINSTALLDIR%\PlatformSDK\bin;%FrameworkSDKDir%\bin;$PG_FRAMEWORKDIR_WINDOWS\$PG_FRAMEWORKVERSION_WINDOWS;%VCINSTALLDIR%\VCPackages;%OLD_PATH%

cd %SOURCE_PATH%\\pg_migrator.windows\\userValidation\\dbserver_guid
vcbuild dbserver_guid.vcproj release

cd %SOURCE_PATH%\\pg_migrator.windows\\userValidation\\validateUser
vcbuild validateUser.vcproj release

cd %SOURCE_PATH%\\pg_migrator.staging
mkdir userValidation
cd %SOURCE_PATH%
copy pg_migrator.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe pg_migrator.staging\\userValidation\\dbserver_guid.exe
copy pg_migrator.windows\\userValidation\\validateUser\\Release\\validateUserClient.exe pg_migrator.staging\\userValidation\\validateUserClient.exe
copy "%PGBUILD%\\vcredist\\vcredist_x86.exe" pg_migrator.staging\\vcredist_x86.exe

cd %SOURCE_PATH%\\pg_migrator.staging
zip -r ../pg_migrator-staging.zip *

echo "Successfully built pg_migrator and User-Validation utilities..."

EOT

    scp build-pgmigrator.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-pgmigrator.bat" || _die "Couldn't build pg_migrator on Windows"

    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/pg_migrator-staging.zip $WD/pg_migrator/staging/windows/

    unzip $WD/pg_migrator/staging/windows/pg_migrator-staging.zip -d $WD/pg_migrator/staging/windows || _die "Failed to unpack the built source tree ($WD/pg_migrator/windows/pg_migrator-staging.zip)"
    rm $WD/pg_migrator/staging/windows/pg_migrator-staging.zip

}


################################################################################
# PG Build
################################################################################

_postprocess_pg_migrator_windows() {
 
    echo "********************************************"
    echo "* Post Processing - pg_migrator (win32)    *"
    echo "********************************************"

    cd $WD/pg_migrator

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "pgmigrator-$PG_VERSION_PGMIGRATOR-$PG_BUILDNUM_PGMIGRATOR-windows.exe"
	
    cd $WD
}


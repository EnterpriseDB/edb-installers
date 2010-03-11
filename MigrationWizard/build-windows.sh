#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_windows() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.windows ];
    then
      echo "Removing existing migrationwizard.windows source directory"
      rm -rf migrationwizard.windows  || _die "Couldn't remove the existing migrationwizard.windows source directory (source/migrationwizard.windows)"
    fi

    if [ -f $WD/MigrationWizard/source/mw-build.bat ]; then
      rm -rf $WD/MigrationWizard/source/mw-build.bat
    fi

    if [ -f $WD/MigrationWizard/source/migrationwizard.zip ]; then
      rm -rf $WD/MigrationWizard/source/migrationwizard.zip
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.windows)"
    mkdir -p migrationwizard.windows || _die "Couldn't create the migrationwizard.windows directory"
    chmod ugo+w migrationwizard.windows || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.windows || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    mkdir $WD/MigrationWizard/source/migrationwizard.windows/userValidation || _die "Failed to create userValidation directory"
    cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $WD/MigrationWizard/source/migrationwizard.windows/userValidation/dbserver_guid || _die "Failed to copy dbserver_guid scripts"
    cp -R $WD/MetaInstaller/scripts/windows/validateUser $WD/MigrationWizard/source/migrationwizard.windows/userValidation/validateUser || _die "Failed to copy validateUser scripts"
    chmod -R ugo+w migrationwizard.windows || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/windows)"
    mkdir -p $WD/MigrationWizard/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationWizard/staging/windows || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_windows() {

    echo ############################################
    echo # Build Migration Wizard (windows)
    echo ############################################

    # build migrationwizard    
    PG_STAGING=$PG_PATH_WINDOWS

    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/MigrationWizard/source/
    cat <<EOT > "mw-build.bat"
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

@SET JAVA_HOME=$PG_JAVA_HOME_WINDOWS

@set PATH=$PG_CMAKE_WINDOWS\bin;%VSINSTALLDIR%\Common7\IDE;%VCINSTALLDIR%\BIN;%VSINSTALLDIR%\Common7\Tools;%VSINSTALLDIR%\Common7\Tools\bin;%VCINSTALLDIR%\PlatformSDK\bin;%FrameworkSDKDir%\bin;$PG_FRAMEWORKDIR_WINDOWS\$PG_FRAMEWORKVERSION_WINDOWS;%VCINSTALLDIR%\VCPackages;%PATH%

cd "$PG_PATH_WINDOWS"
SET SOURCE_PATH=%CD%
SET JAVA_HOME=$PG_JAVA_HOME_WINDOWS

REM Extracting MigrationWizard sources
if NOT EXIST "migrationwizard.zip" GOTO zip-not-found
unzip migrationwizard.zip

echo Building migrationwizard...
cd "%SOURCE_PATH%\\migrationwizard.windows"
cmd /c $PG_ANT_WINDOWS\\bin\\ant clean
cmd /c $PG_ANT_WINDOWS\\bin\\ant
  
echo Building migrationwizard distribution...
cmd /c $PG_ANT_WINDOWS\\bin\\ant dist

cd %SOURCE_PATH%\\migrationwizard.windows\\userValidation\\dbserver_guid
if NOT EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe" vcbuild dbserver_guid.vcproj release || SET ERRORMSG="Couldn't build the validateUserClient script" && goto OnError
if NOT EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe" copy "%SOURCE_PATH%\\migrationwizard.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe" "%SOURCE_PATH%\\migrationwizard.windows\\dist"
if EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe" copy "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\dbserver_guid\\Release\\dbserver_guid.exe" "%SOURCE_PATH%\\migrationwizard.windows\\dist"

cd %SOURCE_PATH%\\migrationwizard.windows\\userValidation\\validateUser
if NOT EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\validateUser\\release\\validateUserClient.exe" vcbuild validateUser.vcproj release
if NOT EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\validateUser\\Release\\validateUserClient.exe" copy "%SOURCE_PATH%\\migrationwizard.windows\\userValidation\\validateUser\\Release\\validateUserClient.exe" "%SOURCE_PATH%\\migrationwizard.windows\\dist"
if EXIST "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\validateUser\\Release\\validateUserClient.exe" copy "%SOURCE_PATH%\\tuningwizard.windows\\userValidation\\validateUser\\Release\\validateUserClient.exe" "%SOURCE_PATH%\\migrationwizard.windows\\dist"

copy $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe "%SOURCE_PATH%\\migrationwizard.windows\\dist"

cd %SOURCE_PATH%\\migrationwizard.windows
zip -r dist.zip dist
echo "Build operation completed successfully"
goto end

:OnError
   echo %ERRORMSG%

:end

EOT

    echo "Copying source tree to Windows build VM"
    zip -r migrationwizard.zip migrationwizard.windows || _die "Failed to pack the source tree (migrationwizard.windows)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationwizard.zip\" del /q migrationwizard.zip" || _die "Failed to remove the source tree on the windows build host (migrationwizard.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"mw-build.bat\" del /q mw-build.bat" || _die "Failed to remove the build script (mw-build.bat)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationwizard.windows\" rd /s /q migrationwizard.windows" || _die "Failed to remove the source tree on the windows build host (migrationwizard.windows)"

    scp migrationwizard.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (migrationwizard.zip)"
    scp mw-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the build script to windows VM (mw-build.bat)"

    echo "Building migrationwizard"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c mw-build.bat" || _die "Couldn't build the migrationwizard"
  
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to host"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/migrationwizard.windows/dist.zip $WD/MigrationWizard/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/migrationwizard.windows/dist.zip)"
    unzip $WD/MigrationWizard/staging/windows/dist.zip -d $WD/MigrationWizard/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/dist.zip)"
    rm $WD/MigrationWizard/staging/windows/dist.zip
    mv $WD/MigrationWizard/staging/windows/dist $WD/MigrationWizard/staging/windows/MigrationWizard || _die "Failed to rename the dist folder"

}
    


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_windows() {

    cd $WD/MigrationWizard

    mkdir -p staging/windows/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/windows/launchMigrationWizard.vbs staging/windows/scripts/launchMigrationWizard.vbs || _die "Failed to copy the launch scripts (scripts/windows)"

    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the icon images (resourcedds/*.ico)"

    # Build the installer
	"$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    
	# Sign the installer
	win32_sign "migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-windows.exe"
	
    cd $WD
}


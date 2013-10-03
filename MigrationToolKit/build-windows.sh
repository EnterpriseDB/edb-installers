#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_windows() {
    
    echo "BEGIN PREP MigrationToolKit Windows"   
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationtoolkit.windows ];
    then
      echo "Removing existing migrationtoolkit.windows source directory"
      rm -rf migrationtoolkit.windows  || _die "Couldn't remove the existing migrationtoolkit.windows source directory (source/migrationtoolkit.windows)"
    fi

    if [ -f $WD/MigrationToolKit/source/mw-build.bat ]; then
      rm -rf $WD/MigrationToolKit/source/mw-build.bat
    fi

    if [ -f $WD/MigrationToolKit/source/migrationtoolkit.zip ]; then
      rm -rf $WD/MigrationToolKit/source/migrationtoolkit.zip
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.windows)"
    mkdir -p migrationtoolkit.windows || _die "Couldn't create the migrationtoolkit.windows directory"
    cp -R EDB-MTK/* migrationtoolkit.windows || _die "Failed to copy the mtk source code"
    chmod ugo+w migrationtoolkit.windows || _die "Couldn't set the permissions on the source directory"
 
    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.windows/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.windows || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w migrationtoolkit.windows || _die "Couldn't set the permissions on the source directory"
    
    cp $WD/tarballs/edb-jdbc14.jar migrationtoolkit.windows/lib/ || _die "Failed to copy the edb-jdbc driver"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/windows)"
    mkdir -p $WD/MigrationToolKit/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/windows || _die "Couldn't set the permissions on the staging directory"
        
    echo "END PREP MigrationToolKit Windows"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_windows() {

    echo "BEGIN BUILD MigrationToolKit Windows" 

    echo ############################################
    echo # Build Migration ToolKit (windows)
    echo ############################################

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_WINDOWS

    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/MigrationToolKit/source/
    cat <<EOT > "mw-build.bat"

@SET JAVA_HOME=$PG_JAVA_HOME_WINDOWS

cd "$PG_PATH_WINDOWS"
SET SOURCE_PATH=%CD%
SET JAVA_HOME=$PG_JAVA_HOME_WINDOWS
REM Extracting MigrationToolKit sources
if NOT EXIST "migrationtoolkit.zip" GOTO zip-not-found
unzip migrationtoolkit.zip

echo Building migrationtoolkit...
cd "%SOURCE_PATH%\\migrationtoolkit.windows"
cmd /c $PG_ANT_WINDOWS\\bin\\ant clean
cmd /c $PG_ANT_WINDOWS\\bin\\ant install-pg
  
cd %SOURCE_PATH%\\migrationtoolkit.windows
zip -r dist.zip install 
echo "Build operation completed successfully"
goto end

:OnError
   echo %ERRORMSG%

:end

EOT

    echo "Copying source tree to Windows build VM"
    zip -r migrationtoolkit.zip migrationtoolkit.windows || _die "Failed to pack the source tree (migrationtoolkit.windows)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationtoolkit.zip\" del /q migrationtoolkit.zip" || _die "Failed to remove the source tree on the windows build host (migrationtoolkit.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"mw-build.bat\" del /q mw-build.bat" || _die "Failed to remove the build script (mw-build.bat)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationtoolkit.windows\" rd /s /q migrationtoolkit.windows" || _die "Failed to remove the source tree on the windows build host (migrationtoolkit.windows)"

    scp migrationtoolkit.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (migrationtoolkit.zip)"
    scp mw-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the build script to windows VM (mw-build.bat)"

    echo "Building migrationtoolkit"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c mw-build.bat" || _die "Couldn't build the migrationtoolkit"
  
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to host"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/migrationtoolkit.windows/dist.zip $WD/MigrationToolKit/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/migrationtoolkit.windows/dist.zip)"
    unzip $WD/MigrationToolKit/staging/windows/dist.zip -d $WD/MigrationToolKit/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/dist.zip)"
    rm $WD/MigrationToolKit/staging/windows/dist.zip
    mv $WD/MigrationToolKit/staging/windows/install $WD/MigrationToolKit/staging/windows/MigrationToolKit || _die "Failed to rename the dist folder"
    
    echo "END BUILD MigrationToolKit Windows"
}
    


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_windows() {

    echo "BEGIN POST MigrationToolKit Windows"

    cd $WD/MigrationToolKit

    if [ -f installer-win.xml ];    
    then
        rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml
    _replace "registration_plus_component" "registration_plus_component_windows" installer-win.xml || _die "Failed to replace the registration_plus component file name"
    _replace "registration_plus_preinstallation" "registration_plus_preinstallation_windows" installer-win.xml || _die "Failed to replace the registration_plus preinstallation file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"
    
	# Sign the installer
	win32_sign "migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-windows.exe"
	
    cd $WD

    echo "END POST MigrationToolKit Windows"
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_linux() {

    echo "BEGIN PREP Npgsql Linux"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.linux ];
    then
      echo "Removing existing Npgsql.linux source directory"
      rm -rf Npgsql.linux  || _die "Couldn't remove the existing Npgsql.linux source directory (source/Npgsql.linux)"
    fi
     
    if [ -e Npgsql.zip ];
    then
      echo "Removing existing Npgsql.zip file"
      rm -rf Npgsql.zip || _die "Couldn't remove the existing Npgsql.zip file (source/Npgsql.zip)"
    fi

    echo "Creating Npgsql source directory ($WD/Npgsql/source/Npgsql.linux)"
    mkdir -p Npgsql.linux || _die "Couldn't create the Npgsql.linux directory"
    chmod ugo+w Npgsql.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the Npgsql source tree
    cp -R npgsql-$PG_VERSION_NPGSQL/* Npgsql.linux || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"

    cd $WD/Npgsql/source

    echo "Archieving Npgsql sources"
    zip -r Npgsql.zip Npgsql.linux/ || _die "Couldn't create archieve of the Npgsql sources (Npgsql.zip)"
    chmod -R ugo+w Npgsql.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/linux.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/linux.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/linux)"
    mkdir -p $WD/Npgsql/staging/linux.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/linux.build || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.zip del /S /Q Npgsql.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.linux rd /S /Q Npgsql.linux" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.linux directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.staging rd /S /Q Npgsql.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST npgsql-staging.zip del /S /Q npgsql-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\npgsql-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-Npgsql.bat del /S /Q build-Npgsql.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-Npgsql.bat on Windows VM"

    echo "Copying Npgsql sources to Windows VM"
    scp Npgsql.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the Npgsql archieve to windows VM (Npgsql.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip Npgsql.zip" || _die "Couldn't extract Npgsql archieve on windows VM (Npgsql.zip)"
    
    echo "END PREP Npgsql Linux"

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_linux() {
  
    echo "BEGIN BUILD Npgsql Linux"

    cd $WD/Npgsql/source

    cat <<EOT > "build-Npgsql.bat"
    cd Npgsql.linux\src\Npgsql
    REM Restore Npgsql
    dotnet restore
    REM Build Npgsql
    dotnet build -c Release

GOTO end

:end

EOT
    scp build-Npgsql.bat  $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the script to the windows build host (build-Npgsql.bat)"

    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c $PG_PATH_WINDOWS\\\\build-Npgsql.bat Npgsql.sln Release $PLATFORM_TOOLSET" || _die "Failed to build npgsql on the windows build host"
     
    # We need to copy them to staging directory
    ssh $PG_SSH_WINDOWS  "mkdir -p $PG_PATH_WINDOWS/Npgsql.staging/bin" || _die "Failed to create the bin directory"
    ssh $PG_SSH_WINDOWS "cp -pR $PG_PATH_WINDOWS/Npgsql.linux/src/Npgsql/bin/Release/* $PG_PATH_WINDOWS/Npgsql.staging/bin" || _die "Failed to copy Npgsql binary to staging directory"
    
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying npgsql built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\Npgsql.staging; cmd /c zip -r ..\\\\npgsql-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/Npgsql.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip $WD/Npgsql/staging/linux.build || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip)"
    unzip $WD/Npgsql/staging/linux.build/npgsql-staging.zip -d $WD/Npgsql/staging/linux.build || _die "Failed to unpack the built source tree ($WD/staging/linux/npgsql-staging.zip)"
    rm $WD/Npgsql/staging/linux.build/npgsql-staging.zip
    
    cp $WD/Npgsql/source/Npgsql.linux/LICENSE.txt $WD/Npgsql/staging/linux.build/ || _die "Unable to copy LICENSE.txt"
    mkdir -p $WD/Npgsql/staging/linux || _die "Failed to create staging/linux directory"
    cp -pR $WD/Npgsql/staging/linux.build/* $WD/Npgsql/staging/linux || _die "Failed to copy the staging/linux.build to staging/linux"
    echo "PG_VERSION_NPGSQL=$PG_VERSION_NPGSQL" > $WD/Npgsql/staging/linux/versions-linux.sh
    echo "PG_BUILDNUM_NPGSQL=$PG_BUILDNUM_NPGSQL" >> $WD/Npgsql/staging/linux/versions-linux.sh

    cd $WD

    echo "END BUILD Npgsql Linux"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_linux() {

    echo "BEGIN POST Npgsql Linux"
    source $WD/Npgsql/staging/linux/versions-linux.sh
    PG_BUILD_NPGSQL=$(expr $PG_BUILD_NPGSQL + $SKIPBUILD)
 
    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/npgsql || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/npgsql/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/npgsql/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Setup the Npgsql xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchDocsAPI.desktop staging/linux/scripts/xdg/pg-launchDocsAPI.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-launchUserManual.desktop staging/linux/scripts/xdg/pg-launchUserManual.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-npgsql.directory staging/linux/scripts/xdg/pg-npgsql.directory || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files"

    # Set permissions to all files and folders in staging
    _set_permissions linux
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_NPGSQL -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux.run $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-${BUILD_FAILED}linux.run

    cd $WD

    echo "END POST Npgsql Linux"
}


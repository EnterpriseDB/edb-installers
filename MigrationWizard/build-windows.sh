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

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.windows)"
    mkdir -p migrationwizard.windows || _die "Couldn't create the migrationwizard.windows directory"
    chmod ugo+w migrationwizard.windows || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.windows || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
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

    # build migrationwizard    
    PG_STAGING=$PG_PATH_WINDOWS

    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/MigrationWizard/source/
    echo "Copying source tree to Windows build VM"
    zip -r migrationwizard.zip migrationwizard.windows || _die "Failed to pack the source tree (migrationwizard.windows)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationwizard.zip\" del /q migrationwizard.zip" || _die "Failed to remove the source tree on the windows build host (migrationwizard.zip)"
    scp migrationwizard.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (migrationwizard.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST \"migrationwizard.windows\" rd /s /q migrationwizard.windows" || _die "Failed to remove the source tree on the windows build host (migrationwizard.windows)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip migrationwizard.zip" || _die "Failed to unpack the source tree on the windows build host (migrationwizard.zip)"
    

    echo "Building migrationwizard"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\migrationwizard.windows; cmd /c \"$PG_ANT_WINDOWS\\\\bin\\\\ant\"" || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\migrationwizard.windows; cmd /c \"$PG_ANT_WINDOWS\\\\bin\\\\ant dist\"" || _die "Couldn't build the migrationwizard distribution jars"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\migrationwizard.windows; cmd /c zip -r dist.zip dist" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/migrationwizard.windows)"
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
    
    cd $WD
}


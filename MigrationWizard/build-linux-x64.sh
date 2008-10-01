#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_linux_x64() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.linux-x64 ];
    then
      echo "Removing existing migrationwizard.linux-x64 source directory"
      rm -rf migrationwizard.linux-x64  || _die "Couldn't remove the existing migrationwizard.linux-x64 source directory (source/migrationwizard.linux-x64)"
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.linux-x64)"
    mkdir -p migrationwizard.linux-x64 || _die "Couldn't create the migrationwizard.linux-x64 directory"
    chmod ugo+w migrationwizard.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.linux-x64 || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    chmod -R ugo+w migrationwizard.linux-x64 || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/linux-x64)"
    mkdir -p $WD/MigrationWizard/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationWizard/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_linux_x64() {

    # build migrationwizard    
    PG_STAGING=$PG_PATH_LINUX_X64/MigrationWizard/staging/linux-x64    

    echo "Building migrationwizard"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationWizard/source/migrationwizard.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant" || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationWizard/source/migrationwizard.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant dist" || _die "Couldn't build the migrationwizard distribution"

    # Copying the MigrationWizard binary to staging directory
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationWizard/source/migrationwizard.linux-x64; mkdir $PG_STAGING/MigrationWizard" || _die "Couldn't create the migrationwizard staging directory (MigrationWizard/staging/linux-x64/MigrationWizard)"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationWizard/source/migrationwizard.linux-x64; cp -R dist/* $PG_STAGING/MigrationWizard" || _die "Couldn't copy the binaries to the migrationwizard staging directory (MigrationWizard/staging/linux-x64/MigrationWizard)"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_linux_x64() {

    cd $WD/MigrationWizard

    mkdir -p staging/linux-x64/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/linux-x64/createshortcuts.sh staging/linux-x64/installer/MigrationWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/MigrationWizard/createshortcuts.sh

    cp scripts/linux-x64/removeshortcuts.sh staging/linux-x64/installer/MigrationWizard/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/MigrationWizard/removeshortcuts.sh    

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux-x64/launchMigrationWizard.sh staging/linux-x64/scripts/launchMigrationWizard.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux-x64/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchMigrationWizard.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchMigrationWizard.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD
}


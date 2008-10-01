#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_linux() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.linux ];
    then
      echo "Removing existing migrationwizard.linux source directory"
      rm -rf migrationwizard.linux  || _die "Couldn't remove the existing migrationwizard.linux source directory (source/migrationwizard.linux)"
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.linux)"
    mkdir -p migrationwizard.linux || _die "Couldn't create the migrationwizard.linux directory"
    chmod ugo+w migrationwizard.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.linux || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    chmod -R ugo+w migrationwizard.linux || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/linux)"
    mkdir -p $WD/MigrationWizard/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationWizard/staging/linux || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_linux() {

    # build migrationwizard    
    PG_STAGING=$PG_PATH_LINUX/MigrationWizard/staging/linux    

    echo "Building migrationwizard"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant" || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant dist" || _die "Couldn't build the migrationwizard distribution"

    # Copying the MigrationWizard binary to staging directory
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; mkdir $PG_STAGING/MigrationWizard" || _die "Couldn't create the migrationwizard staging directory (MigrationWizard/staging/linux/MigrationWizard)"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; cp -R dist/* $PG_STAGING/MigrationWizard" || _die "Couldn't copy the binaries to the migrationwizard staging directory (MigrationWizard/staging/linux/MigrationWizard)"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_linux() {

    cd $WD/MigrationWizard

    mkdir -p staging/linux/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/MigrationWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/MigrationWizard/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/MigrationWizard/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/MigrationWizard/removeshortcuts.sh    

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchMigrationWizard.sh staging/linux/scripts/launchMigrationWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchMigrationWizard.desktop staging/linux/scripts/xdg/enterprisedb-launchMigrationWizard.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}


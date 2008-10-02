#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.osx ];
    then
      echo "Removing existing migrationwizard.osx source directory"
      rm -rf migrationwizard.osx  || _die "Couldn't remove the existing migrationwizard.osx source directory (source/migrationwizard.osx)"
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.osx)"
    mkdir -p migrationwizard.osx || _die "Couldn't create the migrationwizard.osx directory"
    chmod ugo+w migrationwizard.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.osx || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    chmod -R ugo+w migrationwizard.osx || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/osx)"
    mkdir -p $WD/MigrationWizard/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationWizard/staging/osx || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_osx() {

    # build migrationwizard    
    PG_STAGING=$PG_PATH_OSX/MigrationWizard/staging/osx    

    cd $PG_PATH_OSX/MigrationWizard/source/migrationwizard.osx

    echo "Building migrationwizard"
    $PG_ANT_HOME_OSX/bin/ant || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    $PG_ANT_HOME_OSX/bin/ant dist || _die "Couldn't build the migrationwizard distribution"

    # Copying the MigrationWizard binary to staging directory
    mkdir $PG_STAGING/MigrationWizard || _die "Couldn't create the migrationwizard staging directory (MigrationWizard/staging/osx/MigrationWizard)"
    cp -R dist/* $PG_STAGING/MigrationWizard || _die "Couldn't copy the binaries to the migrationwizard staging directory (MigrationWizard/staging/osx/MigrationWizard)"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_osx() {

    cd $WD/MigrationWizard

    mkdir -p staging/osx/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/MigrationWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/MigrationWizard/createshortcuts.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/launchMigrationWizard.sh staging/osx/scripts/launchMigrationWizard.sh || _die "Failed to copy the launch scripts (scripts/osx)"

    cp scripts/osx/enterprisedb-launchMigrationWizard.applescript.in staging/osx/scripts/enterprisedb-launchMigrationWizard.applescript || _die "Failed to copy a "
    
    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchMigrationWizard.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/enterprisedb-launchMigrationWizard.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    if [ -d migrationwizard.img ];
    then
        rm -rf migrationwizard.img
    fi
    mkdir migrationwizard.img || _die "Failed to create DMG staging directory"
    mv migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.app migrationwizard.img || _die "Failed to copy the installer bundle into the DMG staging directory"
    hdiutil create -quiet -srcfolder migrationwizard.img -format UDZO -volname "MigrationWizard $PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD" -ov "migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.dmg" || _die "Failed to create the disk image (output/migrationwizard-$PG_VERSION_MIGRATIONWIZARD-$PG_BUILDNUM_MIGRATIONWIZARD-osx.dmg)"
    rm -rf migrationwizard.img

    
    cd $WD
}


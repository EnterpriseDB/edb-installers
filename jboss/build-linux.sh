#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_jboss_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/jboss/source

    if [ -e jboss.linux ];
    then
      echo "Removing existing jboss.linux source directory"
      rm -rf jboss.linux  || _die "Couldn't remove the existing jboss.linux source directory (source/jboss.linux)"
    fi
   
    echo "Creating staging directory ($WD/jboss/source/jboss.linux)"
    mkdir -p $WD/jboss/source/jboss.linux || _die "Couldn't create the jboss.linux directory"

    # Grab a copy of the source tree
    cp -R jboss-$PG_VERSION_JBOSS.GA/* jboss.linux || _die "Failed to copy the source code (source/jboss-$PG_VERSION_JBOSS.GA)"
    chmod -R ugo+w jboss.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/jboss/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/jboss/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/jboss/staging/linux)"
    mkdir -p $WD/jboss/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/jboss/staging/linux || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_jboss_linux() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_jboss_linux() {
 
    cp -R $WD/jboss/source/jboss.linux/* $WD/jboss/staging/linux || _die "Failed to copy the jboss Source into the staging directory"

    cd $WD/jboss

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/jboss || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/jboss/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/jboss/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/jboss/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/jboss/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Setup the jboss xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchjboss.desktop staging/linux/scripts/xdg/pg-launchjboss.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


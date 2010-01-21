#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_hqagent_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    if [ -e hqagent.windows ];
    then
      echo "Removing existing hqagent.windows source directory"
      rm -rf hqagent.windows  || _die "Couldn't remove the existing hqagent.windows source directory (source/hqagent.windows)"
    fi
   
    echo "Creating staging directory ($WD/hqagent/source/hqagent.windows)"
    mkdir -p $WD/hqagent/source/hqagent.windows || _die "Couldn't create the hqagent.windows directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_HQAGENT-windows/* hqagent.windows || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_HQAGENT-windows)"
    chmod -R ugo+w hqagent.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hqagent/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hqagent/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hqagent/staging/windows)"
    mkdir -p $WD/hqagent/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hqagent/staging/windows || _die "Couldn't set the permissions on the staging directory"
   cp -R $WD/hqagent/source/hqagent.windows/* $WD/hqagent/staging/windows || _die "Failed to copy the hqagent Source into the staging directory" 

}

################################################################################
# PG Build
################################################################################

_build_hqagent_windows() {

    cd $WD
}


################################################################################
# HQAGENT Build
################################################################################

_postprocess_hqagent_windows() {
 
    cd $WD/hqagent

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "hqagent-$PG_VERSION_HQAGENT-windows.exe"
	
    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_hqagent_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    if [ -e hqagent.osx ];
    then
      echo "Removing existing hqagent.osx source directory"
      rm -rf hqagent.osx  || _die "Couldn't remove the existing hqagent.osx source directory (source/hqagent.osx)"
    fi
   
    echo "Creating source directory ($WD/hqagent/source/hqagent.osx)"
    mkdir -p $WD/hqagent/source/hqagent.osx || _die "Couldn't create the hqagent.osx directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_PGJDBC/* hqagent.osx || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_PGJDBC)"
    chmod -R ugo+w hqagent.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hqagent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hqagent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hqagent/staging/osx)"
    mkdir -p $WD/hqagent/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hqagent/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_hqagent_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_hqagent_osx() {
 
    cp -R $WD/hqagent/source/hqagent.osx/* $WD/hqagent/staging/osx || _die "Failed to copy the hqagent Source into the staging directory"

    cd $WD/hqagent

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pgjdbc || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/pgjdbc/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/pgjdbc/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pgjdbc.applescript staging/osx/scripts/pgjdbc.applescript || _die "Failed to copy the pgjdbc.applescript script (scripts/osx/pgjdbc.applescript)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


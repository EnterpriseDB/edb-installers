#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.osx ];
    then
      echo "Removing existing pghyperic.osx source directory"
      rm -rf pghyperic.osx  || _die "Couldn't remove the existing pghyperic.osx source directory (source/pghyperic.osx)"
    fi
   
    echo "Creating source directory ($WD/pghyperic/source/pghyperic.osx)"
    mkdir -p $WD/pghyperic/source/pghyperic.osx || _die "Couldn't create the pghyperic.osx directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGJDBC/* pghyperic.osx || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGJDBC)"
    chmod -R ugo+w pghyperic.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/osx)"
    mkdir -p $WD/pghyperic/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pghyperic_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_osx() {
 
    cp -R $WD/pghyperic/source/pghyperic.osx/* $WD/pghyperic/staging/osx || _die "Failed to copy the pghyperic Source into the staging directory"

    cd $WD/pghyperic

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


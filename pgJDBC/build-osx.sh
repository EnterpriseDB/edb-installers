#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    if [ -e pgJDBC.osx ];
    then
      echo "Removing existing pgJDBC.osx source directory"
      rm -rf pgJDBC.osx  || _die "Couldn't remove the existing pgJDBC.osx source directory (source/pgJDBC.osx)"
    fi
   
    echo "Creating source directory ($WD/pgJDBC/source/pgJDBC.osx)"
    mkdir -p $WD/pgJDBC/source/pgJDBC.osx || _die "Couldn't create the pgJDBC.osx directory"

    # Grab a copy of the source tree
    cp -R pgJDBC-$PG_VERSION_PGJDBC/* pgJDBC.osx || _die "Failed to copy the source code (source/pgJDBC-$PG_VERSION_PGJDBC)"
    chmod -R ugo+w pgJDBC.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/osx)"
    mkdir -p $WD/pgJDBC/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgJDBC_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_pgJDBC_osx() {
 
    cp -R $WD/pgJDBC/source/pgJDBC.osx/* $WD/pgJDBC/staging/osx || _die "Failed to copy the pgJDBC Source into the staging directory"

    cd $WD/pgJDBC

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pgjdbc || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/pgjdbc/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/pgjdbc/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/launchbrowser.sh staging/osx/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/osx/launchbrowser.sh)"
    chmod ugo+x staging/osx/scripts/launchbrowser.sh
    
    cp scripts/osx/pgjdbc.applescript staging/osx/scripts/pgjdbc.applescript || _die "Failed to copy the pgjdbc.applescript script (scripts/osx/pgjdbc.applescript)"
    chmod ugo+x staging/osx/scripts/pgjdbc.applescript

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pgjdbc.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pgjdbc.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


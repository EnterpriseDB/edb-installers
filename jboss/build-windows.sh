#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    if [ -e pgJDBC.windows ];
    then
      echo "Removing existing pgJDBC.windows source directory"
      rm -rf pgJDBC.windows  || _die "Couldn't remove the existing pgJDBC.windows source directory (source/pgJDBC.windows)"
    fi
   
    echo "Creating staging directory ($WD/pgJDBC/source/pgJDBC.windows)"
    mkdir -p $WD/pgJDBC/source/pgJDBC.windows || _die "Couldn't create the pgJDBC.windows directory"

    # Grab a copy of the source tree
    cp -R pgJDBC-$PG_VERSION_PGJDBC/* pgJDBC.windows || _die "Failed to copy the source code (source/pgJDBC-$PG_VERSION_PGJDBC)"
    chmod -R ugo+w pgJDBC.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/windows)"
    mkdir -p $WD/pgJDBC/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/windows || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgJDBC_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_pgJDBC_windows() {
 
    cp -R $WD/pgJDBC/source/pgJDBC.windows/* $WD/pgJDBC/staging/windows || _die "Failed to copy the pgJDBC Source into the staging directory"

    cd $WD/pgJDBC

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe"
	
    cd $WD
}


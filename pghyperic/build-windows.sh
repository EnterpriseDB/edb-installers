#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.windows ];
    then
      echo "Removing existing pghyperic.windows source directory"
      rm -rf pghyperic.windows  || _die "Couldn't remove the existing pghyperic.windows source directory (source/pghyperic.windows)"
    fi
   
    echo "Creating staging directory ($WD/pghyperic/source/pghyperic.windows)"
    mkdir -p $WD/pghyperic/source/pghyperic.windows || _die "Couldn't create the pghyperic.windows directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGJDBC/* pghyperic.windows || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGJDBC)"
    chmod -R ugo+w pghyperic.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/windows)"
    mkdir -p $WD/pghyperic/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/windows || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pghyperic_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_windows() {
 
    cp -R $WD/pghyperic/source/pghyperic.windows/* $WD/pghyperic/staging/windows || _die "Failed to copy the pghyperic Source into the staging directory"

    cd $WD/pghyperic

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe"
	
    cd $WD
}


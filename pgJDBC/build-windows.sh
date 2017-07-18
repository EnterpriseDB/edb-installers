#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_windows() {

    echo "BEGIN PREP pgJDBC Windows"   

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

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/windows.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/windows.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/windows.build)"
    mkdir -p $WD/pgJDBC/staging/windows.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/windows.build || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP pgJDBC Windows"

}

################################################################################
# PG Build
################################################################################

_build_pgJDBC_windows() {
    
    echo "BEGIN BUILD pgJDBC Windows"    

    cp -R $WD/pgJDBC/source/pgJDBC.windows/* $WD/pgJDBC/staging/windows.build || _die "Failed to copy the pgJDBC Source into the staging directory"

    cd $WD

    echo "Removing last successful staging directory ($WD/pgJDBC/staging/windows)"
    rm -rf $WD/pgJDBC/staging/windows || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgJDBC/staging/windows || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgJDBC/staging/windows || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgJDBC/staging/windows.build/* $WD/pgJDBC/staging/windows || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGJDBC=$PG_VERSION_PGJDBC" > $WD/pgJDBC/staging/windows/versions-windows.sh
    echo "PG_BUILDNUM_PGJDBC=$PG_BUILDNUM_PGJDBC" >> $WD/pgJDBC/staging/windows/versions-windows.sh

    echo "END BUILD pgJDBC Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgJDBC_windows() {
    
    echo "BEGIN POST pgJDBC Windows"   

    source $WD/pgJDBC/staging/windows/versions-windows.sh
    PG_BUILD_PGJDBC=$(expr $PG_BUILD_PGJDBC + $SKIPBUILD)

    cd $WD/pgJDBC

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGJDBC -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}windows.exe

	# Sign the installer
	win32_sign "pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}windows.exe"
	
    cd $WD

    echo "END POST pgJDBC Windows"
}


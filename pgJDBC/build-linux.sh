#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_linux() {
    
    echo "BEGIN PREP pgJDBC Linux"  

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    if [ -e pgJDBC.linux ];
    then
      echo "Removing existing pgJDBC.linux source directory"
      rm -rf pgJDBC.linux  || _die "Couldn't remove the existing pgJDBC.linux source directory (source/pgJDBC.linux)"
    fi
   
    echo "Creating staging directory ($WD/pgJDBC/source/pgJDBC.linux)"
    mkdir -p $WD/pgJDBC/source/pgJDBC.linux || _die "Couldn't create the pgJDBC.linux directory"

    # Grab a copy of the source tree
    cp -R pgJDBC-$PG_VERSION_PGJDBC/* pgJDBC.linux || _die "Failed to copy the source code (source/pgJDBC-$PG_VERSION_PGJDBC)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/linux.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/linux.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/linux.build)"
    mkdir -p $WD/pgJDBC/staging/linux.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/linux.build || _die "Couldn't set the permissions on the staging directory"

    echo "END PREP pgJDBC Linux"

}

################################################################################
# PG Build
################################################################################

_build_pgJDBC_linux() {
    
    echo "BEGIN BUILD pgJDBC Linux"

    cp -R $WD/pgJDBC/source/pgJDBC.linux/* $WD/pgJDBC/staging/linux.build || _die "Failed to copy the pgJDBC Source into the staging directory"

    cd $WD

    echo "Removing last successful staging directory ($WD/pgJDBC/staging/linux)"
    rm -rf $WD/pgJDBC/staging/linux || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgJDBC/staging/linux || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgJDBC/staging/linux || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgJDBC/staging/linux.build/* $WD/pgJDBC/staging/linux || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGJDBC=$PG_VERSION_PGJDBC" > $WD/pgJDBC/staging/linux/versions-linux.sh
    echo "PG_BUILDNUM_PGJDBC=$PG_BUILDNUM_PGJDBC" >> $WD/pgJDBC/staging/linux/versions-linux.sh

    echo "END BUILD pgJDBC Linux"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgJDBC_linux() {

    echo "BEGIN POST pgJDBC Linux"

    source $WD/pgJDBC/staging/linux/versions-linux.sh
    PG_BUILD_PGJDBC=$(expr $PG_BUILD_PGJDBC + $SKIPBUILD)

    cd $WD/pgJDBC

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pgjdbc || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/pgjdbc/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pgjdbc/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/pgjdbc/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pgjdbc/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Setup the pgJDBC xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchpgJDBC.desktop staging/linux/scripts/xdg/pg-launchpgJDBC.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files "
    
    # Set permissions to all files and folders in staging
    _set_permissions linux
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGJDBC -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux.run $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}linux.run

    echo "END POST pgJDBC Linux"
}


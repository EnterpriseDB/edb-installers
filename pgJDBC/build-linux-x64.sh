#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_linux_x64() {
    
    echo "BEGIN PREP pgJDBC Linux-x64"    

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    if [ -e pgJDBC.linux-x64 ];
    then
      echo "Removing existing pgJDBC.linux-x64 source directory"
      rm -rf pgJDBC.linux-x64  || _die "Couldn't remove the existing pgJDBC.linux-x64 source directory (source/pgJDBC.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/pgJDBC/source/pgJDBC.linux-x64)"
    mkdir -p $WD/pgJDBC/source/pgJDBC.linux-x64 || _die "Couldn't create the pgJDBC.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pgJDBC-$PG_VERSION_PGJDBC/* pgJDBC.linux-x64 || _die "Failed to copy the source code (source/pgJDBC-$PG_VERSION_PGJDBC)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/linux-x64.build)"
    mkdir -p $WD/pgJDBC/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP pgJDBC Linux-x64"

}

################################################################################
# PG Build
################################################################################

_build_pgJDBC_linux_x64() {
    
    echo "BEGIN BUILD pgJDBC Linux-x64"

    cp -R $WD/pgJDBC/source/pgJDBC.linux-x64/* $WD/pgJDBC/staging/linux-x64.build || _die "Failed to copy the pgJDBC Source into the staging directory"

    echo "Removing last successful staging directory ($WD/pgJDBC/staging/linux-x64)"
    rm -rf $WD/pgJDBC/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgJDBC/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgJDBC/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgJDBC/staging/linux-x64.build/* $WD/pgJDBC/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGJDBC=$PG_VERSION_PGJDBC" > $WD/pgJDBC/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_PGJDBC=$PG_BUILDNUM_PGJDBC" >> $WD/pgJDBC/staging/linux-x64/versions-linux-x64.sh

    cd $WD
  
    echo "END BUILD pgJDBC Linux-x64"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgJDBC_linux_x64() {
    
    echo "BEGIN POST pgJDBC Linux-x64"

    source $WD/pgJDBC/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_PGJDBC=$(expr $PG_BUILD_PGJDBC + $SKIPBUILD)

    cd $WD/pgJDBC

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/pgjdbc || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/pgjdbc/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pgjdbc/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/pgjdbc/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pgjdbc/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    # Setup the pgJDBC xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchpgJDBC.desktop staging/linux-x64/scripts/xdg/pg-launchpgJDBC.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg files "

    # Set permissions to all files and folders in staging
    _set_permissions linux-x64
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGJDBC -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux-x64.run $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}linux-x64.run

    cd $WD

    echo "END POST pgJDBC Linux-x64"
}


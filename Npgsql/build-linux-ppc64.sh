#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_linux_ppc64() {

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.linux-ppc64 ];
    then
      echo "Removing existing Npgsql.linux-ppc64 source directory"
      rm -rf Npgsql.linux-ppc64  || _die "Couldn't remove the existing Npgsql.linux-ppc64 source directory (source/Npgsql.linux-ppc64)"
    fi
   
    echo "Creating staging directory ($WD/Npgsql/source/Npgsql.linux-ppc64)"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-ppc64 || _die "Couldn't create the Npgsql.linux-ppc64 directory"

    # Grab a copy of the source tree
    cp -R Mono2.0/* Npgsql.linux-ppc64 || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_NPGSQL)"
    chmod -R ugo+w Npgsql.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/linux-ppc64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/linux-ppc64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/linux-ppc64)"
    mkdir -p $WD/Npgsql/staging/linux-ppc64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/linux-ppc64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_linux_ppc64() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_linux_ppc64() {
 
    cp -R $WD/Npgsql/source/Npgsql.linux-ppc64/* $WD/Npgsql/staging/linux-ppc64 || _die "Failed to copy the Npgsql Source into the staging directory"
    chmod -R ugo+rx $WD/Npgsql/staging/linux-ppc64/docs

    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/linux-ppc64/installer/npgsql || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-ppc64/installer/npgsql/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-ppc64/installer/npgsql/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-ppc64/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-ppc64/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux-ppc64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux-ppc64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-ppc64/scripts/launchbrowser.sh

    # Setup the Npgsql xdg Files
    mkdir -p staging/linux-ppc64/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchDocsAPI.desktop staging/linux-ppc64/scripts/xdg/pg-launchDocsAPI.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-launchUserManual.desktop staging/linux-ppc64/scripts/xdg/pg-launchUserManual.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-npgsql.directory staging/linux-ppc64/scripts/xdg/pg-npgsql.directory || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux-ppc64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux-ppc64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-ppc64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-ppc64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-ppc64/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-ppc || _die "Failed to build the installer"

    mv $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux-ppc.bin $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux-ppc64.bin

    cd $WD
}


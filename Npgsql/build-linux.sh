#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_linux() {

    echo "BEGIN PREP Npgsql Linux"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.linux ];
    then
      echo "Removing existing Npgsql.linux source directory"
      rm -rf Npgsql.linux  || _die "Couldn't remove the existing Npgsql.linux source directory (source/Npgsql.linux)"
    fi
   
    echo "Creating staging directory ($WD/Npgsql/source/Npgsql.linux)"
    mkdir -p $WD/Npgsql/source/Npgsql.linux || _die "Couldn't create the Npgsql.linux directory"

    # Grab a copy of the source tree
    cp -R Npgsql$PG_VERSION_NPGSQL/Mono2.0/* Npgsql.linux || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/linux)"
    mkdir -p $WD/Npgsql/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/linux || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP Npgsql Linux"

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_linux() {
  
    echo "BEGIN BUILD Npgsql Linux"

    cd $WD

    echo "END BUILD Npgsql Linux"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_linux() {

    echo "BEGIN POST Npgsql Linux"
 
    cp -R $WD/Npgsql/source/Npgsql.linux/* $WD/Npgsql/staging/linux || _die "Failed to copy the Npgsql Source into the staging directory"
    chmod -R ugo+rx $WD/Npgsql/staging/linux/docs

    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/npgsql || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/npgsql/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/npgsql/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Setup the Npgsql xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchDocsAPI.desktop staging/linux/scripts/xdg/pg-launchDocsAPI.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-launchUserManual.desktop staging/linux/scripts/xdg/pg-launchUserManual.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-npgsql.directory staging/linux/scripts/xdg/pg-npgsql.directory || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

    echo "END POST Npgsql Linux"
}


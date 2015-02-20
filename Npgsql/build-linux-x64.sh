#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_linux_x64() {

    echo "BEGIN PREP Npgsql Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.linux-x64 ];
    then
      echo "Removing existing Npgsql.linux-x64 source directory"
      rm -rf Npgsql.linux-x64  || _die "Couldn't remove the existing Npgsql.linux-x64 source directory (source/Npgsql.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/Npgsql/source/Npgsql.linux-x64)"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64 || _die "Couldn't create the Npgsql.linux-x64 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64/ms.net20 || _die "Couldn't create the Npgsql.linux-x64/ms.net20 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64/ms.net35 || _die "Couldn't create the Npgsql.linux-x64/ms.net35 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64/ms.net40 || _die "Couldn't create the Npgsql.linux-x64/ms.net40 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64/ms.net45 || _die "Couldn't create the Npgsql.linux-x64/ms.net45 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.linux-x64/docs || _die "Couldn't create the Npgsql.linux-x64/docs directory"

    # Grab a copy of the source tree
    cp -R Npgsql-$PG_VERSION_NPGSQL-net20/* Npgsql.linux-x64/ms.net20 || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-net20)"
    cp -R Npgsql-$PG_VERSION_NPGSQL-net35/* Npgsql.linux-x64/ms.net35 || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-net35)"
    cp -R Npgsql-$PG_VERSION_NPGSQL-net40/* Npgsql.linux-x64/ms.net40 || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-net40)"
    cp -R Npgsql-$PG_VERSION_NPGSQL-net45/* Npgsql.linux-x64/ms.net45 || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-net45)"
    cp -R Npgsql-$PG_VERSION_NPGSQL-docs/* Npgsql.linux-x64/docs || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-docs)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/linux-x64)"
    mkdir -p $WD/Npgsql/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP Npgsql Linux-x64"

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_linux_x64() {
    
    echo "BEGIN BUILD Npgsql Linux-x64"

    cd $WD

    echo "END BUILD Npgsql Linux-x64"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_linux_x64() {

    echo "BEGIN POST Npgsql Linux-x64"
 
    cp -R $WD/Npgsql/source/Npgsql.linux-x64/* $WD/Npgsql/staging/linux-x64 || _die "Failed to copy the Npgsql Source into the staging directory"
    chmod -R ugo+rx $WD/Npgsql/staging/linux-x64/docs

    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/npgsql || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/npgsql/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/npgsql/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    # Setup the Npgsql xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchDocsAPI.desktop staging/linux-x64/scripts/xdg/pg-launchDocsAPI.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-launchUserManual.desktop staging/linux-x64/scripts/xdg/pg-launchUserManual.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-npgsql.directory staging/linux-x64/scripts/xdg/pg-npgsql.directory || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

    echo "END POST Npgsql Linux-x64"
}


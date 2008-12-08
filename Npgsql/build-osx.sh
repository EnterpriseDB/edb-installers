#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.osx ];
    then
      echo "Removing existing Npgsql.osx source directory"
      rm -rf Npgsql.osx  || _die "Couldn't remove the existing Npgsql.osx source directory (source/Npgsql.osx)"
    fi
   
    echo "Creating source directory ($WD/Npgsql/source/Npgsql.osx)"
    mkdir -p $WD/Npgsql/source/Npgsql.osx || _die "Couldn't create the Npgsql.osx directory"

    # Grab a copy of the source tree
    cp -R Mono2.0/* Npgsql.osx || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"
    chmod -R ugo+w Npgsql.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/osx)"
    mkdir -p $WD/Npgsql/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_osx() {
 
    cp -R $WD/Npgsql/source/Npgsql.osx/* $WD/Npgsql/staging/osx || _die "Failed to copy the Npgsql Source into the staging directory"

    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/npgsql || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pg-launchDocsAPI.applescript.in staging/osx/scripts/pg-launchDocsAPI.applescript || _die "Failed to copy the pg-launchDocsAPI.applescript script (scripts/osx/pg-launchDocsAPI.applescript)"
    cp scripts/osx/pg-launchUserManual.applescript.in staging/osx/scripts/pg-launchUserManual.applescript || _die "Failed to copy the pg-launchUserManual.applescript script (scripts/osx/pg-launchUserManual.applescript)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


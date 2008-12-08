#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.windows ];
    then
      echo "Removing existing Npgsql.windows source directory"
      rm -rf Npgsql.windows  || _die "Couldn't remove the existing Npgsql.windows source directory (source/Npgsql.windows)"
    fi
   
    echo "Creating staging directory ($WD/Npgsql/source/Npgsql.windows)"
    mkdir -p $WD/Npgsql/source/Npgsql.windows || _die "Couldn't create the Npgsql.windows directory"

    # Grab a copy of the source tree
    cp -R Npgsql"$PG_VERSION_NPGSQL"-bin-ms.net/* Npgsql.windows || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"
    chmod -R ugo+w Npgsql.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/windows)"
    mkdir -p $WD/Npgsql/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/windows || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_windows() {
 
    cp -R $WD/Npgsql/source/Npgsql.windows/* $WD/Npgsql/staging/windows || _die "Failed to copy the Npgsql Source into the staging directory"

    cd $WD/Npgsql
    
    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD
}


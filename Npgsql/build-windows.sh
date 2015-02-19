#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_windows() {

    echo "BEGIN PREP Npgsql Windows"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.windows ];
    then
      echo "Removing existing Npgsql.windows source directory"
      rm -rf Npgsql.windows  || _die "Couldn't remove the existing Npgsql.windows source directory (source/Npgsql.windows)"
    fi
   
    echo "Creating staging directory ($WD/Npgsql/source/Npgsql.windows)"
    mkdir -p $WD/Npgsql/source/Npgsql.windows || _die "Couldn't create the Npgsql.windows directory"
    mkdir -p $WD/Npgsql/source/Npgsql.windows/ms.net20 || _die "Couldn't create the Npgsql.windows/ms.net20 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.windows/ms.net35 || _die "Couldn't create the Npgsql.windows/ms.net35 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.windows/ms.net40 || _die "Couldn't create the Npgsql.windows/ms.net40 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.windows/ms.net45 || _die "Couldn't create the Npgsql.windows/ms.net45 directory"
    mkdir -p $WD/Npgsql/source/Npgsql.windows/docs || _die "Couldn't create the Npgsql.windows/docs directory"

    cd $WD/Npgsql/source
    # Grab a copy of the source tree
    cp -R Npgsql-"$PG_VERSION_NPGSQL"-net20/* Npgsql.windows/ms.net20/ || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql-net20)"
    cp -R Npgsql-"$PG_VERSION_NPGSQL"-net35/* Npgsql.windows/ms.net35/ || _die "Failed to copy the binaries (source/Npgsql-$PG_VERSION_Npgsql-net35)"
    cp -R Npgsql-"$PG_VERSION_NPGSQL"-net40/* Npgsql.windows/ms.net40/ || _die "Failed to copy the binaries (source/Npgsql-$PG_VERSION_Npgsql-net40)"
    cp -R Npgsql-"$PG_VERSION_NPGSQL"-net45/* Npgsql.windows/ms.net45/ || _die "Failed to copy the binaries (source/Npgsql-$PG_VERSION_Npgsql-net45)"
    cp -R Npgsql-"$PG_VERSION_NPGSQL"-apidocs/* Npgsql.windows/docs/ || _die "Failed to copy the binaries (source/Npgsql-$PG_VERSION_Npgsql-apidocs)"
    
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
    
    echo "END PREP Npgsql Windows"
}

################################################################################
# PG Build
################################################################################

_build_Npgsql_windows() {

    echo "BEGIN BUILD Npgsql Windows"

    cd $WD
    
    echo "END BUILD Npgsql Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_windows() {

    echo "BEGIN POST Npgsql Windows"
 
    cp -R $WD/Npgsql/source/Npgsql.windows/* $WD/Npgsql/staging/windows || _die "Failed to copy the Npgsql Source into the staging directory"
    chmod -R ugo+rx $WD/Npgsql/staging/windows/docs

    cd $WD/Npgsql
    
    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe"

    cd $WD

    echo "END POST Npgsql Windows"
}


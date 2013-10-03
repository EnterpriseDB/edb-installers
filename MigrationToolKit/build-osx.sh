#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_osx() {

    echo "BEGIN PREP MigrationToolKit OSX"
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationtoolkit.osx ];
    then
      echo "Removing existing migrationtoolkit.osx source directory"
      rm -rf migrationtoolkit.osx  || _die "Couldn't remove the existing migrationtoolkit.osx source directory (source/migrationtoolkit.osx)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.osx)"
    mkdir -p migrationtoolkit.osx || _die "Couldn't create the migrationtoolkit.osx directory"
    chmod ugo+w migrationtoolkit.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.osx || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the pg-jdbc driver"
    cp $WD/tarballs/edb-jdbc14.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the edb-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/osx)"
    mkdir -p $WD/MigrationToolKit/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/osx || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP MigrationToolKit OSX"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_osx() {

    echo "BEGIN BUILD MigrationToolKit OSX"

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_OSX/MigrationToolKit/staging/osx
    PG_MW_SOURCE=$WD/MigrationToolKit/source/migrationtoolkit.osx

    cd $PG_MW_SOURCE

    echo "Building migrationtoolkit"
    $PG_ANT_HOME_OSX/bin/ant clean || _die "Couldn't clean the migrationtoolkit"
    $PG_ANT_HOME_OSX/bin/ant install-pg || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    mkdir $PG_STAGING/MigrationToolKit || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolKit)"
    cp -R install/* $PG_STAGING/MigrationToolKit || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolKit)"
    
    echo "END BUILD MigrationToolKit OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_osx() {

    echo "BEGIN POST MigrationToolKit OSX"

    cd $WD/MigrationToolKit
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.zip migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    
    cd $WD
    
    echo "END POST MigrationToolKit OSX"
}


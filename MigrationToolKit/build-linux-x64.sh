#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_linux_x64() {
    
    echo "BEGIN PREP MigrationToolKit Linux-x64"
  
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.linux-x64 ];
    then
      echo "Removing existing migrationtoolkit.linux-x64 source directory"
      rm -rf migrationtoolkit.linux-x64  || _die "Couldn't remove the existing migrationtoolkit.linux-x64 source directory (source/migrationtoolkit.linux-x64)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.linux-x64)"
    mkdir -p migrationtoolkit.linux-x64 || _die "Couldn't create the migrationtoolkit.linux-x64 directory"
    chmod ugo+w migrationtoolkit.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.linux-x64 || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.linux-x64/lib/ || _die "Failed to copy the pg-jdbc driver"
    cp $WD/tarballs/edb-jdbc17.jar migrationtoolkit.linux-x64/lib/ || _die "Failed to copy the edb-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/linux-x64)"
    mkdir -p $WD/MigrationToolKit/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP MigrationToolKit Linux-x64"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_linux_x64() {

    echo "BEGIN BUILD MigrationToolKit Linux-x64"

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_LINUX_X64/MigrationToolKit/staging/linux-x64    

    echo "Building migrationtoolkit"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationToolKit/source/migrationtoolkit.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationToolKit/source/migrationtoolkit.linux-x64; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationToolKit/source/migrationtoolkit.linux-x64; mkdir $PG_STAGING/MigrationToolkit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/linux-x64/MigrationToolKit)"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MigrationToolKit/source/migrationtoolkit.linux-x64; cp -R install/* $PG_STAGING/MigrationToolkit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/linux-x64/MigrationToolKit)"

    echo "END BUILD MigrationToolKit Linux-x64"
}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_linux_x64() {

    echo "BEGIN POST MigrationToolKit Linux-x64"

    cd $WD/MigrationToolKit

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD

    echo "END POST MigrationToolKit Linux-x64"
}


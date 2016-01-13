#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_linux() {

    echo "BEGIN PREP MigrationToolKit Linux"
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.linux ];
    then
      echo "Removing existing migrationtoolkit.linux source directory"
      rm -rf migrationtoolkit.linux  || _die "Couldn't remove the existing migrationtoolkit.linux source directory (source/migrationtoolkit.linux)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.linux)"
    mkdir -p migrationtoolkit.linux || _die "Couldn't create the migrationtoolkit.linux directory"
    chmod ugo+w migrationtoolkit.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.linux || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    
    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.linux/lib/ || _die "Failed to copy the pg-jdbc driver"
    cp $WD/tarballs/edb-jdbc17.jar migrationtoolkit.linux/lib/ || _die "Failed to copy the edb-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/linux)"
    mkdir -p $WD/MigrationToolKit/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/linux || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP MigrationToolKit Linux"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_linux() {

    echo "BEGIN BUILD MigrationToolKit Linux"

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_LINUX/MigrationToolKit/staging/linux    

    echo "Building migrationtoolkit"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; mkdir $PG_STAGING/MigrationToolkit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/linux/MigrationToolkit)"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; cp -R install/* $PG_STAGING/MigrationToolkit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/linux/MigrationToolkit)"
  
    echo "END BUILD MigrationToolKit Linux" 
 
}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_linux() {

    echo "BEGIN POST MigrationToolKit Linux"

    cd $WD/MigrationToolKit

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD

    echo "END POST MigrationToolKit Linux"
}


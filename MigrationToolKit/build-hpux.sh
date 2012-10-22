#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_hpux() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.hpux ];
    then
      echo "Removing existing migrationtoolkit.hpux source directory"
      rm -rf migrationtoolkit.hpux  || _die "Couldn't remove the existing migrationtoolkit.hpux source directory (source/migrationtoolkit.hpux)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.hpux)"
    mkdir -p migrationtoolkit.hpux || _die "Couldn't create the migrationtoolkit.hpux directory"
    chmod ugo+w migrationtoolkit.hpux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.hpux || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w migrationtoolkit.hpux || _die "Couldn't set the permissions on the source directory"
    
    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.hpux/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/hpux)"
    mkdir -p $WD/MigrationToolKit/staging/hpux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/hpux || _die "Couldn't set the permissions on the staging directory"

}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_hpux() {

     zip -r migrationtoolkit.zip migrationtoolkit.hpux/ || _die "Failed to pack the source tree (migrationtoolkit.hpux)"
     ssh $PG_SSH_HPUX "mkdir -p $PG_PATH_HPUX/MigrationToolKit" || _die "Couldn't create MigrationToolKit"
     ssh $PG_SSH_HPUX "mkdir -p $PG_PATH_HPUX/MigrationToolKit/source" || _die "Couldn't create MigrationToolKit/source"
     ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source; rm -rf migrationtoolkit.*" || _die "Failed to remove the source tree on the hpux build host (migrationtoolkit.zip)"
     ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/staging; rm -rf hpux/"

    scp migrationtoolkit.zip $PG_SSH_HPUX:$PG_PATH_HPUX//MigrationToolKit/source || _die "Failed to copy the source tree to the hpux build host (migrationtoolkit.zip)"

    ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source; /usr/local/bin/unzip migrationtoolkit.zip" || _die "Failed to unzip migrationtoolkit.zip"

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_HPUX/MigrationToolKit/staging/hpux    

    echo "Building migrationtoolkit"
    ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source/migrationtoolkit.hpux; JAVA_HOME=$PG_JAVA_HOME_HPUX $PG_ANT_HOME_HPUX/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source/migrationtoolkit.hpux; JAVA_HOME=$PG_JAVA_HOME_HPUX $PG_ANT_HOME_HPUX/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source/migrationtoolkit.hpux; mkdir $PG_PATH_HPUX/MigrationToolKit/staging; mkdir $PG_STAGING; mkdir $PG_STAGING/MigrationToolKit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/hpux/MigrationToolKit)"
    ssh $PG_SSH_HPUX "cd $PG_PATH_HPUX/MigrationToolKit/source/migrationtoolkit.hpux; cp -R install/* $PG_STAGING/MigrationToolKit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/hpux/MigrationToolKit)"
    scp -r $PG_SSH_HPUX:$PG_PATH_HPUX/MigrationToolKit/staging/hpux/* $WD/MigrationToolKit/staging/hpux/ || _die "Failed to get back the staging directory from HPUX build machine."

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_hpux() {

    cd $WD/MigrationToolKit

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml hpux || _die "Failed to build the installer"
    
    cd $WD
}


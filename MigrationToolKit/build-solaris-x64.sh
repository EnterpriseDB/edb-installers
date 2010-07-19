#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_solaris_x64() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.solaris-x64 ];
    then
      echo "Removing existing migrationtoolkit.solaris-x64 source directory"
      rm -rf migrationtoolkit.solaris-x64  || _die "Couldn't remove the existing migrationtoolkit.solaris-x64 source directory (source/migrationtoolkit.solaris-x64)"
    fi

    if [ -e migrationToolKit.solaris-x64.zip ];
    then
      echo "Removing existing migrationtoolkit.solaris-x64 zip file"
      rm -rf migrationtoolkit.solaris-x64.zip  || _die "Couldn't remove the existing migrationtoolkit.solaris-x64 zip file (source/migrationtoolkit.solaris-x64.zip)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.solaris-x64)"
    mkdir -p migrationtoolkit.solaris-x64 || _die "Couldn't create the migrationtoolkit.solaris-x64 directory"
    chmod ugo+w migrationtoolkit.solaris-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.solaris-x64 || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w migrationtoolkit.solaris-x64 || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc3.jar migrationtoolkit.solaris-x64/lib/ || _die "Failed to copy the pg-jdbc driver"
    zip -r migrationtoolkit.solaris-x64.zip migrationtoolkit.solaris-x64 || _die "Failed to zip the migrationtoolkit source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/solaris-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/solaris-x64 || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/MigrationToolKit/staging/solaris-x64" || _die "Failed to remove the migrationtoolkit staging directory from the Solaris VM"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/solaris-x64)"
    mkdir -p $WD/MigrationToolKit/staging/solaris-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/solaris-x64 || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/MigrationToolKit/source" || _die "Failed to remove the migrationtoolkit source directory from the Solaris VM"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/MigrationToolKit/source" || _die "Failed to create the migrationtoolkit source directory on the Solaris VM"
    scp migrationtoolkit.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/MigrationToolKit/source 
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/MigrationToolKit/source; unzip migrationtoolkit.solaris-x64.zip" || _die "Failed to create the migrationtoolkit source directory on the Solaris VM"
    
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/MigrationToolKit/staging/solaris-x64" || _die "Failed to create the migrationtoolkit staging directory on the Solaris VM"

}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_solaris_x64() {

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_SOLARIS_X64/MigrationToolKit/staging/solaris-x64    

    echo "Building migrationtoolkit"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/MigrationToolKit/source/migrationtoolkit.solaris-x64; PATH=$PG_JAVA_HOME_SOLARIS_X64/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_X64 $PG_ANT_HOME_SOLARIS_X64/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/MigrationToolKit/source/migrationtoolkit.solaris-x64; PATH=$PG_JAVA_HOME_SOLARIS_X64/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_X64 $PG_ANT_HOME_SOLARIS_X64/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/MigrationToolKit/source/migrationtoolkit.solaris-x64; mkdir $PG_STAGING/MigrationToolKit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/solaris-x64/MigrationToolKit)"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/MigrationToolKit/source/migrationtoolkit.solaris-x64; cp -R install/* $PG_STAGING/MigrationToolKit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/solaris-x64/MigrationToolKit)"
    
    scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/MigrationToolKit/staging/solaris-x64/* $WD/MigrationToolKit/staging/solaris-x64/ || _die "Failed to get back the staging directory from Solaris VM"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_solaris_x64() {

    cd $WD/MigrationToolKit

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-intel || _die "Failed to build the installer"
   
    mv $WD/output/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-solaris-intel.bin $WD/output/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-solaris-x64.bin 
    cd $WD
}


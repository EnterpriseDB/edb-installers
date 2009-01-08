#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.linux ];
    then
      echo "Removing existing pgAgent.linux source directory"
      rm -rf pgAgent.linux  || _die "Couldn't remove the existing pgAgent.linux source directory (source/pgAgent.linux)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.linux)"
    mkdir -p $WD/pgAgent/source/pgAgent.linux || _die "Couldn't create the pgAgent.linux directory"
    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.linux || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT-Source)"
    chmod -R ugo+w pgAgent.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/linux)"
    mkdir -p $WD/pgAgent/staging/linux || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgAgent_linux() {

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_LINUX/pgAgent/staging/linux
    SOURCE_DIR=$PG_PATH_LINUX/pgAgent/source/pgAgent.linux

    echo "Building pgAgent sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; cmake CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make" || _die "Couldn't compile the pgAgent sources"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_linux() {


    cp -R $WD/pgAgent/source/pgAgent.linux/* $WD/pgAgent/staging/linux || _die "Failed to copy the pgAgent Source into the staging directory"
    
    cd $WD/pgAgent

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pgAgent || _die "Failed to create a directory for the install scripts"

     cp scripts/linux/check-connection.sh staging/linux/installer/pgAgent/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/pgAgent/check-connection.sh

     cp scripts/linux/install.sh staging/linux/installer/pgAgent/install.sh || _die "Failed to copy the install script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux/installer/pgAgent/install.sh

     cp scripts/linux/pgpass staging/linux/installer/pgAgent/pgpass || _die "Failed to copy the pgpass file (scripts/linux/pgpass)"
    chmod ugo+x staging/linux/installer/pgAgent/pgpass

     cp $WD/server/scripts/linux/createuser.sh staging/linux/installer/pgAgent/createuser.sh || _die "Failed to copy the createuser script ($WD/server/scripts/linux/createuser.sh)"
    chmod ugo+x staging/linux/installer/pgAgent/createuser.sh

     cp scripts/linux/check-pgversion.sh staging/linux/installer/pgAgent/check-pgversion.sh || _die "Failed to copy the check-pgversion script ($WD/PostGIS/scripts/linux/check-pgversion.sh)"
    chmod ugo+x staging/linux/installer/pgAgent/check-pgversion.sh

     cp scripts/linux/startupcfg.sh staging/linux/installer/pgAgent/startupcfg.sh || _die "Failed to copy the install script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux/installer/pgAgent/startupcfg.sh

    # Setup the pgAgent Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the pgAgent Launch Scripts"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.linux-x64 ];
    then
      echo "Removing existing pgAgent.linux-x64 source directory"
      rm -rf pgAgent.linux-x64  || _die "Couldn't remove the existing pgAgent.linux-x64 source directory (source/pgAgent.linux-x64)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.linux-x64)"
    mkdir -p $WD/pgAgent/source/pgAgent.linux-x64 || _die "Couldn't create the pgAgent.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.linux-x64 || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    chmod -R ugo+w pgAgent.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/linux-x64)"
    mkdir -p $WD/pgAgent/staging/linux-x64 || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgAgent_linux_x64() {

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_LINUX_X64/pgAgent/staging/linux-x64
    SOURCE_DIR=$PG_PATH_LINUX_X64/pgAgent/source/pgAgent.linux-x64

    echo "Building pgAgent sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; cmake CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; make" || _die "Couldn't compile the pgAgent sources"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_linux_x64() {


    cp -R $WD/pgAgent/source/pgAgent.linux-x64/* $WD/pgAgent/staging/linux-x64 || _die "Failed to copy the pgAgent Source into the staging directory"

    cd $WD/pgAgent

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/check-connection.sh staging/linux-x64/installer/pgAgent/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/check-connection.sh

    cp scripts/linux/install.sh staging/linux-x64/installer/pgAgent/install.sh || _die "Failed to copy the install script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/install.sh

    cp scripts/linux/pgpass staging/linux-x64/installer/pgAgent/pgpass || _die "Failed to copy the pgpass file (scripts/linux/pgpass)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/pgpass

    cp $WD/server/scripts/linux/createuser.sh staging/linux-x64/installer/pgAgent/createuser.sh || _die "Failed to copy the createuser script ($WD/server/scripts/linux/createuser.sh)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/createuser.sh

    cp scripts/linux/check-pgversion.sh staging/linux-x64/installer/pgAgent/check-pgversion.sh || _die "Failed to copy the check-pgversion script ($WD/PostGIS/scripts/linux/check-pgversion.sh)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/check-pgversion.sh

    cp scripts/linux/startupcfg.sh staging/linux-x64/installer/pgAgent/startupcfg.sh || _die "Failed to copy the install script (scripts/linux-x64/startupcfg.sh)"
    chmod ugo+x staging/linux-x64/installer/pgAgent/startupcfg.sh

    # Setup the pgAgent Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the pgAgent Launch Scripts"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


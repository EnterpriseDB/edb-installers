#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
	
    if [ -e pgAgent.osx ];
    then
      echo "Removing existing pgAgent.osx source directory"
      rm -rf pgAgent.osx  || _die "Couldn't remove the existing pgAgent.osx source directory (source/pgAgent.osx)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.osx)"
    mkdir -p $WD/pgAgent/source/pgAgent.osx || _die "Couldn't create the pgAgent.osx directory"
	
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.osx || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    chmod -R ugo+w pgAgent.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/osx)"
    mkdir -p $WD/pgAgent/staging/osx || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgAgent_osx() {

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_OSX/pgAgent/staging/osx
    SOURCE_DIR=$PG_PATH_OSX/pgAgent/source/pgAgent.osx

    echo "Building pgAgent sources"
    cd $SOURCE_DIR
    export PGDIR=$PG_PGHOME_OSX
    cmake CMakeLists.txt || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    cd $SOURCE_DIR
    make || _die "Couldn't compile the pgAgent sources"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_osx() {


    cp -R $WD/pgAgent/source/pgAgent.osx/* $WD/pgAgent/staging/osx || _die "Failed to copy the pgAgent Source into the staging directory"

    cd $WD/pgAgent

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/check-connection.sh staging/osx/installer/pgAgent/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/check-connection.sh

     cp scripts/osx/install.sh staging/osx/installer/pgAgent/install.sh || _die "Failed to copy the install script (scripts/osx/install.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/install.sh

    cp scripts/osx/pgpass staging/osx/installer/pgAgent/pgpass || _die "Failed to copy the pgpass file (scripts/osx/pgpass)"
    chmod ugo+x staging/osx/installer/pgAgent/pgpass

    cp $WD/server/scripts/osx/createuser.sh staging/osx/installer/pgAgent/createuser.sh || _die "Failed to copy the createuser script ($WD/server/scripts/osx/createuser.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/createuser.sh

    cp scripts/osx/check-pgversion.sh staging/osx/installer/pgAgent/check-pgversion.sh || _die "Failed to copy the check-pgversion script ($WD/PostGIS/scripts/osx/check-pgversion.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/check-pgversion.sh

    cp scripts/osx/startupcfg.sh staging/osx/installer/pgAgent/startupcfg.sh || _die "Failed to copy the install script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/startupcfg.sh

    cp scripts/osx/pgagentctl.sh staging/osx/installer/pgAgent/pgagentctl.sh || _die "Failed to copy the install script (scripts/osx/pgagentctl.sh)"
    chmod ugo+x staging/osx/installer/pgAgent/pgagentctl.sh

    # Setup the pgAgent Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the pgAgent Launch Scripts"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgAgent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip pgAgent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgAgent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD

}


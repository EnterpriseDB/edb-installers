#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphqagent_osx() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ Agent (OSX)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/osx
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PPHQAGENT_STAGING_DIR ];
    then
      echo "Removing existing staging directory"
      rm -rf $PPHQAGENT_STAGING_DIR || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($PPHQAGENT_STAGING_DIR)"
    mkdir -p $PPHQAGENT_STAGING_DIR || _die "Couldn't create the staging directory"
    chmod ugo+w $PPHQAGENT_STAGING_DIR || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Agent Build
################################################################################

_build_pphqagent_osx() {

    echo "*******************************************************"
    echo " Build : PPHQ Agent (OSX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/hqagent/staging/osx
    mkdir -p $PPHQ_STAGING/ || _die "Failed to create the pphq installer directory"

    echo "Copying PPHQ Agent binaries to staging directory"
    cd $PPHQ_STAGING/
    tar -zxf $WD/pphq/source/hq/build/archive/hyperic-hq-installer/agent-$PG_VERSION_HQAGENT.tgz || _die "Couldn't extract agent binaries"

    cd $WD

}

################################################################################
# PPHQ Agent Build
################################################################################

_postprocess_pphqagent_osx() {

    echo "*******************************************************"
    echo " Post Process : PPHQ Agent (OSX)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/osx
    PPHQAGENT_DIR=$WD/hqagent
    PPHQ_DIR=$WD/pphq
    cd $PPHQAGENT_DIR

    # Setup the installer scripts.
    mkdir -p $PPHQAGENT_STAGING_DIR/installer/pphqagent || _die "Failed to create a directory for the install scripts"
    cp $PPHQ_DIR/scripts/osx/createuser.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the createuser script"
    cp $PPHQ_DIR/scripts/osx/startupcfg.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the startupcfg sscript"
    cp $PPHQAGENT_DIR/scripts/osx/createshortcuts.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the createshortcuts script"
    chmod ugo+x $PPHQAGENT_STAGING_DIR/installer/pphqagent/*.sh

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p $PPHQAGENT_STAGING_DIR/scripts || _die "Failed to create a directory for the launch scripts"
    cp $PPHQ_DIR/scripts/osx/agent-start.applescript.in $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to to the agent-start.applescript"
    cp $PPHQ_DIR/scripts/osx/agent-stop.applescript.in $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to to the agent-stop.applescript"

    # Copy in the menu pick images
    mkdir -p $PPHQAGENT_STAGING_DIR/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQAGENT_DIR/resources/*.icns $PPHQAGENT_STAGING_DIR/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pphqagent-$PG_VERSION_HQAGENT-$PG_BUILDNUM_HQAGENT-osx.zip pphqagent-$PG_VERSION_HQAGENT-$PG_BUILDNUM_HQAGENT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pphqagent-$PG_VERSION_HQAGENT-$PG_BUILDNUM_HQAGENT-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


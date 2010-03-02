#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphq_osx() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ (OSX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/osx

    if [ -e $PPHQ_STAGING ];
    then
      echo "Removing existing staging directory"
      rm -rf $PPHQ_STAGING || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($PPHQ_STAGING)"
    mkdir -p $PPHQ_STAGING || _die "Couldn't create the staging directory"
    chmod ugo+w $PPHQ_STAGING || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Build
################################################################################

_build_pphq_osx() {

    echo "*******************************************************"
    echo " Build : PPHQ (OSX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/osx
    SERVER_STAGING=$WD/server/staging/osx

    mkdir -p $PPHQ_STAGING/pphq || _die "Failed to create the pphq installer directory"
    mkdir -p $PPHQ_STAGING/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/bin || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/lib || _die "Failed to create the instscripts directory"

    echo "Copying Postgres Plus HQ installer to staging directory"
    cp -r $WD/pphq/source/hq/build/archive/hyperic-hq-installer/* $PPHQ_STAGING/pphq/

    mkdir -p $PPHQ_STAGING/pphq/templates
    cp $WD/pphq/resources/*.prop $PPHQ_STAGING/pphq/templates

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp $SERVER_STAGING/bin/psql $PPHQ_STAGING/instscripts/bin || _die "Failed to copy psql"
    cp $SERVER_STAGING/lib/libpq.*dylib $PPHQ_STAGING/instscripts/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"
    cp $SERVER_STAGING/lib/libxml2* $PPHQ_STAGING/instscripts/lib || _die "Failed to copy the latest libxml2"

}

################################################################################
# PPHQ PostProcess
################################################################################

_postprocess_pphq_osx() {

    echo "*******************************************************"
    echo " Post Process : PPHQ (OSX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/osx
    PPHQ_DIR=$WD/pphq

    cd $PPHQ_DIR

    mkdir -p $PPHQ_STAGING/installer/pphq || _die "Failed to create a directory for the install scripts"
    cp $PPHQ_DIR/scripts/osx/createuser.sh $PPHQ_STAGING/installer/pphq
    cp $PPHQ_DIR/scripts/tune-os.sh $PPHQ_STAGING/installer/pphq/tune-os.sh || _die "Failed to copy the tune-os.sh script"
    cp $PPHQ_DIR/scripts/osx/createshortcuts.sh $PPHQ_STAGING/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script"
    cp $PPHQ_DIR/scripts/osx/startupcfg.sh $PPHQ_STAGING/installer/pphq/ || _die "Failed to copy the startupcfg.sh script"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/*.sh

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p $PPHQ_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp $PPHQ_DIR/scripts/osx/pphq-launch.applescript.in $PPHQ_STAGING/scripts/pphq-launch.applescript || _die "Failed to copy pphq-launch.applescript.in"
    cp $PPHQ_DIR/scripts/osx/server-start.applescript.in $PPHQ_STAGING/scripts/server-start.applescript || _die "Failed to copy server-start.applescript.in"
    cp $PPHQ_DIR/scripts/osx/server-stop.applescript.in $PPHQ_STAGING/scripts/server-stop.applescript || _die "Failed to copy server-stop.applescript.in"
    cp $PPHQ_DIR/scripts/osx/agent-start.applescript.in $PPHQ_STAGING/scripts/agent-start.applescript || _die "Failed to copy agent-start.applescript.in"
    cp $PPHQ_DIR/scripts/osx/agent-stop.applescript.in $PPHQ_STAGING/scripts/agent-stop.applescript || _die "Failed to copy agent-stop.applescript.in"
    cp $PPHQ_DIR/scripts/osx/serverctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy agent-stop.applescript.in"
    cp $PPHQ_DIR/scripts/osx/agentctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy agent-stop.applescript.in"
    chmod ugo+x $PPHQ_STAGING/scripts/*.sh

    # Copy in the menu pick images
    mkdir -p $PPHQ_STAGING/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQ_DIR/resources/*.icns $PPHQ_STAGING/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.zip pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


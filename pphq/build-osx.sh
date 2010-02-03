#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pphq_osx() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ (OSX)"
    echo "*******************************************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/osx)"
    mkdir -p $WD/pphq/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/osx || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Build
################################################################################

_build_pphq_osx() {

    echo "*******************************************************"
    echo " Build : PPHQ (OSX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/osx
    mkdir -p $PPHQ_STAGING/pphq
    mkdir -p $PPHQ_STAGING/instscripts
    mkdir -p $PPHQ_STAGING/instscripts/lib
    mkdir -p $PPHQ_STAGING/instscripts/bin

    echo "Copying Postgres Plus HQ installer to staging directory"
    cp -r $WD/pphq/source/hq/build/archive/hyperic-hq-installer/* $PPHQ_STAGING/pphq

    mkdir -p $PPHQ_STAGING/pphq/templates
    cp $WD/pphq/resources/*.prop $PPHQ_STAGING/pphq/templates

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp $PG_PGHOME_OSX/bin/psql $PPHQ_STAGING/instscripts/bin || _die "Failed to copy psql"
    cp $PG_PGHOME_OSX/lib/libpq.*dylib $PPHQ_STAGING/instscripts/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"
    cp $PG_PGHOME_OSX/lib/libxml2* $PPHQ_STAGING/instscripts/lib || _die "Failed to copy the latest libxml2"

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
    cd $WD/pphq

    # Setup the installer scripts.
    mkdir -p $PPHQ_STAGING/installer/pphq || _die "Failed to create a directory for the install scripts"

    cp $PPHQ_DIR/scripts/tune-os.sh $PPHQ_STAGING/installer/pphq/tune-os.sh || _die "Failed to copy the tune-os.sh script (scripts/tune-os.sh)"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/tune-os.sh
    cp $PPHQ_DIR/scripts/osx/createshortcuts.sh $PPHQ_STAGING/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/createshortcuts.sh

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p $PPHQ_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp $PPHQ_DIR/scripts/osx/pphq-launch.applescript.in $PPHQ_STAGING/scripts/pphq-launch.applescript || _die "Failed to to the menu pick script (scripts/osx/pphq-launch.applescript.in)"
    cp $PPHQ_DIR/scripts/osx/server-start.applescript.in $PPHQ_STAGING/scripts/server-start.applescript || _die "Failed to to the menu pick script (scripts/osx/server-start.applescript.in)"
    cp $PPHQ_DIR/scripts/osx/server-stop.applescript.in $PPHQ_STAGING/scripts/server-stop.applescript || _die "Failed to to the menu pick script (scripts/osx/server-stop.applescript.in)"
    cp $PPHQ_DIR/scripts/osx/agent-start.applescript.in $PPHQ_STAGING/scripts/agent-start.applescript || _die "Failed to to the menu pick script (scripts/osx/agent-start.applescript.in)"
    cp $PPHQ_DIR/scripts/osx/agent-stop.applescript.in $PPHQ_STAGING/scripts/agent-stop.applescript || _die "Failed to to the menu pick script (scripts/osx/agent-stop.applescript.in)"

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


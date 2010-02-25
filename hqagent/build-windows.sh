#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphqagent_windows() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ Agent (WINDOWS)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/windows
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

_build_pphqagent_windows() {

    echo "*******************************************************"
    echo " Build : PPHQ Agent (WINDOWS)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/hqagent/staging/windows

    echo "Copying PPHQ Agent binaries to staging directory"
    cd $PPHQ_STAGING/
    tar -zxf $WD/pphq/source/hq/build/archive/hyperic-hq-installer/agent-$PG_VERSION_HQAGENT.tgz || _die "Couldn't extract agent binaries"

    echo "Copying JRE to staging directory"
    tar -jxf $WD/tarballs/jre6-windows.tar.bz2 || _die "Couldn't extract the JRE"

    cd $WD

}

################################################################################
# PPHQ Agent Build
################################################################################

_postprocess_pphqagent_windows() {

    echo "*******************************************************"
    echo " Post Process : PPHQ Agent (WINDOWS)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/windows
    PPHQAGENT_DIR=$WD/hqagent
    PPHQ_DIR=$WD/pphq
    cd $PPHQAGENT_DIR

    # Copy in the menu pick images
    mkdir -p $PPHQAGENT_STAGING_DIR/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQ_DIR/scripts/windows/runProgram.vbs $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to copy runProgram.vbs script"
    cp $PPHQ_DIR/scripts/windows/shortPathName.vbs $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to copy shortPathName.vbs script"
    cp $PPHQAGENT_DIR/resources/*.ico $PPHQAGENT_STAGING_DIR/scripts/images || _die "Failed to copy the menu pick images (resources/*.ico)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    # Sign the installer
    win32_sign "pphqagent-$PG_VERSION_HQAGENT-$PG_BUILDNUM_HQAGENT-windows.exe"

    cd $WD

}


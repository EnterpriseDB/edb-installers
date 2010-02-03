#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphq_windows() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ (WINDOWS)"
    echo "*******************************************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/windows)"
    mkdir -p $WD/pphq/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/windows || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Build
################################################################################

_build_pphq_windows() {

    echo "*******************************************************"
    echo " Build : PPHQ (WINDOWS)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/windows
    SERVER_STAGING=$WD/server/staging/windows
    echo ""
    echo "Copying Postgres Plus installers to staging directory"
    mkdir -p $PPHQ_STAGING/pphq || _die "Failed to create the pphq installer directory"
    cp -r $WD/pphq/source/hq/build/archive/hyperic-hq-installer/* $PPHQ_STAGING/pphq/

    mkdir -p $PPHQ_STAGING/pphq/templates
    cp $WD/pphq/resources/*.prop $PPHQ_STAGING/pphq/templates

    # Copy the various support files into place
    mkdir -p $PPHQ_STAGING/instscripts || _die "Failed to create the instscripts directory"
    cp $SERVER_STAGING/lib/libpq* $PPHQ_STAGING/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp $SERVER_STAGING/bin/psql.exe $PPHQ_STAGING/instscripts/ || _die "Failed to copy psql in instscripts"
    cp $SERVER_STAGING/bin/gssapi32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/ssleay32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libeay32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/iconv.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libintl-8.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libiconv-2.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libiconv-2.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/comerr32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/krb5_32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/k5sprt32.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libxml2.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/libxslt.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/zlib1.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/bin/msvcr71.dll $PPHQ_STAGING/instscripts/ || _die "Failed to copy dependent libs"
    cp $SERVER_STAGING/installer/vcredist_x86.exe $PPHQ_STAGING/ || _die "Failed to copy the VC++ runtimes"
    cp $WD/pphq/scripts/windows/installruntimes.vbs $PPHQ_STAGING/ || _die "Failed to copy the installruntimes script ($PPHQ_STAGING)"

}


################################################################################
# PPHQ Post-Process
################################################################################

_postprocess_pphq_windows() {

    echo "*******************************************************"
    echo " Post Process : PPHQ (WINDOWS)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/windows
    PPHQ_DIR=$WD/pphq
    SERVER_STAGING=$WD/server/staging/windows

    cd $WD/pphq


    # Copy in the menu pick images
    mkdir -p $PPHQ_STAGING/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQ_DIR/scripts/windows/runProgram.vbs $PPHQ_STAGING/scripts/ || _die "Failed to copy runProgram.vbs script"
    cp $PPHQ_DIR/scripts/windows/shortPathName.vbs $PPHQ_STAGING/scripts/ || _die "Failed to copy runProgram.vbs script"
    cp $PPHQ_DIR/resources/*.ico $PPHQ_STAGING/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-windows.exe"

    cd $WD
}


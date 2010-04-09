#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_TuningWizard_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/TuningWizard/source

    if [ -e tuningwizard.osx ];
    then
      echo "Removing existing tuningwizard.osx source directory"
      rm -rf tuningwizard.osx  || _die "Couldn't remove the existing tuningwizard.osx source directory (source/tuningwizard.osx)"
    fi

    echo "Creating tuningwizard source directory ($WD/TuningWizard/source/tuningwizard.osx)"
    mkdir -p tuningwizard.osx || _die "Couldn't create the tuningwizard.osx directory"
    chmod ugo+w tuningwizard.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the tuningwizard source tree
    cp -R wizard/* tuningwizard.osx || _die "Failed to copy the source code (source/tuningwizard-$PG_VERSION_TUNINGWIZARD)"
    chmod -R ugo+w tuningwizard.osx || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/TuningWizard/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/TuningWizard/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/TuningWizard/staging/osx)"
    mkdir -p $WD/TuningWizard/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/TuningWizard/staging/osx || _die "Couldn't set the permissions on the staging directory"

}


################################################################################
# PG Build
################################################################################

_build_TuningWizard_osx() {

    # build tuningwizard    
    PG_STAGING=$PG_PATH_OSX/TuningWizard/staging/osx    
    cd $PG_PATH_OSX/TuningWizard/source/tuningwizard.osx

    echo "Configuring the tuningwizard source tree"
    cmake -D CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" -D wxWidgets_CONFIG_EXECUTABLE=/usr/local/bin/wx-config -D OPENSSL_INCLUDE_DIR=/opt/local/include -D OPENSSL_LIBRARIES=/opt/local/lib/libssl.a -D CRYPTO_LIBRARIES=/opt/local/lib/libcrypto.a -D UUID_LIBRARIES=/opt/local/lib/libuuid.a CMakeLists.txt || _die "Failed configuring(cmake) TuningWizard"
  
    echo "Building tuningwizard"
    make || _die "Failed to build TuningWizard"

    # Copying the TuningWizard binary to staging directory
    mkdir $PG_STAGING/TuningWizard
    cp -R TuningWizard.app $PG_STAGING/TuningWizard/TuningWizard.app || _die "Failed copying TuningWizard.app to staging directory"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/TuningWizard/staging/osx/TuningWizard TuningWizard.app/Contents/MacOS @loader_path/../../.. || _die "Failed rewriting references"

}


################################################################################
# PG Build
################################################################################

_postprocess_TuningWizard_osx() {

    cd $WD/TuningWizard

    mkdir -p staging/osx/installer/TuningWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/TuningWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"

    chmod ugo+x staging/osx/installer/TuningWizard/createshortcuts.sh
    
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pg-launchTuningWizard.applescript.in staging/osx/scripts/pg-launchTuningWizard.applescript || _die "Failed to copy applescript (scripts/osx/pg-launchTuningWizard.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchTuningWizard.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchTuningWizard.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r tuningwizard-$PG_VERSION_TUNINGWIZARD-$PG_BUILDNUM_TUNINGWIZARD-osx.zip tuningwizard-$PG_VERSION_TUNINGWIZARD-$PG_BUILDNUM_TUNINGWIZARD-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf tuningwizard-$PG_VERSION_TUNINGWIZARD-$PG_BUILDNUM_TUNINGWIZARD-osx.app/ || _die "Failed to remove the unpacked installer bundle"
       
    cd $WD
}


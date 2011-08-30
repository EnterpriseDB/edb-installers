#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ];
then
    source $WD/Drupal7/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Drupal7/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/Drupal7/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Drupal7/build-windows.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_Drupal7() {

    # Create the source directory if required
    if [ ! -e $WD/Drupal7/source ];
    then
        mkdir $WD/Drupal7/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/Drupal7/source

    # Drupal7
    if [ -e drupal-$PG_VERSION_DRUPAL7 ];
    then
      echo "Removing existing drupal-$PG_VERSION_DRUPAL7 source directory"
      rm -rf drupal-$PG_VERSION_DRUPAL7  || _die "Couldn't remove the existing drupal-$PG_VERSION_DRUPAL7 source directory (source/drupal-$PG_VERSION_DRUPAL7)"
    fi

    echo "Unpacking Drupal7 source..."
    extract_file  ../../tarballs/drupal-$PG_VERSION_DRUPAL7 || exit 1

    # Per-platform prep
    cd $WD

    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ];
    then
        _prep_Drupal7_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Drupal7_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Drupal7_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Drupal7_windows || exit 1
    fi

}

################################################################################
# Build Drupal7
################################################################################

_build_Drupal7() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _build_Drupal7_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Drupal7_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_Drupal7_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Drupal7_windows || exit 1
    fi
}

################################################################################
# Postprocess Drupal7
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_Drupal7() {

    cd $WD/Drupal7

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (Drupal7/installer.xml.in)"

    _replace PG_VERSION_DRUPAL7 $PG_VERSION_DRUPAL7 installer.xml || _die "Failed to set the version in the installer project file (Drupal7/installer.xml)"
    _replace PG_BUILDNUM_DRUPAL7 $PG_BUILDNUM_DRUPAL7 installer.xml || _die "Failed to set the Build Number in the installer project file (Drupal7/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _postprocess_Drupal7_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Drupal7_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Drupal7_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_Drupal7_windows || exit 1
    fi
}

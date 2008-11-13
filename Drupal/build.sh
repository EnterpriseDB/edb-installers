#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/Drupal/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Drupal/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/Drupal/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Drupal/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_Drupal() {

    # Create the source directory if required
    if [ ! -e $WD/Drupal/source ];
    then
        mkdir $WD/Drupal/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/Drupal/source

    # Drupal
    if [ -e drupal-$PG_VERSION_DRUPAL ];
    then
      echo "Removing existing drupal-$PG_VERSION_DRUPAL source directory"
      rm -rf drupal-$PG_VERSION_DRUPAL  || _die "Couldn't remove the existing drupal-$PG_VERSION_DRUPAL source directory (source/drupal-$PG_VERSION_DRUPAL)"
    fi

    echo "Unpacking MediaWiki source..."
    extract_file  ../../tarballs/drupal-$PG_VERSION_DRUPAL.tar.gz || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_Drupal_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Drupal_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Drupal_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Drupal_windows || exit 1
    fi
    
}

################################################################################
# Build Drupal
################################################################################

_build_Drupal() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_Drupal_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Drupal_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_Drupal_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Drupal_windows || exit 1
    fi
}

################################################################################
# Postprocess Drupal
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_Drupal() {

    cd $WD/Drupal

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (Drupal/installer.xml.in)"

    _replace PG_VERSION_DRUPAL $PG_VERSION_DRUPAL installer.xml || _die "Failed to set the version in the installer project file (Drupal/installer.xml)"
    _replace PG_BUILDNUM_DRUPAL $PG_BUILDNUM_DRUPAL installer.xml || _die "Failed to set the Build Number in the installer project file (Drupal/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_Drupal_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Drupal_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Drupal_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_Drupal_windows || exit 1
    fi
}

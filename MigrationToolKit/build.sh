#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/MigrationToolKit/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/MigrationToolKit/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/MigrationToolKit/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/MigrationToolKit/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit() {

    # Create the source directory if required
    if [ ! -e $WD/MigrationToolKit/source ];
    then
        mkdir $WD/MigrationToolKit/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ ! -e EDB-MTK ];
    then
      echo "Fetching MigrationToolKit sources from the cvs..."
      mkdir -p EDB-MTK
      cd EDB-MTK
      cvs -d:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-MTK co . 
    else  
      cd $WD/MigrationToolKit/source/EDB-MTK
      echo "Updating MigrationToolKit sources from the cvs..."
      cvs update -dP
    fi
    
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_MigrationToolKit_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_MigrationToolKit_windows || exit 1
    fi
    
}

################################################################################
# Build MigrationToolKit
################################################################################

_build_MigrationToolKit() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_MigrationToolKit_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_MigrationToolKit_windows || exit 1
    fi
}

################################################################################
# Postprocess MigrationToolKit
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_MigrationToolKit() {

    cd $WD/MigrationToolKit


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (MigrationToolKit/installer.xml.in)"

    _replace PG_VERSION_MIGRATIONTOOLKIT $PG_VERSION_MIGRATIONTOOLKIT installer.xml || _die "Failed to set the major version in the installer project file (MigrationToolKit/installer.xml)"
    _replace PG_BUILDNUM_MIGRATIONTOOLKIT $PG_BUILDNUM_MIGRATIONTOOLKIT installer.xml || _die "Failed to set the Build Number in the installer project file (MigrationToolKit/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_MigrationToolKit_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_MigrationToolKit_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_MigrationToolKit_windows || exit 1
    fi
}

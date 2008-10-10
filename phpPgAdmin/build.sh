#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/phpPgAdmin/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/phpPgAdmin/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/phpPgAdmin/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/phpPgAdmin/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin() {

    # Create the source directory if required
    if [ ! -e $WD/phpPgAdmin/source ];
    then
        mkdir $WD/phpPgAdmin/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source

    # phpPgAdmin
    if [ -e phpPgAdmin-$PG_VERSION_PHPPGADMIN ];
    then
      echo "Removing existing phpPgAdmin-$PG_VERSION_PHPPGADMIN source directory"
      rm -rf phpPgAdmin-$PG_VERSION_PHPPGADMIN  || _die "Couldn't remove the existing phpPgAdmin-$PG_VERSION_PHPPGADMIN source directory (source/phpPgAdmin-$PG_VERSION_PHPPGADMIN)"
    fi

    echo "Unpacking phpPgAdmin source..."
    extract_file  ../../tarballs/phpPgAdmin-$PG_VERSION_PHPPGADMIN.tar.bz2 || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_phpPgAdmin_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_phpPgAdmin_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_phpPgAdmin_windows || exit 1
    fi
    
}

################################################################################
# Build phpPgAdmin
################################################################################

_build_phpPgAdmin() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_phpPgAdmin_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_phpPgAdmin_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_phpPgAdmin_windows || exit 1
    fi
}

################################################################################
# Postprocess phpPgAdmin
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_phpPgAdmin() {

    cd $WD/phpPgAdmin


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (phpPgAdmin/installer.xml.in)"

    _replace PG_VERSION_PHPPGADMIN $PG_VERSION_PHPPGADMIN installer.xml || _die "Failed to set the version in the installer project file (phpPgAdmin/installer.xml)"
    _replace PG_BUILDNUM_PHPPGADMIN $PG_BUILDNUM_PHPPGADMIN installer.xml || _die "Failed to set the Build Number in the installer project file (phpPgAdmin/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_phpPgAdmin_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_phpPgAdmin_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_phpPgAdmin_windows || exit 1
    fi
}

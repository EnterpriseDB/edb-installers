#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pgphonehome/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pgphonehome/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pgphonehome/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pgphonehome/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome() {

    # Create the source directory if required
    if [ ! -e $WD/pgphonehome/source ];
    then
        mkdir $WD/pgphonehome/source
    fi
   
    if [ ! -e $WD/pgphonehome/source/PGPHONEHOME ];
    then
         cd $WD/pgphonehome/source
         git clone ssh://pginstaller@scm.enterprisedb.com/git/PGPHONEHOME
    else
        # Enter the source directory and cleanup if required
        cd $WD/pgphonehome/source/PGPHONEHOME

        # Updating to the latest source (from git)
        git pull
    fi
 
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pgphonehome_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgphonehome_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pgphonehome_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pgphonehome_windows || exit 1
    fi
    
}

################################################################################
# Build pgphonehome
################################################################################

_build_pgphonehome() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pgphonehome_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgphonehome_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_pgphonehome_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pgphonehome_windows || exit 1
    fi
}

################################################################################
# Postprocess pgphonehome
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgphonehome() {

    cd $WD/pgphonehome


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgphonehome/installer.xml.in)"

    _replace PG_VERSION_PGPHONEHOME $PG_VERSION_PGPHONEHOME installer.xml || _die "Failed to set the version in the installer project file (pgphonehome/installer.xml)"
    _replace PG_BUILDNUM_PGPHONEHOME $PG_BUILDNUM_PGPHONEHOME installer.xml || _die "Failed to set the Build Numer in the installer project file (pgphonehome/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pgphonehome_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgphonehome_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pgphonehome_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_pgphonehome_windows || exit 1
    fi
}

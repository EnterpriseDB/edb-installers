#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
   source $WD/pgAgent/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pgAgent/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
   source $WD/pgAgent/build-linux-x64.sh
fi

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
   source $WD/pgAgent/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pgAgent/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent() {

    # Create the source directory if required
    if [ ! -e $WD/pgAgent/source ];
    then
        mkdir $WD/pgAgent/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source

    # pgAgent
    if [ -e pgAgent-$PG_VERSION_PGAGENT-Source ];
    then
      echo "Removing existing pgAgent-$PG_VERSION_PGAGENT-Source source directory"
      rm -rf pgAgent-$PG_VERSION_PGAGENT-Source  || _die "Couldn't remove the existing pgAgent-$PG_VERSION_PGAGENT-Source source directory (source/pgAgent-$PG_VERSION_PGAGENT-Source)"
    fi

    echo "Unpacking pgAgent source..."
    extract_file  ../../tarballs/pgAgent-$PG_VERSION_PGAGENT-Source || exit 1
    cd pgAgent-$PG_VERSION_PGAGENT-Source
    #patch -p1 < $WD/tarballs/pgAgent-Lion.patch # This is not required to build pgAgent3.3.0. Hence, commenting this.
    
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       _prep_pgAgent_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgAgent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _prep_pgAgent_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
       #_prep_pgAgent_linux_ppc64 || exit 1
       echo "Linux-PPC64 build pre-process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pgAgent_windows || exit 1
    fi
    
}

################################################################################
# Build pgAgent
################################################################################

_build_pgAgent() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       _build_pgAgent_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgAgent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
      _build_pgAgent_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
      #_build_pgAgent_linux_ppc64 || exit 1
      echo "Linux-PPC64 build process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pgAgent_windows || exit 1
    fi
}

################################################################################
# Postprocess pgAgent
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgAgent() {

    cd $WD/pgAgent


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi

    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgAgent/installer.xml.in)"

    _replace PG_VERSION_PGAGENT $PG_VERSION_PGAGENT installer.xml || _die "Failed to set the version in the installer project file (pgAgent/installer.xml)"
    _replace PG_BUILDNUM_PGAGENT $PG_BUILDNUM_PGAGENT installer.xml || _die "Failed to set the Build Number in the installer project file (pgAgent/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       _postprocess_pgAgent_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgAgent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
      _postprocess_pgAgent_linux_x64 || exit 1
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
      _postprocess_pgAgent_linux_ppc64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_pgAgent_windows || exit 1
    fi
}

#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/Slony/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Slony/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/Slony/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Slony/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_Slony() {

    # Create the source directory if required
    if [ ! -e $WD/Slony/source ];
    then
        mkdir $WD/Slony/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    #postgresql for windows
    if [ ! -e postgresql-$PG_TARBALL_POSTGRESQL ];
    then
      extract_file  ../../tarballs/postgresql-$PG_TARBALL_POSTGRESQL || exit 1
      cd postgresql-$PG_TARBALL_POSTGRESQL
      patch -p0 < ../../../tarballs/mingw_build.patch
    fi

    cd $WD/Slony/source

    # SLONY
    if [ -e slony1-$PG_VERSION_SLONY ];
    then
      echo "Removing existing SLONY-$PG_VERSION_SLONY source directory"
      rm -rf slony1-$PG_VERSION_SLONY  || _die "Couldn't remove the existing slony1-$PG_VERSION_SLONY source directory (source/slony1--$PG_VERSION_SLONY)"
    fi

    echo "Unpacking SLONY source..."
    extract_file  $WD/tarballs/slony1-$PG_VERSION_SLONY || exit 1

    cd slony1-$PG_VERSION_SLONY
    patch -p0 < $WD/tarballs/slony-postgresql-8.4.patch  

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_Slony_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Slony_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Slony_windows || exit 1
    fi

}

################################################################################
# Build Slony
################################################################################

_build_Slony() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_Slony_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_Slony_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Slony_windows || exit 1
    fi
}

################################################################################
# Postprocess Slony
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_Slony() {
    cd $WD/Slony

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (Slony/installer.xml.in)"
 
     PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`

     SLONY_MAJOR_VERSION=`echo $PG_VERSION_SLONY | cut -f1,2 -d "."`
 
    _replace PG_VERSION_SLONY "$PG_VERSION_SLONY" installer.xml || _die "Failed to set the major version in the installer project file (Slony/installer.xml)"
    _replace PG_BUILDNUM_SLONY $PG_BUILDNUM_SLONY installer.xml || _die "Failed to set the Build Number in the installer project file (Slony/installer.xml)"
    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION installer.xml || _die "Failed to set the Major Number in the installer project file (Slony/installer.xml)"
    _replace SLONY_MAJOR_VERSION $SLONY_MAJOR_VERSION installer.xml || _die "Failed to set the Slony Major Number in the installer project file (Slony/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the PG Major Number in the installer project file (Slony/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_Slony_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Slony_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_Slony_windows || exit 1
    fi
}


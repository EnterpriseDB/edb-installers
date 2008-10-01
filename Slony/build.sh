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
    #source $WD/Slony/build-windows.sh
    echo "Not yet implemented" 
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


    # SLONY
    if [ -e slony1-$PG_VERSION_SLONY ];
    then
      echo "Removing existing SLONY-$PG_VERSION_SLONY source directory"
      rm -rf slony1-$PG_VERSION_SLONY  || _die "Couldn't remove the existing slony1-$PG_VERSION_SLONY source directory (source/slony1--$PG_VERSION_SLONY)"
    fi

    echo "Unpacking SLONY source..."
    extract_file  $WD/tarballs/slony1-$PG_VERSION_SLONY.tar.bz2 || exit 1 

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
        #_prep_Slony_windows || exit 1
        echo "Not yet implemented" 
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
        #_build_Slony_windows || exit 1
        echo "Not yet implemented" 
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
 
    _replace PG_VERSION_SLONY "PG$PG_CURRENT_VERSION-$PG_VERSION_SLONY" installer.xml || _die "Failed to set the major version in the installer project file (Slony/installer.xml)"
    _replace PG_PACKAGE_SLONY $PG_PACKAGE_SLONY installer.xml || _die "Failed to set the Build Number in the installer project file (Slony/installer.xml)"
    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION installer.xml || _die "Failed to set the Major Number in the installer project file (Slony/installer.xml)"

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
        #_postprocess_Slony_windows || exit 1
        echo "Not yet implemented" 
    fi
}


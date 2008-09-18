#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/Slony/build-osx.sh
    echo "Not yet implemented" 
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Slony/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/Slony/build-linux-x64.sh
    echo "Not yet implemented" 
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
    if [ -e SLONY-$PG_SLONY_TARBALL ];
    then
      echo "Removing existing SLONY-$PG_SLONY_TARBALL source directory"
      rm -rf slony$PG_SLONY_TARBALL  || _die "Couldn't remove the existing slony$PG_SLONY_TARBALL source directory (source/SLONY-$PG_SLONY_TARBALL)"
    fi

    echo "Unpacking SLONY source..."
    tar -jxvf $WD/tarballs/slony$PG_SLONY_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_Slony_osx || exit 1
        echo "Not yet implemented" 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_Slony_linux_x64 || exit 1
        echo "Not yet implemented" 
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
        #_build_Slony_osx || exit 1
        echo "Not yet implemented" 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_Slony_linux_x64 || exit 1
        echo "Not yet implemented" 
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


    _replace PG_SLONY_VERSION $PG_SLONY_VERSION installer.xml || _die "Failed to set the major version in the installer project file (Slony/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_Slony_osx || exit 1
        echo "Not yet implemented" 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Slony_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_Slony_linux_x64 || exit 1
        echo "Not yet implemented" 
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_postprocess_Slony_windows || exit 1
        echo "Not yet implemented" 
    fi
}


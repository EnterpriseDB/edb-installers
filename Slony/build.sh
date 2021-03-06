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

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/Slony/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Slony/build-windows.sh
fi
    
# Windows x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/Slony/build-windows-x64.sh
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
    extract_file  $WD/tarballs/slony1-$PG_VERSION_SLONY 

    cd $WD/Slony/source/slony1-$PG_VERSION_SLONY
    echo "Applying slony_228_win64.patch"
    patch -p1 < $WD/tarballs/slony_228_win64.patch || _die "Could not apply slony_228_win64.patch"

    autoconf

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_Slony_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Slony_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Slony_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_prep_Slony_linux_ppc64 
        echo "Linux-PPC64 build pre-process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Slony_windows 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_Slony_windows_x64 
    fi

}

################################################################################
# Build Slony
################################################################################

_build_Slony() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_Slony_osx 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Slony_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_Slony_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_build_Slony_linux_ppc64 
        echo "Linux-PPC64 build process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Slony_windows 
    fi
 
    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_Slony_windows_x64 
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
    _replace PG_MINOR_VERSION $PG_MINOR_VERSION installer.xml || _die "Failed to set the PG Minor Number in the installer project file (Slony/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_Slony_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Slony_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Slony_linux_x64 
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_Slony_linux_ppc64 
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_Slony_windows 
    fi
    
    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_Slony_windows_x64 
    fi
    
}


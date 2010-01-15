#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    echo "Not yet implemented"
    #source $WD/pghyperic/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pghyperic/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    echo "Not yet implemented"
    #source $WD/pghyperic/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    echo "Not yet implemented"
    #source $WD/pghyperic/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic() {

    # Create the source directory if required
    if [ ! -e $WD/pghyperic/source ];
    then
        mkdir $WD/pghyperic/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    # pghyperic
    if [ -e pghyperic-$PG_VERSION_PGHYPERIC ];
    then
      echo "Removing existing pghyperic-$PG_VERSION_PGHYPERIC source directory"
      rm -rf pghyperic-$PG_VERSION_PGHYPERIC  || _die "Couldn't remove the existing pghyperic-$PG_VERSION_PGHYPERIC source directory (source/pghyperic-$PG_VERSION_PGHYPERIC)"
    fi

    echo "Unpacking pghyperic source..."
    extract_file ../../tarballs/pghyperic-$PG_VERSION_PGHYPERIC || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_prep_pghyperic_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pghyperic_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
        #_prep_pghyperic_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
        #_prep_pghyperic_windows || exit 1
    fi
    
}

################################################################################
# Build pghyperic
################################################################################

_build_pghyperic() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_build_pghyperic_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pghyperic_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
       #_build_pghyperic_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
        #_build_pghyperic_windows || exit 1
    fi
}

################################################################################
# Postprocess pghyperic
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pghyperic() {

    cd $WD/pghyperic


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pghyperic/installer.xml.in)"
    
    _replace PG_VERSION_PGHYPERIC $PG_VERSION_PGHYPERIC installer.xml || _die "Failed to set the version in the installer project file (pghyperic/installer.xml)"
    _replace PG_BUILDNUM_PGHYPERIC $PG_BUILDNUM_PGHYPERIC installer.xml || _die "Failed to set the Build Number in the installer project file (pghyperic/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_postprocess_pghyperic_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pghyperic_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
        #_postprocess_pghyperic_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
       #_postprocess_pghyperic_windows || exit 1
    fi
}

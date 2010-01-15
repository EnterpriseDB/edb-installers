#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    echo "Not yet implemented"
    #source $WD/hqagent/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/hqagent/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    echo "Not yet implemented"
    #source $WD/hqagent/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    echo "Not yet implemented"
    #source $WD/hqagent/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_hqagent() {

    # Create the source directory if required
    if [ ! -e $WD/hqagent/source ];
    then
        mkdir $WD/hqagent/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    # hqagent
    if [ -e hqagent-$PG_VERSION_HQAGENT ];
    then
      echo "Removing existing hqagent-$PG_VERSION_HQAGENT source directory"
      rm -rf hqagent-$PG_VERSION_HQAGENT  || _die "Couldn't remove the existing hqagent-$PG_VERSION_HQAGENT source directory (source/hqagent-$PG_VERSION_HQAGENT)"
    fi

    echo "Unpacking hqagent source..."
    extract_file ../../tarballs/hqagent-$PG_VERSION_HQAGENT || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_prep_hqagent_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_hqagent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
        #_prep_hqagent_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
        #_prep_hqagent_windows || exit 1
    fi
    
}

################################################################################
# Build hqagent
################################################################################

_build_hqagent() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_build_hqagent_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_hqagent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
       #_build_hqagent_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
        #_build_hqagent_windows || exit 1
    fi
}

################################################################################
# Postprocess hqagent
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_hqagent() {

    cd $WD/hqagent


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (hqagent/installer.xml.in)"
    
    _replace PG_VERSION_HQAGENT $PG_VERSION_HQAGENT installer.xml || _die "Failed to set the version in the installer project file (hqagent/installer.xml)"
    _replace PG_BUILDNUM_HQAGENT $PG_BUILDNUM_HQAGENT installer.xml || _die "Failed to set the Build Number in the installer project file (hqagent/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "Not yet implemented"
        #_postprocess_hqagent_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_hqagent_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
	echo "Not yet implemented"
        #_postprocess_hqagent_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Not yet implemented"
       #_postprocess_hqagent_windows || exit 1
    fi
}

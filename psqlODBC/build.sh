#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/psqlODBC/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/psqlODBC/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/psqlODBC/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    #source $WD/psqlODBC/build-windows.sh
    echo "Not yet implemented"
fi
    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC() {

    # Create the source directory if required
    if [ ! -e $WD/psqlODBC/source ];
    then
        mkdir $WD/psqlODBC/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    # psqlODBC
    if [ -e psqlODBC-$PG_VERSION_PSQLODBC ];
    then
      echo "Removing existing psqlODBC-$PG_VERSION_PSQLODBC source directory"
      rm -rf psqlODBC-$PG_VERSION_PSQLODBC  || _die "Couldn't remove the existing psqlODBC-$PG_VERSION_PSQLODBC source directory (source/psqlODBC-$PG_VERSION_PSQLODBC)"
    fi

    echo "Unpacking psqlODBC source..."
    extract_file  ../../tarballs/psqlODBC-$PG_VERSION_PSQLODBC || exit 1 
    
    # psqlODBC Docs
    if [ -e docs ];
    then
      echo "Removing existing docs source directory"
      rm -rf docs  || _die "Couldn't remove the existing docs source directory (source/docs)"
    fi
   
    if [ -e templates ];
    then
      echo "Removing existing templates source directory"
      rm -rf templates  || _die "Couldn't remove the existing templates source directory (source/templates)"
    fi
    echo "Unpacking psqlODBC-docs source..."
    extract_file  ../../tarballs/psqlODBC-docs-$PG_VERSION_PSQLODBC || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_psqlODBC_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_psqlODBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_psqlODBC_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_psqlODBC_windows || exit 1
        echo "Not yet implemented"
    fi
    
}

################################################################################
# Build psqlODBC
################################################################################

_build_psqlODBC() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_psqlODBC_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_psqlODBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_psqlODBC_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_psqlODBC_windows || exit 1
        echo "Not yet implemented"
    fi
}

################################################################################
# Postprocess psqlODBC
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_psqlODBC() {

    cd $WD/psqlODBC


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (psqlODBC/installer.xml.in)"
    
    _replace PG_VERSION_PSQLODBC $PG_VERSION_PSQLODBC installer.xml || _die "Failed to set the version in the installer project file (psqlODBC/installer.xml)"
    _replace PG_BUILDNUM_PSQLODBC $PG_BUILDNUM_PSQLODBC installer.xml || _die "Failed to set the Build Number in the installer project file (psqlODBC/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_psqlODBC_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_psqlODBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_psqlODBC_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_postprocess_psqlODBC_windows || exit 1
        echo "Not yet implemented"
    fi
}

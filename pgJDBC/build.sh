#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/pgJDBC/build-osx.sh
    echo "Not yet implemented" 
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pgJDBC/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/pgJDBC/build-linux-x64.sh
    echo "Not yet implemented" 
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    #source $WD/pgJDBC/build-windows.sh
    echo "Not yet implemented" 
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pgJDBC() {

    # Create the source directory if required
    if [ ! -e $WD/pgJDBC/source ];
    then
        mkdir $WD/pgJDBC/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    # pgJDBC
    if [ -e pgJDBC-$PG_PGJDBC_TARBALL ];
    then
      echo "Removing existing pgJDBC-$PG_PGJDBC_TARBALL source directory"
      rm -rf pgJDBC-$PG_PGJDBC_TARBALL  || _die "Couldn't remove the existing pgJDBC-$PG_PGJDBC_TARBALL source directory (source/pgJDBC-$PG_PGJDBC_TARBALL)"
    fi

    echo "Unpacking pgJDBC source..."
    tar -jxvf ../../tarballs/pgJDBC-$PG_PGJDBC_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       # _prep_pgJDBC_osx || exit 1
       echo "Not yet implemented" 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgJDBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       # _prep_pgJDBC_linux_x64 || exit 1
       echo "Not yet implemented" 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_pgJDBC_windows || exit 1
       echo "Not yet implemented" 
    fi
	
}

################################################################################
# Build pgJDBC
################################################################################

_build_pgJDBC() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       # _build_pgJDBC_osx || exit 1
       echo "Not yet implemented" 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgJDBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       #_build_pgJDBC_linux_x64 || exit 1
       echo "Not yet implemented" 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_pgJDBC_windows || exit 1
       echo "Not yet implemented" 
    fi
}

################################################################################
# Postprocess pgJDBC
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgJDBC() {

    cd $WD/pgJDBC


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgJDBC/installer.xml.in)"
	
    _replace PG_PGJDBC_VERSION $PG_PGJDBC_VERSION installer.xml || _die "Failed to set the version in the installer project file (pgJDBC/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       # _postprocess_pgJDBC_osx || exit 1
       echo "Not yet implemented" 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgJDBC_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       # _postprocess_pgJDBC_linux_x64 || exit 1
       echo "Not yet implemented" 
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       #_postprocess_pgJDBC_windows || exit 1
       echo "Not yet implemented" 
    fi
}

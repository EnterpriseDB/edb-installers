#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
   # source $WD/phpBB/build-osx.sh
   echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/phpBB/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
   # source $WD/phpBB/build-linux-x64.sh
   echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/phpBB/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_phpBB() {

    # Create the source directory if required
    if [ ! -e $WD/phpBB/source ];
    then
        mkdir $WD/phpBB/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source

    # phpBB
    if [ -e phpBB-$PG_PHPBB_TARBALL ];
    then
      echo "Removing existing phpBB-$PG_PHPBB_TARBALL source directory"
      rm -rf phpBB-$PG_PHPBB_TARBALL  || _die "Couldn't remove the existing phpBB-$PG_PHPBB_TARBALL source directory (source/phpBB-$PG_PHPBB_TARBALL)"
    fi

    echo "Unpacking PhpBB source..."
    tar -jxvf ../../tarballs/phpBB-$PG_PHPBB_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       # _prep_phpBB_osx || exit 1
       echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_phpBB_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       # _prep_phpBB_linux_x64 || exit 1
       echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_phpBB_windows || exit 1
    fi
	
}

################################################################################
# Build phpBB
################################################################################

_build_phpBB() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       # _build_phpBB_osx || exit 1
       echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_phpBB_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       # _build_phpBB_linux_x64 || exit 1
	echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_phpBB_windows || exit 1
    fi
}

################################################################################
# Postprocess phpBB
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_phpBB() {

    cd $WD/phpBB


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (phpBB/installer.xml.in)"

    _replace PG_PHPBB_VERSION $PG_PHPBB_VERSION installer.xml || _die "Failed to set the version in the installer project file (phpBB/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_phpBB_osx || exit 1
	echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_phpBB_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_phpBB_linux_x64 || exit 1
	echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_phpBB_windows || exit 1
    fi
}

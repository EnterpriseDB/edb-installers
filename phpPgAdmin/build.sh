#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/phpPgAdmin/build-osx.sh
    echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/phpPgAdmin/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/phpPgAdmin/build-linux-x64.sh
    echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/phpPgAdmin/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin() {

    # Create the source directory if required
    if [ ! -e $WD/phpPgAdmin/source ];
    then
        mkdir $WD/phpPgAdmin/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source

    # phpPgAdmin
    if [ -e phpwiki-$PG_PHPWIKI_TARBALL ];
    then
      echo "Removing existing phpPgAdmin-$PG_PHPPGADMIN_TARBALL source directory"
      rm -rf phpPgAdmin-$PG_PHPPGADMIN_TARBALL  || _die "Couldn't remove the existing phpPgAdmin-$PG_PHPPGADMIN_TARBALL source directory (source/phpPgAdmin-$PG_PHPPGADMIN_TARBALL)"
    fi

    echo "Unpacking phpPgAdmin source..."
    tar -jxvf ../../tarballs/phpPgAdmin-$PG_PHPPGADMIN_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_phpPgAdmin_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_phpPgAdmin_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_phpPgAdmin_windows || exit 1
    fi
	
}

################################################################################
# Build phpPgAdmin
################################################################################

_build_phpPgAdmin() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_build_phpPgAdmin_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_phpPgAdmin_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_phpPgAdmin_windows || exit 1
    fi
}

################################################################################
# Postprocess phpPgAdmin
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_phpPgAdmin() {

    cd $WD/phpPgAdmin


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (phpPgAdmin/installer.xml.in)"

    _replace PG_PHPPGADMIN_VERSION $PG_PHPPGADMIN_VERSION installer.xml || _die "Failed to set the version in the installer project file (phpPgAdmin/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_phpPgAdmin_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_phpPgAdmin_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_phpPgAdmin_linux_x64 || exit 1
        echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_phpPgAdmin_windows || exit 1
    fi
}

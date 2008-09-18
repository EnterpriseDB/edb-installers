#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
   #source $WD/phpWiki/build-osx.sh
   echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/phpWiki/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
   #source $WD/phpWiki/build-linux-x64.sh
   echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/phpWiki/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_phpWiki() {

    # Create the source directory if required
    if [ ! -e $WD/phpWiki/source ];
    then
        mkdir $WD/phpWiki/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/phpWiki/source

    # phpWiki
    if [ -e phpwiki-$PG_PHPWIKI_TARBALL ];
    then
      echo "Removing existing phpwiki-$PG_PHPWIKI_TARBALL source directory"
      rm -rf phpwiki-$PG_PHPWIKI_TARBALL  || _die "Couldn't remove the existing phpwiki-$PG_PHPWIKI_TARBALL source directory (source/phpwiki-$PG_PHPWIKI_TARBALL)"
    fi

    echo "Unpacking PhpWiki source..."
    tar -jxvf ../../tarballs/phpwiki-$PG_PHPWIKI_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       #_prep_phpWiki_osx || exit 1
       echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_phpWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       #_prep_phpWiki_linux_x64 || exit 1
       echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_phpWiki_windows || exit 1
    fi
	
}

################################################################################
# Build phpWiki
################################################################################

_build_phpWiki() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       #_build_phpWiki_osx || exit 1
       echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_phpWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
      #_build_phpWiki_linux_x64 || exit 1
      echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_phpWiki_windows || exit 1
    fi
}

################################################################################
# Postprocess phpWiki
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_phpWiki() {

    cd $WD/phpWiki


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (phpWiki/installer.xml.in)"

    _replace PG_PHPWIKI_VERSION $PG_PHPWIKI_VERSION installer.xml || _die "Failed to set the version in the installer project file (phpWiki/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
       #_postprocess_phpWiki_osx || exit 1
       echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_phpWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
      #_postprocess_phpWiki_linux_x64 || exit 1
      echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_phpWiki_windows || exit 1
    fi
}

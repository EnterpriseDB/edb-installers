#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/mediaWiki/build-osx.sh
    echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/mediaWiki/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/mediaWiki/build-linux-x64.sh
    echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/mediaWiki/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki() {

    # Create the source directory if required
    if [ ! -e $WD/mediaWiki/source ];
    then
        mkdir $WD/mediaWiki/source
    fi
    
    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source

    # mediaWiki
    if [ -e mediawiki-$PG_MEDIAWIKI_TARBALL ];
    then
      echo "Removing existing mediawiki-$PG_MEDIAWIKI_TARBALL source directory"
      rm -rf mediawiki-$PG_MEDIAWIKI_TARBALL  || _die "Couldn't remove the existing mediawiki-$PG_MEDIAWIKI_TARBALL source directory (source/mediawiki-$PG_MEDIAWIKI_TARBALL)"
    fi

    echo "Unpacking MediaWiki source..."
    tar -jxvf ../../tarballs/mediawiki-$PG_MEDIAWIKI_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_mediaWiki_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_mediaWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_mediaWiki_linux_x64 || exit 1
    	echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_mediaWiki_windows || exit 1
    fi
	
}

################################################################################
# Build mediaWiki
################################################################################

_build_mediaWiki() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_build_mediaWiki_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_mediaWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_mediaWiki_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_mediaWiki_windows || exit 1
    fi
}

################################################################################
# Postprocess mediaWiki
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_mediaWiki() {

    cd $WD/mediaWiki


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (mediaWiki/installer.xml.in)"

    _replace PG_MEDIAWIKI_VERSION $PG_MEDIAWIKI_VERSION installer.xml || _die "Failed to set the version in the installer project file (mediaWiki/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_mediaWiki_osx || exit 1
    	echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_mediaWiki_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_mediaWiki_linux_x64 || exit 1
        echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_mediaWiki_windows || exit 1
    fi
}

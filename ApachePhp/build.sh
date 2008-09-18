#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/ApachePhp/build-osx.sh
    echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/ApachePhp/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/ApachePhp/build-linux-x64.sh
    echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    #source $WD/ApachePhp/build-windows.sh
    echo "Not yet implemented"
fi
    
################################################################################
# Build preparation
################################################################################

_prep_ApachePhp() {

    # Create the source directory if required
    if [ ! -e $WD/ApachePhp/source ];
    then
        mkdir $WD/ApachePhp/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source


    # Apache
    if [ -e httpd-$PG_APACHE_TARBALL ];
    then
      echo "Removing existing httpd-$PG_APACHE_TARBALL source directory"
      rm -rf httpd-$PG_APACHE_TARBALL  || _die "Couldn't remove the existing httpd-$PG_APACHE_TARBALL source directory (source/httpd-$PG_APACHE_TARBALL)"
    fi

    echo "Unpacking apache source..."
    if [[ $PG_ARCH_LINUX = 1 || $PG_ARCH_LINUX_X64 = 1 || $PG_ARCH_OSX = 1 ]];
    then
        tar -jxvf ../../tarballs/httpd-$PG_APACHE_TARBALL.tar.bz2
    fi
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #unzip -o ../../tarballs/httpd-$PG_APACHE_TARBALL-win32-src.zip
        #tar -jxvf ../../tarballs/zlib-$PG_ZLIB_TARBALL.tar.bz2
        #tar -zxvf ../../tarballs/openssl-$PG_OPENSSL_TARBALL.tar.gz
        echo "Not yet implemented"
    fi

    # php
    if [ -e php-$PG_PHP_TARBALL ];
    then
      echo "Removing existing php-$PG_PHP_TARBALL source directory"
      rm -rf php-$PG_PHP_TARBALL  || _die "Couldn't remove the existing php-$PG_PHP_TARBALL source directory (source/php-$PG_PHP_TARBALL)"
    fi

    echo "Unpacking php source..."
    tar -jxvf ../../tarballs/php-$PG_PHP_TARBALL.tar.bz2
 
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_ApachePhp_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_ApachePhp_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_ApachePhp_windows || exit 1
        echo "Not yet implemented"
    fi
	
}

################################################################################
# Build ApachePhp
################################################################################

_build_ApachePhp() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_build_ApachePhp_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_ApachePhp_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_ApachePhp_windows || exit 1
        echo "Not yet implemented"
    fi
}

################################################################################
# Postprocess ApachePhp
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_ApachePhp() {

    cd $WD/ApachePhp


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (ApachePhp/installer.xml.in)"

    _replace PG_APACHEPHP_VERSION $PG_APACHE_VERSION-$PG_PHP_VERSION installer.xml || _die "Failed to set the major version in the installer project file (ApachePhp/installer.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_ApachePhp_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_ApachePhp_linux_x64 || exit 1
        echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_postprocess_ApachePhp_windows || exit 1
        echo "Not yet implemented"
    fi
}

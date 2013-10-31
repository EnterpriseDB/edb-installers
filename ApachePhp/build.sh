#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/ApachePhp/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/ApachePhp/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/ApachePhp/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/ApachePhp/build-windows.sh
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
    if [ -e httpd-$PG_VERSION_APACHE ];
    then
      echo "Removing existing httpd-$PG_VERSION_APACHE source directory"
      rm -rf httpd-$PG_VERSION_APACHE  || _die "Couldn't remove the existing httpd-$PG_VERSION_APACHE source directory (source/httpd-$PG_VERSION_APACHE)"
    fi

    echo "Unpacking apache source..."
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        if [ -e apache.windows ]; then
            rm -rf apache.windows || _die "Couldn't remove the existing apache.windows source directory (source/apache.windows)"
        fi
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-win32-src || exit 1
        extract_file ../../tarballs/zlib-$PG_TARBALL_ZLIB || exit 1
        extract_file ../../tarballs/openssl-$PG_TARBALL_OPENSSL || exit 1
        mv httpd-$PG_VERSION_APACHE apache.windows || _die "Couldn't move httpd-$PG_VERSION_APACHE as apache.windows"

    fi

    if [[ $PG_ARCH_LINUX = 1 || $PG_ARCH_LINUX_X64 = 1 || $PG_ARCH_OSX = 1 ]];
    then
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE || exit 1
    fi

    # php
    if [ -e php-$PG_VERSION_PHP ];
    then
      echo "Removing existing php-$PG_VERSION_PHP source directory"
      rm -rf php-$PG_VERSION_PHP  || _die "Couldn't remove the existing php-$PG_VERSION_PHP source directory (source/php-$PG_VERSION_PHP)"
    fi

    echo "Unpacking php source..."
    extract_file ../../tarballs/php-$PG_VERSION_PHP || exit 1
    
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_ApachePhp_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_ApachePhp_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_ApachePhp_windows || exit 1
    fi
    
}

################################################################################
# Build ApachePhp
################################################################################

_build_ApachePhp() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_ApachePhp_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_ApachePhp_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_ApachePhp_windows || exit 1
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

    PHP_MAJOR_VERSION=`echo $PG_VERSION_PHP | cut -f1 -d "." ` 

    _replace PG_VERSION_APACHEPHP $PG_VERSION_APACHE-$PG_VERSION_PHP installer.xml || _die "Failed to set the major version in the installer project file (ApachePhp/installer.xml)"
    _replace PG_BUILDNUM_APACHEPHP $PG_BUILDNUM_APACHEPHP installer.xml || _die "Failed to set the major version in the installer project file (ApachePhp/installer.xml)"
    _replace PHP_MAJOR_VERSION $PHP_MAJOR_VERSION installer.xml || _die "Failed to set the major version in the installer project file (ApachePhp/installer.xml)"
    
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_ApachePhp_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_ApachePhp_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_ApachePhp_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_ApachePhp_windows || exit 1
    fi
}

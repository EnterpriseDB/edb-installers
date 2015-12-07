#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    echo "ApacheHTTPD OSX build not supported."
    #source $WD/ApacheHTTPD/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/ApacheHTTPD/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/ApacheHTTPD/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/ApacheHTTPD/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_ApacheHTTPD() {

    # Create the source directory if required
    if [ ! -e $WD/ApacheHTTPD/source ];
    then
        mkdir $WD/ApacheHTTPD/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/ApacheHTTPD/source

    # Apache
    if [ -e httpd-$PG_VERSION_APACHE ];
    then
      echo "Removing existing httpd-$PG_VERSION_APACHE source directory"
      rm -rf httpd-$PG_VERSION_APACHE  || _die "Couldn't remove the existing httpd-$PG_VERSION_APACHE source directory (source/httpd-$PG_VERSION_APACHE)"
    fi

    # WSGI
    if [ -e mod_wsgi-$PG_VERSION_WSGI ];
    then
      echo "Removing existing mod_wsgi-$PG_VERSION_WSGI source directory"
      rm -rf mod_wsgi-$PG_VERSION_WSGI  || _die "Couldn't remove the existing mod_wsgi-$PG_VERSION_WSGI source directory (source/mod_wsgi-$PG_VERSION_WSGI)"
    fi

    extract_file ../../tarballs/mod_wsgi-$PG_VERSION_WSGI || exit 1

    echo "Unpacking apache source..."
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        if [ -e apache.windows ]; then
            rm -rf apache.windows || _die "Couldn't remove the existing apache.windows source directory (source/apache.windows)"
        fi
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-win32-src || exit 1
        extract_file ../../tarballs/zlib-$PG_TARBALL_ZLIB || exit 1
        extract_file ../../tarballs/openssl-$PG_TARBALL_OPENSSL || exit 1
        extract_file ../../tarballs/pcre-836-win32-binaries || exit 1
	mv pcre-836-win32-binaries httpd-$PG_VERSION_APACHE/srclib/pcre || exit 1
        mv httpd-$PG_VERSION_APACHE apache.windows || _die "Couldn't move httpd-$PG_VERSION_APACHE as apache.windows"

    fi

    if [[ $PG_ARCH_LINUX = 1 || $PG_ARCH_LINUX_X64 = 1 || $PG_ARCH_OSX = 1 ]];
    then
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE || exit 1
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-deps || exit 1
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "ApacheHTTPD OSX build not supported."
        #_prep_ApacheHTTPD_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_ApacheHTTPD_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_ApacheHTTPD_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_ApacheHTTPD_windows || exit 1
    fi
    
}

################################################################################
# Build ApacheHTTPD
################################################################################

_build_ApacheHTTPD() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "ApacheHTTPD OSX build not supported."
        #_build_ApacheHTTPD_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_ApacheHTTPD_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_ApacheHTTPD_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_ApacheHTTPD_windows || exit 1
    fi
}

################################################################################
# Postprocess ApacheHTTPD
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_ApacheHTTPD() {

    cd $WD/ApacheHTTPD


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (ApacheHTTPD/installer.xml.in)"

    _replace PG_VERSION_APACHEHTTPD $PG_VERSION_APACHE installer.xml || _die "Failed to set the major version in the installer project file (ApacheHTTPD/installer.xml)"
    _replace PG_BUILDNUM_APACHEHTTPD $PG_BUILDNUM_APACHEHTTPD installer.xml || _die "Failed to set the major version in the installer project file (ApacheHTTPD/installer.xml)"
    _replace PG_VERSION_PYTHON $PG_VERSION_PYTHON installer.xml || _die "Failed to set the Python version in the file (ApacheHTTPD/installer.xml)"    
    _replace PG_VERSION_LANGUAGEPACK $PG_VERSION_LANGUAGEPACK installer.xml || _die "Failed to set the languagepack version in the installer project file (ApacheHTTPD/installer.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
	echo "ApacheHTTPD OSX build not supported."
        #_postprocess_ApacheHTTPD_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_ApacheHTTPD_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_ApacheHTTPD_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_ApacheHTTPD_windows || exit 1
    fi
}

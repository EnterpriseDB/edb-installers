#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    echo "Disabling Mac OS X build"
    #source $WD/PEM-HTTPD/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    echo "Disable Linux 32 build"
    #source $WD/PEM-HTTPD/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/PEM-HTTPD/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/PEM-HTTPD/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_PEM_HTTPD() {

    # Download source packages
    _download_sources

    # Create the source directory if required
    if [ ! -e $WD/PEM-HTTPD/source ];
    then
        mkdir $WD/PEM-HTTPD/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/PEM-HTTPD/source

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

    extract_file ../../tarballs/mod_wsgi-$PG_VERSION_WSGI 

    echo "Unpacking apache source..."
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        if [ -e apache.windows ]; then
            rm -rf apache.windows || _die "Couldn't remove the existing apache.windows source directory (source/apache.windows)"
        fi
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE
        extract_file ../../tarballs/zlib-$PG_TARBALL_ZLIB 
        extract_file ../../tarballs/openssl-$PG_TARBALL_OPENSSL 
        extract_file ../../tarballs/pcre-$PG_VERSION_APACHE_PCRE
        extract_file ../../tarballs/apr-$PG_VERSION_APACHE_APR-win32-src
        extract_file ../../tarballs/apr-util-$PG_VERSION_APACHE_APR_UTIL-win32-src
        extract_file ../../tarballs/apr-iconv-$PG_VERSION_APACHE_APR_ICONV-win32-src
        extract_file ../../tarballs/expat-$PG_VERSION_APACHE_EXPAT

	mv pcre-$PG_VERSION_APACHE_PCRE httpd-$PG_VERSION_APACHE/srclib/pcre
        mv httpd-$PG_VERSION_APACHE apache.windows || _die "Couldn't move httpd-$PG_VERSION_APACHE as apache.windows"
        mv apr-$PG_VERSION_APACHE_APR apache.windows/srclib/apr || _die "Couldn't move apr-$PG_VERSION_APACHE_APR as apache.windows/srclib/apr"
        mv apr-util-$PG_VERSION_APACHE_APR_UTIL apache.windows/srclib/apr-util || _die "Couldn't move apr-util-$PG_VERSION_APACHE_APR_UTIL as apache.windows/srclib/apr-util"
        mv apr-iconv-$PG_VERSION_APACHE_APR_ICONV apache.windows/srclib/apr-iconv || _die "Couldn't move apr-iconv-$PG_VERSION_APACHE_APR_UTIL as apache.windows/srclib/apr-iconv"
        mv expat-$PG_VERSION_APACHE_EXPAT apache.windows/srclib/apr-util/xml/expat || _die "Couldn't move apr-iconv-$PG_VERSION_APACHE_APR_UTIL as apache.windows/srclib/expat"
    fi

    if [[ $PG_ARCH_LINUX = 1 || $PG_ARCH_LINUX_X64 = 1 || $PG_ARCH_OSX = 1 ]];
    then
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE 
        extract_file ../../tarballs/httpd-$PG_VERSION_APACHE-deps 
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disabling Mac OS X build"
        #_prep_PEM-HTTPD_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        echo "Disable Linux 32 build"
        #_prep_PEM-HTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_PEM-HTTPD_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_PEM_HTTPD_windows
    fi
    
}


################################################################################
# Download source packages for PEM-HTTPD
################################################################################

_download_sources() {

    rm -rf $WD/tarballs
    mkdir -p $WD/tarballs

    # mod_wsgi
    wget https://github.com/GrahamDumpleton/mod_wsgi/archive/refs/tags/$PG_VERSION_WSGI.tar.gz -O $WD/tarballs/mod_wsgi-$PG_VERSION_WSGI.tar.gz

    # httpd
    wget http://archive.apache.org/dist/httpd/httpd-$PG_VERSION_APACHE.tar.gz -O $WD/tarballs/httpd-$PG_VERSION_APACHE.tar.gz

    # zlib
    wget https://www.zlib.net/zlib-$PG_TARBALL_ZLIB.tar.gz -O $WD/tarballs/zlib-$PG_TARBALL_ZLIB.tar.gz

    # openssl
    OPENSSL_FOLDER=`echo $PG_TARBALL_OPENSSL|sed -e 's/\./_/g'`
    wget https://github.com/openssl/openssl/releases/download/OpenSSL_$OPENSSL_FOLDER/openssl-$PG_TARBALL_OPENSSL.tar.gz -O $WD/tarballs/openssl-$PG_TARBALL_OPENSSL.tar.gz

    # pcre
    wget https://sourceforge.net/projects/pcre/files/pcre/$PG_VERSION_APACHE_PCRE/pcre-$PG_VERSION_APACHE_PCRE.tar.gz/download -O $WD/tarballs/pcre-$PG_VERSION_APACHE_PCRE.tar.gz

    # apr
    wget https://archive.apache.org/dist/apr/apr-$PG_VERSION_APACHE_APR-win32-src.zip -O $WD/tarballs/apr-$PG_VERSION_APACHE_APR-win32-src.zip

    # apr-util
    wget https://archive.apache.org/dist/apr/apr-util-$PG_VERSION_APACHE_APR_UTIL-win32-src.zip -O $WD/tarballs/apr-util-$PG_VERSION_APACHE_APR_UTIL-win32-src.zip

    # apr-iconv
    wget https://archive.apache.org/dist/apr/apr-iconv-$PG_VERSION_APACHE_APR_ICONV-win32-src.zip -O $WD/tarballs/apr-iconv-$PG_VERSION_APACHE_APR_ICONV-win32-src.zip

    # expat
    EXPAT_FOLDER=`echo $PG_VERSION_APACHE_EXPAT|sed -e 's/\./_/g'`
    wget https://github.com/libexpat/libexpat/releases/download/R_$EXPAT_FOLDER/expat-$PG_VERSION_APACHE_EXPAT.tar.gz -O $WD/tarballs/expat-$PG_VERSION_APACHE_EXPAT.tar.gz
}


################################################################################
# Build PEM-HTTPD
################################################################################

_build_PEM_HTTPD() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disabling Mac OS X build"
        #_build_PEM-HTTPD_osx 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        echo "Disable Linux 32 build"
        #_build_PEM-HTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_PEM-HTTPD_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_PEM_HTTPD_windows
    fi
}

################################################################################
# Postprocess PEM-HTTPD
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_PEM_HTTPD() {

    cd $WD/PEM-HTTPD


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (PEM-HTTPD/installer.xml.in)"

    _replace PG_VERSION_PEMHTTPD $PG_VERSION_APACHE installer.xml || _die "Failed to set the major version in the installer project file (PEM-HTTPD/installer.xml)"
    _replace PG_BUILDNUM_PEMHTTPD $PG_BUILDNUM_PEMHTTPD installer.xml || _die "Failed to set the major version in the installer project file (PEM-HTTPD/installer.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        echo "Disabling Mac OS X build"
        #_postprocess_PEM-HTTPD_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        echo "Disable Linux 32 build"
        #_postprocess_PEM-HTTPD_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_PEM-HTTPD_linux_x64 
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_PEM_HTTPD_windows
    fi
}

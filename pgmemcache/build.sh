#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pgmemcache/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pgmemcache/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pgmemcache/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    #source $WD/pgmemcache/build-windows.sh
    echo "Not Applicable"
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pgmemcache() {

    # Create the source directory if required
    if [ ! -e $WD/pgmemcache/source ];
    then
        mkdir $WD/pgmemcache/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    # libmemcached
    if [ -e libmemcached-$PG_TARBALL_LIBMEMCACHED ];
    then
      echo "Removing existing libmemcached-$PG_TARBALL_LIBMEMCACHED source directory"
      rm -rf libmemcached-$PG_TARBALL_LIBMEMCACHED  || _die "Couldn't remove the existing libmemcached-$PG_TARBALL_LIBMEMCACHED source directory (source/libmemcached-$PG_TARBALL_LIBMEMCACHED)"
    fi

    echo "Unpacking libmemcached source..."
    extract_file ../../tarballs/libmemcached-$PG_TARBALL_LIBMEMCACHED || exit 1


    # pgmemcache
    if [ -e pgmemcache-$PG_VERSION_PGMEMCACHE ];
    then
      echo "Removing existing pgmemcache-$PG_VERSION_PGMEMCACHE source directory"
      rm -rf pgmemcache-$PG_VERSION_PGMEMCACHE  || _die "Couldn't remove the existing pgmemcache-$PG_VERSION_PGMEMCACHE source directory (source/pgmemcache-$PG_VERSION_PGMEMCACHE)"
    fi

    echo "Unpacking pgmemcache source..."
    extract_file ../../tarballs/pgmemcache_$PG_VERSION_PGMEMCACHE || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pgmemcache_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgmemcache_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pgmemcache_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_pgmemcache_windows || exit 1
        echo "Not Applicable"
    fi
    
}

################################################################################
# Build pgmemcache
################################################################################

_build_pgmemcache() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pgmemcache_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgmemcache_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pgmemcache_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_pgmemcache_windows || exit 1
        echo "Not Applicable"
    fi
}

################################################################################
# Postprocess pgmemcache
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgmemcache() {

    cd $WD/pgmemcache


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgmemcache/installer.xml.in)"
    
    _replace PG_VERSION_PGMEMCACHE $PG_VERSION_PGMEMCACHE installer.xml || _die "Failed to set the version in the installer project file (pgmemcache/installer.xml)"
    _replace PG_BUILDNUM_PGMEMCACHE $PG_BUILDNUM_PGMEMCACHE installer.xml || _die "Failed to set the Build Number in the installer project file (pgmemcache/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pgmemcache_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgmemcache_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pgmemcache_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       #_postprocess_pgmemcache_windows || exit 1
	   echo "Not Applicable"
    fi
}

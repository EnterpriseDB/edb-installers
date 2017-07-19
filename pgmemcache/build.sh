#!/bin/bash
set -x
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

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/pgmemcache/build-linux-ppc64.sh
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
    else
        #Clean up pgmemcache/source directory if it contains pgmemcache<Version> folder     
        if [ -e $WD/pgmemcache/source/pgmemcache-$PG_VERSION_PGMEMCACHE ];
        then
            echo "Removing existing $WD/pgmemcache/source/pgmemcache-$PG_VERSION_PGMEMCACHE source directory"
            rm -rf $WD/pgmemcache/source/pgmemcache-$PG_VERSION_PGMEMCACHE  || _die "Couldn't remove the existing pgmemcache_$PG_VERSION_PGMEMCACHE source directory (source/pgmemcache_$PG_VERSION_PGMEMCACHE)"
        fi
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    echo "Unpacking pgmemcache source..."
    extract_file ../../tarballs/pgmemcache_$PG_VERSION_PGMEMCACHE 

    #cd $WD/pgmemcache/source/pgmemcache
    #patch -p1 < $WD/tarballs/pgmemcache-libmemcached-1.0.8.patch
    #patch -p1 < $WD/tarballs/pgmemcache-2.0.6.patch

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pgmemcache_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgmemcache_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pgmemcache_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_prep_pgmemcache_linux_ppc64 
        echo "Linux-PPC64 build pre-process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_pgmemcache_windows 
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
        _build_pgmemcache_osx 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgmemcache_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pgmemcache_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
       #_build_pgmemcache_linux_ppc64 
       echo "Linux-PPC64 build process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_pgmemcache_windows 
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

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    
    _replace PG_VERSION_PGMEMCACHE $PG_VERSION_PGMEMCACHE installer.xml || _die "Failed to set the version in the installer project file (pgmemcache/installer.xml)"
    _replace PG_BUILDNUM_PGMEMCACHE $PG_BUILDNUM_PGMEMCACHE installer.xml || _die "Failed to set the Build Number in the installer project file (pgmemcache/installer.xml)"
  
    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION installer.xml || _die "Failed to set the PG Current Number in the installer project file (pgmemcache/installer.xml)"

    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the PG MAJOR Number in the installer project file (pgmemcache/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pgmemcache_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgmemcache_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pgmemcache_linux_x64 
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_pgmemcache_linux_ppc64 
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       #_postprocess_pgmemcache_windows 
	   echo "Not Applicable"
    fi
}

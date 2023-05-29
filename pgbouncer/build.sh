#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pgbouncer/build-osx.sh
fi

# Windows-x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/pgbouncer/build-windows-x64.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer() {

    # Create the source directory if required
    if [ ! -e $WD/pgbouncer/source ];
    then
        mkdir $WD/pgbouncer/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    # pgbouncer
    if [ -e pgbouncer-$PG_VERSION_PGBOUNCER ];
    then
      echo "Removing existing pgbouncer-$PG_VERSION_PGBOUNCER source directory"
      rm -rf pgbouncer-$PG_VERSION_PGBOUNCER  || _die "Couldn't remove the existing pgbouncer-$PG_VERSION_PGBOUNCER source directory (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    fi

    echo "Unpacking pgbouncer source..."
    extract_file ../../tarballs/pgbouncer-$PG_VERSION_PGBOUNCER 

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pgbouncer_osx 
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_pgbouncer_windows_x64 
    fi
    
}

################################################################################
# Build pgbouncer
################################################################################

_build_pgbouncer() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pgbouncer_osx 
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_pgbouncer_windows_x64  
    fi

}


################################################################################
# Postprocess pgbouncer
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgbouncer() {

    cd $WD/pgbouncer


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgbouncer/installer.xml.in)"
    
    _replace PG_VERSION_PGBOUNCER $PG_VERSION_PGBOUNCER installer.xml || _die "Failed to set the version in the installer project file (pgbouncer/installer.xml)"
    _replace PG_BUILDNUM_PGBOUNCER $PG_BUILDNUM_PGBOUNCER installer.xml || _die "Failed to set the Build Number in the installer project file (pgbouncer/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pgbouncer_osx 
    fi

   # Windows-x64
   if [ $PG_ARCH_WINDOWS_X64 = 1 ]; 
   then
       _postprocess_pgbouncer_windows_x64 
    fi
}

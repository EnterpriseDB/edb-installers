#!/bin/bash

# Read the various build scripts

# Windows-x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/libpq/build-windows-x64.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_libpq() {

    # Create the source directory if required
    if [ ! -e $WD/libpq/source ];
    then
        mkdir $WD/libpq/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/libpq/source

    # PostgreSQL
    if [ -e postgresql-$PG_TARBALL_POSTGRESQL ];
    then
      echo "Removing existing postgresql-$PG_TARBALL_POSTGRESQL source directory"
      rm -rf postgresql-$PG_TARBALL_POSTGRESQL  || _die "Couldn't remove the existing postgresql-$PG_TARBALL_POSTGRESQL source directory (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    fi
	
    echo "Unpacking PostgreSQL source..."
    tar -jxvf ../../tarballs/postgresql-$PG_TARBALL_POSTGRESQL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_libpq_windows_x64 || exit 1
    fi
}

################################################################################
# Build libpq
################################################################################

_build_libpq() {

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_libpq_windows_x64 || exit 1
    fi
}

################################################################################
# Postprocess libpq
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_libpq() {

    cd $WD/libpq

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (libpq/installer.xml.in)"
    _replace PG_VERSION_LIBPQ $PG_VERSION_LIBPQ installer.xml || _die "Failed to set the major version in the installer project file (libpq/installer.xml)"
    _replace PG_BUILDNUM_LIBPQ $PG_BUILDNUM_LIBPQ installer.xml || _die "Failed to set the major version in the installer project file (libpq/installer.xml)"
	   
    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_libpq_windows_x64 || exit 1
    fi
}

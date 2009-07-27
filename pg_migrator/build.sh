#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pg_migrator/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pg_migrator/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pg_migrator/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pg_migrator/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pg_migrator() {

    # Create the source directory if required
    if [ ! -e $WD/pg_migrator/source ];
    then
        mkdir $WD/pg_migrator/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pg_migrator/source

    # pg_migrator
    if [ -e pg_migrator-$PG_VERSION_PGMIGRATOR ];
    then
      echo "Removing existing pg_migrator-$PG_VERSION_PGMIGRATOR source directory"
      rm -rf pg_migrator-$PG_VERSION_PGMIGRATOR  || _die "Couldn't remove the existing pg_migrator-$PG_VERSION_PGMIGRATOR source directory (source/pg_migrator-$PG_VERSION_PGMIGRATOR)"
    fi

    echo "Unpacking pg_migrator source..."
    extract_file ../../tarballs/pg_migrator-$PG_VERSION_PGMIGRATOR || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pg_migrator_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pg_migrator_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pg_migrator_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pg_migrator_windows || exit 1
    fi
    
}

################################################################################
# Build pg_migrator
################################################################################

_build_pg_migrator() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pg_migrator_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pg_migrator_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pg_migrator_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pg_migrator_windows || exit 1
    fi
}

################################################################################
# Postprocess pg_migrator
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pg_migrator() {

    cd $WD/pg_migrator


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pg_migrator/installer.xml.in)"
    
    _replace PG_VERSION_PGMIGRATOR $PG_VERSION_PGMIGRATOR installer.xml || _die "Failed to set the version in the installer project file (pg_migrator/installer.xml)"
    _replace PG_BUILDNUM_PGMIGRATOR $PG_BUILDNUM_PGMIGRATOR installer.xml || _die "Failed to set the Build Number in the installer project file (pg_migrator/installer.xml)"
    _replace PG_MAJOR_VERSION "$PG_MAJOR_VERSION" installer.xml || _die "Failed to set the major version for PostgreSQL in the installer project file (pg_migrator/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pg_migrator_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pg_migrator_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pg_migrator_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_pg_migrator_windows || exit 1
    fi
}

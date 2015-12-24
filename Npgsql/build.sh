#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/Npgsql/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/Npgsql/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/Npgsql/build-linux-x64.sh
fi

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/Npgsql/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/Npgsql/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql() {

    # Create the source directory if required
    if [ ! -e $WD/Npgsql/source ];
    then
        mkdir $WD/Npgsql/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    echo "Unpacking Npgsql source..."

    cd $WD/Npgsql/source/
    extract_file ../../../tarballs/npgsql-"${PG_VERSION_NPGSQL}" || exit 1

    #Npgsql-3.0.4 patch against VS 2013.
    cd npgsql-$PG_VERSION_NPGSQL
    patch -p0 < $WD/tarballs/npgsql.patch
 
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_Npgsql_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_Npgsql_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _prep_Npgsql_linux_ppc64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_Npgsql_windows || exit 1
    fi
    
}

################################################################################
# Build Npgsql
################################################################################

_build_Npgsql() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_Npgsql_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_Npgsql_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
       _build_Npgsql_linux_ppc64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_Npgsql_windows || exit 1
    fi
}

################################################################################
# Postprocess Npgsql
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_Npgsql() {

    cd $WD/Npgsql

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (Npgsql/installer.xml.in)"
    
    _replace PG_VERSION_NPGSQL $PG_VERSION_NPGSQL installer.xml || _die "Failed to set the version in the installer project file (Npgsql/installer.xml)"
    _replace PG_BUILDNUM_NPGSQL $PG_BUILDNUM_NPGSQL installer.xml || _die "Failed to set the Build Number in the installer project file (Npgsql/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_Npgsql_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_Npgsql_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_Npgsql_linux_x64 || exit 1
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_Npgsql_linux_ppc64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_Npgsql_windows || exit 1
    fi
}

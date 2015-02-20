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

    if [ -e Npgsql-"$PG_VERSION_NPGSQL"-net20 ];
    then
       rm -rf Npgsql-"${PG_VERSION_NPGSQL}"-net*  || _die "Couldn't remove the existing Npgsql-"${PG_VERSION_NPGSQL}"-net20  source directory (source/Npgsql"${PG_VERSION_Npgsql}-net20")"
    fi
    
    mkdir -p $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net20
    mkdir -p $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net35
    mkdir -p $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net40
    mkdir -p $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net45
    mkdir -p $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-docs
   
    echo "Unpacking Npgsql source..."

    cd $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net20
    extract_file ../../../tarballs/Npgsql-"${PG_VERSION_NPGSQL}"-net20 || exit 1

    cd $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net35
    extract_file ../../../tarballs/Npgsql-"${PG_VERSION_NPGSQL}"-net35 || exit 1
    
    cd $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net40
    extract_file ../../../tarballs/Npgsql-"${PG_VERSION_NPGSQL}"-net40 || exit 1

    cd $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-net45
    extract_file ../../../tarballs/Npgsql-"${PG_VERSION_NPGSQL}"-net45 || exit 1
    
    cd $WD/Npgsql/source/Npgsql-"${PG_VERSION_NPGSQL}"-docs
    extract_file ../../../tarballs/Npgsql-"${PG_VERSION_NPGSQL}"-docs || exit 1

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

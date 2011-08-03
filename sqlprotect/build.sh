#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/sqlprotect/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/sqlprotect/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/sqlprotect/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/sqlprotect/build-windows.sh
fi

# Windows x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/sqlprotect/build-windows-x64.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect() {

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_sqlprotect_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_sqlprotect_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_sqlprotect_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_sqlprotect_windows || exit 1
    fi
  
    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_sqlprotect_windows_x64 || exit 1
    fi

}

################################################################################
# Build sqlprotect
################################################################################

_build_sqlprotect() {

    # Clean up the registration plus xmls
    rm -f $WD/sqlprotect/staging/*.xml

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_sqlprotect_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_sqlprotect_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_sqlprotect_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_sqlprotect_windows || exit 1
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_sqlprotect_windows_x64 || exit 1
    fi

}

################################################################################
# Postprocess sqlprotect
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_sqlprotect() {

    cd $WD/sqlprotect


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (sqlprotect/installer.xml.in)"

    _replace PG_VERSION_SQLPROTECT $PG_VERSION_SQLPROTECT installer.xml || _die "Failed to set the version in the installer project file (sqlprotect/installer.xml)"
    _replace PG_BUILDNUM_SQLPROTECT $PG_BUILDNUM_SQLPROTECT installer.xml || _die "Failed to set the Build Number in the installer project file (sqlprotect/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the version in the installer project file (sqlprotect/installer.xml)"

    #_registration_plus_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, TEMP DIRECTORY, PRODUCT_DESCRIPTION, PRODUCT_VERSION)
    _registration_plus_postprocess "$WD/sqlprotect/staging"  "SQL Protect" "sqlprotectVersion" "/etc/postgres-reg.ini" "sqlprotect-PG_$PG_MAJOR_VERSION" "sqlprotect-PG_$PG_MAJOR_VERSION" "sqlprotect" "SQL Protect" "$PG_VERSION_SQLPROTECT"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_sqlprotect_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_sqlprotect_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_sqlprotect_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_sqlprotect_windows || exit 1
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_sqlprotect_windows_x64 || exit 1
    fi

}

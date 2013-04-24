#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ];
then
    source $WD/plpgsqlo/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/plpgsqlo/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/plpgsqlo/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/plpgsqlo/build-windows.sh
fi

# Windows-x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/plpgsqlo/build-windows-x64.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo() {

    # Per-platform prep
    cd $WD

    # Clean up the registration plus xmls
    rm -f $WD/plpgsqlo/staging/*.xml

    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ];
    then
        _prep_plpgsqlo_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_plpgsqlo_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_plpgsqlo_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_plpgsqlo_windows || exit 1
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_plpgsqlo_windows_x64 || exit 1
    fi

}

################################################################################
# Build plpgsqlo
################################################################################

_build_plpgsqlo() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _build_plpgsqlo_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_plpgsqlo_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_plpgsqlo_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_plpgsqlo_windows || exit 1
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_plpgsqlo_windows_x64 || exit 1
    fi

}

################################################################################
# Postprocess plpgsqlo
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_plpgsqlo() {

    cd $WD/plpgsqlo


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (plpgsqlo/installer.xml.in)"

    _replace PG_VERSION_PLPGSQLO $PG_VERSION_PLPGSQLO installer.xml || _die "Failed to set the version in the installer project file (plpgsqlo/installer.xml)"
    _replace PG_BUILDNUM_PLPGSQLO $PG_BUILDNUM_PLPGSQLO installer.xml || _die "Failed to set the Build Number in the installer project file (plpgsqlo/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the version in the installer project file (plpgsqlo/installer.xml)"

    #_registration_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, COMONENT TYPE)
    _registration_postprocess "$WD/plpgsqlo/staging"  "PLPGSQLO"         "plpgsqloVersion" "/etc/postgres-reg.ini" "plpgsqlo/$PG_MAJOR_VERSION" "plpgsqlo-$PG_MAJOR_VERSION" "plpgsqlo"


    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _postprocess_plpgsqlo_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_plpgsqlo_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_plpgsqlo_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_plpgsqlo_windows || exit 1
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_plpgsqlo_windows_x64 || exit 1
    fi

}

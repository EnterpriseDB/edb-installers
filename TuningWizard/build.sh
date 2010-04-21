#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ];
then
    source $WD/TuningWizard/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/TuningWizard/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/TuningWizard/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/TuningWizard/build-windows.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_TuningWizard() {

    # Create the source directory if required
    if [ ! -e $WD/TuningWizard/source ];
    then
        mkdir $WD/TuningWizard/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/TuningWizard/source

    if [ ! -e wizard ];
    then
      echo "Fetching the tuningwizard sources from the cvs."
      CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/TUNINGTOOL cvs co wizard
    else
      CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/TUNINGTOOL cvs update -PdC
    fi

    # Per-platform prep
    cd $WD

    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ];
    then
        _prep_TuningWizard_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_TuningWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_TuningWizard_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_TuningWizard_windows || exit 1
    fi

}

################################################################################
# Build TuningWizard
################################################################################

_build_TuningWizard() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _build_TuningWizard_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_TuningWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_TuningWizard_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_TuningWizard_windows || exit 1
    fi
}

################################################################################
# Postprocess TuningWizard
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_TuningWizard() {

    cd $WD/TuningWizard


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (TuningWizard/installer.xml.in)"

    _replace PG_VERSION_TUNINGWIZARD $PG_VERSION_TUNINGWIZARD installer.xml || _die "Failed to set the major version in the installer project file (TuningWizard/installer.xml)"
    _replace PG_BUILDNUM_TUNINGWIZARD $PG_BUILDNUM_TUNINGWIZARD installer.xml || _die "Failed to set the major version in the installer project file (TuningWizard/installer.xml)"

    #_registration_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, TEMP DIRECTORY, COMONENT TYPE)
    _registration_postprocess "$WD/TuningWizard/staging" "Tuning Wizard" "TuningWizardVersion" "/etc/postgres-reg.ini" "TuningWizard" "TuningWizard" "tuningwizard" "tuning"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
        _postprocess_TuningWizard_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_TuningWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_TuningWizard_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_TuningWizard_windows || exit 1
    fi
}


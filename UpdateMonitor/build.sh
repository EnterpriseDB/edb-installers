#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/UpdateMonitor/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/UpdateMonitor/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/UpdateMonitor/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/UpdateMonitor/build-windows.sh
fi
    
# Solaris x64
#if [ $PG_ARCH_SOLARIS_X64 = 1 ];
#then
#    source $WD/UpdateMonitor/build-solaris-x64.sh
#fi
#
## Solaris sparc
#if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
#then
#    source $WD/UpdateMonitor/build-solaris-sparc.sh
#fi

################################################################################
# Build preparation
################################################################################

_prep_updatemonitor() {

    # Create the source directory if required
    if [ ! -e $WD/UpdateMonitor/source ];
    then
        mkdir $WD/UpdateMonitor/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    # UpdateMonitor
    if [ ! -e SS-UPDATEMANAGER ]; then
        git clone ssh://pginstaller@cvs.enterprisedb.com/git/SS-UPDATEMANAGER
    else
        cd $WD/UpdateMonitor/source/SS-UPDATEMANAGER
        git pull
    fi

    # Clean up the registration plus xmls
    rm -f $WD/UpdateMonitor/staging/*.xml	

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_updatemonitor_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_updatemonitor_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_updatemonitor_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_updatemonitor_windows || exit 1
    fi
    
    # Solaris x64
#    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
#    then
#        _prep_updatemonitor_solaris_x64 || exit 1
#    fi
#    
#    # Solaris sparc
#    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
#    then
#        _prep_updatemonitor_solaris_sparc || exit 1
#    fi

}

################################################################################
# Build UpdateMonitor
################################################################################

_build_updatemonitor() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_updatemonitor_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_updatemonitor_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_updatemonitor_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_updatemonitor_windows || exit 1
    fi
    
    # Solaris x64
#    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
#    then
#       _build_updatemonitor_solaris_x64 || exit 1
#    fi
#    
#    # Solaris sparc
#    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
#    then
#       _build_updatemonitor_solaris_sparc || exit 1
#    fi

}

################################################################################
# Postprocess UpdateMonitor
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_updatemonitor() {

    cd $WD/UpdateMonitor


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (UpdateMonitor/installer.xml.in)"

    
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the version in the installer project file (UpdateMonitor/installer.xml)"
    _replace PG_VERSION_UPDATE_MONITOR $PG_VERSION_UPDATE_MONITOR installer.xml || _die "Failed to set the version in the installer project file (UpdateMonitor/installer.xml)"
    _replace PG_BUILDNUM_UPDATE_MONITOR $PG_BUILDNUM_UPDATE_MONITOR installer.xml || _die "Failed to set the Build Number in the installer project file (UpdateMonitor/installer.xml)"

    #_registration_plus_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, TEMP DIRECTORY, COMONENT TYPE PRODUCT_DESCRIPTION, PRODUCT_VERSION)
    _registration_plus_postprocess "$WD/UpdateMonitor/staging"  "UpdateMonitor" "iUMVersion" "/etc/postgres-reg.ini" "UpdateMonitor" "UpdateMonitor" "UpdateMonitor" "UpdateMonitor" "$PG_VERSION_UPDATE_MONITOR"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_updatemonitor_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_updatemonitor_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_updatemonitor_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_updatemonitor_windows || exit 1
    fi

    # Solaris x64
#    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
#    then
#        _postprocess_updatemonitor_solaris_x64 || exit 1
#    fi
#
#    # Solaris sparc
#    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
#    then
#        _postprocess_updatemonitor_solaris_sparc || exit 1
#    fi
    
    cd $WD

}

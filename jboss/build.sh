#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/jboss/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/jboss/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/jboss/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/jboss/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_jboss() {

    # Create the source directory if required
    if [ ! -e $WD/jboss/source ];
    then
        mkdir $WD/jboss/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/jboss/source

    # jboss
    if [ -e jboss-$PG_VERSION_JBOSS ];
    then
      echo "Removing existing jboss-$PG_VERSION_JBOSS source directory"
      rm -rf jboss-$PG_VERSION_JBOSS  || _die "Couldn't remove the existing jboss-$PG_VERSION_JBOSS source directory (source/jboss-$PG_VERSION_JBOSS)"
    fi

    echo "Unpacking jboss source..."
    extract_file ../../tarballs/jboss-$PG_VERSION_JBOSS.GA || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_jboss_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_jboss_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_jboss_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_jboss_windows || exit 1
    fi
    
}

################################################################################
# Build jboss
################################################################################

_build_jboss() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_jboss_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_jboss_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_jboss_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_jboss_windows || exit 1
    fi
}

################################################################################
# Postprocess jboss
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_jboss() {

    cd $WD/jboss


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (jboss/installer.xml.in)"
    
    _replace PG_VERSION_JBOSS $PG_VERSION_JBOSS installer.xml || _die "Failed to set the version in the installer project file (jboss/installer.xml)"
    _replace PG_BUILDNUM_JBOSS $PG_BUILDNUM_JBOSS installer.xml || _die "Failed to set the Build Number in the installer project file (jboss/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the Build Number in the installer project file (jboss/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_jboss_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_jboss_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_jboss_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_jboss_windows || exit 1
    fi
}

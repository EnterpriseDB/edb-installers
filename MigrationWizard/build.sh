#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/MigrationWizard/build-osx.sh
    echo "Not yet implemented"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/MigrationWizard/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/MigrationWizard/build-linux-x64.sh
    echo "Not yet implemented"
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/MigrationWizard/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard() {

    # Create the source directory if required
    if [ ! -e $WD/MigrationWizard/source ];
    then
        mkdir $WD/MigrationWizard/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source


    # migrationwizard
    if [ -e wizard ];
    then
      echo "Removing existing wizard source directory"
      rm -rf wizard  || _die "Couldn't remove the existing wizard source directory (source/wizard)"
    fi

    echo "Unpacking migrationwizard source..."
    tar -jxvf ../../tarballs/MigrationWizard-$PG_MIGRATIONWIZARD_TARBALL.tar.bz2

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_MigrationWizard_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_MigrationWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_MigrationWizard_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_MigrationWizard_windows || exit 1
    fi
	
}

################################################################################
# Build MigrationWizard
################################################################################

_build_MigrationWizard() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_build_MigrationWizard_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_MigrationWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_MigrationWizard_linux_x64 || exit 1
        echo "Not yet implemented"
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_MigrationWizard_windows || exit 1
    fi
}

################################################################################
# Postprocess MigrationWizard
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_MigrationWizard() {

    cd $WD/MigrationWizard


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (MigrationWizard/installer.xml.in)"

    _replace PG_MIGRATIONWIZARD_VERSION $PG_MIGRATIONWIZARD_VERSION installer.xml || _die "Failed to set the major version in the installer project file (MigrationWizard/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_MigrationWizard_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_MigrationWizard_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_MigrationWizard_linux_x64 || exit 1
        echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_MigrationWizard_windows || exit 1
    fi
}

#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/StackBuilderPlus/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/StackBuilderPlus/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/StackBuilderPlus/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/StackBuilderPlus/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus() {

    # Create the source directory if required
    if [ ! -e $WD/StackBuilderPlus/source ];
    then
        mkdir $WD/StackBuilderPlus/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    # StackBuilderPlus
    if [ ! -e STACKBUILDER-PLUS ]; then
        git clone ssh://pginstaller@cvs.enterprisedb.com/git/STACKBUILDER-PLUS
    else
        cd $WD/StackBuilderPlus/source/STACKBUILDER-PLUS
        git pull
    fi

    cd $WD/StackBuilderPlus/source
    # Update Manager
    if [ ! -e SS-UPDATEMANAGER ]; then
        git clone ssh://pginstaller@cvs.enterprisedb.com/git/SS-UPDATEMANAGER
    else
        cd $WD/StackBuilderPlus/source/SS-UPDATEMANAGER
        git pull
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_stackbuilderplus_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_stackbuilderplus_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_stackbuilderplus_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_stackbuilderplus_windows || exit 1
    fi
    
}

################################################################################
# Build StackBuilderPlus
################################################################################

_build_stackbuilderplus() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_stackbuilderplus_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_stackbuilderplus_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_stackbuilderplus_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_stackbuilderplus_windows || exit 1
    fi
}

################################################################################
# Postprocess StackBuilderPlus
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_stackbuilderplus() {

    cd $WD/StackBuilderPlus


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (StackBuilderPlus/installer.xml.in)"

    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed -e 's/\./_/'`
    
    _replace PG_VERSION_SBP $PG_VERSION_SBP installer.xml || _die "Failed to set the version in the installer project file (StackBuilderPlus/installer.xml)"
    _replace PG_BUILDNUM_SBP $PG_BUILDNUM_SBP installer.xml || _die "Failed to set the Build Number in the installer project file (StackBuilderPlus/installer.xml)"
    _replace PG_VERSION_STR $PG_VERSION_STR installer.xml || _die "Failed to set the Build Number in the installer project file (StackBuilderPlus/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the Build Number in the installer project file (StackBuilderPlus/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_stackbuilderplus_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_stackbuilderplus_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_stackbuilderplus_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_stackbuilderplus_windows || exit 1
    fi

    cd $WD

}

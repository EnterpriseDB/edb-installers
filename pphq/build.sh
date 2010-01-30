#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pphq/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pphq/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pphq/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pphq/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pphq() {

    # Create the source directory if required
    if [ ! -e $WD/pphq/source ];
    then
        mkdir $WD/pphq/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    # pphq
    if [ -e pphq-$PG_VERSION_PPHQ ];
    then
      echo "Removing existing pphq-$PG_VERSION_PPHQ source directory"
      rm -rf pphq-$PG_VERSION_PPHQ  || _die "Couldn't remove the existing pphq-$PG_VERSION_PPHQ source directory (source/pphq-$PG_VERSION_PPHQ)"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        if [ -e pphq-"$PG_VERSION_PPHQ" ];
        then
          echo "Removing existing pphq-"$PG_VERSION_PPHQ" source directory"
          rm -rf pphq-"$PG_VERSION_PPHQ"  || _die "Couldn't remove the existing pphq-"$PG_VERSION_PPHQ" source directory (source/pphq-"$PG_VERSION_PPHQ")"
        fi
   
	echo "Unpacking pphq source..."
	 extract_file ../../tarballs/pphq-$PG_VERSION_PPHQ || exit 1
    fi

    # Linux-x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        if [ -e pphq-"$PG_VERSION_PPHQ"-x64 ];
        then
          echo "Removing existing pphq-"$PG_VERSION_PPHQ"-x64 source directory"
          rm -rf pphq-"$PG_VERSION_PPHQ"-x64  || _die "Couldn't remove the existing pphq-"$PG_VERSION_PPHQ"-x64 source directory (source/pphq-"$PG_VERSION_PPHQ"-x64)"
        fi
   
	echo "Unpacking pphq source..."
	 extract_file ../../tarballs/pphq-$PG_VERSION_PPHQ-x64 || exit 1
    fi

    # osx
    if [ $PG_ARCH_OSX = 1 ];
    then
        if [ -e pphq-"$PG_VERSION_PPHQ"-osx ];
        then
          echo "Removing existing pphq-"$PG_VERSION_PPHQ"-osx source directory"
          rm -rf pphq-"$PG_VERSION_PPHQ"-osx || _die "Couldn't remove the existing pphq-"$PG_VERSION_PPHQ"-osx source directory (source/pphq-"$PG_VERSION_PPHQ"-osx)"
        fi
   
	echo "Unpacking pphq source..."
	 extract_file ../../tarballs/pphq-$PG_VERSION_PPHQ-osx || exit 1
    fi

    # windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        if [ -e pphq-"$PG_VERSION_PPHQ"-windows ];
        then
          echo "Removing existing pphq-"$PG_VERSION_PPHQ"-windows source directory"
          rm -rf pphq-"$PG_VERSION_PPHQ"-windows || _die "Couldn't remove the existing pphq-"$PG_VERSION_PPHQ"-windows source directory (source/pphq-"$PG_VERSION_PPHQ"-windows)"
        fi
   
	echo "Unpacking pphq source..."
	 extract_file ../../tarballs/pphq-$PG_VERSION_PPHQ-windows || exit 1
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pphq_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pphq_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pphq_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pphq_windows || exit 1
    fi
    
}

################################################################################
# Build pphq
################################################################################

_build_pphq() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pphq_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pphq_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pphq_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pphq_windows || exit 1
    fi
}

################################################################################
# Postprocess pphq
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pphq() {

    cd $WD/pphq


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pphq/installer.xml.in)"
    
    _replace PG_VERSION_PPHQ $PG_VERSION_PPHQ installer.xml || _die "Failed to set the version in the installer project file (pphq/installer.xml)"
    _replace PG_BUILDNUM_PPHQ $PG_BUILDNUM_PPHQ installer.xml || _die "Failed to set the Build Number in the installer project file (pphq/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pphq_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pphq_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pphq_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_pphq_windows || exit 1
    fi
}

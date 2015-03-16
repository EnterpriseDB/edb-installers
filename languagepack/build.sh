#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/languagepack/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/languagepack/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/languagepack/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/languagepack/build-windows.sh
fi

# Windows -- It will remain 32 bit installer for Win-64 but it will take binaries from 64 bit distro.
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/languagepack/build-windows.sh 
fi

# Solaris-Intel
if [ $PG_ARCH_SOLARIS_X64 = 1 ];
then
    source $WD/languagepack/build-solaris.sh
fi

# Solaris-Sparc
if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/languagepack/build-solaris.sh
fi    

# HPUX
if [ $PG_ARCH_HPUX = 1 ];
then
    source $WD/languagepack/build-hpux.sh
fi    

################################################################################
# Build preparation
################################################################################

_prep_languagepack() {

    # Create the source directory if required
    if [ ! -e $WD/languagepack/source ];
    then
        mkdir $WD/languagepack/source
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_languagepack_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
	echo " "
        _prep_languagepack_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_languagepack_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_languagepack_windows x32 || exit 1
    fi

    # Windows -- It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_languagepack_windows x64 || exit 1
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_languagepack_solaris intel || exit 1
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_languagepack_solaris sparc || exit 1
    fi    

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _prep_languagepack_hpux || exit 1
    fi    
}

################################################################################
# Build languagepack
################################################################################

_build_languagepack() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_languagepack_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
	echo " "
        _build_languagepack_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_languagepack_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_languagepack_windows x32 || exit 1
    fi

    # Windows -- It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_languagepack_windows x64 || exit 1
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _build_languagepack_solaris intel || exit 1
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _build_languagepack_solaris sparc || exit 1
    fi

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _build_languagepack_hpux || exit 1
    fi
}

################################################################################
# Postprocess languagepack
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_languagepack() {

    cd $WD/languagepack


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (languagepack/installer.xml.in)"

    _replace EDB_VERSION_PERL $EDB_VERSION_PERL installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_VERSION_TCL $EDB_VERSION_TCL installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_VERSION_PYTHON $EDB_VERSION_PYTHON installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"    
    _replace EDB_VERSION_LANGUAGEPACK $EDB_VERSION_LANGUAGEPACK installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_BUILDNUM_LANGUAGEPACK $EDB_BUILDNUM_LANGUAGEPACK installer.xml || _die "Failed to set the buildnumber in the installer project file (languagepack/installer.xml)"
    _replace EDB_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_languagepack_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_languagepack_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_languagepack_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_languagepack_windows x32 || exit 1
    fi

    # Windows --It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
       _postprocess_languagepack_windows x64 || exit 1
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_languagepack_solaris intel || exit 1
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_languagepack_solaris sparc || exit 1
    fi

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _postprocess_languagepack_hpux || exit 1
    fi
}

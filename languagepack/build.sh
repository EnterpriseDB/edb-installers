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
        _prep_languagepack_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_languagepack_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_languagepack_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_languagepack_windows x32 
    fi

    # Windows -- It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_languagepack_windows x64 
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_languagepack_solaris intel 
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_languagepack_solaris sparc 
    fi    

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _prep_languagepack_hpux 
    fi    
}

################################################################################
# Build languagepack
################################################################################

_build_languagepack() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_languagepack_osx 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_languagepack_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_languagepack_linux_x64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_languagepack_windows x32 
    fi

    # Windows -- It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_languagepack_windows x64 
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _build_languagepack_solaris intel 
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _build_languagepack_solaris sparc 
    fi

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _build_languagepack_hpux 
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

    echo "Extract the number from the $PG_LP_VERSION"
    LP_VERSION=`echo $PG_LP_VERSION | cut -f1 -d "."`

    _replace EDB_VERSION_PERL $PG_VERSION_PERL installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_VERSION_TCL $PG_VERSION_TCL installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_VERSION_PYTHON $PG_VERSION_PYTHON installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_VERSION_LANGUAGEPACK $PG_VERSION_LANGUAGEPACK installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    _replace EDB_BUILDNUM_LANGUAGEPACK $PG_BUILDNUM_LANGUAGEPACK installer.xml || _die "Failed to set the buildnumber in the installer project file (languagepack/installer.xml)"
    _replace EDB_MAJOR_VERSION $LP_VERSION installer.xml || _die "Failed to set the version in the installer project file (languagepack/installer.xml)"
    
    # Replace placeholder for Python batch script
    if [ -f $WD/languagepack/scripts/windows-x64/Python_Build.bat ];
    then
        rm -f $WD/languagepack/scripts/windows-x64/Python_Build.bat
    fi
    cp $WD/languagepack/scripts/windows-x64/Python_Build.bat.in $WD/languagepack/scripts/windows-x64/Python_Build.bat || _die "Failed to copy Python_Build.bat"

    _replace PG_PYTHON_TCL_TK $PG_PYTHON_TCL_TK $WD/languagepack/scripts/windows-x64/Python_Build.bat || die "Failed to set PG_PYTHON_TCL_TK Version"
    _replace PG_PYTHON_TIX $PG_PYTHON_TIX $WD/languagepack/scripts/windows-x64/Python_Build.bat || die "Failed to set PG_PYTHON_TIX Version"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_languagepack_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_languagepack_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_languagepack_linux_x64 
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_languagepack_windows x32 
    fi

    # Windows --It will remain 32 bit installer for Windows-x64 but it will take binaries from 64 bit distro.
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
       _postprocess_languagepack_windows x64 
    fi

    # Solaris Intel
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_languagepack_solaris intel 
    fi

    # Solaris Sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_languagepack_solaris sparc 
    fi

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _postprocess_languagepack_hpux 
    fi
}

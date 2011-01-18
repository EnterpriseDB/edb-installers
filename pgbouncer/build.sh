#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pgbouncer/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pgbouncer/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pgbouncer/build-linux-x64.sh
fi

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/pgbouncer/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pgbouncer/build-windows.sh
fi
    
# Solaris x64
if [ $PG_ARCH_SOLARIS_X64 = 1 ];
then
    source $WD/pgbouncer/build-solaris-x64.sh
fi

# Solaris sparc
if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/pgbouncer/build-solaris-sparc.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_pgbouncer() {

    # Create the source directory if required
    if [ ! -e $WD/pgbouncer/source ];
    then
        mkdir $WD/pgbouncer/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    # pgbouncer
    if [ -e pgbouncer-$PG_VERSION_PGBOUNCER ];
    then
      echo "Removing existing pgbouncer-$PG_VERSION_PGBOUNCER source directory"
      rm -rf pgbouncer-$PG_VERSION_PGBOUNCER  || _die "Couldn't remove the existing pgbouncer-$PG_VERSION_PGBOUNCER source directory (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    fi

    echo "Unpacking pgbouncer source..."
    extract_file ../../tarballs/pgbouncer-$PG_VERSION_PGBOUNCER || exit 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pgbouncer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pgbouncer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pgbouncer_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_prep_pgbouncer_linux_ppc64 || exit 1
        echo "Linux-PPC64 build pre-process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pgbouncer_windows || exit 1
    fi
    
    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_pgbouncer_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_pgbouncer_solaris_sparc || exit 1
    fi
}

################################################################################
# Build pgbouncer
################################################################################

_build_pgbouncer() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pgbouncer_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pgbouncer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pgbouncer_linux_x64 || exit 1
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
       #_build_pgbouncer_linux_ppc64 || exit 1
       echo "Linux-PPC64 build process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pgbouncer_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
       _build_pgbouncer_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
       _build_pgbouncer_solaris_sparc || exit 1
    fi
}


################################################################################
# Postprocess pgbouncer
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pgbouncer() {

    cd $WD/pgbouncer

    PGBOUNCER_SERVICE_VER=`echo $PG_MAJOR_VERSION | sed 's/\.//'`
    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pgbouncer/installer.xml.in)"
    
    _replace PG_VERSION_PGBOUNCER $PG_VERSION_PGBOUNCER installer.xml || _die "Failed to set the version in the installer project file (pgbouncer/installer.xml)"
    _replace PG_BUILDNUM_PGBOUNCER $PG_BUILDNUM_PGBOUNCER installer.xml || _die "Failed to set the Build Number in the installer project file (pgbouncer/installer.xml)"
    _replace PGBOUNCER_SERVICE_VER $PGBOUNCER_SERVICE_VER installer.xml || _die "Failed to set the service version in the installer project file (pgbouncer/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pgbouncer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pgbouncer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pgbouncer_linux_x64 || exit 1
    fi
    
    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_pgbouncer_linux_ppc64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_pgbouncer_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_pgbouncer_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_pgbouncer_solaris_sparc || exit 1
    fi
}

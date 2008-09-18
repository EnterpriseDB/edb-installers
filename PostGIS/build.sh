#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    #source $WD/PostGIS/build-osx.sh
    echo "Not yet implemented" 
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/PostGIS/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    #source $WD/PostGIS/build-linux-x64.sh
    echo "Not yet implemented" 
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    #source $WD/PostGIS/build-windows.sh
    echo "Not yet implemented" 
fi
    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS() {

    # Create the source directory if required
    if [ ! -e $WD/PostGIS/source ];
    then
        mkdir $WD/PostGIS/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source


    # postgis
    if [ -e postgis-$PG_POSTGIS_TARBALL ];
    then
      echo "Removing existing postgis-$PG_POSTGIS_TARBALL source directory"
      rm -rf postgis-$PG_POSTGIS_TARBALL  || _die "Couldn't remove the existing postgis-$PG_POSTGIS_TARBALL source directory (source/postgis-$PG_POSTGIS_TARBALL)"
    fi

    echo "Unpacking postgis source..."
    tar -zxvf ../../tarballs/postgis-$PG_POSTGIS_TARBALL.tar.gz

    # geos
    if [ -e geos-$PG_GEOS_TARBALL ];
    then
      echo "Removing existing geos-$PG_GEOS_TARBALL source directory"
      rm -rf geos-$PG_GEOS_TARBALL  || _die "Couldn't remove the existing geos-$PG_GEOS_TARBALL source directory (source/geos-$PG_GEOS_TARBALL)"
    fi

    echo "Unpacking geos source..."
    tar -jxvf ../../tarballs/geos-$PG_GEOS_TARBALL.tar.bz2

    # proj
    if [ -e proj-$PG_PROJ_TARBALL ];
    then
      echo "Removing existing proj-$PG_PROJ_TARBALL source directory"
      rm -rf proj-$PG_PROJ_TARBALL  || _die "Couldn't remove the existing proj-$PG_PROJ_TARBALL source directory (source/proj-$PG_PROJ_TARBALL)"
    fi

    echo "Unpacking proj source..."
    tar -zxvf ../../tarballs/proj-$PG_PROJ_TARBALL.tar.gz

    echo "Copying the postgresql jar file..."
    cp ../../tarballs/postgresql-$PG_POSTGRESQL_JAR.jar .

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_prep_PostGIS_osx || exit 1
        echo "Not yet implemented" 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_PostGIS_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_prep_PostGIS_linux_x64 || exit 1
        echo "Not yet implemented" 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_prep_PostGIS_windows || exit 1
        echo "Not yet implemented" 
    fi
	
}

################################################################################
# Build PostGIS
################################################################################

_build_PostGIS() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_build_PostGIS_osx || exit 1
        echo "Not yet implemented" 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_PostGIS_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_build_PostGIS_linux_x64 || exit 1
        echo "Not yet implemented" 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_build_PostGIS_windows || exit 1
        echo "Not yet implemented" 
    fi
}

################################################################################
# Postprocess PostGIS
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_PostGIS() {

    cd $WD/PostGIS


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (PostGIS/installer.xml.in)"

    _replace PG_POSTGIS_VERSION $PG_POSTGIS_VERSION installer.xml || _die "Failed to set the major version in the installer project file (PostGIS/installer.xml)"

    _replace PG_GEOS_VERSION $PG_GEOS_VERSION installer.xml || _die "Failed to set the major version of geos in the installer project file (PostGIS/installer.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        #_postprocess_PostGIS_osx || exit 1
        echo "Not yet implemented"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_PostGIS_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        #_postprocess_PostGIS_linux_x64 || exit 1
        echo "Not yet implemented"
    fi
	
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        #_postprocess_PostGIS_windows || exit 1
        echo "Not yet implemented"
    fi
}

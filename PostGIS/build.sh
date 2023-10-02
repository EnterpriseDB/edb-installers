#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/PostGIS/build-osx.sh
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
    if [ -e postgis-$PG_VERSION_POSTGIS ];
    then
      echo "Removing existing postgis-$PG_VERSION_POSTGIS source directory"
      rm -rf postgis-$PG_VERSION_POSTGIS  || _die "Couldn't remove the existing postgis-$PG_VERSION_POSTGIS source directory (source/postgis-$PG_VERSION_POSTGIS)"
    fi

    echo "Unpacking postgis source..."
    extract_file  ../../tarballs/postgis-$PG_VERSION_POSTGIS 

#    echo "Extracting the postgis-java source..."
#    extract_file  ../../tarballs/postgis-java-$PG_VERSION_POSTGIS_JAVA
#    mv postgis-java-$PG_VERSION_POSTGIS_JAVA  postgis-$PG_VERSION_POSTGIS/java/

    echo "Applying patches..." 
    #cd postgis-$PG_VERSION_POSTGIS
    #patch -p1 < ~/tarballs/postgis-211-liblwgeom.patch

    cd $WD/PostGIS/source  

#    echo "Extracting the postgresql jar file..."
#    extract_file  ../../tarballs/pgJDBC-$PG_VERSION_PGJDBC
#    mv pgJDBC-$PG_VERSION_PGJDBC/*.jar .

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_PostGIS_osx 
    fi
}

################################################################################
# Build PostGIS
################################################################################

_build_PostGIS() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_PostGIS_osx 
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

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    _replace PG_VERSION_POSTGIS "$PG_VERSION_POSTGIS" installer.xml || _die "Failed to set the major version in the installer project file (PostGIS/installer.xml)"

    _replace PG_BUILDNUM_POSTGIS $PG_BUILDNUM_POSTGIS installer.xml || _die "Failed to set Build Number in the installer project file (PostGIS/installer.xml)"

    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION installer.xml || _die "Failed to set the PG Current Number in the installer project file (PostGIS/installer.xml)"
    
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the PG MAJOR Number in the installer project file (PostGIS/installer.xml)"
    _replace POSTGIS_MAJOR_VERSION $POSTGIS_MAJOR_VERSION installer.xml || _die "Failed to set the POSTGIS MAJOR Number in the installer project file (PostGIS/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_PostGIS_osx 
    fi
}


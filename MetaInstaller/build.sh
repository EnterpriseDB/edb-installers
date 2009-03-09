#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ "$PG_ARCH_OSX" = 1 ]; 
then
    source $WD/MetaInstaller/build-osx.sh
fi

# Linux
if [ "$PG_ARCH_LINUX" = 1 ];
then
    source $WD/MetaInstaller/build-linux.sh
fi

# Linux x64
if [ "$PG_ARCH_LINUX_X64" = 1 ];
then
    source $WD/MetaInstaller/build-linux-x64.sh
fi

# Windows
if [ "$PG_ARCH_WINDOWS" = 1 ];
then
    source $WD/MetaInstaller/build-windows.sh
fi

PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    
################################################################################
# Build preparation
################################################################################

_prep_metainstaller() {

    # Per-platform prep
    cd $WD/MetaInstaller

    if [ -d staging ];
    then
      rm -rf staging || _die "Unable to remove $WD/MetaInstaller/staging folder"
    fi
    
    mkdir staging
    
    cd $WD

    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_metainstaller_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_metainstaller_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_metainstaller_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_metainstaller_windows || exit 1
    fi
}

################################################################################
# Build server
################################################################################

_build_metainstaller() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_metainstaller_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_metainstaller_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_metainstaller_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_metainstaller_windows || exit 1
    fi
}

################################################################################
# Postprocess server
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_metainstaller() {
    #Obtain the catalog number from PostgreSQL source.
    if [ ! -f $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h ];
    then
       _die "$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h does not exist, please build 'server' first".
    fi

    cd $WD/server
    # Get the catalog version number
    PG_CATALOG_VERSION=`cat source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`

    cd $WD/MetaInstaller

    # Prepare the installer XML file
    if [ -f postgresplus.xml ];
    then
        rm postgresplus.xml
    fi

    cp postgresplus.xml.in postgresplus.xml || _die "Failed to copy the installer project file (MetaInstaller/postgresplus.xml.in)"
    _replace PG_VERSION_METAINSTALLER $PG_VERSION_METAINSTALLER postgresplus.xml || _die "Failed to set the major version in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_PACKAGE_VERSION $PG_PACKAGE_VERSION postgresplus.xml || _die "Failed to set the postgresql version in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION postgresplus.xml || _die "Failed to set the pg version in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_VERSION_SLONY $PG_VERSION_SLONY postgresplus.xml || _die "Failed to set the slony version in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_BUILDNUM_SLONY $PG_BUILDNUM_SLONY postgresplus.xml || _die "Failed to set the pg buildnum  in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_VERSION_PGJDBC $PG_VERSION_PGJDBC postgresplus.xml || _die "Failed to set the pgJDBC version  in the installer project file (MetaInstaller/postgresplus.xml)"
    _replace PG_BUILDNUM_PGJDBC $PG_BUILDNUM_PGJDBC postgresplus.xml || _die "Failed to set the pgJDBC buildnum  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_VERSION_POSTGIS $PG_VERSION_POSTGIS postgresplus.xml || _die "Failed to set the postgis version  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_BUILDNUM_POSTGIS $PG_BUILDNUM_POSTGIS postgresplus.xml || _die "Failed to set the postgis buildnum  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_VERSION_PSQLODBC $PG_VERSION_PSQLODBC postgresplus.xml || _die "Failed to set the psqlodbc version  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_BUILDNUM_PSQLODBC $PG_BUILDNUM_PSQLODBC postgresplus.xml || _die "Failed to set the psqlodbc buildnum  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_VERSION_NPGSQL $PG_VERSION_NPGSQL postgresplus.xml || _die "Failed to set the npgsql version  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_BUILDNUM_NPGSQL $PG_BUILDNUM_NPGSQL postgresplus.xml || _die "Failed to set the npgsql buildnum  in the installer project file (MetaInstaller/postgresplus.xml)"
   _replace PG_CATALOG_VERSION $PG_CATALOG_VERSION postgresplus.xml || _die "Failed to set the catalog version number in the installer project file (MetaInstaller/postgresplus.xml)"
 
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_metainstaller_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_metainstaller_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_metainstaller_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_metainstaller_windows || exit 1
    fi
}

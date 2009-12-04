#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/server/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/server/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/server/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/server/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_server() {

    # Create the source directory if required
    if [ ! -e $WD/server/source ];
    then
        mkdir $WD/server/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/server/source

    # PostgreSQL
    if [ -e postgresql-$PG_TARBALL_POSTGRESQL ];
    then
      echo "Removing existing postgresql-$PG_TARBALL_POSTGRESQL source directory"
      rm -rf postgresql-$PG_TARBALL_POSTGRESQL  || _die "Couldn't remove the existing postgresql-$PG_TARBALL_POSTGRESQL source directory (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    fi
	
    echo "Unpacking PostgreSQL source..."
    tar -jxvf ../../tarballs/postgresql-$PG_TARBALL_POSTGRESQL.tar.bz2

    # pgAdmin
    if [ -e pgadmin3-$PG_TARBALL_PGADMIN ];
    then
      echo "Removing existing pgadmin3-$PG_TARBALL_PGADMIN source directory"
      rm -rf pgadmin3-$PG_TARBALL_PGADMIN  || _die "Couldn't remove the existing pgadmin3-$PG_TARBALL_PGADMIN source directory (source/pgadmin3-$PG_TARBALL_PGADMIN)"
    fi

    echo "Unpacking pgAdmin source..."
    tar -zxvf ../../tarballs/pgadmin3-$PG_TARBALL_PGADMIN.tar.gz

    # pl/Java
    if [ -e pljava-$PG_TARBALL_PLJAVA ];
    then
      echo "Removing existing pljava-$PG_TARBALL_PLJAVA source directory"
      rm -rf pljava-$PG_TARBALL_PLJAVA || _die "Couldn't remove the existing pljava-$PG_TARBALL_PLJAVA source directory (source/pljava-$PG_TARBALL_PLJAVA)"
    fi

    echo "Unpacking pljava source..."
    tar -zxvf ../../tarballs/pljava-src-$PG_TARBALL_PLJAVA.tar.gz
    cd pljava-$PG_TARBALL_PLJAVA 
    patch -p0 < ../../../tarballs/pljava-fix.patch  

    # Debugger
    cd $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib

    if [ -e pldebugger ]; 
    then
    echo "Updating debugger source..."
        cd pldebugger
        cvs -z3 update -dP  || _die "Failed to update the pldebugger code" 
    else
        echo "Fetching debugger source..."
        cvs -d:pserver:anonymous@cvs.pgfoundry.org:/cvsroot/edb-debugger co -d pldebugger server || _die "Failed to checkout the pldebugger code"
    fi  
	
	# StackBuilder (CVS Tree)
	echo "Updating the StackBuilder source tree..."
	cd $WD/server/source/stackbuilder
    cvs -z3 update -dP

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_server_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_server_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_server_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_server_windows || exit 1
    fi
}

################################################################################
# Build server
################################################################################

_build_server() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_server_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_server_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_server_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_server_windows || exit 1
    fi
}

################################################################################
# Postprocess server
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_server() {

    cd $WD/server

    # Get the catalog version number
    PG_CATALOG_VERSION=`cat source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (server/installer.xml.in)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the major version in the installer project file (server/installer.xml)"
    _replace PG_MINOR_VERSION $PG_MINOR_VERSION installer.xml || _die "Failed to set the minor version in the installer project file (server/installer.xml)"
    _replace PG_STAGING_DIR $WD/server/staging installer.xml || _die "Failed to set the staging directory in the installer project file (server/installer.xml)"
    _replace PG_CATALOG_VERSION $PG_CATALOG_VERSION installer.xml || _die "Failed to set the catalog version number in the installer project file (server/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_server_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_server_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_server_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_server_windows || exit 1
    fi
}

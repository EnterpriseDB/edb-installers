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

# Linux ppc64
if [ $PG_ARCH_LINUX_PPC64 = 1 ];
then
    source $WD/server/build-linux-ppc64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/server/build-windows.sh
fi

# Windows x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $WD/server/build-windows-x64.sh
fi
    
# Solaris x64
if [ $PG_ARCH_SOLARIS_X64 = 1 ];
then
    source $WD/server/build-solaris-x64.sh
fi

# Solaris sparc
if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/server/build-solaris-sparc.sh
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
    if [ -e pgadmin4-$PG_TARBALL_PGADMIN ];
    then
      echo "Removing existing pgadmin4-$PG_TARBALL_PGADMIN source directory"
      rm -rf pgadmin4-$PG_TARBALL_PGADMIN  || _die "Couldn't remove the existing pgadmin4-$PG_TARBALL_PGADMIN source directory (source/pgadmin4-$PG_TARBALL_PGADMIN)"
    fi

    echo "Unpacking pgAdmin source..."
    tar -zxvf ../../tarballs/pgadmin4-$PG_TARBALL_PGADMIN.tar.gz
    # Applying the patch for pgAdmin.Because it has icon rendering issue.
    cd pgadmin4-$PG_TARBALL_PGADMIN
    if [ -e $WD/tarballs/icon_display_issue.patch ]
    then
        echo "Appyling the icon_display_issue.patch"
        patch -p1 < $WD/tarballs/icon_display_issue.patch || _die "icon_display_issue.patch doesnot applied"
    fi

    # Patch to compile the pgAdmin runtime successfully on macOS with 10.19 SDK
    if [ "$PG_TARBALL_PGADMIN" = "4.21" ]
    then
        if [ -e $WD/tarballs/pgadmin-oldsdk.patch ]
        then
            echo "Appyling the pgadmin-oldsdk.patch"
            patch -p1 < ~/tarballs/pgadmin-oldsdk.patch || _die "failed to apply pgadmin-oldsdk.patch"
        fi
    fi

    # psycopg2 latest version 2.8 is not yet supported. Hence use the last supported version
    if [ "$PG_TARBALL_PGADMIN" = "4.4" ]
    then
        sed -i 's/psycopg2.*/psycopg2==2.7.7/' requirements.txt || die "failed to modify requirements.txt for psycopg2"
    fi

    cd $WD/server/source

    # Debugger
    if [ -e pldebugger ]; 
    then
        echo "Updating debugger source..."
        cd pldebugger
        git pull || _die "Failed to update the pldebugger code"
        cd ..
    else
        echo "Fetching debugger source..."
        git clone git://git.postgresql.org/git/pldebugger.git || _die "Failed to checkout the pldebugger code"
    fi  
    
    # Get the last commit id
    cd pldebugger
    echo "pldebugger repo details:" 
    echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
    echo "Last commit:"
    git log -n 1
    cd ..
    cp -R pldebugger $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/

    # StackBuilder (Git Tree)
    if [ -e $WD/server/source/stackbuilder/CVS/Repository ]; then
        echo "Remove existing stackbuilder directory (based on CVS)..."
        rm -rf $WD/server/source/stackbuilder
    fi

    if [ ! -e $WD/server/source/stackbuilder ]; then
        echo "Cloning the StackBuilder source tree..."
        cd $WD/server/source
        git clone git://git.postgresql.org/git/stackbuilder
    else
        echo "Updating the StackBuilder source tree..."
        cd $WD/server/source/stackbuilder
        git reset HEAD --hard && git clean -dfx
        git pull
    fi
    
    # Get the last commit id
    cd $WD/server/source/stackbuilder
    echo "stackbuilder repo details:" 
    echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
    echo "Last commit:"
    git log -n 1

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_server_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_server_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_server_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_prep_server_linux_ppc64 
        echo "Linux-PPC64 build pre-process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_server_windows 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_server_windows_x64 
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_server_solaris_x64 
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_server_solaris_sparc 
    fi
}

################################################################################
# Build server
################################################################################

_build_server() {

    # Get the pgAdmin versioning
    cd $WD/server/source
    if [ -e pgadmin4-$PG_TARBALL_PGADMIN ];
    then
        cd pgadmin4-$PG_TARBALL_PGADMIN
        export APP_RELEASE=`grep "^APP_RELEASE" web/config.py | cut -d"=" -f2 | sed 's/ //g'`
        export APP_REVISION=`grep "^APP_REVISION" web/config.py | cut -d"=" -f2 | sed 's/ //g'`
        export APP_NAME=`grep "^APP_NAME" web/config.py | cut -d"=" -f2 | sed "s/'//g" | sed 's/^ //'`
        export APP_BUNDLE_NAME=$APP_NAME.app
        export APP_LONG_VERSION=$APP_RELEASE.$APP_REVISION
        export APP_SHORT_VERSION=`echo $APP_LONG_VERSION | cut -d . -f1,2`
        export APP_SUFFIX=`grep "^APP_SUFFIX" web/config.py | cut -d"=" -f2 | sed 's/ //g' | sed "s/'//g"`
        if [ ! -z $APP_SUFFIX ]; then
            export APP_LONG_VERSION=$APP_LONG_VERSION-$APP_SUFFIX
        fi
    fi

    # Set PYTHON_VERSION variable required for pgadmin build
    export PYTHON_HOME=/System/Library/Frameworks/Python.framework/Versions/2.7
    export PYTHON_VERSION="27"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_server_osx 
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_server_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_server_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        #_build_server_linux_ppc64 
        echo "Linux-PPC64 build process is not part of build framework yet."
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_server_windows 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_server_windows_x64 
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _build_server_solaris_x64 
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _build_server_solaris_sparc 
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
    PG_CONTROL_VERSION=`cat source/postgresql-$PG_TARBALL_POSTGRESQL/src/include/catalog/pg_control.h |grep "#define PG_CONTROL_VERSION" | awk '{print $3}'`

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (server/installer.xml.in)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the major version in the installer project file (server/installer.xml)"
    _replace PG_MINOR_VERSION $PG_MINOR_VERSION installer.xml || _die "Failed to set the minor version in the installer project file (server/installer.xml)"
    _replace PG_PACKAGE_VERSION $PG_PACKAGE_VERSION installer.xml || _die "Failed to set the package version in the installer project file (server/installer.xml)"
    _replace PG_STAGING_DIR $WD/server/staging installer.xml || _die "Failed to set the staging directory in the installer project file (server/installer.xml)"
    _replace PG_CATALOG_VERSION $PG_CATALOG_VERSION installer.xml || _die "Failed to set the catalog version number in the installer project file (server/installer.xml)"
    _replace PG_CONTROL_VERSION $PG_CONTROL_VERSION installer.xml || _die "Failed to set the catalog version number in the installer project file (server/installer.xml)"

    _replace PERL_PACKAGE_VERSION $PG_VERSION_PERL installer.xml || _die "Failed to set the PERL version in server/installer.xml file."
    _replace PYTHON_PACKAGE_VERSION $PG_VERSION_PYTHON installer.xml || _die "Failed to set the PYTHON version in server/installer.xml file."
    _replace TCL_PACKAGE_VERSION $PG_VERSION_TCL installer.xml || _die "Failed to set the TCL version in server/installer.xml file."
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_server_osx 
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_server_linux 
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_server_linux_x64 
    fi

    # Linux ppc64
    if [ $PG_ARCH_LINUX_PPC64 = 1 ];
    then
        _postprocess_server_linux_ppc64 
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_server_windows 
    fi

    # Windows x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _postprocess_server_windows_x64 
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_server_solaris_x64 
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_server_solaris_sparc 
    fi
}

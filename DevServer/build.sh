#!/bin/bash

# Copy the script folder from server
if [ -e $WD/DevServer/scripts ]; then
    echo "Removing existing scripts directory"
    rm -rf $WD/DevServer/scripts || _die "couldn't remove the scripts directory"
fi
echo "creating scripts directory"
mkdir -p $WD/DevServer/scripts || _die "Failed to create directory for scripts"
cp -R $WD/server/scripts/* $WD/DevServer/scripts || _die "Failed to copy the script folder from server to DevServer"

# Copy the resources folder from server
if [ -e $WD/DevServer/resources ]; then
    echo "Removing existing resources directory"
    rm -rf $WD/DevServer/resources _die "couldn't remove the resources directory"
fi
echo "creating resources directory"
mkdir -p $WD/DevServer/resources || _die "Failed to create directory for resources"
cp -R $WD/server/resources/* $WD/DevServer/resources || _die "Failed to copy the resources folder from server to DevServer"

# Copy the i18n folder from server
if [ -e $WD/DevServer/i18n ]; then
    echo "Removing existing i18n directory"
    rm -rf $WD/DevServer/i18n _die "couldn't remove the i18n directory"
fi
echo "creating i18n directory"
mkdir -p $WD/DevServer/i18n || _die "Failed to create directory for i18n"
cp -R $WD/server/i18n/* $WD/DevServer/i18n || _die "Failed to copy the i18n folder from server to DevServer"

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    if [ -e $WD/DevServer/build-osx.sh ];
    then
	echo "Removing existing build-osx.sh script"
	rm -f $WD/DevServer/build-osx.sh || _die "couldn't remove the build.osx.sh script"
    fi
    cp $WD/server/build-osx.sh  $WD/DevServer/build-osx.sh || _die "Failed to copy build.osx.sh script from server"
    _replace "\$WD\/server" "\$WD\/DevServer" "$WD/DevServer/build-osx.sh"
    _replace "\/server\/" "\/DevServer\/" "$WD/DevServer/build-osx.sh"
    _replace "\/installer\/server" "\/installer\/DevServer" "$WD/DevServer/build-osx.sh"
    _replace "_server_" "_DevServer_" "$WD/DevServer/build-osx.sh"
    _replace "postgresql-\$PG_TARBALL_POSTGRESQL" "pgsql" "$WD/DevServer/build-osx.sh"
    _replace "pgadmin3-\$PG_TARBALL_PGADMIN" "pgadmin3" "$WD/DevServer/build-osx.sh"
    _replace "\$PG_MAJOR_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-osx.sh"
    _replace "\$PG_PACKAGE_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-osx.sh"
    source $WD/DevServer/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    if [ -e $WD/DevServer/build-linux.sh ];
    then
	echo "Removing existing build-linux.sh script"
        rm -f $WD/DevServer/build-linux.sh || _die "couldn't remove the build.linux.sh script"
    fi
    cp $WD/server/build-linux.sh  $WD/DevServer/build-linux.sh || _die "Failed to copy build.linux.sh script from server"
    _replace "\$WD\/server" "\$WD\/DevServer" "$WD/DevServer/build-linux.sh"
    _replace "\/server\/" "\/DevServer\/" "$WD/DevServer/build-linux.sh"
    _replace "\/installer\/server" "\/installer\/DevServer" "$WD/DevServer/build-linux.sh"
    _replace "_server_" "_DevServer_" "$WD/DevServer/build-linux.sh"
    _replace "postgresql-\$PG_TARBALL_POSTGRESQL" "pgsql" "$WD/DevServer/build-linux.sh"
    _replace "pgadmin3-\$PG_TARBALL_PGADMIN" "pgadmin3" "$WD/DevServer/build-linux.sh"
    _replace "\$PG_MAJOR_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-linux.sh"
    _replace "\$PG_PACKAGE_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-linux.sh"
    source $WD/DevServer/build-linux.sh

fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    if [ -e $WD/DevServer/build-linux-x64.sh ];
    then
	echo "Removing existing build-linux-x64.sh script"
        rm -f $WD/DevServer/build-linux-x64.sh || _die "couldn't remove the build.linux-x64.sh script"
    fi
    cp $WD/server/build-linux-x64.sh  $WD/DevServer/build-linux-x64.sh || _die "Failed to copy build.linux-x64.sh script from server"
    _replace "\$WD\/server" "\$WD\/DevServer" "$WD/DevServer/build-linux-x64.sh"
    _replace "\/server\/" "\/DevServer\/" "$WD/DevServer/build-linux-x64.sh"
    _replace "\/installer\/server" "\/installer\/DevServer" "$WD/DevServer/build-linux-x64.sh"
    _replace "_server_" "_DevServer_" "$WD/DevServer/build-linux-x64.sh"
    _replace "postgresql-\$PG_TARBALL_POSTGRESQL" "pgsql" "$WD/DevServer/build-linux-x64.sh"
    _replace "pgadmin3-\$PG_TARBALL_PGADMIN" "pgadmin3" "$WD/DevServer/build-linux-x64.sh"
    _replace "\$PG_MAJOR_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-linux-x64.sh"
    _replace "\$PG_PACKAGE_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-linux-x64.sh"
    source $WD/DevServer/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    if [ -e $WD/DevServer/build-windows.sh ];
    then
	echo "Removing existing build-windows.sh script"
        rm -f $WD/DevServer/build-windows.sh || _die "couldn't remove the build.windows.sh script"
    fi
    cp $WD/server/build-windows.sh  $WD/DevServer/build-windows.sh || _die "Failed to copy build.windows.sh script from server"
    _replace "\$WD\/server" "\$WD\/DevServer" "$WD/DevServer/build-windows.sh"
    _replace "\/server\/" "\/DevServer\/" "$WD/DevServer/build-windows.sh"
    _replace "\\\\server" "\\\\DevServer" "$WD/DevServer/build-windows.sh"
    _replace "\/installer\/server" "\/installer\/DevServer" "$WD/DevServer/build-windows.sh"
    _replace "_server_" "_DevServer_" "$WD/DevServer/build-windows.sh"
    _replace "postgresql-\$PG_TARBALL_POSTGRESQL" "pgsql" "$WD/DevServer/build-windows.sh"
    _replace "pgadmin3-\$PG_TARBALL_PGADMIN" "pgadmin3" "$WD/DevServer/build-windows.sh"
    _replace "\$PG_MAJOR_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-windows.sh"
    _replace "\$PG_PACKAGE_VERSION" "\$PG_VERSION_DEVSERVER" "$WD/DevServer/build-windows.sh"
    sed '/tips.txt/ s/^/#/' $WD/DevServer/build-windows.sh > /tmp/$$.tmp
    mv /tmp/$$.tmp $WD/DevServer/build-windows.sh
    sed '/pg.gent/ s/^/#/' $WD/DevServer/build-windows.sh > /tmp/$$.tmp
    mv /tmp/$$.tmp $WD/DevServer/build-windows.sh
    sed '/pgaevent/ s/^/#/' $WD/DevServer/build-windows.sh > /tmp/$$.tmp
    mv /tmp/$$.tmp $WD/DevServer/build-windows.sh
    sed '/postgres.tar.gz/ s/^/#/' $WD/DevServer/build-windows.sh > /tmp/$$.tmp
    mv /tmp/$$.tmp $WD/DevServer/build-windows.sh
    source $WD/DevServer/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_DevServer() {

    # Create the source directory if required
    if [ ! -e $WD/DevServer/source ];
    then
        mkdir $WD/DevServer/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/DevServer/source

    # PostgreSQL
    echo "Updating the DevServer source tree..."
    cd $WD/DevServer/source/pgsql
    cvs -z3 update -dP  
    
    # pgadmin
    echo "Updating the pgadmin source tree..."
    cd $WD/DevServer/source/pgadmin3
    svn update

    # Debugger
    echo "Updating the Debugger source tree..."
    cd $WD/DevServer/source/pgsql/contrib/pldebugger
    cvs -z3 update -dP
	
    # StackBuilder (CVS Tree)
    echo "Updating the StackBuilder source tree..."
    cd $WD/DevServer/source/stackbuilder
    cvs -z3 update -dP

    cd $WD/DevServer/source
    # pl/Java
    if [ -e pljava-$PG_TARBALL_PLJAVA ];
    then
      echo "Removing existing pljava-$PG_TARBALL_PLJAVA source directory"
      rm -rf pljava-$PG_TARBALL_PLJAVA || _die "Couldn't remove the existing pljava-$PG_TARBALL_PLJAVA source directory (source/pljava-$PG_TARBALL_PLJAVA)"
    fi

    echo "Unpacking pljava source..."
    tar -zxvf ../../tarballs/pljava-src-$PG_TARBALL_PLJAVA.tar.gz

	echo "Patching pl/java source..."
    cd pljava-1.4.0
    patch -p0 < ../../../tarballs/pljava-fix.patch
	
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_DevServer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_DevServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_DevServer_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_DevServer_windows || exit 1
    fi
}

################################################################################
# Build server
################################################################################

_build_DevServer() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_DevServer_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_DevServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_DevServer_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_DevServer_windows || exit 1
    fi
}

################################################################################
# Postprocess server
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_DevServer() {

    cd $WD/DevServer

    # Get the catalog version number
    PG_CATALOG_VERSION=`cat source/pgsql/src/include/catalog/catversion.h |grep "#define CATALOG_VERSION_NO" | awk '{print $3}'`

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
	echo "Removing the Existing installer.xml file"
        rm installer.xml || _die "couldn't remove the existing installer.xml"
    fi
    cp $WD/server/installer.xml.in $WD/DevServer/installer.xml || _die "Failed to copy the installer project file (server/installer.xml.in)"
    _replace "\/server\/" "\/DevServer\/" "$WD/DevServer/installer.xml" || _die "Failed to replace server with DevServer (for unix paths) in xml"
    _replace "\\\\server\\\\" "\\\\DevServer\\\\" "$WD/DevServer/installer.xml" || _die "Failed to replace server with DevServer (for windows paths) in xml"
    _replace PG_MAJOR_VERSION $PG_VERSION_DEVSERVER installer.xml || _die "Failed to set the major version in the installer project file (server/installer.xml)"
    _replace PG_MINOR_VERSION "" installer.xml || _die "Failed to set the minor version in the installer project file (server/installer.xml)"
    _replace PG_STAGING_DIR $WD/DevServer/staging installer.xml || _die "Failed to set the staging directory in the installer project file (server/installer.xml)"
    _replace PG_CATALOG_VERSION $PG_CATALOG_VERSION installer.xml || _die "Failed to set the catalog version number in the installer project file (server/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_DevServer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_DevServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_DevServer_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_DevServer_windows || exit 1
    fi
}

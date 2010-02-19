#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgmemcache_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    if [ -e pgmemcache.osx ];
    then
      echo "Removing existing pgmemcache.osx source directory"
      rm -rf pgmemcache.osx  || _die "Couldn't remove the existing pgmemcache.osx source directory (source/pgmemcache.osx)"
    fi
    if [ -e libmemcachedd.osx ];
    then
      echo "Removing existing libmemcachedd.osx source directory"
      rm -rf libmemcachedd.osx  || _die "Couldn't remove the existing libmemcachedd.osx source directory (source/libmemcachedd.osx)"
    fi
   
    echo "Creating staging directory ($WD/pgmemcache/source/pgmemcache.osx)"
    mkdir -p $WD/pgmemcache/source/pgmemcache.osx || _die "Couldn't create the pgmemcache.osx directory"
    echo "Creating staging directory ($WD/pgmemcache/source/libmemcached.osx)"
    mkdir -p $WD/pgmemcache/source/libmemcached.osx || _die "Couldn't create the libmemcached.osx directory"

    # Grab a copy of the source tree
    cp -R pgmemcache_$PG_VERSION_PGMEMCACHE/* pgmemcache.osx || _die "Failed to copy the source code (source/pgmemcache_$PG_VERSION_PGMEMCACHE)"
    chmod -R ugo+w pgmemcache.osx || _die "Couldn't set the permissions on the source directory"

    cp -R libmemcached-$PG_TARBALL_LIBMEMCACHED/* libmemcached.osx || _die "Failed to copy the source code (source/libmemcached-$PG_VERSION_LIBMEMCACHED)"
    chmod -R ugo+w libmemcached.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgmemcache/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgmemcache/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
   
    # Remove the libmemcached from server staging directory if left behind.
    if [ -e $PG_PGHOME_OSX/include/libmemcached ]
    then 
       rm -rf $PG_PGHOME_OSX/include/libmemcached || _die "Couldn't remove the libmemcached directory from server staging directory"
    fi 
    if [ -e $PG_PGHOME_OSX/include/postgresql/server/libmemcached ]
    then 
       rm -rf $PG_PGHOME_OSX/include/postgresql/server/libmemcached || _die "Couldn't remove the libmemcached directory from server staging directory"
    fi 
    echo "Creating staging directory ($WD/pgmemcache/staging/osx)"
    mkdir -p $WD/pgmemcache/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgmemcache/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgmemcache_osx() {

    cd $PG_PATH_OSX/pgmemcache/source/libmemcached.osx

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure prefix=$PG_PGHOME_OSX  --disable-static --disable-dependency-tracking || _die "Failed to configure libmemcached"
    mv config.h config_ppc.h  || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure prefix=$PG_PGHOME_OSX  --disable-static --disable-dependency-tracking || _die "Failed to configure libmemcached"
    mv config.h config_i386.h  || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc"  MACOSX_DEPLOYMENT_TARGET=10.4 ./configure prefix=$PG_PGHOME_OSX  --disable-static --disable-dependency-tracking || _die "Failed to configure libmemcached"

    echo "#ifdef __BIG_ENDIAN__" > config.h
    echo "#include \"config_ppc.h\"" >> config.h
    echo "#else" >> config.h
    echo "#include \"config_i386.h\"" >> config.h
    echo "#endif" >> config.h


    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 make  || _die "Failed to build libmemcached"
    make install  || _die "Failed to install libmemcached"

    mv $PG_PGHOME_OSX/include/libmemcached $PG_PGHOME_OSX/include/postgresql/server/ || _die "Failed to copy libmemcached folder to staging directory"
 
    mkdir -p $PG_PATH_OSX/pgmemcache/staging/osx/lib  || _die "Failed to create staging/osx/lib "
    mkdir -p $PG_PATH_OSX/pgmemcache/staging/osx/include  || _die "Failed to create staging/osx/include "
    mkdir -p $PG_PATH_OSX/pgmemcache/staging/osx/share  || _die "Failed to create staging/osx/share "

    cd $PG_PATH_OSX/pgmemcache/source/pgmemcache.osx; 
    MACOSX_DEPLOYMENT_TARGET=10.4 PATH=$PATH:$PG_PGHOME_OSX/bin make  || _die "Failed to build pgmemcache"
    PATH=$PATH:$PG_PGHOME_OSX/bin make install  || _die "Failed to install pgmemcache"

    cp $PG_PGHOME_OSX/lib/postgresql/pgmemcache.so $PG_PATH_OSX/pgmemcache/staging/osx/lib/; rm -f $PG_PGHOME_OSX/lib/postgresql/pgmemcache.so || _die "Failed to copy libpgmemcache to staging directory"
    cp $PG_PGHOME_OSX/share/postgresql/contrib/pgmemcache.sql $PG_PATH_OSX/pgmemcache/staging/osx/share/; rm -f $PG_PGHOME_OSX/share/postgresql/contrib/pgmemcache.sql || _die "Failed to copy pgmemcache sql to staging directory"


    cp $PG_PGHOME_OSX/lib/libmemcached* $PG_PATH_OSX/pgmemcache/staging/osx/lib/ ; rm -f $PG_PGHOME_OSX/lib/libmemcached*  || _die "Failed to copy libmemcached to staging directory"
    cp -R $PG_PGHOME_OSX/include/postgresql/server/libmemcached $PG_PATH_OSX/pgmemcache/staging/osx/include/; rm -rf $PG_PGHOME_OSX/include/postgresql/server/libmemcached || _die "Failed to copy memcache folder to staging directory"

    cd $PG_PATH_OSX/pgmemcache/staging/osx/lib

    filelist=`ls *.dylib`
    for file in $filelist
    do
        new_id=`otool -D $file | grep -v : | sed -e "s:$PG_PGHOME_OSX/lib/::g"`  
        install_name_tool -id $new_id $file
    done
    
    install_name_tool -change $PG_PGHOME_OSX/lib/libmemcached.2.dylib @loader_path/../lib/libmemcached.2.dylib pgmemcache.so
}


################################################################################
# PG Build
################################################################################

_postprocess_pgmemcache_osx() {
 

    cd $WD/pgmemcache

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/psqlODBC $WD/scripts/risePrivileges || _die "Failed to copy privileges escalation applet"
        rm -rf $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    chmod a+x $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgmemcache-pg$PG_CURRENT_VERSION $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    chmod a+x $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to remove the unpacked installer bundle"



    cd $WD
}


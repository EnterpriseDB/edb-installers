#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.osx ];
    then
      echo "Removing existing pgbouncer.osx source directory"
      rm -rf pgbouncer.osx  || _die "Couldn't remove the existing pgbouncer.osx source directory (source/pgbouncer.osx)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.osx)"
    mkdir -p $WD/pgbouncer/source/libevent.osx || _die "Couldn't create the libevent.osx directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.osx)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.osx || _die "Couldn't create the pgbouncer.osx directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.osx || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the source tree
    cp -R libevent-$PG_TARBALL_LIBEVENT/* libevent.osx || _die "Failed to copy the source code (source/libevent-$PG_TARBALL_LIBEVENT)"
    chmod -R ugo+w libevent.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/osx)"
    mkdir -p $WD/pgbouncer/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_osx() {

    cd $PG_PATH_OSX/pgbouncer/source/libevent.osx/; 

    # There is no change in the config.h for ppc and i386, thus configuring only once.

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer || _die "Failed to configure libevent"

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 make || _die "Failed to build libevent"
    make install || _die "Failed to install libevent"


    cd $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/; 
    CFLAGS="$PG_ARCH_OSX_FLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer || _die "Failed to configure pgbouncer"
    mv include/config.h include/config_ppc.h || _die "Failed to rename config.h"
    
    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer || _die "Failed to configure pgbouncer"
    mv include/config.h include/config_i386.h || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc"  MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer || _die "Failed to configure pgbouncer"

    echo "#ifdef __BIG_ENDIAN__" > include/config.h
    echo "#include \"config_ppc.h\"" >> include/config.h
    echo "#else" >> include/config.h
    echo "#include \"config_i386.h\"" >> include/config.h
    echo "#endif" >> include/config.h
    
    CFLAGS="$PG_ARCH_OSX_FLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 make || _die "Failed to build pgbouncer"
    make install || _die "Failed to install pgbouncer"

    cd $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/lib

    filelist=`ls *.dylib`
    for file in $filelist
    do
         new_id=`otool -D $file | grep -v : | sed -e "s:$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/lib/::g"` 
         install_name_tool -id $new_id $file
    done

    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer bin @loader_path/..
  
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_osx() {
 

    cd $WD/pgbouncer

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD
}


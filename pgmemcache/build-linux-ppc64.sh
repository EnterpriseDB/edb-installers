#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgmemcache_linux_ppc64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    if [ -e pgmemcache.linux-ppc64 ];
    then
      echo "Removing existing pgmemcache.linux-ppc64 source directory"
      rm -rf pgmemcache.linux-ppc64  || _die "Couldn't remove the existing pgmemcache.linux-ppc64 source directory (source/pgmemcache.linux-ppc64)"
    fi
    if [ -e libmemcached.linux-ppc64 ];
    then
      echo "Removing existing libmemcached.linux-ppc64 source directory"
      rm -rf libmemcached.linux-ppc64  || _die "Couldn't remove the existing libmemcached.linux-ppc64 source directory (source/libmemcached.linux-ppc64)"
    fi
   
    echo "Creating source directory ($WD/pgmemcache/source/pgmemcache.linux-ppc64)"
    mkdir -p $WD/pgmemcache/source/pgmemcache.linux-ppc64 || _die "Couldn't create the pgmemcache.linux-ppc64 directory"
    echo "Creating source directory ($WD/pgmemcache/source/libmemcached.linux-ppc64)"
    mkdir -p $WD/pgmemcache/source/libmemcached.linux-ppc64 || _die "Couldn't create the libmemcached.linux-ppc64 directory"

    # Grab a copy of the source tree
    cp -R pgmemcache/* pgmemcache.linux-ppc64 || _die "Failed to copy the source code (source/pgmemcache_$PG_VERSION_PGMEMCACHE)"
    chmod -R ugo+w pgmemcache.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    cp -R libmemcached-$PG_TARBALL_LIBMEMCACHED/* libmemcached.linux-ppc64 || _die "Failed to copy the source code (source/libmemcached-$PG_VERSION_LIBMEMCACHED)"
    chmod -R ugo+w libmemcached.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgmemcache/staging/linux-ppc64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgmemcache/staging/linux-ppc64 || _die "Couldn't remove the existing staging directory"
    fi

    ssh $PG_SSH_LINUX_PPC64 "rm -rf $PG_PGHOME_LINUX_PPC64/include/libmemcached $PG_PGHOME_LINUX_PPC64/include/postgresql/server/libmemcached" || _die "Failed to remove libmemcached from server staging directory"

    echo "Creating staging directory ($WD/pgmemcache/staging/linux-ppc64)"
    mkdir -p $WD/pgmemcache/staging/linux-ppc64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgmemcache/staging/linux-ppc64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgmemcache_linux_ppc64() {

    # Note: Make sure the linux-ppc64 VM contain memcached binary in the PATH.  

    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgmemcache/source/libmemcached.linux-ppc64; ./configure prefix=$PG_PGHOME_LINUX_PPC64 " || _die "Failed to configure libmemcache"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgmemcache/source/libmemcached.linux-ppc64; make " || _die "Failed to build libmemcached"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgmemcache/source/libmemcached.linux-ppc64; make install " || _die "Failed to install libmemcached"

    ssh $PG_SSH_LINUX_PPC64 "mv $PG_PGHOME_LINUX_PPC64/include/libmemcached $PG_PGHOME_LINUX_PPC64/include/postgresql/server/" || _die "Failed to copy libmemcached to staging directory"
    ssh $PG_SSH_LINUX_PPC64 "mv $PG_PGHOME_LINUX_PPC64/include/libhashkit $PG_PGHOME_LINUX_PPC64/include/postgresql/server/" || _die "Failed to copy libhashkit to staging directory"
 
    ssh $PG_SSH_LINUX_PPC64 "mkdir -p $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/lib " || _die "Failed to create staging/linux-ppc64/lib "
    ssh $PG_SSH_LINUX_PPC64 "mkdir -p $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/include " || _die "Failed to create staging/linux-ppc64/include "
    ssh $PG_SSH_LINUX_PPC64 "mkdir -p $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/share " || _die "Failed to create staging/linux-ppc64/share "

    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgmemcache/source/pgmemcache.linux-ppc64; PATH=\$PATH:$PG_PGHOME_LINUX_PPC64/bin make " || _die "Failed to build pgmemcache"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgmemcache/source/pgmemcache.linux-ppc64; PATH=\$PATH:$PG_PGHOME_LINUX_PPC64/bin make install " || _die "Failed to install pgmemcache"
    ssh $PG_SSH_LINUX_PPC64 "cp $PG_PGHOME_LINUX_PPC64/lib/postgresql/pgmemcache.so $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/lib/; rm -f $PG_PGHOME_LINUX_PPC64/lib/postgresql/pgmemcache.so" || _die "Failed to copy pgmemcache to staging directory"
    ssh $PG_SSH_LINUX_PPC64 "cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/pgmemcache.sql $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/share/; rm -f $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/pgmemcache.sql" || _die "Failed to copy pgmemcache sql to staging directory"

    ssh $PG_SSH_LINUX_PPC64 "cp $PG_PGHOME_LINUX_PPC64/lib/libmemcached* $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/lib/ ; rm -f $PG_PGHOME_LINUX_PPC64/lib/libmemcached* " || _die "Failed to copy libmemcached to staging directory"
    ssh $PG_SSH_LINUX_PPC64 "cp $PG_PGHOME_LINUX_PPC64/lib/libhashkit* $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/lib/ ; rm -f $PG_PGHOME_LINUX_PPC64/lib/libhashkit* " || _die "Failed to copy libhashkit to staging directory"
    ssh $PG_SSH_LINUX_PPC64 "cp -R $PG_PGHOME_LINUX_PPC64/include/postgresql/server/libmemcached $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/include/; rm -rf $PG_PGHOME_LINUX_PPC64/include/postgresql/server/libmemcached" || _die "Failed to copy libmemcached folder to staging directory"
    ssh $PG_SSH_LINUX_PPC64 "cp -R $PG_PGHOME_LINUX_PPC64/include/postgresql/server/libhashkit $PG_PATH_LINUX_PPC64/pgmemcache/staging/linux-ppc64/include/; rm -rf $PG_PGHOME_LINUX_PPC64/include/postgresql/server/libhashkit" || _die "Failed to copy libhashkit folder to staging directory"
    
}


################################################################################
# PG Build
################################################################################

_postprocess_pgmemcache_linux_ppc64() {
 

    cd $WD/pgmemcache

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-ppc || _die "Failed to build the installer"

    mv $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux-ppc.bin $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux-ppc64.bin
    cd $WD
}


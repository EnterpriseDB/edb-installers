#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgmemcache_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    if [ -e pgmemcache.linux ];
    then
      echo "Removing existing pgmemcache.linux source directory"
      rm -rf pgmemcache.linux  || _die "Couldn't remove the existing pgmemcache.linux source directory (source/pgmemcache.linux)"
    fi
    if [ -e libmemcached.linux ];
    then
      echo "Removing existing libmemcached.linux source directory"
      rm -rf libmemcached.linux  || _die "Couldn't remove the existing libmemcached.linux source directory (source/libmemcached.linux)"
    fi
   
    echo "Creating source directory ($WD/pgmemcache/source/pgmemcache.linux)"
    mkdir -p $WD/pgmemcache/source/pgmemcache.linux || _die "Couldn't create the pgmemcache.linux directory"
    echo "Creating source directory ($WD/pgmemcache/source/libmemcached.linux)"
    mkdir -p $WD/pgmemcache/source/libmemcached.linux || _die "Couldn't create the libmemcached.linux directory"

    # Grab a copy of the source tree
    cp -R pgmemcache_$PG_VERSION_PGMEMCACHE/* pgmemcache.linux || _die "Failed to copy the source code (source/pgmemcache_$PG_VERSION_PGMEMCACHE)"
    chmod -R ugo+w pgmemcache.linux || _die "Couldn't set the permissions on the source directory"

    cp -R libmemcached-$PG_TARBALL_LIBMEMCACHED/* libmemcached.linux || _die "Failed to copy the source code (source/libmemcached-$PG_VERSION_LIBMEMCACHED)"
    chmod -R ugo+w libmemcached.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgmemcache/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgmemcache/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    ssh $PG_SSH_LINUX "rm -rf $PG_PGHOME_LINUX/include/libmemcached $PG_PGHOME_LINUX/include/postgresql/server/libmemcached" || _die "Failed to remove libmemcached from server staging directory"
    echo "Creating staging directory ($WD/pgmemcache/staging/linux)"
    mkdir -p $WD/pgmemcache/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgmemcache/staging/linux || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgmemcache_linux() {

    # Note: Make sure the linux VM contain memcached binary in the PATH.  

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgmemcache/source/libmemcached.linux; ./configure prefix=$PG_PGHOME_LINUX " || _die "Failed to configure libmemcache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgmemcache/source/libmemcached.linux; make " || _die "Failed to build libmemcached"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgmemcache/source/libmemcached.linux; make install " || _die "Failed to install libmemcached"

    ssh $PG_SSH_LINUX "mv $PG_PGHOME_LINUX/include/libmemcached $PG_PGHOME_LINUX/include/postgresql/server/" || _die "Failed to copy memcache.h to staging directory"
 
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/pgmemcache/staging/linux/lib " || _die "Failed to create staging/linux/lib "
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/pgmemcache/staging/linux/include " || _die "Failed to create staging/linux/include "
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/pgmemcache/staging/linux/share " || _die "Failed to create staging/linux/share "

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgmemcache/source/pgmemcache.linux; PATH=\$PATH:$PG_PGHOME_LINUX/bin make " || _die "Failed to build pgmemcache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgmemcache/source/pgmemcache.linux; PATH=\$PATH:$PG_PGHOME_LINUX/bin make install " || _die "Failed to install pgmemcache"
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/lib/postgresql/pgmemcache.so $PG_PATH_LINUX/pgmemcache/staging/linux/lib/; rm -f $PG_PGHOME_LINUX/lib/postgresql/pgmemcache.so" || _die "Failed to copy pgmemcache to staging directory"
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/share/postgresql/contrib/pgmemcache.sql $PG_PATH_LINUX/pgmemcache/staging/linux/share/; rm -f $PG_PGHOME_LINUX/share/postgresql/contrib/pgmemcache.sql" || _die "Failed to copy pgmemcache sql to staging directory"

    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/lib/libmemcached* $PG_PATH_LINUX/pgmemcache/staging/linux/lib/ ; rm -f $PG_PGHOME_LINUX/lib/libmemcached* " || _die "Failed to copy libmemcached to staging directory"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/include/postgresql/server/libmemcached $PG_PATH_LINUX/pgmemcache/staging/linux/include/; rm -rf $PG_PGHOME_LINUX/include/postgresql/server/libmemcached" || _die "Failed to copy libmemcached folder to staging directory"
    
}


################################################################################
# PG Build
################################################################################

_postprocess_pgmemcache_linux() {
 

    cd $WD/pgmemcache

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


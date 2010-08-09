#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgmemcache_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgmemcache/source

    if [ -e pgmemcache.linux-x64 ];
    then
      echo "Removing existing pgmemcache.linux-x64 source directory"
      rm -rf pgmemcache.linux-x64  || _die "Couldn't remove the existing pgmemcache.linux-x64 source directory (source/pgmemcache.linux-x64)"
    fi
    if [ -e libmemcached.linux-x64 ];
    then
      echo "Removing existing libmemcached.linux-x64 source directory"
      rm -rf libmemcached.linux-x64  || _die "Couldn't remove the existing libmemcached.linux-x64 source directory (source/libmemcached.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/pgmemcache/source/pgmemcache.linux-x64)"
    mkdir -p $WD/pgmemcache/source/pgmemcache.linux-x64 || _die "Couldn't create the pgmemcache.linux-x64 directory"
    echo "Creating source directory ($WD/pgmemcache/source/libmemcached.linux-x64)"
    mkdir -p $WD/pgmemcache/source/libmemcached.linux-x64 || _die "Couldn't create the libmemcached.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pgmemcache_$PG_VERSION_PGMEMCACHE/* pgmemcache.linux-x64 || _die "Failed to copy the source code (source/pgmemcache_$PG_VERSION_PGMEMCACHE)"
    chmod -R ugo+w pgmemcache.linux-x64 || _die "Couldn't set the permissions on the source directory"

    cp -R libmemcached-$PG_TARBALL_LIBMEMCACHED/* libmemcached.linux-x64 || _die "Failed to copy the source code (source/libmemcached-$PG_VERSION_LIBMEMCACHED)"
    chmod -R ugo+w libmemcached.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgmemcache/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgmemcache/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    ssh $PG_SSH_LINUX_X64 "rm -rf $PG_PGHOME_LINUX_X64/include/libmemcached $PG_PGHOME_LINUX_X64/include/postgresql/server/libmemcached" || _die "Failed to remove libmemcached from server staging directory"

    echo "Creating staging directory ($WD/pgmemcache/staging/linux-x64)"
    mkdir -p $WD/pgmemcache/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgmemcache/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgmemcache_linux_x64() {

    # Note: Make sure the linux-x64 VM contain memcached binary in the PATH.  

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/source/libmemcached.linux-x64; ./configure prefix=$PG_PGHOME_LINUX_X64 " || _die "Failed to configure libmemcache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/source/libmemcached.linux-x64; make " || _die "Failed to build libmemcached"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/source/libmemcached.linux-x64; make install " || _die "Failed to install libmemcached"

    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/include/libmemcached $PG_PGHOME_LINUX_X64/include/postgresql/server/" || _die "Failed to copy libmemcached to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/include/libhashkit $PG_PGHOME_LINUX_X64/include/postgresql/server/" || _die "Failed to copy libhashkit to staging directory"
 
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib " || _die "Failed to create staging/linux-x64/lib "
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/include " || _die "Failed to create staging/linux-x64/include "
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/share " || _die "Failed to create staging/linux-x64/share "

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/source/pgmemcache.linux-x64; PATH=\$PATH:$PG_PGHOME_LINUX_X64/bin make " || _die "Failed to build pgmemcache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/source/pgmemcache.linux-x64; PATH=\$PATH:$PG_PGHOME_LINUX_X64/bin make install " || _die "Failed to install pgmemcache"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/postgresql/pgmemcache.so $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/; rm -f $PG_PGHOME_LINUX_X64/lib/postgresql/pgmemcache.so" || _die "Failed to copy pgmemcache to staging directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/; chmod 755 pgmemcache.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/staging/linux_x64/lib/; for f in \`file pgmemcache.so | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/pgmemcache.sql $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/share/; rm -f $PG_PGHOME_LINUX_X64/share/postgresql/contrib/pgmemcache.sql" || _die "Failed to copy pgmemcache sql to staging directory"

    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/libmemcached* $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/ ; rm -f $PG_PGHOME_LINUX_X64/lib/libmemcached* " || _die "Failed to copy libmemcached to staging directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/; chmod 755 libmemcached*"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/; for f in \`file libmemcached* | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"

    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/libhashkit* $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/lib/ ; rm -f $PG_PGHOME_LINUX_X64/lib/libhashkit* " || _die "Failed to copy libhashkit to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/include/postgresql/server/libmemcached $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/include/; rm -rf $PG_PGHOME_LINUX_X64/include/postgresql/server/libmemcached" || _die "Failed to copy libmemcached folder to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/include/postgresql/server/libhashkit $PG_PATH_LINUX_X64/pgmemcache/staging/linux-x64/include/; rm -rf $PG_PGHOME_LINUX_X64/include/postgresql/server/libhashkit" || _die "Failed to copy libhashkit folder to staging directory"
    
}


################################################################################
# PG Build
################################################################################

_postprocess_pgmemcache_linux_x64() {
 

    cd $WD/pgmemcache

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


#!/bin/bash

################################################################################
# pgmemcache Build preparation
################################################################################

_prep_pgmemcache_linux_x64() {

    echo "############################################"
    echo "# pgmemcache : LINUX-X64 : Build preparation #"
    echo "############################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux-x64
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source

    # Remove any existing source directory that might exists, and create a clean one
    if [ -e $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM ]; then
        echo "Removing existing source directory (pgmemcache.$PGMEM_PLATFORM/pgmemcache.$PGMEM_PLATFORM)"
        rm -rf $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't remove the existing source directory ($PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM)"
    fi
    cp -r $PGMEM_SOURCE/pgmemcache_$PG_VERSION_PGMEMCACHE $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"

    LIBMEMCACHED_SOURCE=$PGMEM_SOURCE/libmemcached.$PGMEM_PLATFORM
    if [ -d $LIBMEMCACHED_SOURCE ]; then
        rm -rf $LIBMEMCACHED_SOURCE
    fi

    if [ $BUILD_LIBMEMCACHED_LINUX_X64 -eq 1 ]; then
        cp -r $PGMEM_SOURCE/libmemcached-$PG_TARBALL_LIBMEMCACHED $LIBMEMCACHED_SOURCE
    fi

}

################################################################################
# pgmemcache Build
################################################################################

_build_pgmemcache_linux_x64() {

    echo "##################################"
    echo "# pgmemcache : LINUX-X64 : Build #"
    echo "##################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux-x64
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source/pgmemcache.$PGMEM_PLATFORM
    PG_PATH=$PG_PGHOME_LINUX_X64
    PVT_SSH=$PG_SSH_LINUX_X64
    PVT_REPO=$PG_PATH_LINUX_X64
    PGMEM_PACKAGE_VM_PATH=$PVT_REPO/pgmemcache/source/pgmemcache.$PGMEM_PLATFORM
    LIBMEMCACHED_CACHING=$PGMEM_PACKAGE_PATH/cache/libmemcached-$PG_TARBALL_LIBMEMCACHED/$PGMEM_PLATFORM
    LIBMEMCACHED_CACHING_VM_PATH=$PVT_REPO/pgmemcache/cache/libmemcached-$PG_TARBALL_LIBMEMCACHED/$PGMEM_PLATFORM

    if [ $BUILD_LIBMEMCACHED_LINUX_X64 -eq 1 ]; then
        LIBMEMCACHED_SOURCE=$PVT_REPO/pgmemcache/source/libmemcached.$PGMEM_PLATFORM

        ssh $PVT_SSH "cd $LIBMEMCACHED_SOURCE; ./configure --prefix=$LIBMEMCACHED_CACHING_VM_PATH --disable-static && make && make install" || _die "Failed to configure/make/install libmemcached ($PGMEM_PLATFORM)"

        # Make all the files readable under the given directory
        find "$LIBMEMCACHED_CACHING" -exec chmod a+r {} \;
        # Make all the directories readable, writable and executable under the given directory
        find "$LIBMEMCACHED_CACHING" -type d -exec chmod a+wrx {} \;
        # Make all the shared objects readable and executable under the given directory
        find "$LIBMEMCACHED_CACHING" -name "*.so" -exec chmod a+rx {} \;

    fi

    cd $PGMEM_SOURCE
    ssh $PVT_SSH "cd $PGMEM_PACKAGE_VM_PATH; LD_LIBRARY_PATH=$PG_PATH/lib PATH=$PG_PATH/bin:$PATH make CFLAGS=\" -I$LIBMEMCACHED_CACHING_VM_PATH/include \" LDFLAGS=\" -L$LIBMEMCACHED_CACHING_VM_PATH/lib \"" || _die "Failed to build the pgmemcache for $PGMEM_PLATFORM"

    cd $PGMEM_SOURCE

    # Copying the binaries
    mkdir -p $PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p $PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p $PGMEM_STAGING/share || _die "Failed to create share directory"

    cp $LIBMEMCACHED_CACHING/lib/libmemcached.so* $PGMEM_STAGING/lib || _die "Failed to copy the libmemcached binaries"
    cp -R $PGMEM_SOURCE/pgmemcache.so $PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -R $PGMEM_SOURCE/*.sql $PGMEM_STAGING/share || _die "Failed to copy the share files for the pgmemcache"
    cp -R $LIBMEMCACHED_CACHING/include/* $PGMEM_STAGING/include || _die "Failed to copy the header files for the libmemcached"

    chmod a+rx $PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r $PGMEM_STAGING/share/* || _die "Failed to set permissions"

}


################################################################################
# pgmemcache Post Process
################################################################################

_postprocess_pgmemcache_linux_x64() {

    echo "#########################################"
    echo "# pgmemcache : LINUX-X64 : Post Process #"
    echo "#########################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux-x64
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM

    cd $PGMEM_PACKAGE_PATH

    # Make all the files readable under the given directory
    find "$PGMEM_PACKAGE_PATH" -exec chmod a+r {} \;
    # Make all the directories readable, writable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -type d -exec chmod 755 {} \;
    # Make all the shared objects readable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -name "*.so*" -exec chmod 755 {} \;

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml ${PGMEM_PLATFORM} || _die "Failed to build the installer (${PGMEM_PLATFORM})"

    cd $WD

}


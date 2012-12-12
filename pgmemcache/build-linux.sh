#!/bin/bash

################################################################################
# pgmemcache Build preparation
################################################################################

_prep_pgmemcache_linux() {

    echo "############################################"
    echo "# pgmemcache : LINUX : Build preparation #"
    echo "############################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source

    # Remove any existing source directory that might exists, and create a clean one
    if [ -e $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM ]; then
        echo "Removing existing source directory (pgmemcache.$PGMEM_PLATFORM/pgmemcache.$PGMEM_PLATFORM)"
        rm -rf $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't remove the existing source directory ($PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM)"
    fi
    cp -r $PGMEM_SOURCE/pgmemcache $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"

}

################################################################################
# pgmemcache Build
################################################################################

_build_pgmemcache_linux() {

    echo "##############################"
    echo "# pgmemcache : LINUX : Build #"
    echo "##############################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source/pgmemcache.$PGMEM_PLATFORM
    PG_PATH=$PG_PGHOME_LINUX
    PVT_SSH=$PG_SSH_LINUX
    PVT_REPO=$PG_PATH_LINUX
    PGMEM_PACKAGE_VM_PATH=$PVT_REPO/pgmemcache/source/pgmemcache.$PGMEM_PLATFORM

    cd $PGMEM_SOURCE
    ssh $PVT_SSH "cd $PGMEM_PACKAGE_VM_PATH; LD_LIBRARY_PATH=$PG_PATH/lib PATH=$PG_PATH/bin:$PATH make CFLAGS=\" -I/usr/local/include \" LDFLAGS=\" -L/usr/local/lib -Wl,--rpath,$PGMEM_PACKAGE_VM_PATH/../lib\"" || _die "Failed to build the pgmemcache for $PGMEM_PLATFORM"
    
    echo "Changing rpath"
    ssh $PVT_SSH "cd $PGMEM_PACKAGE_VM_PATH; chrpath --replace \"\\\${ORIGIN}\" pgmemcache.so"

    cd $PGMEM_SOURCE

    # Copying the binaries
    mkdir -p $PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p $PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p $PGMEM_STAGING/share || _die "Failed to create share directory"

    ssh $PVT_SSH "cp -pR /usr/local/lib/libmemcached.so* $PVT_REPO/pgmemcache/staging/linux/lib/" || _die "Failed to copy the libmemcached binaries"
    cp -pR $PGMEM_SOURCE/pgmemcache.so $PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -pR $PGMEM_SOURCE/*.sql $PGMEM_STAGING/share || _die "Failed to copy the share files for the pgmemcache"
    ssh $PVT_SSH "cp -pR /usr/local/include/libmemcached* $PVT_REPO/pgmemcache/staging/linux/include/" || _die "Failed to copy the header files for the libmemcached"
    

    chmod a+rx $PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r $PGMEM_STAGING/share/* || _die "Failed to set permissions"

}


################################################################################
# pgmemcache Post Process
################################################################################

_postprocess_pgmemcache_linux() {

    echo "#######################################"
    echo "# pgmemcache : LINUX : Post Process #"
    echo "#######################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
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


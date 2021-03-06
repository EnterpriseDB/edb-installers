#!/bin/bash

################################################################################
# pgmemcache Build preparation
################################################################################

_prep_pgmemcache_linux() {
    
    echo "BEGIN PREP pgmemcache Linux"    

    echo "############################################"
    echo "# pgmemcache : LINUX : Build preparation #"
    echo "############################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/${PGMEM_PLATFORM}.build
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source

    # Remove any existing source directory that might exists, and create a clean one
    if [ -e $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM ]; then
        echo "Removing existing source directory (pgmemcache.$PGMEM_PLATFORM/pgmemcache.$PGMEM_PLATFORM)"
        rm -rf $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't remove the existing source directory ($PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM)"
    fi
    cp -r $PGMEM_SOURCE/pgmemcache-$PG_VERSION_PGMEMCACHE $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"
    echo "END PREP pgmemcache Linux"
}

################################################################################
# pgmemcache Build
################################################################################

_build_pgmemcache_linux() {

    echo "BEGIN BUILD pgmemcache Linux"

    echo "##############################"
    echo "# pgmemcache : LINUX : Build #"
    echo "##############################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/${PGMEM_PLATFORM}.build
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source/pgmemcache.$PGMEM_PLATFORM
    PG_PATH=$PG_PGHOME_LINUX
    PVT_SSH=$PG_SSH_LINUX
    PVT_REPO=$PG_PATH_LINUX
    PGMEM_PACKAGE_VM_PATH=$PVT_REPO/pgmemcache/source/pgmemcache.$PGMEM_PLATFORM

    cd $PGMEM_SOURCE
    ssh $PVT_SSH "cd $PGMEM_PACKAGE_VM_PATH; LD_LIBRARY_PATH=$PG_PATH/lib PATH=$PG_PATH/bin:$PATH make CFLAGS=\" -I/opt/local/Current/include \" LDFLAGS=\" -L/opt/local/Current/lib -Wl,--rpath,$PGMEM_PACKAGE_VM_PATH/../lib\"" || _die "Failed to build the pgmemcache for $PGMEM_PLATFORM"
    
    echo "Changing rpath"
    ssh $PVT_SSH "cd $PGMEM_PACKAGE_VM_PATH; chrpath --replace \"\\\${ORIGIN}\" pgmemcache.so"

    cd $PGMEM_SOURCE

    # Copying the binaries
    mkdir -p $PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p $PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p $PGMEM_STAGING/share/extension || _die "Failed to create share directory"

    ssh $PVT_SSH "cp -pR /opt/local/Current/lib/libmemcached.so* $PVT_REPO/pgmemcache/staging/linux.build/lib/" || _die "Failed to copy the libmemcached binaries"
    cp -pR $PGMEM_SOURCE/pgmemcache.so $PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -pR $PGMEM_SOURCE/*.sql $PGMEM_STAGING/share/extension || _die "Failed to copy the share files for the pgmemcache"
    cp -pR $PGMEM_SOURCE/pgmemcache.control $PGMEM_STAGING/share/extension || _die "Failed to copy the control file for the pgmemcache"
    ssh $PVT_SSH "cp -pR /opt/local/Current/include/libmemcached* $PVT_REPO/pgmemcache/staging/linux.build/include/" || _die "Failed to copy the header files for the libmemcached"

    chmod a+rx $PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r $PGMEM_STAGING/share/extension/* || _die "Failed to set permissions"

    # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_LINUX/pgmemcache/staging/linux.build" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/pgmemcache ];
    then
        echo "Removing existing $WD/output/symbols/linux/pgmemcache directory"
        rm -rf $WD/output/symbols/linux/pgmemcache  || _die "Couldn't remove the existing $WD/output/symbols/linux/pgmemcache directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/pgmemcache/staging/linux.build/symbols $WD/output/symbols/linux/pgmemcache || _die "Failed to move $WD/pgmemcache/staging/linux.build/symbols to $WD/output/symbols/linux/pgmemcache directory"

    echo "Removing last successful staging directory ($WD/pgmemcache/staging/linux)"
    rm -rf $WD/pgmemcache/staging/linux || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgmemcache/staging/linux || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgmemcache/staging/linux || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgmemcache/staging/linux.build/* $WD/pgmemcache/staging/linux || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGMEMCACHE=$PG_VERSION_PGMEMCACHE" > $WD/pgmemcache/staging/linux/versions-linux.sh
    echo "PG_BUILDNUM_PGMEMCACHE=$PG_BUILDNUM_PGMEMCACHE" >> $WD/pgmemcache/staging/linux/versions-linux.sh

    echo "END BUILD pgmemcache Linux"

}


################################################################################
# pgmemcache Post Process
################################################################################

_postprocess_pgmemcache_linux() {
    
    echo "BEGIN POST pgmemcache Linux"

    echo "#######################################"
    echo "# pgmemcache : LINUX : Post Process #"
    echo "#######################################"

    source $WD/pgmemcache/staging/linux/versions-linux.sh
    PG_BUILD_PGMEMCACHE=$(expr $PG_BUILD_PGMEMCACHE + $SKIPBUILD)

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=linux
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM

    cd $PGMEM_PACKAGE_PATH

    pushd staging/linux
    generate_3rd_party_license "pgmemcache"
    popd

    # Make all the files readable under the given directory
    find "$PGMEM_STAGING" -exec chmod a+r {} \;
    # Make all the directories readable, writable and executable under the given directory
    find "$PGMEM_STAGING" -type d -exec chmod 755 {} \;
    # Make all the shared objects readable and executable under the given directory
    find "$PGMEM_STAGING" -name "*.so*" -exec chmod 755 {} \;

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml ${PGMEM_PLATFORM} || _die "Failed to build the installer (${PGMEM_PLATFORM})"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGMEMCACHE -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux.run $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}linux.run

    cd $WD

    echo "END POST pgmemcache Linux"

}


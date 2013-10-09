#!/bin/bash

################################################################################
# pgmemcache Build preparation
################################################################################

_prep_pgmemcache_osx() {
    
    echo "BEGIN PREP pgmemcache OSX"

    echo "########################################"
    echo "# pgmemcache : OSX : Build preparation #"
    echo "########################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source

    # Remove any existing source directory that might exists, and create a clean one
    if [ -e $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM ]; then
        echo "Removing existing source directory (pgmemcache.$PGMEM_PLATFORM/pgmemcache.$PGMEM_PLATFORM)"
        rm -rf $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't remove the existing source directory ($PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM)"
    fi
    cp -r $PGMEM_SOURCE/pgmemcache  $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"
    
    echo "END PREP pgmemcache OSX"
}

################################################################################
# pgmemcache Build
################################################################################

_build_pgmemcache_osx() {
 
    echo "BEGIN BUILD pgmemcache OSX"

    echo "############################"
    echo "# pgmemcache : OSX : Build #"
    echo "############################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM
    PGMEM_SOURCE=$PGMEM_PACKAGE_PATH/source/pgmemcache.$PGMEM_PLATFORM
    PG_PATH=$WD/server/staging/$PGMEM_PLATFORM

    cd $PGMEM_SOURCE
    PATH=$PG_PATH/bin:$PATH make CFLAGS="$PG_ARCH_OSX_CFLAGS -I/usr/local/include -arch x86_64 -arch i386" LDFLAGS="-L/usr/local/lib -arch x86_64 -arch i386" || _die "Failed to build the pgmemcache for $PGMEM_PLATFORM"

    # Copying the binaries
    mkdir -p $PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p $PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p $PGMEM_STAGING/share || _die "Failed to create share directory"

    cp -pR /usr/local/lib/libmemcached.*.dylib $PGMEM_STAGING/lib || _die "Failed to copy the libmemcached binaries"
    cp -pR $PGMEM_SOURCE/pgmemcache.so $PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -pR $PGMEM_SOURCE/*.sql $PGMEM_STAGING/share || _die "Failed to copy the share files for the pgmemcache"
    cp -pR /usr/local/include/libmemcached* $PGMEM_STAGING/include || _die "Failed to copy the header files for the libmemcached"

    chmod a+rx $PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r $PGMEM_STAGING/share/* || _die "Failed to set permissions"

    cd $PGMEM_STAGING/lib
    _rewrite_so_refs  $PGMEM_STAGING lib @loader_path/..
    
    echo "END BUILD pgmemcache OSX"
}


################################################################################
# pgmemcache Post Process
################################################################################

_postprocess_pgmemcache_osx() {

    echo "BEGIN POST pgmemcache OSX"

    echo "###################################"
    echo "# pgmemcache : OSX : Post Process #"
    echo "###################################"

    PGMEM_PACKAGE_PATH=$WD/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PGMEM_PACKAGE_PATH/staging/$PGMEM_PLATFORM

    cd $PGMEM_PACKAGE_PATH

    # Make all the files readable under the given directory
    find "$PGMEM_PACKAGE_PATH" -exec chmod a+r {} \;
    # Make all the directories readable, writable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -type d -exec chmod a+wrx {} \;
    # Make all the shared objects readable and executable under the given directory
    find "$PGMEM_PACKAGE_PATH" -name "*.dylib" -exec chmod a+rx {} \;

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml $PGMEM_PLATFORM || _die "Failed to build the installer"
        cp $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy privileges escalation applet"
        rm -rf $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app

        if [ -f installer_1.xml ]; then
            rm -f installer_1.xml
        fi
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml $PGMEM_PLATFORM || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    chmod a+x $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgmemcache-pg$PG_CURRENT_VERSION $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh
    chmod a+rwx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
    
    echo "END POST pgmemcache OSX"
}


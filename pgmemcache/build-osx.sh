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
    cp -r $PGMEM_SOURCE/pgmemcache-$PG_VERSION_PGMEMCACHE $PGMEM_SOURCE/pgmemcache.$PGMEM_PLATFORM || _die "Couldn't copy the source directory (pgmemcache.$PGMEM_PLATFORM)"
    
    cd $PGMEM_SOURCE
    tar -jcvf pgmemcache.tar.bz2 pgmemcache.$PGMEM_PLATFORM

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi

    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/source" || _die "Falied to clean the pgmemcache/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/scripts" || _die "Falied to clean the pgmemcache/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/*.bz2" || _die "Falied to clean the pgmemcache/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/*.sh" || _die "Falied to clean the pgmemcache/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/staging/osx.build" || _die "Falied to clean the pgmemcache/staging/osx.build directory on Mac OS X VM"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgmemcache/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/pgmemcache/source/pgmemcache.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgmemcache/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/pgmemcache
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/pgmemcache/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgmemcache || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache/source; tar -jxvf pgmemcache.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache; tar -jxvf scripts.tar.bz2"
    
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

cat <<PGMEMCACHE > $WD/pgmemcache/build-pgmemcache.sh
    
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    PGMEM_PACKAGE_PATH=$PG_PATH_OSX/pgmemcache
    PGMEM_PLATFORM=osx
    PGMEM_STAGING=$PG_PATH_OSX/pgmemcache/staging/\${PGMEM_PLATFORM}.build
    PGMEM_SOURCE=$PG_PATH_OSX/pgmemcache/source/pgmemcache.\$PGMEM_PLATFORM
    PG_PATH=$PG_PATH_OSX/server/staging_cache/\$PGMEM_PLATFORM

    cd \$PGMEM_SOURCE
    PATH=\$PG_PATH/bin:\$PATH make CFLAGS="$PG_ARCH_OSX_CFLAGS -g -I/opt/local/Current/include -arch x86_64" LDFLAGS="-L/opt/local/Current/lib -arch x86_64" || _die "Failed to build the pgmemcache for \$PGMEM_PLATFORM"

    # Copying the binaries
    mkdir -p \$PGMEM_STAGING/include || _die "Failed to create include directory"
    mkdir -p \$PGMEM_STAGING/lib || _die "Failed to create lib directory"
    mkdir -p \$PGMEM_STAGING/share/extension || _die "Failed to create share directory"

    cp -pR /opt/local/Current/lib/libmemcached.*.dylib \$PGMEM_STAGING/lib || _die "Failed to copy the libmemcached binaries"
    cp -pR \$PGMEM_SOURCE/pgmemcache.so \$PGMEM_STAGING/lib || _die "Failed to copy the pgmemcache binary"
    cp -pR \$PGMEM_SOURCE/*.sql \$PGMEM_STAGING/share/extension || _die "Failed to copy the share files for the pgmemcache"
    cp -pR \$PGMEM_SOURCE/pgmemcache.control \$PGMEM_STAGING/share/extension || _die "Failed to copy the control file for the pgmemcache"
    cp -pR /opt/local/Current/include/libmemcached* \$PGMEM_STAGING/include || _die "Failed to copy the header files for the libmemcached"

    chmod a+rx \$PGMEM_STAGING/lib/* || _die "Failed to set permissions"
    chmod a+r \$PGMEM_STAGING/share/extension/* || _die "Failed to set permissions"

    cd \$PGMEM_STAGING/lib
    _rewrite_so_refs  \$PGMEM_STAGING lib @loader_path/..
    install_name_tool -change "@loader_path/../lib/libmemcached.10.dylib" "@loader_path/libmemcached.10.dylib" $PG_PATH_OSX/pgmemcache/staging/osx.build/lib/pgmemcache.so
PGMEMCACHE
    
    cd $WD
    scp resources/create_debug_symbols.sh $PG_SSH_OSX:$PG_PATH_OSX
    scp pgmemcache/build-pgmemcache.sh $PG_SSH_OSX:$PG_PATH_OSX/pgmemcache
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache; sh ./build-pgmemcache.sh" || _die "Failed to build the pgmemcache on OSX VM"

    echo "Removing last successful staging directory ($PG_PATH_OSX/pgmemcache/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgmemcache/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgmemcache/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR pgmemcache/staging/osx.build/* pgmemcache/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; chmod 755 create_debug_symbols.sh; sh ./create_debug_symbols.sh $PG_PATH_OSX/pgmemcache/staging/osx" || _die "Failed to create debug symbols for pgmemcache on OSX VM"
    ssh $PG_SSH_OSX "echo PG_VERSION_PGMEMCACHE=$PG_VERSION_PGMEMCACHE > $PG_PATH_OSX/pgmemcache/staging/osx/versions-osx.sh" || _die "Failed to write pgmemcache version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_VERSION_PGMEMCACHE=$PG_VERSION_PGMEMCACHE >> $PG_PATH_OSX/pgmemcache/staging/osx/versions-osx.sh" || _die "Failed to write pgmemcache build number into versions-osx.sh"

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

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PGMEM_STAGING ];
    then
        echo "Removing existing staging directory"
        rm -rf $PGMEM_STAGING || _die "Couldn't remove the existing staging directory ($PGMEM_STAGING)"
    fi
    echo "Creating staging directory ($PGMEM_STAGING)"
    mkdir -p $PGMEM_STAGING || _die "Couldn't create the staging directory"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache/staging/osx; rm -f pgmemcache-staging.tar.bz2" || _die "Failed to remove archive of the pgmemcache staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgmemcache/staging/osx; tar -jcvf pgmemcache-staging.tar.bz2 *" || _die "Failed to create archive of the pgmemcache staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/pgmemcache/staging/osx/pgmemcache-staging.tar.bz2 $WD/pgmemcache/staging/osx || _die "Failed to scp pgmemcache staging"

    # Extract the staging archive
    cd $WD/pgmemcache/staging/osx
    tar -jxvf pgmemcache-staging.tar.bz2 || _die "Failed to extract the pgmemcache staging archive"
    rm -f pgmemcache-staging.tar.bz2

    source $WD/pgmemcache/staging/osx/versions-osx.sh
    PG_BUILD_PGMEMCACHE=$(expr $PG_BUILD_PGMEMCACHE + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGMEMCACHE -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    cd $PGMEM_PACKAGE_PATH
 
    pushd staging/osx
    generate_3rd_party_license "pgmemcache"
    popd

    # Make all the files readable under the given directory
    find "$PGMEM_STAGING" -exec chmod a+r {} \;
    # Make all the directories readable, writable and executable under the given directory
    find "$PGMEM_STAGING" -type d -exec chmod 755 {} \;
    # Make all the shared objects readable and executable under the given directory
    find "$PGMEM_STAGING" -name "*.dylib" -exec chmod 755 {} \;

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

    # Rename the installer
    mv $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.app $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    chmod a+x $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app/Contents/MacOS/pgmemcache-pg$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgmemcache-pg$PG_CURRENT_VERSION $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    chmod a+rwx $WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh

    cd $WD/output
 
    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app.tar.bz2 pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgmemcahe*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app; mv pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx-signed.app  pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD

    echo "END POST pgmemcache OSX"

}


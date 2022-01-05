#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_osx() {

    echo "BEGIN PREP pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Build preparation #"
    echo "#####################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
	
    if [ -e pgAgent.osx ];
    then
      echo "Removing existing pgAgent.osx source directory"
      rm -rf pgAgent.osx  || _die "Couldn't remove the existing pgAgent.osx source directory (source/pgAgent.osx)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.osx)"
    mkdir -p $WD/pgAgent/source/pgAgent.osx || _die "Couldn't create the pgAgent.osx directory"
	
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.osx || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    tar -jcvf pgagent.tar.bz2 pgAgent.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    
    echo "Creating staging directory ($WD/pgAgent/staging/osx)"
    mkdir -p $WD/pgAgent/staging/osx || _die "Couldn't create the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/source" || _die "Falied to clean the pgAgent/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/scripts" || _die "Falied to clean the pgAgent/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/*.bz2" || _die "Falied to clean the pgAgent/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/*.sh" || _die "Falied to clean the pgAgent/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/staging/osx.build" || _die "Falied to clean the pgAgent/staging/osx.build directory on Mac OS X VM"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgAgent/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/pgAgent/source/pgagent.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgAgent/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/pgAgent
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/pgAgent/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgAgent || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent/source; tar -jxvf pgagent.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent; tar -jxvf scripts.tar.bz2"

    # Create staging directory while preparing for build. PPS-182
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgAgent/staging/osx" || _die "Couldn't create the staging directory"

    echo "END PREP pgAgent OSX"

}

################################################################################
# pgAgent Build
################################################################################

_build_pgAgent_osx() {

    echo "BEGIN BUILD pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Build             #"
    echo "#####################################"

    cd $WD/pgAgent
cat <<EOT-PGAGENT > $WD/pgAgent/build-pgagent.sh

    source ../settings.sh
    source ../versions.sh
    source ../common.sh
    

    PG_STAGING=$PG_PATH_OSX/pgAgent/staging/osx.build
    SOURCE_DIR=$PG_PATH_OSX/pgAgent/source/pgAgent.osx

    echo "Building pgAgent sources"
    cd \$SOURCE_DIR
    BOOST_ROOT=/opt/local/Current/boost PGDIR=$PG_PGHOME_OSX /opt/local/bin/cmake -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${MACOSX_MIN_VERSION}  -DCMAKE_INSTALL_PREFIX=\$PG_STAGING/pgAgent -DSTATIC_BUILD=NO -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CFLAGS='$PG_ARCH_OSX_CFLAGS  -arch x86_64 -O2' CMakeLists.txt || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    cd \$SOURCE_DIR
    make || _die "Couldn't compile the pgAgent sources"
    make install || _die "Couldn't install pgAgent"

    mkdir -p \$PG_STAGING/pgAgent/lib

    
    cp -pR /opt/local/Current/boost/lib/libboost_filesystem.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_system.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_thread.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_chrono.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_regex.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_date_time.dylib \$PG_STAGING/pgAgent/lib
    cp -pR /opt/local/Current/boost/lib/libboost_atomic.dylib \$PG_STAGING/pgAgent/lib

    mkdir -p \$PG_STAGING/pgAgent/share/extension
    mv \$PG_STAGING/pgAgent/share/*.sql \$PG_STAGING/pgAgent/share/extension
    mv \$PG_PGHOME_OSX/share/postgresql/extension/pgagent.control \$PG_STAGING/pgAgent/share/extension
    mv \$PG_PGHOME_OSX/share/postgresql/extension/pgagent*.sql \$PG_STAGING/pgAgent/share/extension

    #otool -L $PG_PATH_OSX/pgAgent/staging/osx.build/bin/pgagent
    #install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "\$PG_STAGING/bin/psql"
    install_name_tool -change "\$PG_PATH_OSX/server/staging_cache/osx.build/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    _rewrite_so_refs $PG_PATH_OSX/pgAgent/staging/osx.build/pgAgent lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/pgAgent/staging/osx.build/pgAgent bin @loader_path/..

    install_name_tool -change "libboost_filesystem.dylib" "@loader_path/../lib/libboost_filesystem.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_regex.dylib" "@loader_path/../lib/libboost_regex.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_date_time.dylib" "@loader_path/../lib/libboost_date_time.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_thread.dylib" "@loader_path/../lib/libboost_thread.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_system.dylib" "@loader_path/../lib/libboost_system.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_chrono.dylib" "@loader_path/../lib/libboost_chrono.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_atomic.dylib" "@loader_path/../lib/libboost_atomic.dylib" "\$PG_STAGING/pgAgent/bin/pgagent"
    install_name_tool -change "libboost_system.dylib" "@loader_path/libboost_system.dylib" "\$PG_STAGING/pgAgent/lib/libboost_filesystem.dylib"
    install_name_tool -change "libboost_system.dylib" "@loader_path/libboost_system.dylib" "\$PG_STAGING/pgAgent/lib/libboost_thread.dylib"
    install_name_tool -change "libboost_system.dylib" "@loader_path/libboost_system.dylib" "\$PG_STAGING/pgAgent/lib/libboost_chrono.dylib"

    chmod +r \$PG_STAGING/pgAgent/lib/*
    chmod +rx \$PG_STAGING/pgAgent/bin/*
EOT-PGAGENT
    
    cd $WD
    scp pgAgent/build-pgagent.sh $PG_SSH_OSX:$PG_PATH_OSX/pgAgent
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent; sh ./build-pgagent.sh" || _die "Failed to build pgAgent on OSX VM"
    
    echo "Removing last successful staging directory ($PG_PATH_OSX/pgAgent/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgAgent/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgAgent/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR pgAgent/staging/osx.build/* pgAgent/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_PGAGENT=$PG_VERSION_PGAGENT > $PG_PATH_OSX/pgAgent/staging/osx/versions-osx.sh" || _die "Failed to write pgAgent version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_PGAGENT=$PG_BUILDNUM_PGAGENT >> $PG_PATH_OSX/pgAgent/staging/osx/versions-osx.sh" || _die "Failed to write pgAgent build number into versions-osx.sh"

    echo "END BUILD pgAgent OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_osx() {

    echo "BEGIN POST pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Post Process      #"
    echo "#####################################"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/pgAgent/staging/osx)"
    mkdir -p $WD/pgAgent/staging/osx || _die "Couldn't create the staging directory"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent/staging/osx; rm -f pgagent-staging.tar.bz2" || _die "Failed to remove archive of the pgAgent staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent/staging/osx; tar -jcvf pgagent-staging.tar.bz2 *" || _die "Failed to create archive of the pgagent staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/pgAgent/staging/osx/pgagent-staging.tar.bz2 $WD/pgAgent/staging/osx || _die "Failed to scp pgagent staging"

    # sign the binaries and libraries
   scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf pgagent-staging.tar.bz2" || _die "Failed to remove PostGIS-staging.tar from signing server"
   scp $WD/pgAgent/staging/osx/pgagent-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy pgagent-staging.tar.bz2 on signing server"
   rm -rf $WD/pgAgent/staging/osx/pgagent-staging.tar.bz2 || _die "Failed to remove PostGIS-staging.tar from controller"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../pgagent-staging.tar.bz2"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh; sign_binaries staging" || _die "Failed to do binaries signing"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh; sign_libraries staging" || _die "Failed to do libraries signing"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging;tar -jcvf pgagent-staging.tar.bz2 *" || _die "Failed to create pgagent-staging tar on signing server"
   scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/pgagent-staging.tar.bz2 $WD/pgAgent/staging/osx || _die "Failed to copy pgagent-staging to controller vm"

    # Extract the staging archive
    cd $WD/pgAgent/staging/osx
    tar -jxvf pgagent-staging.tar.bz2 || _die "Failed to extract the pgagent staging archive"
    rm -f pgagent-staging.tar.bz2

    source $WD/pgAgent/staging/osx/versions-osx.sh
    PG_BUILD_PGAGENT=$(expr $PG_BUILD_PGAGENT + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGAGENT -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Setup the installer scripts.
    cd $WD/pgAgent/staging
    mkdir -p $WD/pgAgent/staging/osx/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $WD/pgAgent/scripts/osx/*.sh   $WD/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the installer scripts"
    cp -f $WD/pgAgent/scripts/osx/pgpass $WD/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the pgpass script (scripts/osx/pgpass)"
    chmod ugo+x $WD/pgAgent/staging/osx/installer/pgAgent/*

    cd $WD/pgAgent

    pushd staging/osx
    generate_3rd_party_license "pgAgent"
    popd

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/pgAgent
    chmod a+x $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/pgAgent
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgAgent $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with pgAgent ($WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app.tar.bz2 pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgagent*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."
    
    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"
    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app; mv pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx-signed.app  pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
   ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
   ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx*" || _die "Failed to remove the installer from notarization installer directory"
   scp $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
   scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

   echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip pgagent" || _die "Failed to notarize the app"
   ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip pgagent" || _die "Failed to notarize the app"
   scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD

    echo "END POST pgAgent OSX"

}


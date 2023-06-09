#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_osx() {

    echo "BEGIN PREP pgbouncer OSX"

    echo "**********************************"
    echo "*  Pre Process: pgBouncer (OSX)  *"
    echo "**********************************"

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.osx ];
    then
      echo "Removing existing pgbouncer.osx source directory"
      rm -rf pgbouncer.osx  || _die "Couldn't remove the existing pgbouncer.osx source directory (source/pgbouncer.osx)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.osx)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.osx || _die "Couldn't create the pgbouncer.osx directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.osx || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    tar -jcvf pgbouncer.tar.bz2 pgbouncer.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    
    echo "Creating staging directory ($WD/pgbouncer/staging/osx)"
    mkdir -p $WD/pgbouncer/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/source" || _die "Falied to clean the pgbouncer/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/scripts" || _die "Falied to clean the pgbouncer/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/*.bz2" || _die "Falied to clean the pgbouncer/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/*.sh" || _die "Falied to clean the pgbouncer/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/staging/osx.build" || _die "Falied to clean the pgbouncer/staging/osx.build directory on Mac OS X VM"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgbouncer/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/pgbouncer/source/pgbouncer.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/pgbouncer
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/pgbouncer/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer/source; tar -jxvf pgbouncer.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer; tar -jxvf scripts.tar.bz2"
   
    echo "Creating staging doc directory ($WD/pgbouncer/staging/osx.build/pgbouncer/doc)"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/doc" || _die "Couldn't create the staging doc directory"
    ssh $PG_SSH_OSX "chmod 755 $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/doc" || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    scp $WD/pgbouncer/resources/README.pgbouncer $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    
    echo "END PREP pgbouncer OSX"

}

################################################################################
# Build
################################################################################

_build_pgbouncer_osx() {

    echo "BEGIN BUILD pgbouncer OSX"

    echo "****************************"
    echo "*  Build: pgBouncer (OSX)  *"
    echo "****************************"
cat<<PGBOUNCER > $WD/pgbouncer/build-pgbouncer.sh
   
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    cd $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/
    
    CFLAGS="$PG_ARCH_OSX_CFLAGS -O2" LDFLAGS="$ARCHFLAGS" MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION LIBEVENT_LIBS="-L/opt/local/Current_v15/lib -levent" LIBEVENT_CFLAGS="-I/opt/local/Current_v15/include" ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer --with-openssl=/opt/local/Current_v15 || _die "Failed to configure pgbouncer"

    MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION make || _die "Failed to build pgbouncer"
    ln -s $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/install-sh $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/doc/install-sh
    make install || _die "Failed to install pgbouncer"

    cp -R $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/share || _die "Failed to copy the ini file to share directory"

    mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"
    cp -pR /opt/local/Current_v15/lib/libevent-*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libssl*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libcrypto*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libcom_err*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libgssapi_krb5*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libk5crypto*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
    cp -pR /opt/local/Current_v15/lib/libkrb5*.dylib $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib
 
    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer bin @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer lib @loader_path/

 
    mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to create the instscripts directory"
    mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/bin || _die "Failed to create the instscripts directory"

    cp -pR $PG_PGHOME_OSX/lib/libpq* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libpq in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libedit* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libedit in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libssl* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libssl in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libcrypto* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libcrypto in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libxml2* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libxml2 in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libcom_err* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libcom_err in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libgssapi_krb5* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libgssapi_krb5 in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libk5crypto* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libk5crypto in instscripts"
    cp -pR $PG_PGHOME_OSX/lib/libkrb5* $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/lib || _die "Failed to copy libkrb5 in instscripts"
    cp -pR $PG_PGHOME_OSX/bin/psql $PG_PATH_OSX/pgbouncer/staging/osx.build/instscripts/bin || _die "Failed to copy psql in instscripts"

    install_name_tool -change "@loader_path//lib/libcrypto.3.dylib" "@loader_path/libcrypto.3.dylib" $PG_PATH_OSX/pgbouncer/staging/osx.build/pgbouncer/lib/libssl.3.dylib

PGBOUNCER
    
    cd $WD
    scp pgbouncer/build-pgbouncer.sh $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer; sh ./build-pgbouncer.sh" || _die "Failed to build pgbouncer on OSX VM"

    echo "Removing last successful staging directory ($PG_PATH_OSX/pgbouncer/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/pgbouncer/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR pgbouncer/staging/osx.build/* pgbouncer/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_PGBOUNCER=$PG_VERSION_PGBOUNCER > $PG_PATH_OSX/pgbouncer/staging/osx/versions-osx.sh" || _die "Failed to write pgbouncer version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_PGBOUNCER=$PG_BUILDNUM_PGBOUNCER >> $PG_PATH_OSX/pgbouncer/staging/osx/versions-osx.sh" || _die "Failed to write pgbouncer build number into versions-osx.sh"

    echo "END BUILD pgbouncer OSX"  
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_osx() {

    echo "BEGIN POST pgbouncer OSX"

    echo "***********************************"
    echo "*  Post Process: pgBouncer (OSX)  *"
    echo "***********************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/pgbouncer/staging/osx)"
    mkdir -p $WD/pgbouncer/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/osx || _die "Couldn't set the permissions on the staging directory"
 
    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer/staging/osx; rm -f pgbouncer-staging.tar.bz2" || _die "Failed to remove archive of the pgbouncer staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer/staging/osx/; tar -jcvf pgbouncer-staging.tar.bz2 *" || _die "Failed to create archive of the pgbouncer staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer-staging.tar.bz2 $WD/pgbouncer/staging/osx || _die "Failed to scp pgbouncer staging"

    # sign the binaries and libraries
    scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf pgbouncer-staging.tar.bz2" || _die "Failed to remove pgbouncer-staging.tar from signing server"
    scp $WD/pgbouncer/staging/osx/pgbouncer-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy pgbouncer-staging.tar.bz2 on signing server"
    rm -rf $WD/pgbouncer/staging/osx/pgbouncer-staging.tar.bz2 || _die "Failed to remove pgbouncer-staging.tar from controller"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../pgbouncer-staging.tar.bz2"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging" || _die "Failed to do binaries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging" || _die "Failed to do libraries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging;tar -jcvf pgbouncer-staging.tar.bz2 *" || _die "Failed to create pgbouncer-staging tar on signing server"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/pgbouncer-staging.tar.bz2 $WD/pgbouncer/staging/osx || _die "Failed to copy pgbouncer-staging to controller vm"

    # Extract the staging archive
    cd $WD/pgbouncer/staging/osx
    tar -jxvf pgbouncer-staging.tar.bz2 || _die "Failed to extract the pgbouncer staging archive"
    rm -f pgbouncer-staging.tar.bz2

    source $WD/pgbouncer/staging/osx/versions-osx.sh
    PG_BUILD_PGBOUNCER=$(expr $PG_BUILD_PGBOUNCER + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGBOUNCER -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    cd $WD/pgbouncer
 
    pushd staging/osx
    generate_3rd_party_license "pgbouncer"
    popd

    mkdir -p staging/osx/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/osx/startupcfg.sh staging/osx/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/osx/installer/pgbouncer/startupcfg.sh    

    rm -rf staging/osx/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace ";foodb =" "@@CON@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = /var/run/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type" 
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/PgBouncer
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/PgBouncer
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PgBouncer $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with PgBouncer ($WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    
    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app.tar.bz2 pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgbouncer*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"

     #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app; mv pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx-signed.app  pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx*" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip pgbouncer" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip pgbouncer" || _die "Failed to notarize the app"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/pgbouncer$PG_CURRENT_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD

    echo "END POST pgbouncer OSX"
}



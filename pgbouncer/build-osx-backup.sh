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
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/pgbouncer ]; then rm -rf $PG_PATH_OSX/pgbouncer/*; fi" || _die "Couldn't remove the existing files on OS X build server"

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
   
    echo "Creating staging doc directory ($WD/pgbouncer/staging/osx/pgbouncer/doc)"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/doc" || _die "Couldn't create the staging doc directory"
    ssh $PG_SSH_OSX "chmod 755 $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/doc" || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    scp $WD/pgbouncer/resources/README.pgbouncer $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    
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
    
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -O2" LDFLAGS="-arch i386" MACOSX_DEPLOYMENT_TARGET=10.6 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"
    mv lib/usual/config.h lib/usual/config_i386.h || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -O2" LDFLAGS="-arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.6 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"
    mv lib/usual/config.h lib/usual/config_x86_64.h || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -O2" LDFLAGS="-arch i386 -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.6 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"

    echo "#ifdef __BIG_ENDIAN__" > lib/usual/config.h
    echo "  #error \"Do not support ppc architecture\"" >> lib/usual/config.h
    echo "#else" >> lib/usual/config.h
    echo "  #ifdef __LP64__" >> lib/usual/config.h
    echo "    #include \"config_x86_64.h\"" >> lib/usual/config.h
    echo "  #else" >> lib/usual/config.h
    echo "    #include \"config_i386.h\"" >> lib/usual/config.h
    echo "  #endif" >> lib/usual/config.h
    echo "#endif" >> lib/usual/config.h
    
    MACOSX_DEPLOYMENT_TARGET=10.6 make || _die "Failed to build pgbouncer"
    ln -s $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/install-sh $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/doc/install-sh
    make install || _die "Failed to install pgbouncer"

    cp -R $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/share || _die "Failed to copy the ini file to share directory"

    mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"
    cp -pR /usr/local/lib/libevent-*.dylib $WD/pgbouncer/staging/osx/pgbouncer/lib
 
    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer bin @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer lib @loader_path/

 
    mkdir -p $PG_PATH_OSX/pgbouncer/staging/osx/instscripts || _die "Failed to create the instscripts directory"

    cp -pR $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -pR $PG_PATH_OSX/server/staging/osx/lib/libedit* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libedit in instscripts"
    cp -pR $PG_PATH_OSX/server/staging/osx/lib/libssl* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libssl in instscripts"
    cp -pR $PG_PATH_OSX/server/staging/osx/lib/libcrypto* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libcrypto in instscripts"
    cp -pR $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libxml2 in instscripts"
    cp -pR $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLL_LIST=`otool -L $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for OLD_DLL in $OLD_DLL_LIST
    do 
        NEW_DLL=`echo $OLD_DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$OLD_DLL" "$NEW_DLL" "$PG_PATH_OSX/pgbouncer/staging/osx/instscripts/psql"
    done

    OLD_DLLS=`otool -L $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/libpq.5.dylib| grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/pgbouncer/staging/osx/instscripts/libpq.5.dylib"
    done

    OLD_DLLS=`otool -L $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/libssl.dylib| grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/pgbouncer/staging/osx/instscripts/libssl.dylib"
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/pgbouncer/staging/osx/instscripts/libssl.1.0.0.dylib"
    done
PGBOUNCER
    
    cd $WD
    scp pgbouncer/build-pgbouncer.sh $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer; sh ./build-pgbouncer.sh" || _die "Failed to build pgbouncer on OSX VM"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgbouncer/staging/osx/; tar -jcvf pgbouncer-staging.tar.bz2 *" || _die "Failed to create archive of the pgbouncer staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer-staging.tar.bz2 $WD/pgbouncer/staging/osx || _die "Failed to scp pgbouncer staging"

    # Extract the staging archive
    cd $WD/pgbouncer/staging/osx
    tar -jxvf pgbouncer-staging.tar.bz2 || _die "Failed to extract the pgbouncer staging archive"
    rm -f pgbouncer-staging.tar.bz2

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
 
    cd $WD/pgbouncer

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

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PgBouncer $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with PgBouncer ($WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app.tar.bz2 pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgbouncer*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app; mv pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx-signed.app  pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD

    echo "END POST pgbouncer OSX"
}


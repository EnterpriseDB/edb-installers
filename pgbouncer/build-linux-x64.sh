#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_linux_x64() {

    echo "BEGIN PREP pgbouncer Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.linux-x64 ];
    then
      echo "Removing existing pgbouncer.linux-x64 source directory"
      rm -rf pgbouncer.linux-x64  || _die "Couldn't remove the existing pgbouncer.linux-x64 source directory (source/pgbouncer.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.linux-x64)"
    mkdir -p $WD/pgbouncer/source/libevent.linux-x64 || _die "Couldn't create the libevent.linux-x64 directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.linux-x64)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.linux-x64 || _die "Couldn't create the pgbouncer.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.linux-x64 || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/linux-x64.build)"
    mkdir -p $WD/pgbouncer/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"
    
    echo "Creating staging doc directory ($WD/pgbouncer/staging/linux-x64.build/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/linux-x64.build/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/linux-x64.build/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/linux-x64.build/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    
    echo "END PREP pgbouncer Linux-x64"
}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_linux_x64() {

    echo "BEGIN BUILD pgbouncer Linux-x64"

    PG_STAGING_CACHE=$WD/server/staging_cache/linux-x64

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; ./configure --enable-debug --prefix=$PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer --with-libevent=/opt/local/Current --with-openssl=/opt/local/Current" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; make" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; make install" || _die "Failed to install pgbouncer"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/share/" || _die "Failed to copy pgbouncer ini to share folder"


    mkdir -p $WD/pgbouncer/staging/linux-x64.build/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $WD/pgbouncer/staging/linux-x64.build/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"

    ssh $PG_SSH_LINUX_X64 "cp -R /opt/local/Current/lib/libevent-* $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"
    ssh $PG_SSH_LINUX_X64 "cp -R /opt/local/Current/lib/libssl.so* $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/lib" || _die "Failed to copy libssl libs in pgbouncer lib folder"
    ssh $PG_SSH_LINUX_X64 "cp -R /opt/local/Current/lib/libcrypto.so* $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/lib" || _die "Failed to copy libcrypto libs in pgbouncer lib folder"

    ssh $PG_SSH_LINUX_X64 "chmod o+rx $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer/lib/*" || _die "Failed to change permission of libevent libs in pgbouncer lib folder"

    cd $WD/pgbouncer/staging/linux-x64.build/instscripts/

    cp -pR $PG_STAGING_CACHE/bin/psql* . || _die "Failed to copy psql binary"
    cp -pR $PG_STAGING_CACHE/lib/libpq.so* . || _die "Failed to copy libpq.so"
    cp -pR $PG_STAGING_CACHE/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $PG_STAGING_CACHE/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $PG_STAGING_CACHE/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $PG_STAGING_CACHE/lib/libsasl*.so* . || _die "Failed to copy libsasl2.so.3"
    cp -pR $PG_STAGING_CACHE/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $PG_STAGING_CACHE/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $PG_STAGING_CACHE/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $PG_STAGING_CACHE/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $PG_STAGING_CACHE/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $PG_STAGING_CACHE/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $PG_STAGING_CACHE/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $PG_STAGING_CACHE/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"

    ssh $PG_SSH_LINUX_X64 "chmod 755 $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/instscripts/*" || _die "Failed to change permission of libraries"

    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64.build/pgbouncer" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/pgbouncer ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/pgbouncer directory"
        rm -rf $WD/output/symbols/linux-x64/pgbouncer  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/pgbouncer directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/pgbouncer/staging/linux-x64.build/pgbouncer/symbols $WD/output/symbols/linux-x64/pgbouncer || _die "Failed to move $WD/pgbouncer/staging/linux-x64.build/pgbouncer/symbols to $WD/output/symbols/linux-x64/pgbouncer directory"

    echo "Removing last successful staging directory ($WD/pgbouncer/staging/linux-x64)"
    rm -rf $WD/pgbouncer/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgbouncer/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgbouncer/staging/linux-x64.build/* $WD/pgbouncer/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGBOUNCER=$PG_VERSION_PGBOUNCER" > $WD/pgbouncer/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_PGBOUNCER=$PG_BUILDNUM_PGBOUNCER" >> $WD/pgbouncer/staging/linux-x64/versions-linux-x64.sh

    cd $WD
    
    echo "END BUILD pgbouncer Linux-x64"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_linux_x64() {
 
    echo "BEGIN POST pgbouncer Linux-x64"   

    source $WD/pgbouncer/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_PGBOUNCER=$(expr $PG_BUILD_PGBOUNCER + $SKIPBUILD)
 
    cd $WD/pgbouncer

    pushd staging/linux-x64
    generate_3rd_party_license "pgbouncer"
    popd

    mkdir -p staging/linux-x64/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/linux/startupcfg.sh staging/linux-x64/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/linux-x64/installer/pgbouncer/startupcfg.sh


    rm -rf staging/linux-x64/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace ";foodb =" "@@CON@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "pidfile = /var/run/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "auth_type = trust" "auth_type = md5" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/linux-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGBOUNCER -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux-x64.run $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}linux-x64.run

    cd $WD
   
    echo "END POST pgbouncer Linux-x64"  
}

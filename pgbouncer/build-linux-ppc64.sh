#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_linux_ppc64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.linux-ppc64 ];
    then
      echo "Removing existing pgbouncer.linux-ppc64 source directory"
      rm -rf pgbouncer.linux-ppc64  || _die "Couldn't remove the existing pgbouncer.linux-ppc64 source directory (source/pgbouncer.linux-ppc64)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.linux-ppc64)"
    mkdir -p $WD/pgbouncer/source/libevent.linux-ppc64 || _die "Couldn't create the libevent.linux-ppc64 directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.linux-ppc64)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.linux-ppc64 || _die "Couldn't create the pgbouncer.linux-ppc64 directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.linux-ppc64 || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/linux-ppc64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/linux-ppc64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/linux-ppc64)"
    mkdir -p $WD/pgbouncer/staging/linux-ppc64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux-ppc64 || _die "Couldn't set the permissions on the staging directory"
    
    echo "Creating staging doc directory ($WD/pgbouncer/staging/linux-ppc64/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/linux-ppc64/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod ugo+w $WD/pgbouncer/staging/linux-ppc64/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/linux-ppc64/pgbouncer/doc || _die "Couldn't copy README.pgbouncer to staging doc directory"

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_linux_ppc64() {


    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgbouncer/source/pgbouncer.linux-ppc64/; ./configure --prefix=$PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/pgbouncer --with-libevent=/usr/local" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgbouncer/source/pgbouncer.linux-ppc64/; make" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/pgbouncer/source/pgbouncer.linux-ppc64/; make install" || _die "Failed to install pgbouncer"
    ssh $PG_SSH_LINUX_PPC64 "cp -R $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/pgbouncer/share/" || _die "Failed to copy pgbouncer ini to share folder"


    mkdir -p $WD/pgbouncer/staging/linux-ppc64/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $WD/pgbouncer/staging/linux-ppc64/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"
    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 '.'`

    ssh $PG_SSH_LINUX_PPC64 "cp -R /usr/local/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"


    ssh $PG_SSH_LINUX_PPC64 "cp -R $PG_PATH_LINUX_PPC64/server/staging/linux-ppc64/lib/libpq* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX_PPC64 "cp -R $PG_PATH_LINUX_PPC64/server/staging/linux-ppc64/bin/psql $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy psql in instscripts"
    ssh $PG_SSH_LINUX_PPC64 "cp -R /lib64/libssl.so* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_PPC64 "cp -R /lib64/libcrypto.so* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_PPC64 "cp -R /lib64/libtermcap.so* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_PPC64 "cp -R /usr/local/lib/libxml2.so* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_PPC64 "cp -R /usr/lib64/libreadline.so* $PG_PATH_LINUX_PPC64/pgbouncer/staging/linux-ppc64/instscripts/" || _die "Failed to copy the dependency library"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_linux_ppc64() {
 

    cd $WD/pgbouncer

    mkdir -p staging/linux-ppc64/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/linux/startupcfg.sh staging/linux-ppc64/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/linux-ppc64/installer/pgbouncer/startupcfg.sh


    rm -rf staging/linux-ppc64/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace "bardb = host=127.0.0.1 dbname=bazdb" ";bardb = host=127.0.0.1 dbname=bazdb" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" ";forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "nondefaultdb = pool_size=50 reserve_pool=10" ";nondefaultdb = pool_size=50 reserve_pool=10" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "foodb =" "@@CON@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = pgbouncer.log" "logfile = @@LOGFILE@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "pidfile = pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "auth_file = etc/userlist.txt" "auth_file = @@AUTHFILE@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "auth_type = trust" "auth_type = md5" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/linux-ppc64/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-ppc || _die "Failed to build the installer"

    mv $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux-ppc.bin $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux-ppc64.bin

    cd $WD
}


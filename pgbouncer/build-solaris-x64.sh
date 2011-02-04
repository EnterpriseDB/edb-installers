#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_solaris_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.solaris-x64 ];
    then
      echo "Removing existing pgbouncer.solaris-x64 source directory"
      rm -rf pgbouncer.solaris-x64  || _die "Couldn't remove the existing pgbouncer.solaris-x64 source directory (source/pgbouncer.solaris-x64)"
    fi
   
    if [ -e pgbouncer.solaris-x64.zip ];
    then
      echo "Removing existing pgbouncer.solaris-x64 zip file"
      rm -rf pgbouncer.solaris-x64.zip  || _die "Couldn't remove the existing pgbouncer.solaris-x64 zip file (source/pgbouncer.solaris-x64.zip)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.solaris-x64)"
    mkdir -p $WD/pgbouncer/source/libevent.solaris-x64 || _die "Couldn't create the libevent.solaris-x64 directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.solaris-x64)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.solaris-x64 || _die "Couldn't create the pgbouncer.solaris-x64 directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.solaris-x64 || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.solaris-x64 || _die "Couldn't set the permissions on the source directory"
    zip -r pgbouncer.solaris-x64.zip pgbouncer.solaris-x64 || _die "Failed to zip the pgbouncer source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/solaris-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/solaris-x64 || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_X64 "rm -rf  $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64" || _die "Failed to remove the pgbouncer staging directory from Solaris VM"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/solaris-x64)"
    mkdir -p $WD/pgbouncer/staging/solaris-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/solaris-x64 || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_X64 "rm -rf  $PG_PATH_SOLARIS_X64/pgbouncer/source" || _die "Failed to remove the pgbouncer source directory from Solaris VM"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/pgbouncer/source" || _die "Failed to create the pgbouncer source directory from Solaris VM"
    scp pgbouncer.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/pgbouncer/source/ || _die "Failed to scp the pgbouncer zip file"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/pgbouncer/source; unzip pgbouncer.solaris-x64.zip" || _die "Failed to unzip the pgbouncer source directory in Solaris VM"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/solaris-x64/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/solaris-x64/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod ugo+w $WD/pgbouncer/staging/solaris-x64/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/solaris-x64/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_solaris_x64() {

    cd $WD/pgbouncer/source

    cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64 -D _XOPEN_SOURCE=2 -D _XOPEN_SOURCE_EXTENDED=1 -D __EXTENSIONS__=1"
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_X64: || _die "Failed to scp the setenv.sh file"


    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; ./configure --prefix=$PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer --with-libevent=/usr/local" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; gmake" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; gmake install" || _die "Failed to install pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "cp -R $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/share/" || _die "Failed to copy pgbouncer ini to share folder"


    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts" || _die "Failed to create the instscripts directory"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/lib" || _die "Failed to create the pgbouncer lib directory"
    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 '.'`

    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"


    ssh $PG_SSH_SOLARIS_X64 "cp -R $PG_PATH_SOLARIS_X64/server/staging/solaris-x64/lib/libpq* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_SOLARIS_X64 "cp -R $PG_PATH_SOLARIS_X64/server/staging/solaris-x64/bin/psql $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy psql in instscripts"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libssl.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libcrypto.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libedit.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libxml2.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libxslt.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libkrb5.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libkrb5support.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libk5crypto.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libcom_err.so* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts/" || _die "Failed to copy the dependency library"

    scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/* $WD/pgbouncer/staging/solaris-x64/ || _die "Failed to scp back the staging directory"
 
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_solaris_x64() {
 

    cd $WD/pgbouncer

    mkdir -p staging/solaris-x64/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/solaris/startupcfg.sh staging/solaris-x64/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/solaris-x64/installer/pgbouncer/startupcfg.sh


    rm -rf staging/solaris-x64/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace "bardb = host=127.0.0.1 dbname=bazdb" ";bardb = host=127.0.0.1 dbname=bazdb" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" ";forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "nondefaultdb = pool_size=50 reserve_pool=10" ";nondefaultdb = pool_size=50 reserve_pool=10" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "foodb =" "@@CON@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = pgbouncer.log" "logfile = @@LOGFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "pidfile = pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "auth_file = etc/userlist.txt" "auth_file = @@AUTHFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "auth_type = trust" "auth_type = md5" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-intel || _die "Failed to build the installer"

    mv $WD/output/pgbouncer-$PG_MAJOR_VERSION.$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-solaris-intel.bin  $WD/output/pgbouncer-$PG_MAJOR_VERSION.$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-solaris-x64.bin
    cd $WD
}


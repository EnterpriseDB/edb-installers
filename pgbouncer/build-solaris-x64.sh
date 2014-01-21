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

    # Applying patch for solaris build failure
    cd pgbouncer.solaris-x64
    patch -p1 < ../../../tarballs/pgbouncer-1.5.4-solaris.patch
    cd $WD/pgbouncer/source
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
    chmod 755 $WD/pgbouncer/staging/solaris-x64/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/solaris-x64/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_solaris_x64() {

    cd $WD/pgbouncer/source

    cat <<EOT > "setenv.sh"
export CC="cc"
export CXX="CC"
export CFLAGS="-m64"
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=$PG_SOLARIS_STUDIO_SOLARIS_X64/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH
#export CFLAGS="-m64 -D_XPG5 -D__EXTENSIONS__ -DX_OPEN_SOURCE=2 -D _XOPEN_SOURCE_EXTENDED=1"
#export LDFLAGS="-m64 -Wl,-R,\$ORIGIN/../lib/"
EOT
    scp setenv.sh $PG_SSH_SOLARIS_X64: || _die "Failed to scp the setenv.sh file"


    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; LDFLAGS="-Wl,-rpath,$PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/lib" ./configure --prefix=$PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer --with-libevent=/usr/local" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; gmake" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/pgbouncer/source/pgbouncer.solaris-x64/; gmake install" || _die "Failed to install pgbouncer"
    ssh $PG_SSH_SOLARIS_X64 "cp -R $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/share/" || _die "Failed to copy pgbouncer ini to share folder"


    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/instscripts" || _die "Failed to create the instscripts directory"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/lib" || _die "Failed to create the pgbouncer lib directory"
    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 -d'.'`

    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"
    ssh $PG_SSH_SOLARIS_X64 "/usr/local/bin/chrpath -r '\$ORIGIN/../lib/' $PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/pgbouncer/bin/pgbouncer" || _die "Failed to set rpath of pgbouncer"

    scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/pgbouncer/staging/solaris-x64/* $WD/pgbouncer/staging/solaris-x64/ || _die "Failed to scp back the staging directory"
 
    cp -R $WD/server/staging/solaris-x64/lib/libpq* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $WD/server/staging/solaris-x64/bin/psql $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R $WD/server/staging/solaris-x64/lib/libssl.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libcrypto.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libedit.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libxml2.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libxslt.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libkrb5.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libkrb5support.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libk5crypto.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libcom_err.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-x64/lib/libz.so* $WD/pgbouncer/staging/solaris-x64/instscripts/ || _die "Failed to copy the dependency library"
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

    _replace ";foodb =" "@@CON@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "pidfile = /var/log/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "auth_type = trust" "auth_type = md5" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/solaris-x64/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-intel || _die "Failed to build the installer"

    mv $WD/output/pgbouncer-$PG_MAJOR_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-solaris-intel.run  $WD/output/pgbouncer-$PG_MAJOR_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-solaris-x64.run
    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_linux_x64() {

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
    chmod -R ugo+w pgbouncer.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the source tree
    cp -R libevent-$PG_TARBALL_LIBEVENT/* libevent.linux-x64 || _die "Failed to copy the source code (source/libevent-$PG_TARBALL_LIBEVENT)"
    chmod -R ugo+w libevent.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/linux-x64)"
    mkdir -p $WD/pgbouncer/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_linux_x64() {

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/libevent.linux-x64/; ./configure --prefix=$PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64/pgbouncer" || _die "Failed to configure libevent"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/libevent.linux-x64/; make" || _die "Failed to build libevent"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/libevent.linux-x64/; make install" || _die "Failed to install libevent"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; ./configure --prefix=$PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64/pgbouncer --with-libevent=$PG_PATH_LINUX_X64/pgbouncer/staging/linux-x64/pgbouncer" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; make" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pgbouncer/source/pgbouncer.linux-x64/; make install" || _die "Failed to install pgbouncer"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_linux_x64() {
 

    cd $WD/pgbouncer

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


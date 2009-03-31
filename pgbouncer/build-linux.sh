#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.linux ];
    then
      echo "Removing existing pgbouncer.linux source directory"
      rm -rf pgbouncer.linux  || _die "Couldn't remove the existing pgbouncer.linux source directory (source/pgbouncer.linux)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.linux)"
    mkdir -p $WD/pgbouncer/source/libevent.linux || _die "Couldn't create the libevent.linux directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.linux)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.linux || _die "Couldn't create the pgbouncer.linux directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.linux || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the source tree
    cp -R libevent-$PG_TARBALL_LIBEVENT/* libevent.linux || _die "Failed to copy the source code (source/libevent-$PG_TARBALL_LIBEVENT)"
    chmod -R ugo+w libevent.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/linux)"
    mkdir -p $WD/pgbouncer/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_linux() {

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/libevent.linux/; ./configure --prefix=$PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer" || _die "Failed to configure libevent"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/libevent.linux/; make" || _die "Failed to build libevent"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/libevent.linux/; make install" || _die "Failed to install libevent"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; ./configure --prefix=$PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer --with-libevent=$PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; make" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; make install" || _die "Failed to install pgbouncer"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_linux() {
 

    cd $WD/pgbouncer

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


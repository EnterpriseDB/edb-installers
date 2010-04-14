#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgphonehome/source
    
    if [ -e pgphonehome.linux ];
    then
      echo "Removing existing pgphonehome.linux source directory"
      rm -rf pgphonehome.linux  || _die "Couldn't remove the existing pgphonehome.linux source directory (source/pgphonehome.linux)"
    fi

    echo "Creating staging directory ($WD/pgphonehome/source/pgphonehome.linux)"
    mkdir -p $WD/pgphonehome/source/pgphonehome.linux || _die "Couldn't create the pgphonehome.linux directory"
    
    # Grab a copy of the source tree
    cp -R PGPHONEHOME/* pgphonehome.linux || _die "Failed to copy the source code (source/pgphonehome-$PG_VERSION_PGPHONEHOME)"
    chmod -R ugo+w pgphonehome.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgphonehome/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgphonehome/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgphonehome/staging/linux)"
    mkdir -p $WD/pgphonehome/staging/linux/pgph || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgphonehome_linux() {
    
    cd $WD
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p pgphonehome/staging/linux/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/bin/psql pgphonehome/staging/linux/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libpq.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libcrypto.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libssl.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libreadline.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libreadline.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libtermcap.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxml2.so* pgphonehome/staging/linux/instscripts" || _die "Failed to copy libxml2.so"

}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_linux() {


    cp -R $WD/pgphonehome/source/pgphonehome.linux/* $WD/pgphonehome/staging/linux/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pgph || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux/installer/pgph/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/pgph/check-connection.sh

    cp staging/linux/pgph/config.php.in staging/linux/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/linux/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=@@DBNAME@@ user=@@USER@@ password=@@PASSWORD@@\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/linux/pgph/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


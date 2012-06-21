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
    cd $WD/pgphonehome/staging/linux/instscripts/

    cp -pR $WD/server/staging/linux/bin/psql* . || _die "Failed to copy psql binary"
    cp -pR $WD/server/staging/linux/lib/libpq.so* . || _die "Failed to copy libpq.so"
    cp -pR $WD/server/staging/linux/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $WD/server/staging/linux/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $WD/server/staging/linux/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $WD/server/staging/linux/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $WD/server/staging/linux/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $WD/server/staging/linux/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $WD/server/staging/linux/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $WD/server/staging/linux/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $WD/server/staging/linux/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"

    ssh $PG_SSH_LINUX "chmod 755 $PG_PATH_LINUX/pgphonehome/staging/linux/instscripts/*" || _die "Failed to change permission of libraries"

    cd $WD
}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_linux() {


    cp -R $WD/pgphonehome/source/pgphonehome.linux/* $WD/pgphonehome/staging/linux/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    cp staging/linux/pgph/config.php.in staging/linux/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/linux/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=@@DBNAME@@ user=@@USER@@ password=@@PASSWORD@@\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/linux/pgph/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


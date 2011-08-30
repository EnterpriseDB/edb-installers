#!/bin/bash

Drupal7
################################################################################
# Build preparation
################################################################################

_prep_Drupal7_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal7/source

    if [ -e Drupal7.linux-x64 ];
    then
      echo "Removing existing Drupal7.linux-x64 source directory"
      rm -rf Drupal7.linux-x64  || _die "Couldn't remove the existing Drupal7.linux-x64 source directory (source/Drupal7.linux-x64)"
    fi

    echo "Creating staging directory ($WD/Drupal7/source/Drupal7.linux-x64)"
    mkdir -p $WD/Drupal7/source/Drupal7.linux-x64 || _die "Couldn't create the Drupal7.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL7/* Drupal7.linux-x64 || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL7)"
    chmod -R ugo+w Drupal7.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal7/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal7/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal7/staging/linux-x64)"
    mkdir -p $WD/Drupal7/staging/linux-x64/Drupal7 || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_Drupal7_linux_x64() {

	cd $WD

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p Drupal7/staging/linux-x64/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/bin/psql* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libpq.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libcrypto.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libssl.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libedit.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libedit.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libtermcap.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libxml2.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libxslt.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libxslt.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libldap*2.3.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/liblber*2.3.so* Drupal7/staging/linux-x64/instscripts" || _die "Failed to copy libxslt.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal7_linux_x64() {


    cp -R $WD/Drupal7/source/Drupal7.linux-x64/* $WD/Drupal7/staging/linux-x64/Drupal7 || _die "Failed to copy the Drupal7 Source into the staging directory"

    cd $WD/Drupal7

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/Drupal7 || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/Drupal7/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal7/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/Drupal7/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal7/removeshortcuts.sh

    # Setup the Drupal7 launch Files
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the Drupal7 Launch Files"
    cp scripts/linux/launchDrupal7.sh staging/linux-x64/scripts/launchDrupal7.sh || _die "Failed to copy the launchDrupal7.sh  script (scripts/linux/launchDrupal7.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchDrupal7.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

     # Setup the Drupal7 xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the Drupal7 xdg Files"
    cp resources/xdg/pg-launchDrupal7.desktop staging/linux-x64/scripts/xdg/pg-launchDrupal7.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchDrupal7.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchDrupal7.png)"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/pg-postgresql.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal7/staging/linux-x64/Drupal7/install.php"

    chmod ugo+w staging/linux-x64/Drupal7/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/linux-x64/Drupal7/sites/default/default.settings.php staging/linux-x64/Drupal7/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/linux-x64/Drupal7/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/linux-x64/Drupal7/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/linux-x64/Drupal7/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


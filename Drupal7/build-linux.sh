#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_Drupal7_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal7/source

    if [ -e Drupal7.linux ];
    then
      echo "Removing existing Drupal7.linux source directory"
      rm -rf Drupal7.linux  || _die "Couldn't remove the existing Drupal7.linux source directory (source/Drupal7.linux)"
    fi

    echo "Creating staging directory ($WD/Drupal7/source/Drupal7.linux)"
    mkdir -p $WD/Drupal7/source/Drupal7.linux || _die "Couldn't create the Drupal7.linux directory"

    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL7/* Drupal7.linux || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL7)"
    chmod -R ugo+w Drupal7.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal7/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal7/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal7/staging/linux)"
    mkdir -p $WD/Drupal7/staging/linux/Drupal7 || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_Drupal7_linux() {

    cd $WD
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p Drupal7/staging/linux/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/bin/psql* Drupal7/staging/linux/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libpq.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libcrypto.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libssl.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libedit.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libedit.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libtermcap.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxml2.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxslt.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libxslt.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libldap*.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/liblber*.so* Drupal7/staging/linux/instscripts" || _die "Failed to copy libxslt.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal7_linux() {


    cp -R $WD/Drupal7/source/Drupal7.linux/* $WD/Drupal7/staging/linux/Drupal7 || _die "Failed to copy the Drupal7 Source into the staging directory"

    cd $WD/Drupal7

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/Drupal7 || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts.sh staging/linux/installer/Drupal7/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Drupal7/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/Drupal7/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Drupal7/removeshortcuts.sh

    # Setup the Drupal7 launch Files
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the Drupal7 Launch Files"
    cp scripts/linux/launchDrupal7.sh staging/linux/scripts/launchDrupal7.sh || _die "Failed to copy the launchDrupal7.sh  script (scripts/linux/launchDrupal7.sh)"
    chmod ugo+x staging/linux/scripts/launchDrupal7.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

     # Setup the Drupal7 xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the Drupal7 xdg Files"
    cp resources/xdg/pg-launchDrupal7.desktop staging/linux/scripts/xdg/pg-launchDrupal7.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchDrupal7.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchDrupal7.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/pg-postgresql.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal7/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal7/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal7/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal7/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal7/staging/linux/Drupal7/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal7/staging/linux/Drupal7/install.php"

    chmod ugo+w staging/linux/Drupal7/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/linux/Drupal7/sites/default/default.settings.php staging/linux/Drupal7/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/linux/Drupal7/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/linux/Drupal7/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/linux/Drupal7/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


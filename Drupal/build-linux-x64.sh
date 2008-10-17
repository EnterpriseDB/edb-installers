#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Drupal_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal/source
	
    if [ -e Drupal.linux-x64 ];
    then
      echo "Removing existing Drupal.linux-x64 source directory"
      rm -rf Drupal.linux-x64  || _die "Couldn't remove the existing Drupal.linux-x64 source directory (source/Drupal.linux-x64)"
    fi

    echo "Creating staging directory ($WD/Drupal/source/Drupal.linux-x64)"
    mkdir -p $WD/Drupal/source/Drupal.linux-x64 || _die "Couldn't create the Drupal.linux-x64 directory"
	
    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL/* Drupal.linux-x64 || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL)"
    chmod -R ugo+w Drupal.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal/staging/linux-x64/Drupal ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal/staging/linux-x64/Drupal || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal/staging/linux-x64)"
    mkdir -p $WD/Drupal/staging/linux-x64/Drupal || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Drupal_linux_x64() {

	cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal_linux_x64() {


    cp -R $WD/Drupal/source/Drupal.linux-x64/* $WD/Drupal/staging/linux-x64/Drupal || _die "Failed to copy the Drupal Source into the staging directory"

    cd $WD/Drupal

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/Drupal || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux-x64/installer/Drupal/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal/check-connection.sh

    cp scripts/linux/check-db.sh staging/linux-x64/installer/Drupal/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/Drupal/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux-x64/installer/Drupal/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/Drupal/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Drupal/removeshortcuts.sh

    # Setup the Drupal launch Files
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the Drupal Launch Files"
    cp scripts/linux/launchDrupal.sh staging/linux-x64/scripts/launchDrupal.sh || _die "Failed to copy the launchDrupal.sh  script (scripts/linux/launchDrupal.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchDrupal.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

     # Setup the Drupal xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the Drupal xdg Files"
    cp resources/xdg/enterprisedb-launchDrupal.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchDrupal.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux-x64/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchDrupal.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/launchDrupal.png)"
    cp resources/enterprisedb-postgres.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/enterprisedb-postgres.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
	
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal/staging/linux-x64/Drupal/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal/staging/linux-x64/Drupal/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal/staging/linux-x64/Drupal/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => localhost," "$WD/Drupal/staging/linux-x64/Drupal/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => 5432," "$WD/Drupal/staging/linux-x64/Drupal/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal/staging/linux-x64/Drupal/install.php"

    chmod ugo+w staging/linux-x64/Drupal/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/linux-x64/Drupal/sites/default/default.settings.php staging/linux-x64/Drupal/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/linux-x64/Drupal/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/linux-x64/Drupal/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/linux-x64/Drupal/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


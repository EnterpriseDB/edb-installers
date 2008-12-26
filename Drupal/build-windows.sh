#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Drupal_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal/source
    
    if [ -e Drupal.windows ];
    then
      echo "Removing existing Drupal.windows source directory"
      rm -rf Drupal.windows  || _die "Couldn't remove the existing Drupal.windows source directory (source/Drupal.windows)"
    fi

    echo "Creating staging directory ($WD/Drupal/source/Drupal.windows)"
    mkdir -p $WD/Drupal/source/Drupal.windows || _die "Couldn't create the Drupal.windows directory"
    
    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL/* Drupal.windows || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL)"
    chmod -R ugo+w Drupal.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal/staging/windows)"
    mkdir -p $WD/Drupal/staging/windows/Drupal || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Drupal_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal_windows() {

    cp -R $WD/Drupal/source/Drupal.windows/* $WD/Drupal/staging/windows/Drupal || _die "Failed to copy the Drupal Source into the staging directory"

    cd $WD/Drupal

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/Drupal || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/check-connection.bat staging/windows/installer/Drupal/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/Drupal/check-connection.bat

    cp scripts/windows/check-db.bat staging/windows/installer/Drupal/check-db.bat || _die "Failed to copy the check-db.bat script (scripts/windows/check-db.bat)"
    chmod ugo+x staging/windows/installer/Drupal/check-db.bat

    cp scripts/windows/install.bat staging/windows/installer/Drupal/install.bat || _die "Failed to copy the install.bat script (scripts/windows/install.bat)"
    chmod ugo+x staging/windows/installer/Drupal/install.bat

    # Setup the Drupal launch Files
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the Drupal Launch Files"
    cp scripts/windows/launchDrupal.vbs staging/windows/scripts/launchDrupal.vbs || _die "Failed to copy the launchDrupal.vbs  script (scripts/windows/launchDrupal.vbs)"
    chmod ugo+x staging/windows/scripts/launchDrupal.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => localhost," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => 5432," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal/staging/windows/Drupal/install.php"

    chmod ugo+w staging/windows/Drupal/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/windows/Drupal/sites/default/default.settings.php staging/windows/Drupal/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/windows/Drupal/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/windows/Drupal/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/windows/Drupal/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD

}


#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_Drupal7_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal7/source

    if [ -e Drupal7.windows ];
    then
      echo "Removing existing Drupal7.windows source directory"
      rm -rf Drupal7.windows  || _die "Couldn't remove the existing Drupal7.windows source directory (source/Drupal7.windows)"
    fi

    echo "Creating staging directory ($WD/Drupal7/source/Drupal7.windows)"
    mkdir -p $WD/Drupal7/source/Drupal7.windows || _die "Couldn't create the Drupal7.windows directory"

    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL7/* Drupal7.windows || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL7)"
    chmod -R ugo+w Drupal7.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal7/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal7/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal7/staging/windows)"
    mkdir -p $WD/Drupal7/staging/windows/Drupal7 || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_Drupal7_windows() {

    cd $WD
    # Copy the various support files into place

    mkdir -p Drupal7/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* Drupal7/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe Drupal7/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/ssleay32.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll Drupal7/staging/windows/instscripts/ || _die "Failed to copy dependent libs"

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal7_windows() {

    cp -R $WD/Drupal7/source/Drupal7.windows/* $WD/Drupal7/staging/windows/Drupal7 || _die "Failed to copy the Drupal7 Source into the staging directory"

    cd $WD/Drupal7

    # Setup the Drupal7 launch Files
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the Drupal7 Launch Files"
    cp scripts/windows/launchDrupal7.vbs staging/windows/scripts/launchDrupal7.vbs || _die "Failed to copy the launchDrupal7.vbs  script (scripts/windows/launchDrupal7.vbs)"
    chmod ugo+x staging/windows/scripts/launchDrupal7.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal7/staging/windows/Drupal7/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal7/staging/windows/Drupal7/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal7/staging/windows/Drupal7/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal7/staging/windows/Drupal7/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal7/staging/windows/Drupal7/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal7/staging/windows/Drupal7/install.php"

    chmod ugo+w staging/windows/Drupal7/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/windows/Drupal7/sites/default/default.settings.php staging/windows/Drupal7/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/windows/Drupal7/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/windows/Drupal7/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/windows/Drupal7/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "drupal7-$PG_VERSION_DRUPAL7-$PG_BUILDNUM_DRUPAL7-windows.exe"

    cd $WD

}


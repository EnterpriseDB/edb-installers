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
    # Copy the various support files into place

    mkdir -p Drupal/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* Drupal/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe Drupal/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll Drupal/staging/windows/instscripts/ || _die "Failed to copy dependent libs"

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal_windows() {

    cp -R $WD/Drupal/source/Drupal.windows/* $WD/Drupal/staging/windows/Drupal || _die "Failed to copy the Drupal Source into the staging directory"

    cd $WD/Drupal

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
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal/staging/windows/Drupal/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal/staging/windows/Drupal/install.php"

    chmod ugo+w staging/windows/Drupal/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/windows/Drupal/sites/default/default.settings.php staging/windows/Drupal/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/windows/Drupal/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/windows/Drupal/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/windows/Drupal/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "drupal-$PG_VERSION_DRUPAL-$PG_BUILDNUM_DRUPAL-windows.exe"
	
    cd $WD

}


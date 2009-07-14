#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Drupal_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/Drupal/source
	
    if [ -e Drupal.osx ];
    then
      echo "Removing existing Drupal.osx source directory"
      rm -rf Drupal.osx  || _die "Couldn't remove the existing Drupal.osx source directory (source/Drupal.osx)"
    fi

    echo "Creating staging directory ($WD/Drupal/source/Drupal.osx)"
    mkdir -p $WD/Drupal/source/Drupal.osx || _die "Couldn't create the Drupal.osx directory"
	
    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL/* Drupal.osx || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL)"
    chmod -R ugo+w Drupal.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal/staging/osx)"
    mkdir -p $WD/Drupal/staging/osx/Drupal || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_Drupal_osx() {

	cd $WD
    mkdir -p $PG_PATH_OSX/Drupal/staging/osx/instscripts || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/Drupal/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/Drupal/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/Drupal/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLLS=`otool -L $PG_PATH_OSX/Drupal/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/Drupal/staging/osx/instscripts/psql"
    done 

}


################################################################################
# PG Build
################################################################################

_postprocess_Drupal_osx() {


    cp -R $WD/Drupal/source/Drupal.osx/* $WD/Drupal/staging/osx/Drupal || _die "Failed to copy the Drupal Source into the staging directory"

    cd $WD/Drupal

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/Drupal || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/check-connection.sh staging/osx/installer/Drupal/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x staging/osx/installer/Drupal/check-connection.sh

    cp scripts/osx/check-db.sh staging/osx/installer/Drupal/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/osx/check-db.sh)"
    chmod ugo+x staging/osx/installer/Drupal/check-db.sh

    cp scripts/osx/createshortcuts.sh staging/osx/installer/Drupal/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Drupal/createshortcuts.sh

    cp scripts/osx/install.sh staging/osx/installer/Drupal/install.sh || _die "Failed to copy the install.sh script (scripts/osx/install.sh)"
    chmod ugo+x staging/osx/installer/Drupal/install.sh

    # Setup the Drupal launch Files
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the Drupal Launch Files"

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh
 
    cp scripts/osx/pg-launchDrupal.applescript.in staging/osx/scripts/pg-launchDrupal.applescript || _die "Failed to copy the pg-launchDrupal.applescript.in  script (scripts/osx/pg-launchDrupal.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchDrupal.applescript

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchDrupal.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchDrupal.icns)"
	
    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal/staging/osx/Drupal/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal/staging/osx/Drupal/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal/staging/osx/Drupal/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal/staging/osx/Drupal/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal/staging/osx/Drupal/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal/staging/osx/Drupal/install.php"

    chmod ugo+w staging/osx/Drupal/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/osx/Drupal/sites/default/default.settings.php staging/osx/Drupal/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/osx/Drupal/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/osx/Drupal/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/osx/Drupal/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r drupal-$PG_VERSION_DRUPAL-$PG_BUILDNUM_DRUPAL-osx.zip drupal-$PG_VERSION_DRUPAL-$PG_BUILDNUM_DRUPAL-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf drupal-$PG_VERSION_DRUPAL-$PG_BUILDNUM_DRUPAL-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD

}


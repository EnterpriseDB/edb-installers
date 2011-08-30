#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_Drupal7_osx() {

    echo "*******************************************************"
    echo " Pre Process : Drupal7 (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/Drupal7/source

    if [ -e Drupal7.osx ];
    then
      echo "Removing existing Drupal7.osx source directory"
      rm -rf Drupal7.osx  || _die "Couldn't remove the existing Drupal7.osx source directory (source/Drupal7.osx)"
    fi

    echo "Creating staging directory ($WD/Drupal7/source/Drupal7.osx)"
    mkdir -p $WD/Drupal7/source/Drupal7.osx || _die "Couldn't create the Drupal7.osx directory"

    # Grab a copy of the source tree
    cp -R drupal-$PG_VERSION_DRUPAL7/* Drupal7.osx || _die "Failed to copy the source code (source/drupal-$PG_VERSION_DRUPAL7)"
    chmod -R ugo+w Drupal7.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Drupal7/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Drupal7/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Drupal7/staging/osx)"
    mkdir -p $WD/Drupal7/staging/osx/Drupal7 || _die "Couldn't create the staging directory"


}

################################################################################
# Drupal7 Build
################################################################################

_build_Drupal7_osx() {

    echo "*******************************************************"
    echo " Build : Drupal7 (OSX)"
    echo "*******************************************************"

    cd $WD
    mkdir -p $PG_PATH_OSX/Drupal7/staging/osx/instscripts || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/Drupal7/staging/osx/instscripts/ || _die "Failed to copy libpq* in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/Drupal7/staging/osx/instscripts/ || _die "Failed to copy libxml2* in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxslt* $PG_PATH_OSX/Drupal7/staging/osx/instscripts/ || _die "Failed to copy libxslt* in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libedit* $PG_PATH_OSX/Drupal7/staging/osx/instscripts/ || _die "Failed to copy libedit* in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/Drupal7/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLLS=`otool -L $PG_PATH_OSX/Drupal7/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/Drupal7/staging/osx/instscripts/psql"
    done

}


################################################################################
# Drupal7 Build
################################################################################

_postprocess_Drupal7_osx() {

    echo "*******************************************************"
    echo " Post Process : Drupal7 (OSX)"
    echo "*******************************************************"

    cp -R $WD/Drupal7/source/Drupal7.osx/* $WD/Drupal7/staging/osx/Drupal7 || _die "Failed to copy the Drupal7 Source into the staging directory"

    cd $WD/Drupal7

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/Drupal7 || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/Drupal7/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Drupal7/createshortcuts.sh

    # Setup the Drupal7 launch Files
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the Drupal7 Launch Files"

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    cp scripts/osx/pg-launchDrupal7.applescript.in staging/osx/scripts/pg-launchDrupal7.applescript || _die "Failed to copy the pg-launchDrupal7.applescript.in  script (scripts/osx/pg-launchDrupal7.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchDrupal7.applescript

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchDrupal7.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchDrupal7.icns)"

    #Configure the install.php file
    _replace " '#default_value' => \$db_path," " '#default_value' => drupal," "$WD/Drupal7/staging/osx/Drupal7/install.php"
    _replace " '#default_value' => \$db_user," " '#default_value' => drupaluser," "$WD/Drupal7/staging/osx/Drupal7/install.php"
    _replace " '#default_value' => \$db_pass," " '#default_value' => drupaluser," "$WD/Drupal7/staging/osx/Drupal7/install.php"
    _replace " '#default_value' => \$db_host," " '#default_value' => '@@HOST@@'," "$WD/Drupal7/staging/osx/Drupal7/install.php"
    _replace " '#default_value' => \$db_port," " '#default_value' => @@PORT@@," "$WD/Drupal7/staging/osx/Drupal7/install.php"
    _replace " '#default_value' => \$db_prefix," " '#default_value' => drupal_," "$WD/Drupal7/staging/osx/Drupal7/install.php"

    chmod ugo+w staging/osx/Drupal7/sites/default || _die "Couldn't set the permissions on the default directory"

    cp staging/osx/Drupal7/sites/default/default.settings.php staging/osx/Drupal7/sites/default/settings.php || _die "Failed to copy the default.settings.php into the settings.php file"
    chmod ugo+w staging/osx/Drupal7/sites/default/settings.php || _die "Couldn't set the permissions on settings.php"
    mkdir -p staging/osx/Drupal7/sites/default/files || _die "Couldn't create the files directory"
    chmod ugo+w staging/osx/Drupal7/sites/default/files || _die "Couldn't set the permissions on the default/files directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r drupal7-$PG_VERSION_DRUPAL7-$PG_BUILDNUM_DRUPAL7-osx.zip drupal7-$PG_VERSION_DRUPAL7-$PG_BUILDNUM_DRUPAL7-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf drupal7-$PG_VERSION_DRUPAL7-$PG_BUILDNUM_DRUPAL7-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


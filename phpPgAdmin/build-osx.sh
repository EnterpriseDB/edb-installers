#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin_osx() {
    
    echo "BEGIN PREP phpPgAdmin OSX"

    echo "*******************************************************"
    echo " Pre Process : phpPGAdmin (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source

    if [ -e phpPgAdmin.osx ];
    then
      echo "Removing existing phpPgAdmin.osx source directory"
      rm -rf phpPgAdmin.osx  || _die "Couldn't remove the existing phpPgAdmin.osx source directory (source/phpPgAdmin.osx)"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/source/phpPgAdmin.osx)"
    mkdir -p $WD/phpPgAdmin/source/phpPgAdmin.osx || _die "Couldn't create the phpPgAdmin.osx directory"

    # Grab a copy of the source tree
    cp -R phpPgAdmin-$PG_VERSION_PHPPGADMIN/* phpPgAdmin.osx || _die "Failed to copy the source code (source/phpPgAdmin-$PG_VERSION_PHPPGADMIN)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpPgAdmin/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpPgAdmin/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/staging/osx)"
    mkdir -p $WD/phpPgAdmin/staging/osx/phpPgAdmin || _die "Couldn't create the staging directory"
    
    echo "END PREP phpPgAdmin OSX"
}

################################################################################
# phpPGAdmin Build
################################################################################

_build_phpPgAdmin_osx() {
    
    echo "BEGIN BUILD phpPgAdmin OSX"    
 
    echo "*******************************************************"
    echo " Build : phpPGAdmin (OSX)"
    echo "*******************************************************"

    cd $WD
    cp -R $WD/phpPgAdmin/source/phpPgAdmin.osx/* $WD/phpPgAdmin/staging/osx/phpPgAdmin || _die "Failed to copy the phpPgAdmin Source into the staging directory"
     
    echo "END BUILD phpPgAdmin OSX"
 } 


################################################################################
# phpPGAdmin Post-Process
################################################################################

_postprocess_phpPgAdmin_osx() {
           
    echo "BEGIN POST phpPgAdmin OSX"

    echo "*******************************************************"
    echo " Post Process : phpPGAdmin (OSX)"
    echo "*******************************************************"

    cd $WD/phpPgAdmin

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/phpPgAdmin || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/phpPgAdmin/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"

    # Setup the phpPgAdmin Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the phpPgAdmin Launch Scripts"

    cp scripts/osx/pg-launchPhpPgAdmin.applescript.in staging/osx/scripts/pg-launchPhpPgAdmin.applescript || _die "Failed to copy the pg-launchPhpPgAdmin.applescript  script (scripts/osx/pg-launchPhpPgAdmin.applescript.in)"

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod -R ugo+x staging/osx/scripts/getapacheport.sh || _die "Couldn't set the permissions on the getapacheport.sh"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpPgAdmin.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPhpPgAdmin.icns)"

    #Configure the conf.php file
    _replace "\$conf\['servers'\]\[0\]\['host'\] = '';" "\$conf\['servers'\]\[0\]\['host'\] = '@@PGHOST@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['port'\] = 5432;" "\$conf\['servers'\]\[0\]\['port'\] = @@PGPORT@@;" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '/usr/bin/pg_dump';" "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '@@PGDUMP@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '/usr/bin/pg_dumpall';" "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '@@PGDUMPALL@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['extra_login_security'\] = true;" "\$conf\['extra_login_security'\] = false;" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"

    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app.tar.bz2 phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf phppgadmin*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app; mv phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx-signed.app  phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.zip phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD

    echo "END POST phpPgAdmin OSX"

}


#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_phpBB_osx() {

    echo "*******************************************************"
    echo " Pre Process : phpBB (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source

    if [ -e phpBB.osx ];
    then
      echo "Removing existing phpBB.osx source directory"
      rm -rf phpBB.osx  || _die "Couldn't remove the existing phpBB.osx source directory (source/phpBB.osx)"
    fi

    echo "Creating staging directory ($WD/phpBB/source/phpBB.osx)"
    mkdir -p $WD/phpBB/source/phpBB.osx || _die "Couldn't create the phpBB.osx directory"

    # Grab a copy of the source tree
    cp -R phpBB-$PG_VERSION_PHPBB/* phpBB.osx || _die "Failed to copy the source code (source/phpBB-$PG_VERSION_PHPBB)"
    chmod -R ugo+w phpBB.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpBB/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/osx)"
    mkdir -p $WD/phpBB/staging/osx/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# phpBB Build
################################################################################

_build_phpBB_osx() {

    echo "*******************************************************"
    echo " Build : phpBB (OSX)"
    echo "*******************************************************"

    cd $WD
    mkdir -p $PG_PATH_OSX/phpBB/staging/osx/instscripts || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/phpBB/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/phpBB/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/phpBB/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLLS=`otool -L $PG_PATH_OSX/phpBB/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/phpBB/staging/osx/instscripts/psql"
    done

}

################################################################################
# phpBB Post-Process
################################################################################

_postprocess_phpBB_osx() {

    echo "*******************************************************"
    echo " Post Process : phpBB (OSX)"
    echo "*******************************************************"

    cp -R $WD/phpBB/source/phpBB.osx/* $WD/phpBB/staging/osx/phpBB || _die "Failed to copy the phpBB Source into the staging directory"

    cd $WD/phpBB

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/phpBB || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/phpBB/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/phpBB/createshortcuts.sh

    # Setup the phpBB Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the phpBB Launch Scripts"

    cp scripts/osx/pg-launchPhpBB.applescript.in staging/osx/scripts/pg-launchPhpBB.applescript || _die "Failed to copy the pg-launchPhpBB.applescript.in  script (scripts/osx/pg-launchPhpBB.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchPhpBB.applescript

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpBB.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPhpBB.icns)"

    #configuring the install/install_install.php file
    _replace "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language" "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@" "$WD/phpBB/staging/osx/phpBB/install/install_install.php"

    chmod ugo+w staging/osx/phpBB/cache || _die "Couldn't set the permissions on the cache directory"
    chmod ugo+w staging/osx/phpBB/files || _die "Couldn't set the permissions on the files directory"
    chmod ugo+w staging/osx/phpBB/store || _die "Couldn't set the permissions on the store directory"
    chmod ugo+w staging/osx/phpBB/config.php || _die "Couldn't set the permissions on the config File"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r phpbb-$PG_VERSION_PHPBB-$PG_BUILDNUM_PHPBB-osx.zip phpbb-$PG_VERSION_PHPBB-$PG_BUILDNUM_PHPBB-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf phpbb-$PG_VERSION_PHPBB-$PG_BUILDNUM_PHPBB-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD

}


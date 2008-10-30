#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpBB_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source
    
    if [ -e phpBB.linux-x64 ];
    then
      echo "Removing existing phpBB.linux-x64 source directory"
      rm -rf phpBB.linux-x64  || _die "Couldn't remove the existing phpBB.linux-x64 source directory (source/phpBB.linux-x64)"
    fi

    echo "Creating staging directory ($WD/phpBB/source/phpBB.linux-x64)"
    mkdir -p $WD/phpBB/source/phpBB.linux-x64 || _die "Couldn't create the phpBB.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R phpBB-$PG_VERSION_PHPBB/* phpBB.linux-x64 || _die "Failed to copy the source code (source/phpBB-$PG_VERSION_PHPBB)"
    chmod -R ugo+w phpBB.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpBB/staging/linux-x64/phpBB ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/linux-x64/phpBB || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/linux-x64)"
    mkdir -p $WD/phpBB/staging/linux-x64/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpBB_linux_x64() {
    
    cd $WD
}

################################################################################
# PG Build
################################################################################

_postprocess_phpBB_linux_x64() {


    cp -R $WD/phpBB/source/phpBB.linux-x64/* $WD/phpBB/staging/linux-x64/phpBB || _die "Failed to copy the phpBB Source into the staging directory"

    cd $WD/phpBB

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/phpBB || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux-x64/installer/phpBB/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/check-connection.sh

    cp scripts/linux/check-db.sh staging/linux-x64/installer/phpBB/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/phpBB/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux-x64/installer/phpBB/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/phpBB/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/removeshortcuts.sh

    # Setup the phpBB Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the phpBB Launch Scripts"

    cp scripts/linux/launchPhpBB.sh staging/linux-x64/scripts/launchPhpBB.sh || _die "Failed to copy the launchPhpBB.sh  script (scripts/linux/launchPhpBB.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchPhpBB.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

     # Setup the phpBB xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the phpBB xdg Files"
    cp resources/xdg/pg-launchPhpBB.desktop staging/linux-x64/scripts/xdg/pg-launchPhpBB.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpBB.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"


    #configuring the install/install_install.php file  
    _replace "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language" "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@" "$WD/phpBB/staging/linux-x64/phpBB/install/install_install.php" 

    chmod ugo+w staging/linux-x64/phpBB/cache || _die "Couldn't set the permissions on the cache directory"
    chmod ugo+w staging/linux-x64/phpBB/files || _die "Couldn't set the permissions on the files directory"
    chmod ugo+w staging/linux-x64/phpBB/store || _die "Couldn't set the permissions on the store directory"
    chmod ugo+w staging/linux-x64/phpBB/config.php || _die "Couldn't set the permissions on the config File"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


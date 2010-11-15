#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpBB_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source
    
    if [ -e phpBB.linux ];
    then
      echo "Removing existing phpBB.linux source directory"
      rm -rf phpBB.linux  || _die "Couldn't remove the existing phpBB.linux source directory (source/phpBB.linux)"
    fi

    echo "Creating staging directory ($WD/phpBB/source/phpBB.linux)"
    mkdir -p $WD/phpBB/source/phpBB.linux || _die "Couldn't create the phpBB.linux directory"
    
    # Grab a copy of the source tree
    cp -R phpBB-$PG_VERSION_PHPBB/* phpBB.linux || _die "Failed to copy the source code (source/phpBB-$PG_VERSION_PHPBB)"
    chmod -R ugo+w phpBB.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpBB/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/linux)"
    mkdir -p $WD/phpBB/staging/linux/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpBB_linux() {
    
    cd $WD
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p phpBB/staging/linux/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/bin/psql phpBB/staging/linux/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libpq.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libcrypto.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libssl.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libedit.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libedit.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libtermcap.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxml2.so* phpBB/staging/linux/instscripts" || _die "Failed to copy libxml2.so"

}

################################################################################
# PG Build
################################################################################

_postprocess_phpBB_linux() {


    cp -R $WD/phpBB/source/phpBB.linux/* $WD/phpBB/staging/linux/phpBB || _die "Failed to copy the phpBB Source into the staging directory"

    cd $WD/phpBB

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/phpBB || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts.sh staging/linux/installer/phpBB/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/phpBB/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/phpBB/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/phpBB/removeshortcuts.sh

    # Setup the phpBB Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the phpBB Launch Scripts"

    cp scripts/linux/launchPhpBB.sh staging/linux/scripts/launchPhpBB.sh || _die "Failed to copy the launchPhpBB.sh  script (scripts/linux/launchPhpBB.sh)"
    chmod ugo+x staging/linux/scripts/launchPhpBB.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

     # Setup the phpBB xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the phpBB xdg Files"
    cp resources/xdg/pg-launchPhpBB.desktop staging/linux/scripts/xdg/pg-launchPhpBB.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpBB.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"


    #configuring the install/install_install.php file  
    _replace "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language" "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@" "$WD/phpBB/staging/linux/phpBB/install/install_install.php" 

    chmod ugo+w staging/linux/phpBB/cache || _die "Couldn't set the permissions on the cache directory"
    chmod ugo+w staging/linux/phpBB/files || _die "Couldn't set the permissions on the files directory"
    chmod ugo+w staging/linux/phpBB/store || _die "Couldn't set the permissions on the store directory"
    chmod ugo+w staging/linux/phpBB/config.php || _die "Couldn't set the permissions on the config File"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


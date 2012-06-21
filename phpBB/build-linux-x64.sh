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
    if [ -e $WD/phpBB/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/linux-x64)"
    mkdir -p $WD/phpBB/staging/linux-x64/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpBB_linux_x64() {
    
    cd $WD
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p phpBB/staging/linux-x64/instscripts" || _die "Failed to create instscripts directory"

    cd $WD/phpBB/staging/linux-x64/instscripts/

    cp -pR $WD/server/staging/linux-x64/bin/psql* . || _die "Failed to copy psql binary"
    cp -pR $WD/server/staging/linux-x64/lib/libpq.so* . || _die "Failed to copy libpq.so"
    cp -pR $WD/server/staging/linux-x64/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $WD/server/staging/linux-x64/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $WD/server/staging/linux-x64/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $WD/server/staging/linux-x64/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $WD/server/staging/linux-x64/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $WD/server/staging/linux-x64/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $WD/server/staging/linux-x64/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $WD/server/staging/linux-x64/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $WD/server/staging/linux-x64/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $WD/server/staging/linux-x64/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $WD/server/staging/linux-x64/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"

    ssh $PG_SSH_LINUX "chmod 755 $PG_PATH_LINUX/phpBB/staging/linux-x64/instscripts/*" || _die "Failed to change permission of libraries"

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
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/phpBB/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpBB/createshortcuts.sh

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


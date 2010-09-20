#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpBB_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/phpBB/source
    
    if [ -e phpBB.windows ];
    then
      echo "Removing existing phpBB.windows source directory"
      rm -rf phpBB.windows  || _die "Couldn't remove the existing phpBB.windows source directory (source/phpBB.windows)"
    fi

    echo "Creating staging directory ($WD/phpBB/source/phpBB.windows)"
    mkdir -p $WD/phpBB/source/phpBB.windows || _die "Couldn't create the phpBB.windows directory"
    
    # Grab a copy of the source tree
    cp -R phpBB-$PG_VERSION_PHPBB/* phpBB.windows || _die "Failed to copy the source code (source/phpBB-$PG_VERSION_PHPBB)"
    chmod -R ugo+w phpBB.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpBB/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpBB/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpBB/staging/windows)"
    mkdir -p $WD/phpBB/staging/windows/phpBB || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpBB_windows() {

    cd $WD    
    # Copy the various support files into place

    mkdir -p phpBB/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* phpBB/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe phpBB/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/ssleay32.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll phpBB/staging/windows/instscripts/ || _die "Failed to copy dependent libs"

}

################################################################################
# PG Build
################################################################################

_postprocess_phpBB_windows() {


    cp -R $WD/phpBB/source/phpBB.windows/* $WD/phpBB/staging/windows/phpBB || _die "Failed to copy the phpBB Source into the staging directory"

    cd $WD/phpBB

    # Setup the phpBB Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the phpBB Launch Scripts"

    cp scripts/windows/launchPhpBB.vbs staging/windows/scripts/launchPhpBB.vbs || _die "Failed to copy the launchPhpBB.vbs  script (scripts/windows/launchPhpBB.vbs)"
    chmod ugo+x staging/windows/scripts/launchPhpBB.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    #configuring the install/install_install.php file  
    _replace "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language" "\$url = (\!in_array(false, \$passed)) ? \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=database\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@\" : \$this->p_master->module_url . \"?mode=\$mode\&amp;sub=requirements\&amp;language=\$language\&amp;dbname=phpbb\&amp;dbuser=phpbbuser\&amp;dbpasswd=phpbbuser\&amp;dbms=postgres\&amp;dbhost=@@HOST@@\&amp;dbport=@@PORT@@" "$WD/phpBB/staging/windows/phpBB/install/install_install.php" 

    chmod ugo+w staging/windows/phpBB/cache || _die "Couldn't set the permissions on the cache directory"
    chmod ugo+w staging/windows/phpBB/files || _die "Couldn't set the permissions on the files directory"
    chmod ugo+w staging/windows/phpBB/store || _die "Couldn't set the permissions on the store directory"
    chmod ugo+w staging/windows/phpBB/config.php || _die "Couldn't set the permissions on the config File"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "phpbb-$PG_VERSION_PHPBB-$PG_BUILDNUM_PHPBB-windows.exe"
	
    cd $WD

}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpWiki_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/phpWiki/source
    
    if [ -e phpWiki.linux-x64 ];
    then
      echo "Removing existing phpWiki.linux-x64 source directory"
      rm -rf phpWiki.linux-x64  || _die "Couldn't remove the existing phpWiki.linux-x64 source directory (source/phpWiki.linux-x64)"
    fi

    echo "Creating staging directory ($WD/phpWiki/source/phpWiki.linux-x64)"
    mkdir -p $WD/phpWiki/source/phpWiki.linux-x64 || _die "Couldn't create the phpWiki.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R phpwiki-$PG_VERSION_PHPWIKI/* phpWiki.linux-x64 || _die "Failed to copy the source code (source/phpwiki-$PG_VERSION_PHPWIKI)"
    chmod -R ugo+w phpWiki.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpWiki/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpWiki/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpWiki/staging/linux-x64)"
    mkdir -p $WD/phpWiki/staging/linux-x64/phpWiki || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpWiki_linux_x64() {

    cd $WD    

}


################################################################################
# PG Build
################################################################################

_postprocess_phpWiki_linux_x64() {


    cp -R $WD/phpWiki/source/phpWiki.linux-x64/* $WD/phpWiki/staging/linux-x64/phpWiki || _die "Failed to copy the phpWiki Source into the staging directory"
    cp $WD/phpWiki/resources/wiki.sql $WD/phpWiki/staging/linux-x64/phpWiki || _die "Failed to copy the Wiki.sql to Source "
    
    cd $WD/phpWiki

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/phpWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux-x64/installer/phpWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/phpWiki/check-connection.sh

    cp scripts/linux/check-db.sh staging/linux-x64/installer/phpWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux-x64/installer/phpWiki/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/phpWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpWiki/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux-x64/installer/phpWiki/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux-x64/installer/phpWiki/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/phpWiki/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpWiki/removeshortcuts.sh

    # Setup the phpWiki Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the phpWiki Launch Scripts"

    cp scripts/linux/launchPhpWiki.sh staging/linux-x64/scripts/launchPhpWiki.sh || _die "Failed to copy the launchPhpWiki.sh  script (scripts/linux/launchPhpWiki.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchPhpWiki.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    chmod -R ugo+x staging/linux-x64/scripts

     # Setup the phpWiki xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the phpWiki xdg Files"
    cp resources/xdg/pg-launchPhpWiki.desktop staging/linux-x64/scripts/xdg/pg-launchPhpWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpWiki.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"
  
     #Configure the conf.php file
    _replace "\$WhichDatabase = 'default';" "\$WhichDatabase = 'pgsql';" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"
    _replace "localhost" "@@PGHOST@@" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"
    _replace "5432" "@@PGPORT@@" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"
    _replace "\$pg_dbuser    = \"\";" "\$pg_dbuser    = \"phpwikiuser\";" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"
    _replace "\$pg_dbpass    = \"\";" "\$pg_dbpass    = \"phpwikiuser\";" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"
    _replace "\$WikiDataBase  = \"wiki\";" "\$WikiDataBase  = \"phpwiki\";" "$WD/phpWiki/staging/linux-x64/phpWiki/lib/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpWiki_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/phpWiki/source
    
    if [ -e phpWiki.linux ];
    then
      echo "Removing existing phpWiki.linux source directory"
      rm -rf phpWiki.linux  || _die "Couldn't remove the existing phpWiki.linux source directory (source/phpWiki.linux)"
    fi

    echo "Creating staging directory ($WD/phpWiki/source/phpWiki.linux)"
    mkdir -p $WD/phpWiki/source/phpWiki.linux || _die "Couldn't create the phpWiki.linux directory"
    
    # Grab a copy of the source tree
    cp -R phpwiki-$PG_VERSION_PHPWIKI/* phpWiki.linux || _die "Failed to copy the source code (source/phpwiki-$PG_VERSION_PHPWIKI)"
    chmod -R ugo+w phpWiki.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpWiki/staging/linux/phpWiki ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpWiki/staging/linux/phpWiki || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpWiki/staging/linux)"
    mkdir -p $WD/phpWiki/staging/linux/phpWiki || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpWiki_linux() {

    cd $WD    

}


################################################################################
# PG Build
################################################################################

_postprocess_phpWiki_linux() {


    cp -R $WD/phpWiki/source/phpWiki.linux/* $WD/phpWiki/staging/linux/phpWiki || _die "Failed to copy the phpWiki Source into the staging directory"
    cp $WD/phpWiki/resources/wiki.sql $WD/phpWiki/staging/linux/phpWiki || _die "Failed to copy the Wiki.sql to Source "
    
    cd $WD/phpWiki

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/phpWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux/installer/phpWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/phpWiki/check-connection.sh

    cp scripts/linux/check-db.sh staging/linux/installer/phpWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux/installer/phpWiki/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/phpWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/phpWiki/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux/installer/phpWiki/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux/installer/phpWiki/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/phpWiki/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/phpWiki/removeshortcuts.sh

    # Setup the phpWiki Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the phpWiki Launch Scripts"

    cp scripts/linux/launchPhpWiki.sh staging/linux/scripts/launchPhpWiki.sh || _die "Failed to copy the launchPhpWiki.sh  script (scripts/linux/launchPhpWiki.sh)"
    chmod ugo+x staging/linux/scripts/launchPhpWiki.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    chmod -R ugo+x scripts/linux || _die "Couldn't set the permissions on the scripts directory"

     # Setup the phpWiki xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the phpWiki xdg Files"
    cp resources/xdg/pg-launchPhpWiki.desktop staging/linux/scripts/xdg/pg-launchPhpWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpWiki.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     # copy logo Image
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"
  
     #Configure the conf.php file
    _replace "\$WhichDatabase = 'default';" "\$WhichDatabase = 'pgsql';" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"
    _replace "localhost" "@@PGHOST@@" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"
    _replace "5432" "@@PGPORT@@" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"
    _replace "\$pg_dbuser    = \"\";" "\$pg_dbuser    = \"phpwikiuser\";" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"
    _replace "\$pg_dbpass    = \"\";" "\$pg_dbpass    = \"phpwikiuser\";" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"
    _replace "\$WikiDataBase  = \"wiki\";" "\$WikiDataBase  = \"phpwiki\";" "$WD/phpWiki/staging/linux/phpWiki/lib/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


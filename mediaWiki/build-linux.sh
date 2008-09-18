#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source
	
    if [ -e mediaWiki.linux ];
    then
      echo "Removing existing mediaWiki.linux source directory"
      rm -rf mediaWiki.linux  || _die "Couldn't remove the existing mediaWiki.linux source directory (source/mediaWiki.linux)"
    fi

    echo "Creating staging directory ($WD/mediaWiki/source/mediaWiki.linux)"
    mkdir -p $WD/mediaWiki/source/mediaWiki.linux || _die "Couldn't create the mediaWiki.linux directory"
	
    # Grab a copy of the source tree
    cp -R mediawiki-$PG_MEDIAWIKI_TARBALL/* mediaWiki.linux || _die "Failed to copy the source code (source/mediaWiki-$PG_MEDIAWIKI_TARBALL)"
    chmod -R ugo+w mediaWiki.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/linux/mediaWiki ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/linux/mediaWiki || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/linux)"
    mkdir -p $WD/mediaWiki/staging/linux/mediaWiki || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_mediaWiki_linux() {

	cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_linux() {


    cp -R $WD/mediaWiki/source/mediaWiki.linux/* $WD/mediaWiki/staging/linux/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux/installer/mediaWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/check-connection.sh	
   
    cp scripts/linux/check-db.sh staging/linux/installer/mediaWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux/installer/mediaWiki/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/mediaWiki/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/removeshortcuts.sh

    # Setup the mediaWiki launch Files
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"
    cp scripts/linux/launchMediaWiki.sh staging/linux/scripts/launchMediaWiki.sh || _die "Failed to copy the launchMediaWiki.sh  script (scripts/linux/launchMediaWiki.sh)"
    chmod ugo+x staging/linux/scripts/launchMediaWiki.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

     # Setup the mediaWiki xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the mediaWiki xdg Files"
    cp resources/xdg/enterprisedb-launchMediaWiki.desktop staging/linux/scripts/xdg/enterprisedb-launchMediaWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchMediaWiki.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/launchMediaWiki.png)"
    cp resources/enterprisedb-postgres.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/postgres.png)"
    # copy logo Image 
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files "

    #Configure the config/index.php file
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"

    chmod a+w staging/linux/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


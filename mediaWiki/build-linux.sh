#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_linux() {

    echo "*******************************************************"
    echo " Pre Process : MediaWiki (LIN)"
    echo "*******************************************************"

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
    cp -R mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.linux || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
    chmod -R ugo+w mediaWiki.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/linux)"
    mkdir -p $WD/mediaWiki/staging/linux/mediaWiki || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_mediaWiki_linux() {

    echo "*******************************************************"
    echo " Build : MediaWiki (LIN)"
    echo "*******************************************************"

    cd $WD
    mkdir -p mediaWiki/staging/linux/instscripts || _die "Failed to create instscripts directory"
	cd $WD/mediaWiki/staging/linux/instscripts

    cp $WD/server/staging/linux/bin/psql* . || _die "Failed to copy psql binary"
    cp $WD/server/staging/linux/lib/libpq.so* . || _die "Failed to copy libpq.so"
    cp $WD/server/staging/linux/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp $WD/server/staging/linux/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp $WD/server/staging/linux/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp $WD/server/staging/linux/lib/libtermcap.so* . || _die "Failed to copy libtermcap.so"
    cp $WD/server/staging/linux/lib/libxml2.so* . || _die "Failed to copy libxml2.so"
    cp $WD/server/staging/linux/lib/libxslt.so* . || _die "Failed to copy libxslt.so"
    cp $WD/server/staging/linux/lib/libldap*2.3.so* . || _die "Failed to copy libldap*.so"
    cp $WD/server/staging/linux/lib/liblber*2.3.so* . || _die "Failed to copy liblber*.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_linux() {

    echo "*******************************************************"
    echo " Post Process : MediaWiki (LIN)"
    echo "*******************************************************"

    cp -R $WD/mediaWiki/source/mediaWiki.linux/* $WD/mediaWiki/staging/linux/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts.sh staging/linux/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/mediaWiki/createshortcuts.sh

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
    cp resources/xdg/pg-launchMediaWiki.desktop staging/linux/scripts/xdg/pg-launchMediaWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchMediaWiki.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/launchMediaWiki.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/postgresql.png)"
    # copy logo Image 
    cp resources/logo.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files "

    #Configure the config/index.php file
    _replace "\$conf->DBserver = importPost( \"DBserver\", \"localhost\" );" "\$conf->DBserver = importPost( \"DBserver\", \"@@HOST@@\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBport      = importPost( \"DBport\",      \"5432\" );" "\$conf->DBport      = importPost( \"DBport\",      \"@@PORT@@\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"
    _replace "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"postgres\", 1);" "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"template1\", 1);" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"

    chmod a+w staging/linux/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


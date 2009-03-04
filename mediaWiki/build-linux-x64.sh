#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source
    
    if [ -e mediaWiki.linux-x64 ];
    then
      echo "Removing existing mediaWiki.linux-x64 source directory"
      rm -rf mediaWiki.linux-x64  || _die "Couldn't remove the existing mediaWiki.linux-x64 source directory (source/mediaWiki.linux-x64)"
    fi

    echo "Creating staging directory ($WD/mediaWiki/source/mediaWiki.linux-x64)"
    mkdir -p $WD/mediaWiki/source/mediaWiki.linux-x64 || _die "Couldn't create the mediaWiki.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.linux-x64 || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
    chmod -R ugo+w mediaWiki.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/linux-x64)"
    mkdir -p $WD/mediaWiki/staging/linux-x64/mediaWiki || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_mediaWiki_linux_x64() {

    cd $WD
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; mkdir -p mediaWiki/staging/linux-x64/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/bin/psql mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libpq.so* mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libcrypto.so* mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libssl.so* mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libreadline.so* mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy libreadline.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; cp server/staging/linux-x64/lib/libtermcap.so* mediaWiki/staging/linux-x64/instscripts" || _die "Failed to copy libtermcap.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_linux_x64() {


    cp -R $WD/mediaWiki/source/mediaWiki.linux-x64/* $WD/mediaWiki/staging/linux-x64/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux-x64/installer/mediaWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/check-connection.sh    
   
    cp scripts/linux/check-db.sh staging/linux-x64/installer/mediaWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/check-db.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/createshortcuts.sh

    cp scripts/linux/install.sh staging/linux-x64/installer/mediaWiki/install.sh || _die "Failed to copy the install.sh script (scripts/linux/install.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/install.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/mediaWiki/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/removeshortcuts.sh

    # Setup the mediaWiki launch Files
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"
    cp scripts/linux/launchMediaWiki.sh staging/linux-x64/scripts/launchMediaWiki.sh || _die "Failed to copy the launchMediaWiki.sh  script (scripts/linux/launchMediaWiki.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchMediaWiki.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

     # Setup the mediaWiki xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the mediaWiki xdg Files"
    cp resources/xdg/pg-launchMediaWiki.desktop staging/linux-x64/scripts/xdg/pg-launchMediaWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchMediaWiki.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/launchMediaWiki.png)"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/postgresql.png)"
    # copy logo Image 
    cp resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files "

    #Configure the config/index.php file
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/linux-x64/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/linux-x64/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux-x64/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/linux-x64/mediaWiki/config/index.php"

    chmod a+w staging/linux-x64/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


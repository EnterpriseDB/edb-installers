#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_linux_x64() {

    echo "*******************************************************"
    echo " Pre Process : MediaWiki (LIN-X64)"
    echo "*******************************************************"

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
    cp -pR mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.linux-x64 || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
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

    echo "*******************************************************"
    echo " Build : MediaWiki (LIN-X64)"
    echo "*******************************************************"

    mkdir -p $WD/mediaWiki/staging/linux-x64/instscripts || _die "Failed to create instscripts directory"
    cd $WD/mediaWiki/staging/linux-x64/instscripts

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

}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_linux_x64() {

    echo "*******************************************************"
    echo " Post Process : MediaWiki (LIN-X64)"
    echo "*******************************************************"

    cp -pR $WD/mediaWiki/source/mediaWiki.linux-x64/* $WD/mediaWiki/staging/linux-x64/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp -pR scripts/linux/createshortcuts.sh staging/linux-x64/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/createshortcuts.sh

    cp -pR scripts/linux/removeshortcuts.sh staging/linux-x64/installer/mediaWiki/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/mediaWiki/removeshortcuts.sh

    # Setup the mediaWiki launch Files
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"
    cp -pR scripts/linux/launchMediaWiki.sh staging/linux-x64/scripts/launchMediaWiki.sh || _die "Failed to copy the launchMediaWiki.sh  script (scripts/linux/launchMediaWiki.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchMediaWiki.sh

    cp -pR scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

     # Setup the mediaWiki xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the mediaWiki xdg Files"
    cp -pR resources/xdg/pg-launchMediaWiki.desktop staging/linux-x64/scripts/xdg/pg-launchMediaWiki.desktop || _die "Failed to copy the xdg files (resources)"
    cp -pR resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp -pR resources/pg-launchMediaWiki.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/launchMediaWiki.png)"
    cp -pR resources/pg-postgresql.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/postgresql.png)"
    # copy logo Image 
    cp -pR resources/logo.ico staging/linux-x64/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -pR $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files "

    #Configure the includes/DefaultSettings.php file
    _replace "\$wgDBserver = 'localhost';" "\$wgDBserver = '@@HOST@@';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"
    _replace "\$wgDBport = '5432';" "\$wgDBport = '@@PORT@@';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"
    _replace "\$wgDBname = 'my_wiki';" "\$wgDBname = 'mediawiki';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"
    _replace "\$wgDBuser = 'wikiuser';" "\$wgDBuser = 'mediawikiuser';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"    _replace "\$wgDBpassword = '';" "\$wgDBpassword = 'mediawikiuser';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"
    _replace "\$wgDBtype = 'mysql';" "\$$wgDBtype = 'postgresql';" "$WD/mediaWiki/staging/linux-x64/mediaWiki/includes/DefaultSettings.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source
    
    if [ -e mediaWiki.windows ];
    then
      echo "Removing existing mediaWiki.windows source directory"
      rm -rf mediaWiki.windows  || _die "Couldn't remove the existing mediaWiki.windows source directory (source/mediaWiki.windows)"
    fi

    echo "Creating staging directory ($WD/mediaWiki/source/mediaWiki.windows)"
    mkdir -p $WD/mediaWiki/source/mediaWiki.windows || _die "Couldn't create the mediaWiki.windows directory"
    
    # Grab a copy of the source tree
    cp -R mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.windows || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
    chmod -R ugo+w mediaWiki.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/windows)"
    mkdir -p $WD/mediaWiki/staging/windows/mediaWiki || _die "Couldn't create the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_mediaWiki_windows() {
    
    cd $WD

}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_windows() {

    cp -R $WD/mediaWiki/source/mediaWiki.windows/* $WD/mediaWiki/staging/windows/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/mediaWiki || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/check-connection.bat staging/windows/installer/mediaWiki/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/mediaWiki/check-connection.bat
   
    cp scripts/windows/check-db.bat staging/windows/installer/mediaWiki/check-db.bat || _die "Failed to copy the check-db.bat script (scripts/windows/check-db.bat)"
    chmod ugo+x staging/windows/installer/mediaWiki/check-db.bat

    cp scripts/windows/install.bat staging/windows/installer/mediaWiki/install.bat || _die "Failed to copy the install.bat script (scripts/windows/install.bat)"
    chmod ugo+x staging/windows/installer/mediaWiki/install.bat

    # Setup the mediaWiki launch Files
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"

    cp scripts/windows/launchMediaWiki.vbs staging/windows/scripts/launchMediaWiki.vbs || _die "Failed to copy the launchMediaWiki.vbs script (scripts/windows/launchMediaWiki.vbs)"
    chmod ugo+x staging/windows/scripts/launchMediaWiki.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"

    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/logo.ico)"

    #Configure the config/index.php file
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"

    chmod a+w staging/windows/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD

}


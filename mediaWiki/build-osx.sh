		#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_mediaWiki_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/mediaWiki/source

    if [ -e mediaWiki.osx ];
    then
      echo "Removing existing mediaWiki.osx source directory"
      rm -rf mediaWiki.osx  || _die "Couldn't remove the existing mediaWiki.osx source directory (source/mediaWiki.osx)"
    fi

    echo "Creating staging directory ($WD/mediaWiki/source/mediaWiki.osx)"
    mkdir -p $WD/mediaWiki/source/mediaWiki.osx || _die "Couldn't create the mediaWiki.osx directory"

    # Grab a copy of the source tree
    cp -R mediawiki-$PG_VERSION_MEDIAWIKI/* mediaWiki.osx || _die "Failed to copy the source code (source/mediaWiki-$PG_VERSION_MEDIAWIKI)"
    chmod -R ugo+w mediaWiki.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/mediaWiki/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/mediaWiki/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/mediaWiki/staging/osx)"
    mkdir -p $WD/mediaWiki/staging/osx/mediaWiki || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_mediaWiki_osx() {

    cd $WD

}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_osx() {

    cp -R $WD/mediaWiki/source/mediaWiki.osx/* $WD/mediaWiki/staging/osx/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki
    # Setup the installer scripts.
    mkdir -p staging/osx/installer/mediaWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/check-connection.sh staging/osx/installer/mediaWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x staging/osx/installer/mediaWiki/check-connection.sh
   
    cp scripts/osx/check-db.sh staging/osx/installer/mediaWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/osx/check-db.sh)"
    chmod ugo+x staging/osx/installer/mediaWiki/check-db.sh

    cp scripts/osx/createshortcuts.sh staging/osx/installer/mediaWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/mediaWiki/createshortcuts.sh

    cp scripts/osx/install.sh staging/osx/installer/mediaWiki/install.sh || _die "Failed to copy the install.sh script (scripts/osx/install.sh)"
    chmod ugo+x staging/osx/installer/mediaWiki/install.sh

    # Setup the mediaWiki launch Files
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"
    cp scripts/osx/pg-launchMediaWiki.applescript.in staging/osx/scripts/pg-launchMediaWiki.applescript || _die "Failed to copy the pg-launchMediaWiki.applescript.in  script (scripts/osx/pg-launchMediaWiki.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchMediaWiki.applescript

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchMediaWiki.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchMediaWiki.icns)"

    #Configure the config/index.php file
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/osx/mediaWiki/config/index.php"

    chmod a+w staging/osx/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.zip mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


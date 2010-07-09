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

    cd $WD/mediaWiki/source
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
    # Copy the various support files into place

    mkdir -p mediaWiki/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* mediaWiki/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe mediaWiki/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll mediaWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"


}


################################################################################
# PG Build
################################################################################

_postprocess_mediaWiki_windows() {

    cp -R $WD/mediaWiki/source/mediaWiki.windows/* $WD/mediaWiki/staging/windows/mediaWiki || _die "Failed to copy the mediaWiki Source into the staging directory"

    cd $WD/mediaWiki

    # Setup the mediaWiki launch Files
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the mediaWiki Launch Files"

    cp scripts/windows/launchMediaWiki.vbs staging/windows/scripts/launchMediaWiki.vbs || _die "Failed to copy the launchMediaWiki.vbs script (scripts/windows/launchMediaWiki.vbs)"
    chmod ugo+x staging/windows/scripts/launchMediaWiki.vbs

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"

    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/logo.ico)"

    #Configure the config/index.php file
    _replace "\$conf->DBserver = importPost( \"DBserver\", \"localhost\" );" "\$conf->DBserver = importPost( \"DBserver\", \"@@HOST@@\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBport      = importPost( \"DBport\",      \"5432\" );" "\$conf->DBport      = importPost( \"DBport\",      \"@@PORT@@\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBname = importPost( \"DBname\", \"wikidb\" );" "\$conf->DBname = importPost( \"DBname\", \"mediawiki\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBuser = importPost( \"DBuser\", \"wikiuser\" );" "\$conf->DBuser = importPost( \"DBuser\", \"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword = importPost( \"DBpassword\" );" "\$conf->DBpassword = importPost( \"DBpassword\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$conf->DBpassword2 = importPost( \"DBpassword2\" );" "\$conf->DBpassword2 = importPost( \"DBpassword2\",\"mediawikiuser\" );" "$WD/mediaWiki/staging/windows/mediaWiki/config/index.php"
    _replace "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"postgres\", 1);" "\$wgDatabase = \$dbc->newFromParams(\$wgDBserver, \$wgDBsuperuser, \$conf->RootPW, \"template1\", 1);" "$WD/mediaWiki/staging/linux/mediaWiki/config/index.php"

    chmod a+w staging/windows/mediaWiki/config || _die "Couldn't set the permissions on the config directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "mediawiki-$PG_VERSION_MEDIAWIKI-$PG_BUILDNUM_MEDIAWIKI-windows.exe"
	
    cd $WD

}


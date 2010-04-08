#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpWiki_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/phpWiki/source
    
    if [ -e phpWiki.windows ];
    then
      echo "Removing existing phpWiki.windows source directory"
      rm -rf phpWiki.windows  || _die "Couldn't remove the existing phpWiki.windows source directory (source/phpWiki.windows)"
    fi

    echo "Creating staging directory ($WD/phpWiki/source/phpWiki.windows)"
    mkdir -p $WD/phpWiki/source/phpWiki.windows || _die "Couldn't create the phpWiki.windows directory"
    
    # Grab a copy of the source tree
    cp -R phpwiki-$PG_VERSION_PHPWIKI/* phpWiki.windows || _die "Failed to copy the source code (source/phpwiki-$PG_VERSION_PHPWIKI)"
    chmod -R ugo+w phpWiki.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpWiki/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpWiki/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpWiki/staging/windows)"
    mkdir -p $WD/phpWiki/staging/windows/phpWiki || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpWiki_windows() {
    
        cd $WD    
    # Copy the various support files into place

    mkdir -p phpWiki/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* phpWiki/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe phpWiki/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/ssleay32.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll phpWiki/staging/windows/instscripts/ || _die "Failed to copy dependent libs"

}


################################################################################
# PG Build
################################################################################

_postprocess_phpWiki_windows() {


    cp -R $WD/phpWiki/source/phpWiki.windows/* $WD/phpWiki/staging/windows/phpWiki || _die "Failed to copy the phpWiki Source into the staging directory"
    cp $WD/phpWiki/resources/wiki.sql $WD/phpWiki/staging/windows/phpWiki || _die "Failed to copy the Wiki.sql to Source "

    cd $WD/phpWiki/staging/windows/phpWiki/locale/ru/pgsrc/
    rm -f %* || _die "Failed to remove the wierd named file from the phpWiki/locale/ru/pgsrc directory" 

    cd $WD/phpWiki

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/phpWiki || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/check-connection.bat staging/windows/installer/phpWiki/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/phpWiki/check-connection.bat

    cp scripts/windows/check-db.bat staging/windows/installer/phpWiki/check-db.bat || _die "Failed to copy the check-db.bat script (scripts/windows/check-db.bat)"
    chmod ugo+x staging/windows/installer/phpWiki/check-db.bat

    cp scripts/windows/install.bat staging/windows/installer/phpWiki/install.bat || _die "Failed to copy the install.bat script (scripts/windows/install.bat)"
    chmod ugo+x staging/windows/installer/phpWiki/install.bat

    # Setup the phpWiki Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the phpWiki Launch Scripts"

    cp scripts/windows/launchPhpWiki.vbs staging/windows/scripts/launchPhpWiki.vbs || _die "Failed to copy the launchPhpWiki.vbs  script (scripts/windows/launchPhpWiki.vbs)"
    chmod ugo+x staging/windows/scripts/launchPhpWiki.vbs

    chmod -R ugo+x scripts/windows || _die "Couldn't set the permissions on the scripts directory"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"

    
     #Configure the conf.php file
    _replace "\$WhichDatabase = 'default';" "\$WhichDatabase = 'pgsql';" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"
    _replace "localhost" "@@PGHOST@@" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"
    _replace "5432" "@@PGPORT@@" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"
    _replace "\$pg_dbuser    = \"\";" "\$pg_dbuser    = \"phpwikiuser\";" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"
    _replace "\$pg_dbpass    = \"\";" "\$pg_dbpass    = \"phpwikiuser\";" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"
    _replace "\$WikiDataBase  = \"wiki\";" "\$WikiDataBase  = \"phpwiki\";" "$WD/phpWiki/staging/windows/phpWiki/lib/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "phpwiki-$PG_VERSION_PHPWIKI-$PG_BUILDNUM_PHPWIKI-windows.exe"
	
    cd $WD

}


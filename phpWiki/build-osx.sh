#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_phpWiki_osx() {

    echo "*******************************************************"
    echo " Pre Process : phpWiki (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/phpWiki/source

    if [ -e phpWiki.osx ];
    then
      echo "Removing existing phpWiki.osx source directory"
      rm -rf phpWiki.osx  || _die "Couldn't remove the existing phpWiki.osx source directory (source/phpWiki.osx)"
    fi

    echo "Creating staging directory ($WD/phpWiki/source/phpWiki.osx)"
    mkdir -p $WD/phpWiki/source/phpWiki.osx || _die "Couldn't create the phpWiki.osx directory"

    # Grab a copy of the source tree
    cp -R phpwiki-$PG_VERSION_PHPWIKI/* phpWiki.osx || _die "Failed to copy the source code (source/phpwiki-$PG_VERSION_PHPWIKI)"
    chmod -R ugo+w phpWiki.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpWiki/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpWiki/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpWiki/staging/osx)"
    mkdir -p $WD/phpWiki/staging/osx/phpWiki || _die "Couldn't create the staging directory"


}

################################################################################
# phpWiki Build
################################################################################

_build_phpWiki_osx() {

    echo "*******************************************************"
    echo " Build : phpWiki (OSX)"
    echo "*******************************************************"

    cd $WD
    mkdir -p $PG_PATH_OSX/phpWiki/staging/osx/instscripts || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/phpWiki/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/phpWiki/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/phpWiki/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"

    # Change the referenced libraries
    OLD_DLLS=`otool -L $PG_PATH_OSX/phpWiki/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for DLL in $OLD_DLLS
    do
        NEW_DLL=`echo $DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$DLL" "$NEW_DLL" "$PG_PATH_OSX/phpWiki/staging/osx/instscripts/psql"
    done

}


################################################################################
# phpWiki PostProcess
################################################################################

_postprocess_phpWiki_osx() {

    echo "*******************************************************"
    echo " Post Process : phpWiki (OSX)"
    echo "*******************************************************"

    cp -R $WD/phpWiki/source/phpWiki.osx/* $WD/phpWiki/staging/osx/phpWiki || _die "Failed to copy the phpWiki Source into the staging directory"
    cp $WD/phpWiki/resources/wiki.sql $WD/phpWiki/staging/osx/phpWiki || _die "Failed to copy the Wiki.sql to Source "

    cd $WD/phpWiki

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/phpWiki || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/check-connection.sh staging/osx/installer/phpWiki/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x staging/osx/installer/phpWiki/check-connection.sh

    cp scripts/osx/check-db.sh staging/osx/installer/phpWiki/check-db.sh || _die "Failed to copy the check-db.sh script (scripts/osx/check-db.sh)"
    chmod ugo+x staging/osx/installer/phpWiki/check-db.sh

    cp scripts/osx/createshortcuts.sh staging/osx/installer/phpWiki/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/phpWiki/createshortcuts.sh

    cp scripts/osx/install.sh staging/osx/installer/phpWiki/install.sh || _die "Failed to copy the install.sh script (scripts/osx/install.sh)"
    chmod ugo+x staging/osx/installer/phpWiki/install.sh

    # Setup the phpWiki Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the phpWiki Launch Scripts"

    cp scripts/osx/pg-launchPhpWiki.applescript.in staging/osx/scripts/pg-launchPhpWiki.applescript || _die "Failed to copy the pg-launchPhpWiki.applescript.in  script (scripts/osx/pg-launchPhpWiki.applescript)"
    chmod ugo+x staging/osx/scripts/pg-launchPhpWiki.applescript

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    chmod -R ugo+x scripts/osx || _die "Couldn't set the permissions on the scripts directory"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchPhpWiki.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPhpWiki.icns)"

    #Configure the conf.php file
    _replace "\$WhichDatabase = 'default';" "\$WhichDatabase = 'pgsql';" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"
    _replace "localhost" "@@PGHOST@@" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"
    _replace "5432" "@@PGPORT@@" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"
    _replace "\$pg_dbuser    = \"\";" "\$pg_dbuser    = \"phpwikiuser\";" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"
    _replace "\$pg_dbpass    = \"\";" "\$pg_dbpass    = \"phpwikiuser\";" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"
    _replace "\$WikiDataBase  = \"wiki\";" "\$WikiDataBase  = \"phpwiki\";" "$WD/phpWiki/staging/osx/phpWiki/lib/config.php"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r phpwiki-$PG_VERSION_PHPWIKI-$PG_BUILDNUM_PHPWIKI-osx.zip phpwiki-$PG_VERSION_PHPWIKI-$PG_BUILDNUM_PHPWIKI-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf phpwiki-$PG_VERSION_PHPWIKI-$PG_BUILDNUM_PHPWIKI-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD

}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source
    
    if [ -e phpPgAdmin.linux-x64 ];
    then
      echo "Removing existing phpPgAdmin.linux-x64 source directory"
      rm -rf phpPgAdmin.linux-x64  || _die "Couldn't remove the existing phpPgAdmin.linux-x64 source directory (source/phpPgAdmin.linux-x64)"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/source/phpPgAdmin.linux-x64)"
    mkdir -p $WD/phpPgAdmin/source/phpPgAdmin.linux-x64 || _die "Couldn't create the phpPgAdmin.linux-x64 directory"
    
    # Grab a copy of the source tree
    cp -R phpPgAdmin-$PG_VERSION_PHPPGADMIN/* phpPgAdmin.linux-x64 || _die "Failed to copy the source code (source/phpPgAdmin-$PG_VERSION_PHPPGADMIN)"
    chmod -R ugo+w phpPgAdmin.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpPgAdmin/staging/linux-x64/phpPgAdmin ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpPgAdmin/staging/linux-x64/phpPgAdmin || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/staging/linux-x64)"
    mkdir -p $WD/phpPgAdmin/staging/linux-x64/phpPgAdmin || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpPgAdmin_linux_x64() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_phpPgAdmin_linux_x64() {


    cp -R $WD/phpPgAdmin/source/phpPgAdmin.linux-x64/* $WD/phpPgAdmin/staging/linux-x64/phpPgAdmin || _die "Failed to copy the phpPgAdmin Source into the staging directory"

    cd $WD/phpPgAdmin

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/phpPgAdmin || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/phpPgAdmin/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/phpPgAdmin/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/phpPgAdmin/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x  staging/linux-x64/installer/phpPgAdmin/removeshortcuts.sh

    # Setup the phpPgAdmin Launch Scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the phpPgAdmin Launch Scripts"

    cp scripts/linux/launchPhpPgAdmin.sh staging/linux-x64/scripts/launchPhpPgAdmin.sh || _die "Failed to copy the launchPhpWiki.sh  script (scripts/linux/launchPhpWiki.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchPhpPgAdmin.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    chmod -R ugo+x staging/linux-x64/scripts || _die "Couldn't set the permissions on the scripts directory"

     # Setup the phpPgAdmin xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the phpPgAdmin xdg Files"
    cp resources/xdg/enterprisedb-launchPhpPgAdmin.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchPhpPgAdmin.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux-x64/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchPhpPgAdmin.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/enterprisedb-postgres.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/install.ico staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"    

    #Configure the conf.php file
    _replace "\$conf\['servers'\]\[0\]\['host'\] = '';" "\$conf\['servers'\]\[0\]\['host'\] = '@@PGHOST@@';" "$WD/phpPgAdmin/staging/linux-x64/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['port'\] = 5432;" "\$conf\['servers'\]\[0\]\['port'\] = @@PGPORT@@;" "$WD/phpPgAdmin/staging/linux-x64/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '/usr/bin/pg_dump';" "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '@@PGDUMP@@';" "$WD/phpPgAdmin/staging/linux-x64/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '/usr/bin/pg_dumpall';" "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '@@PGDUMPALL@@';" "$WD/phpPgAdmin/staging/linux-x64/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['extra_login_security'\] = true;" "\$conf\['extra_login_security'\] = false;" "$WD/phpPgAdmin/staging/linux-x64/phpPgAdmin/conf/config.inc.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


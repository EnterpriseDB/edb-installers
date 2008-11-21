#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgphonehome/source
    
    if [ -e pgphonehome.linux ];
    then
      echo "Removing existing pgphonehome.linux source directory"
      rm -rf pgphonehome.linux  || _die "Couldn't remove the existing pgphonehome.linux source directory (source/pgphonehome.linux)"
    fi

    echo "Creating staging directory ($WD/pgphonehome/source/pgphonehome.linux)"
    mkdir -p $WD/pgphonehome/source/pgphonehome.linux || _die "Couldn't create the pgphonehome.linux directory"
    
    # Grab a copy of the source tree
    cp -R PGPHONEHOME/* pgphonehome.linux || _die "Failed to copy the source code (source/pgphonehome-$PG_VERSION_PGPHONEHOME)"
    chmod -R ugo+w pgphonehome.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgphonehome/staging/linux/pgphonehome ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgphonehome/staging/linux/pgphonehome || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgphonehome/staging/linux)"
    mkdir -p $WD/pgphonehome/staging/linux/pgph || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgphonehome_linux() {
    
    cd $WD
}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_linux() {


    cp -R $WD/pgphonehome/source/pgphonehome.linux/* $WD/pgphonehome/staging/linux/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pgph || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/check-connection.sh staging/linux/installer/pgph/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/pgph/check-connection.sh

    cp scripts/linux/check-httpd.sh staging/linux/installer/pgph/check-httpd.sh || _die "Failed to copy the check-httpd script (scripts/linux/check-httpd.sh)"
    chmod ugo+x staging/linux/installer/pgph/check-httpd.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/pgph/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pgph/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/pgph/removeshortcuts.sh || _die "Failed to copy the removeshortcuts.sh (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pgph/removeshortcuts.sh

    # Setup the pgphonehome Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the pgphonehome Launch Scripts"

    cp scripts/linux/launchpgphonehome.sh staging/linux/scripts/launchpgphonehome.sh || _die "Failed to copy the launchpgphonehome.sh  script (scripts/linux/launchpgphonehome.sh)"
    chmod ugo+x staging/linux/scripts/launchpgphonehome.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser.sh script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

     # Setup the pgphonehome xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the pgphonehome xdg Files"
    cp resources/xdg/pg-launchpgphonehome.desktop staging/linux/scripts/xdg/pg-launchpgphonehome.desktop || _die "Failed to copy the xdg files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchpgphonehome.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     # copy logo Image
    cp resources/*.ico staging/linux/scripts/images || _die "Failed to copy the logo image (resources/logo.ico)"
    
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg/ || _die "Failed to copy the xdg files (resources/)"

    cp staging/linux/pgph/config.php.in staging/linux/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/linux/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=postgres user=@@USER@@ password=@@PASSWORD@@\";" "staging/linux/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/linux/pgph/config.php"



    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


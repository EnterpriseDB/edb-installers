#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pgphonehome/source
	
    if [ -e pgphonehome.osx ];
    then
      echo "Removing existing pgphonehome.osx source directory"
      rm -rf pgphonehome.osx  || _die "Couldn't remove the existing pgphonehome.osx source directory (source/pgphonehome.osx)"
    fi

    echo "Creating staging directory ($WD/pgphonehome/source/pgphonehome.osx)"
    mkdir -p $WD/pgphonehome/source/pgphonehome.osx || _die "Couldn't create the pgphonehome.osx directory"
	
    # Grab a copy of the source tree
    cp -R PGPHONEHOME/* pgphonehome.osx || _die "Failed to copy the source code (source/pgphonehome-$PG_VERSION_PGPHONEHOME)"
    chmod -R ugo+w pgphonehome.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgphonehome/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgphonehome/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgphonehome/staging/osx)"
    mkdir -p $WD/pgphonehome/staging/osx/pgph || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgphonehome_osx() {
	
    cd $WD
}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_osx() {


    cp -R $WD/pgphonehome/source/pgphonehome.osx/* $WD/pgphonehome/staging/osx/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pgph || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/check-connection.sh staging/osx/installer/pgph/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x staging/osx/installer/pgph/check-connection.sh

    cp staging/osx/pgph/config.php.in staging/osx/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/osx/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/osx/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=postgres user=@@USER@@ password=@@PASSWORD@@\";" "staging/osx/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/osx/pgph/config.php"
	

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgphonehome-$PG_VERSION_PGPHONEHOME-$PG_BUILDNUM_PGPHONEHOME-osx.zip pgphonehome-$PG_VERSION_PGPHONEHOME-$PG_BUILDNUM_PGPHONEHOME-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgphonehome-$PG_VERSION_PGPHONEHOME-$PG_BUILDNUM_PGPHONEHOME-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


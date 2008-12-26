#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgphonehome_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pgphonehome/source
    
    if [ -e pgphonehome.windows ];
    then
      echo "Removing existing pgphonehome.windows source directory"
      rm -rf pgphonehome.windows  || _die "Couldn't remove the existing pgphonehome.windows source directory (source/pgphonehome.windows)"
    fi

    echo "Creating staging directory ($WD/pgphonehome/source/pgphonehome.windows)"
    mkdir -p $WD/pgphonehome/source/pgphonehome.windows || _die "Couldn't create the pgphonehome.windows directory"
    
    # Grab a copy of the source tree
    cp -R PGPHONEHOME/* pgphonehome.windows || _die "Failed to copy the source code (source/pgphonehome-$PG_VERSION_PGPHONEHOME)"
    chmod -R ugo+w pgphonehome.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgphonehome/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgphonehome/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgphonehome/staging/windows)"
    mkdir -p $WD/pgphonehome/staging/windows/pgph || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgphonehome_windows() {

    cd $WD    
}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_windows() {


    cp -R $WD/pgphonehome/source/pgphonehome.windows/* $WD/pgphonehome/staging/windows/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/pgph || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/check-connection.bat staging/windows/installer/pgph/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/pgph/check-connection.bat

    cp staging/windows/pgph/config.php.in staging/windows/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/windows/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/windows/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=postgres user=@@USER@@ password=@@PASSWORD@@\";" "staging/windows/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/windows/pgph/config.php"

    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD

}


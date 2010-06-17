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
    # Copy the various support files into place

    mkdir -p pgphonehome/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* pgphonehome/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe pgphonehome/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll pgphonehome/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
 
}

################################################################################
# PG Build
################################################################################

_postprocess_pgphonehome_windows() {


    cp -R $WD/pgphonehome/source/pgphonehome.windows/* $WD/pgphonehome/staging/windows/pgph || _die "Failed to copy the pgphonehome Source into the staging directory"

    cd $WD/pgphonehome

    cp staging/windows/pgph/config.php.in staging/windows/pgph/config.php || _die "Failed to copy the config file"
    rm -f staging/windows/pgph/config.php.in  || _die "Failed to remove the template config file"

    _replace "// \$servers\[1\]\[\"description\"\] = \"Development\";" "\$servers\[1\]\[\"description\"\] = \"Development\";" "staging/windows/pgph/config.php"
    _replace "// \$servers\[1\]\[\"connstr\"\] = \"host=localhost dbname=postgres user=postgres\";" "\$servers\[1\]\[\"connstr\"\] = \"host=@@HOST@@ port=@@PORT@@ dbname=@@DBNAME@@ user=@@USER@@ password=@@PASSWORD@@\";" "staging/windows/pgph/config.php"
    _replace "// \$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "\$servers\[1\]\[\"icon\"\] = \"images/pg.png\";" "staging/windows/pgph/config.php"

    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "pgphonehome-$PG_VERSION_PGPHONEHOME-$PG_BUILDNUM_PGPHONEHOME-windows.exe"
	
    cd $WD

}


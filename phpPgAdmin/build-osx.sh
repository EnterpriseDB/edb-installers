#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source
	
    if [ -e phpPgAdmin.osx ];
    then
      echo "Removing existing phpPgAdmin.osx source directory"
      rm -rf phpPgAdmin.osx  || _die "Couldn't remove the existing phpPgAdmin.osx source directory (source/phpPgAdmin.osx)"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/source/phpPgAdmin.osx)"
    mkdir -p $WD/phpPgAdmin/source/phpPgAdmin.osx || _die "Couldn't create the phpPgAdmin.osx directory"
	
    # Grab a copy of the source tree
    cp -R phpPgAdmin-$PG_VERSION_PHPPGADMIN/* phpPgAdmin.osx || _die "Failed to copy the source code (source/phpPgAdmin-$PG_VERSION_PHPPGADMIN)"
    chmod -R ugo+w phpPgAdmin.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpPgAdmin/staging/osx/phpPgAdmin ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpPgAdmin/staging/osx/phpPgAdmin || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/staging/osx)"
    mkdir -p $WD/phpPgAdmin/staging/osx/phpPgAdmin || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpPgAdmin_osx() {

	cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_phpPgAdmin_osx() {


    cp -R $WD/phpPgAdmin/source/phpPgAdmin.osx/* $WD/phpPgAdmin/staging/osx/phpPgAdmin || _die "Failed to copy the phpPgAdmin Source into the staging directory"

    cd $WD/phpPgAdmin

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/phpPgAdmin || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/phpPgAdmin/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"

    # Setup the phpPgAdmin Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the phpPgAdmin Launch Scripts"

    cp scripts/osx/enterprisedb-launchPhpPgAdmin.applescript.in staging/osx/scripts/enterprisedb-launchPhpPgAdmin.applescript || _die "Failed to copy the enterprisedb-launchPhpPgAdmin.applescript  script (scripts/osx/enterprisedb-launchPhpPgAdmin.applescript.in)"
    

    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport.sh script (scripts/osx/getapacheport.sh)"
    chmod -R ugo+x staging/osx/scripts/getapacheport.sh || _die "Couldn't set the permissions on the getapacheport.sh"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchPhpPgAdmin.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/enterprisedb-launchPhpPgAdmin.icns)"
	
    #Configure the conf.php file
    _replace "\$conf\['servers'\]\[0\]\['host'\] = '';" "\$conf\['servers'\]\[0\]\['host'\] = '@@PGHOST@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['port'\] = 5432;" "\$conf\['servers'\]\[0\]\['port'\] = @@PGPORT@@;" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '/usr/bin/pg_dump';" "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '@@PGDUMP@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '/usr/bin/pg_dumpall';" "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '@@PGDUMPALL@@';" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['extra_login_security'\] = true;" "\$conf\['extra_login_security'\] = false;" "$WD/phpPgAdmin/staging/osx/phpPgAdmin/conf/config.inc.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.zip phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD

}


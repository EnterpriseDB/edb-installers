#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_phpPgAdmin_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/phpPgAdmin/source
    
    if [ -e phpPgAdmin.windows ];
    then
      echo "Removing existing phpPgAdmin.windows source directory"
      rm -rf phpPgAdmin.windows  || _die "Couldn't remove the existing phpPgAdmin.windows source directory (source/phpPgAdmin.windows)"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/source/phpPgAdmin.windows)"
    mkdir -p $WD/phpPgAdmin/source/phpPgAdmin.windows || _die "Couldn't create the phpPgAdmin.windows directory"
    
    # Grab a copy of the source tree
    cp -R phpPgAdmin-$PG_VERSION_PHPPGADMIN/* phpPgAdmin.windows || _die "Failed to copy the source code (source/phpPgAdmin-$PG_VERSION_PHPPGADMIN)"
    chmod -R ugo+w phpPgAdmin.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/phpPgAdmin/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/phpPgAdmin/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/phpPgAdmin/staging/windows)"
    mkdir -p $WD/phpPgAdmin/staging/windows/phpPgAdmin || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_phpPgAdmin_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_phpPgAdmin_windows() {


    cp -R $WD/phpPgAdmin/source/phpPgAdmin.windows/* $WD/phpPgAdmin/staging/windows/phpPgAdmin || _die "Failed to copy the phpPgAdmin Source into the staging directory"

    cd $WD/phpPgAdmin

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/phpPgAdmin || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/setPath.bat staging/windows/installer/phpPgAdmin/setPath.bat || _die "Failed to copy the setPath.bat script (scripts/windows/setPath.bat)"
    chmod ugo+x staging/windows/installer/phpPgAdmin/setPath.bat

    # Setup the phpPgAdmin Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the phpPgAdmin Launch Scripts"

    cp scripts/windows/launchPhpPgAdmin.vbs staging/windows/scripts/launchPhpPgAdmin.vbs || _die "Failed to copy the launchPhpWiki.vbs  script (scripts/windows/launchPhpWiki.vbs)"
    chmod -R ugo+x staging/windows/scripts/launchPhpPgAdmin.vbs || _die "Couldn't set the permissions on the launchPhpPgAdmin.vbs"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/install.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/install.ico)"
    cp resources/logo.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/logo.ico)"

    #Configure the conf.php file
    _replace "\$conf\['servers'\]\[0\]\['host'\] = '';" "\$conf\['servers'\]\[0\]\['host'\] = '@@PGHOST@@';" "$WD/phpPgAdmin/staging/windows/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['port'\] = 5432;" "\$conf\['servers'\]\[0\]\['port'\] = @@PGPORT@@;" "$WD/phpPgAdmin/staging/windows/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '/usr/bin/pg_dump';" "\$conf\['servers'\]\[0\]\['pg_dump_path'\] = '@@PGDUMP@@';" "$WD/phpPgAdmin/staging/windows/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '/usr/bin/pg_dumpall';" "\$conf\['servers'\]\[0\]\['pg_dumpall_path'\] = '@@PGDUMPALL@@';" "$WD/phpPgAdmin/staging/windows/phpPgAdmin/conf/config.inc.php"
    _replace "\$conf\['extra_login_security'\] = true;" "\$conf\['extra_login_security'\] = false;" "$WD/phpPgAdmin/staging/windows/phpPgAdmin/conf/config.inc.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "phppgadmin-$PG_VERSION_PHPPGADMIN-$PG_BUILDNUM_PHPPGADMIN-windows.exe"
	
    cd $WD

}


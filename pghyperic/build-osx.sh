#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.osx ];
    then
      echo "Removing existing pghyperic.osx source directory"
      rm -rf pghyperic.osx  || _die "Couldn't remove the existing pghyperic.osx source directory (source/pghyperic.osx)"
    fi
   
    echo "Creating source directory ($WD/pghyperic/source/pghyperic.osx)"
    mkdir -p $WD/pghyperic/source/pghyperic.osx || _die "Couldn't create the pghyperic.osx directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGHYPERIC-osx/* pghyperic.osx || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGHYPERIC-osx)"
    chmod -R ugo+w pghyperic.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/osx)"
    mkdir -p $WD/pghyperic/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/osx || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pghyperic/source/pghyperic.osx/* $WD/pghyperic/staging/osx || _die "Failed to copy the pghyperic Source into the staging directory"
}

################################################################################
# PG Build
################################################################################

_build_pghyperic_osx() {

    PG_STAGING=$WD/pghyperic/staging/osx
    mkdir -p $PG_STAGING/lib
    mkdir -p $PG_STAGING/bin

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -R $PG_PGHOME_OSX/bin/psql $PG_STAGING/bin || _die "Failed to copy psql"
    cp -R $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"

    # Copy libxml2 as System's libxml can be old.
    cp /usr/local/lib/libxml2* $PG_STAGING/lib || _die "Failed to copy the latest libxml2"

    _rewrite_so_refs $WD/pghyperic/staging/osx lib @loader_path/..
    install_name_tool -change "libpq.5.dylib" "@loader_path/libpq.5.dylib" "$PG_STAGING/bin/psql"
}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_osx() {
     cd $WD/pghyperic

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pghyperic || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/pghyperic/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/pghyperic/createshortcuts.sh

    cp scripts/tune-os.sh staging/osx/installer/pghyperic/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/osx/installer/pghyperic/tune-os.sh

    cp scripts/hqdb.sql staging/osx/installer/pghyperic/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pghyperic-launch.applescript.in staging/osx/scripts/pghyperic-launch.applescript || _die "Failed to to the menu pick script (scripts/osx/pghyperic-launch.applescript.in)"
    cp scripts/osx/server-start.applescript.in staging/osx/scripts/server-start.applescript || _die "Failed to to the menu pick script (scripts/osx/server-start.applescript.in)"
    cp scripts/osx/server-stop.applescript.in staging/osx/scripts/server-stop.applescript || _die "Failed to to the menu pick script (scripts/osx/server-stop.applescript.in)"
    cp scripts/osx/agent-start.applescript.in staging/osx/scripts/agent-start.applescript || _die "Failed to to the menu pick script (scripts/osx/agent-start.applescript.in)"
    cp scripts/osx/agent-stop.applescript.in staging/osx/scripts/agent-stop.applescript || _die "Failed to to the menu pick script (scripts/osx/agent-stop.applescript.in)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    if [ -f installer_1.xml ]; then
      rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/pghyperic $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"
  
    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/pghyperic
    chmod a+x $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/pghyperic
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pghyperic $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/pghyperic-$PG_VERSION_PGHYPERIC-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pghyperic-$PG_VERSION_PGHYPERIC-osx.zip pghyperic-$PG_VERSION_PGHYPERIC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pghyperic-$PG_VERSION_PGHYPERIC-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}

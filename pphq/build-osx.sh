#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pphq_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    if [ -e pphq.osx ];
    then
      echo "Removing existing pphq.osx source directory"
      rm -rf pphq.osx  || _die "Couldn't remove the existing pphq.osx source directory (source/pphq.osx)"
    fi
   
    echo "Creating source directory ($WD/pphq/source/pphq.osx)"
    mkdir -p $WD/pphq/source/pphq.osx || _die "Couldn't create the pphq.osx directory"

    # Grab a copy of the source tree
    cp -R pphq-$PG_VERSION_PPHQ-osx/* pphq.osx || _die "Failed to copy the source code (source/pphq-$PG_VERSION_PPHQ-osx)"
    chmod -R ugo+w pphq.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/osx)"
    mkdir -p $WD/pphq/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/osx || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pphq/source/pphq.osx/* $WD/pphq/staging/osx || _die "Failed to copy the pphq Source into the staging directory"
}

################################################################################
# PG Build
################################################################################

_build_pphq_osx() {

    PG_STAGING=$WD/pphq/staging/osx
    mkdir -p $PG_STAGING/lib
    mkdir -p $PG_STAGING/bin

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -R $PG_PGHOME_OSX/bin/psql $PG_STAGING/bin || _die "Failed to copy psql"
    cp -R $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"

    # Copy libxml2 as System's libxml can be old.
    cp /usr/local/lib/libxml2* $PG_STAGING/lib || _die "Failed to copy the latest libxml2"

    _rewrite_so_refs $WD/pphq/staging/osx lib @loader_path/..
    install_name_tool -change "libpq.5.dylib" "@loader_path/libpq.5.dylib" "$PG_STAGING/bin/psql"
}


################################################################################
# PG Build
################################################################################

_postprocess_pphq_osx() {
     cd $WD/pphq

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pphq || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/pphq/createshortcuts.sh

    cp scripts/tune-os.sh staging/osx/installer/pphq/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/osx/installer/pphq/tune-os.sh

    cp scripts/change_version_str.sh staging/osx/installer/pphq/change_version_str.sh || _die "Failed to copy the change_version_str.sh script (scripts/change_version_str.sh)"
    chmod ugo+x staging/osx/installer/pphq/change_version_str.sh
    
    cp scripts/hqdb.sql staging/osx/installer/pphq/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pphq-launch.applescript.in staging/osx/scripts/pphq-launch.applescript || _die "Failed to to the menu pick script (scripts/osx/pphq-launch.applescript.in)"
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
        cp $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/pphq $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"
  
    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/pphq
    chmod a+x $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/pphq
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pphq $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.zip pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}

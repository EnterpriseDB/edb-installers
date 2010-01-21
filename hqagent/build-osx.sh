    #!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_hqagent_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    if [ -e hqagent.osx ];
    then
      echo "Removing existing hqagent.osx source directory"
      rm -rf hqagent.osx  || _die "Couldn't remove the existing hqagent.osx source directory (source/hqagent.osx)"
    fi
   
    echo "Creating source directory ($WD/hqagent/source/hqagent.osx)"
    mkdir -p $WD/hqagent/source/hqagent.osx || _die "Couldn't create the hqagent.osx directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_HQAGENT-osx/* hqagent.osx || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_HQAGENT-osx)"
    chmod -R ugo+w hqagent.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hqagent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hqagent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hqagent/staging/osx)"
    mkdir -p $WD/hqagent/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hqagent/staging/osx || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/hqagent/source/hqagent.osx/* $WD/hqagent/staging/osx || _die "Failed to copy the hqagent Source into the staging directory"

}

################################################################################
# PG Build
################################################################################

_build_hqagent_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_hqagent_osx() {
 
     cd $WD/hqagent

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/hqagent || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/hqagent/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/hqagent/createshortcuts.sh

    # Hack up the scripts, and compile them into the staging directory
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
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
        cp $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/hqagent $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/hqagent
    chmod a+x $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/hqagent
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ hqagent $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/hqagent-$PG_VERSION_HQAGENT-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r hqagent-$PG_VERSION_HQAGENT-osx.zip hqagent-$PG_VERSION_HQAGENT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf hqagent-$PG_VERSION_HQAGENT-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


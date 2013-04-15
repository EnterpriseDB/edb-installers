#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_osx() {

    echo "*******************************************************"
    echo " Pre Process : pgJDBC (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/pgJDBC/source

    if [ -e pgJDBC.osx ];
    then
      echo "Removing existing pgJDBC.osx source directory"
      rm -rf pgJDBC.osx  || _die "Couldn't remove the existing pgJDBC.osx source directory (source/pgJDBC.osx)"
    fi

    echo "Creating source directory ($WD/pgJDBC/source/pgJDBC.osx)"
    mkdir -p $WD/pgJDBC/source/pgJDBC.osx || _die "Couldn't create the pgJDBC.osx directory"

    # Grab a copy of the source tree
    cp -R pgJDBC-$PG_VERSION_PGJDBC/* pgJDBC.osx || _die "Failed to copy the source code (source/pgJDBC-$PG_VERSION_PGJDBC)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgJDBC/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/osx)"
    mkdir -p $WD/pgJDBC/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/osx || _die "Couldn't set the permissions on the staging directory"


}

################################################################################
# pgJDBC Build
################################################################################

_build_pgJDBC_osx() {

    echo "*******************************************************"
    echo " Build : pgJDBC (OSX)"
    echo "*******************************************************"
    cp -R $WD/pgJDBC/source/pgJDBC.osx/* $WD/pgJDBC/staging/osx || _die "Failed to copy the pgJDBC Source into the staging directory"

    cd $WD
}


################################################################################
# pgJDBC Post-Process
################################################################################

_postprocess_pgJDBC_osx() {

    echo "*******************************************************"
    echo " Post Process : pgJDBC (OSX)"
    echo "*******************************************************"

    cd $WD/pgJDBC

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/pgjdbc || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/pgjdbc/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/pgjdbc/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pgjdbc.applescript staging/osx/scripts/pgjdbc.applescript || _die "Failed to copy the pgjdbc.applescript script (scripts/osx/pgjdbc.applescript)"

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
        cp $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/pgJDBC $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/pgJDBC
    chmod a+x $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/pgJDBC
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgJDBC $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}


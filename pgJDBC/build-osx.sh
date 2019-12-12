#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pgJDBC_osx() {
    
    echo "BEGIN PREP pgJDBC OSX"    

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
    if [ -e $WD/pgJDBC/staging/osx.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgJDBC/staging/osx.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgJDBC/staging/osx.build)"
    mkdir -p $WD/pgJDBC/staging/osx.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgJDBC/staging/osx.build || _die "Couldn't set the permissions on the staging directory"

    echo "END PREP pgJDBC OSX"
}

################################################################################
# pgJDBC Build
################################################################################

_build_pgJDBC_osx() {
    
    echo "BEGIN BUILD pgJDBC OSX"    

    echo "*******************************************************"
    echo " Build : pgJDBC (OSX)"
    echo "*******************************************************"
    cp -R $WD/pgJDBC/source/pgJDBC.osx/* $WD/pgJDBC/staging/osx.build || _die "Failed to copy the pgJDBC Source into the staging directory"

    echo "Removing last successful staging directory ($WD/pgJDBC/staging/osx)"
    rm -rf $WD/pgJDBC/staging/osx || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/pgJDBC/staging/osx || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/pgJDBC/staging/osx || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/pgJDBC/staging/osx.build/* $WD/pgJDBC/staging/osx || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PGJDBC=$PG_VERSION_PGJDBC" > $WD/pgJDBC/staging/osx/versions-osx.sh
    echo "PG_BUILDNUM_PGJDBC=$PG_BUILDNUM_PGJDBC" >> $WD/pgJDBC/staging/osx/versions-osx.sh

    cd $WD

    echo "END BUILD pgJDBC OSX"
}


################################################################################
# pgJDBC Post-Process
################################################################################

_postprocess_pgJDBC_osx() {

    echo "BEGIN POST pgJDBC OSX"

    echo "*******************************************************"
    echo " Post Process : pgJDBC (OSX)"
    echo "*******************************************************"

    source $WD/pgJDBC/staging/osx/versions-osx.sh
    PG_BUILD_PGJDBC=$(expr $PG_BUILD_PGJDBC + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PGJDBC -gt 0 ];
    then
        BUILD_FAILED=""
    fi

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

    # Set permissions to all files and folders in staging
    _set_permissions osx
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.app $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app/Contents/MacOS/pgJDBC
    chmod a+x $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app/Contents/MacOS/pgJDBC
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgJDBC $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh

    cd $WD/output
    
    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app.tar.bz2 pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgjdbc*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app; mv pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx-signed.app  pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.zip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf pgjdbc-$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx*" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/pgjdbc-$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh pgjdbc-$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip pgmemcache" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; sh -x ./notarize_apps.sh pgjdbc-$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip pgmemcache" || _die "Failed to notarize the app"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/pgjdbc-$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD

    echo "END POST pgJDBC OSX"
}


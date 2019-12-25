#!/bin/bash
set -x

################################################################################
# Build preparation
################################################################################

_prep_Slony_osx() {
    
    echo "BEGIN PREP Slony OSX"    

    echo "*******************************************************"
    echo " Pre Process : Slony(OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.osx ];
    then
      echo "Removing existing slony.osx source directory"
      rm -rf slony.osx  || _die "Couldn't remove the existing slony.osx source directory (source/slony.osx)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.osx)"
    mkdir -p slony.osx || _die "Couldn't create the slony.osx directory"
    chmod ugo+w slony.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.osx || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"
    tar -jcvf slony.osx.tar.bz2 slony.osx || _die "Failed to create the archive (source/postgres.tar.bz2)" ############

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/osx)"
    mkdir -p $WD/Slony/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/staging/osx.build"
    ssh $PG_SSH_OSX "rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.$PG_VERSION_SLONY.so" || _die "Failed to remove slony binary files"
    ssh $PG_SSH_OSX "rm -f share/postgresql/slony*.sql" || _die "remove slony share files"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/source" || _die "Falied to clean the Slony/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/scripts" || _die "Falied to clean the Slony/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/*.bz2" || _die "Falied to clean the Slony/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/*.sh" || _die "Falied to clean the Slony/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/staging/osx.build" || _die "Falied to clean the Slony/staging/osx.build directory on Mac OS X VM"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/Slony/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/Slony/source/slony.osx.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/Slony/source || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/Slony
    tar -jcvf scripts.tar.bz2 scripts/osx 
    scp $WD/Slony/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/Slony || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"
    rm -f $WD/Slony/scripts.tar.bz2 || _die "Couldn't remove the scipts archive (source/scripts.tar.bz2)"    

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony/source; tar -jxvf slony.osx.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony; tar -jxvf scripts.tar.bz2"
    
    cd $WD
    echo "END PREP Slony OSX"
}

################################################################################
# Slony Build
################################################################################

_build_Slony_osx() {
 
    echo "BEGIN BUILD Slony OSX"

    echo "*******************************************************"
    echo " Build : Slony(OSX)"
    echo "*******************************************************"

    # build slony
    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx.build
cat <<EOT-SLONY > $WD/Slony/build-slony.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    echo "Configuring the slony source tree"
    cd $PG_PATH_OSX/Slony/source/slony.osx/

    echo "Configuring slony sources for x86_64"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -g" PATH="$PG_PGHOME_OSX/bin:$PATH" DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$PG_PGHOME_OSX/lib" ./configure --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin --with-pgport=yes || _die "Failed to configure slony for intel x86_64"

    echo "Building slony"
    cd $PG_PATH_OSX/Slony/source/slony.osx
    CFLAGS="$PG_ARCH_OSX_CFLAGS -g" make

    cd $PG_PATH_OSX/Slony/source/slony.osx
    make install || _die "Failed to install slony"

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory

    mkdir -p $PG_PATH_OSX/Slony/staging/osx.build/bin
    cp $PG_PGHOME_OSX/bin/slon $PG_STAGING/bin || _die "Failed to copy slon binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slonik $PG_STAGING/bin || _die "Failed to copy slonik binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slony_logshipper $PG_STAGING/bin || _die "Failed to copy slony_logshipper binary to staging directory"
    chmod +rx $PG_PATH_OSX/Slony/staging/osx.build/bin/*

    mkdir -p $PG_PATH_OSX/Slony/staging/osx.build/lib
    cp $PG_PGHOME_OSX/lib/postgresql/slony1_funcs.$PG_VERSION_SLONY.so $PG_STAGING/lib || _die "Failed to copy slony_funcs.so to staging directory"
    chmod +r $PG_PATH_OSX/Slony/staging/osx.build/lib/*

    mkdir -p $PG_PATH_OSX/Slony/staging/osx.build/Slony
    cp $PG_PGHOME_OSX/share/postgresql/slony*.sql $PG_STAGING/Slony || _die "Failed to share files to staging directory"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $PG_PATH_OSX/Slony/staging/osx.build lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/Slony/staging/osx.build bin @loader_path/..

    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx.build/bin/slon"
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx.build/bin/slonik"
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/Slony/staging/osx.build/bin/slony_logshipper"
EOT-SLONY

    cd $WD
    scp Slony/build-slony.sh $PG_SSH_OSX:$PG_PATH_OSX/Slony
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony; sh ./build-slony.sh" || _die "Failed to build slony on OSX VM"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_OSX/Slony/staging/osx.build/" || _die "Failed to execute create_debug_symbols.sh"

    echo "Removing last successful staging directory ($PG_PATH_OSX/Slony/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/Slony/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/Slony/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR Slony/staging/osx.build/* Slony/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_SLONY=$PG_VERSION_SLONY > $PG_PATH_OSX/Slony/staging/osx/versions-osx.sh" || _die "Failed to write Slony version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_SLONY=$PG_BUILDNUM_SLONY >> $PG_PATH_OSX/Slony/staging/osx/versions-osx.sh" || _die "Failed to write Slony build number into versions-osx.sh"

    echo "END BUILD Slony OSX"
 }

################################################################################
# Slony Postprocess
################################################################################

_postprocess_Slony_osx() {

    echo "BEGIN POST Slony OSX"

    echo "*******************************************************"
    echo " Post Process : Slony(OSX)"
    echo "*******************************************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/Slony/staging/osx)"
    mkdir -p $WD/Slony/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony/staging/osx; rm -f Slony-staging.tar.bz2" || _die "Failed to remove archive of the Slony staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/Slony/staging/osx; tar -jcvf Slony-staging.tar.bz2 *" || _die "Failed to create archive of the Slony staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/Slony/staging/osx/slony-staging.tar.bz2 $WD/Slony/staging/osx || _die "Failed to scp Slony staging"

    # sign the binaries and libraries
    scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf slony-staging.tar.bz2" || _die "Failed to remove Slony-staging.tar from signing server"
    scp $WD/Slony/staging/osx/slony-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy slony-staging.tar.bz2 on signing server"
    rm -rf $WD/Slony/staging/osx/slony-staging.tar.bz2 || _die "Failed to remove Slony-staging.tar from controller"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../slony-staging.tar.bz2"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging" || _die "Failed to do binaries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging" || _die "Failed to do libraries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging;tar -jcvf slony-staging.tar.bz2 *" || _die "Failed to create slony-staging tar on signing server"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/slony-staging.tar.bz2 $WD/Slony/staging/osx || _die "Failed to copy slony-staging to controller vm"

    # Extract the staging archive
    cd $WD/Slony/staging/osx
    tar -jxvf slony-staging.tar.bz2 || _die "Failed to extract the slony staging archive"
    rm -f slony-staging.tar.bz2

    source $WD/Slony/staging/osx/versions-osx.sh
    PG_BUILD_SLONY=$(expr $PG_BUILD_SLONY + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SLONY -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    cd $WD/Slony

    mkdir -p staging/osx/installer/Slony || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Slony/createshortcuts.sh

    cp scripts/osx/configureslony.sh staging/osx/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/osx/configureslony.sh)"
    chmod ugo+x staging/osx/installer/Slony/configureslony.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/pg-launchSlonyDocs.applescript.in staging/osx/scripts/pg-launchSlonyDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchSlonyDocs.applescript.in)"

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchSlonyDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchSlonyDocs.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app/Contents/MacOS/Slony_I_PG$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Slony_I_PG$PG_CURRENT_VERSION $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app.tar.bz2 slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf slony*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app" || _die "Failed to sign the code"

    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app; mv slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx-signed.app  slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx*" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip slony" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; sh -x ./notarize_apps.sh slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip slony" || _die "Failed to notarize the app"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD

    echo "END POST Slony OSX"

}


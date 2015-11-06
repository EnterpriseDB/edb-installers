#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_osx() {
    
    echo "BEGIN PREP psqlODBC OSX"    

    echo "*******************************************************"
    echo " Pre Process : psqlODBC(OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.osx ];
    then
      echo "Removing existing psqlODBC.osx source directory"
      rm -rf psqlODBC.osx  || _die "Couldn't remove the existing psqlODBC.osx source directory (source/psqlODBC.osx)"
    fi

    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.osx)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.osx || _die "Couldn't create the psqlODBC.osx directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.osx || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    # patch to make sure it picks libpq from the server staging
    cd psqlODBC.osx
    patch -p0 < $WD/tarballs/psqlodbc-osx.patch

    cd $WD/psqlODBC/source
    tar -jcvf psqlodbc.tar.bz2 psqlODBC.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/osx)"
    mkdir -p $WD/psqlODBC/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/psqlODBC ]; then rm -rf $PG_PATH_OSX/psqlODBC/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/psqlODBC/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/psqlODBC/source/psqlodbc.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/psqlODBC/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/psqlODBC
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/psqlODBC/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/psqlODBC || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/psqlODBC/source; tar -jxvf psqlodbc.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/psqlODBC; tar -jxvf scripts.tar.bz2"
    
    echo "END PREP psqlODBC OSX"
}

################################################################################
# psqlODBC Build
################################################################################

_build_psqlODBC_osx() {
    
    echo "BEGIN BUILD psqlODBC OSX"

    echo "*******************************************************"
    echo " Build : psqlODBC(OSX)"
    echo "*******************************************************"

    PG_STAGING=$PG_PATH_OSX/psqlODBC/staging/osx
    SOURCE_DIR=$PG_PATH_OSX/psqlODBC/source/psqlODBC.osx
    #cd $SOURCE_DIR
    
    cat <<EOT-PSQLODBC > $WD/psqlODBC/build-psqlodbc.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh
    cd $PG_PATH_OSX/psqlODBC/source/psqlODBC.osx

    CONFIG_FILES="config"
    ARCHS="i386 x86_64"
    ARCH_FLAGS=""
    for ARCH in ${ARCHS}
    do
      echo "Configuring psqlODBC sources for ${ARCH}"
      CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ${ARCH}" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --with-iodbc --prefix="$PG_STAGING" || _die "Could not configuring psqlODBC sources for intel"
      ARCH_FLAGS="${ARCH_FLAGS} -arch ${ARCH}"
      for configFile in ${CONFIG_FILES}
      do
           if [ -f "${configFile}.h" ]; then
              cp "${configFile}.h" "${configFile}_${ARCH}.h"
           fi
      done
    done

    echo "Configuring psqlODBC sources for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS}" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --with-iodbc --prefix="$PG_STAGING" || _die "Could not configuring psqlODBC sources for Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    for configFile in ${CONFIG_FILES}
    do
      HEADER_FILE=${configFile}.h
      if [ -f "${HEADER_FILE}" ]; then
        CONFIG_BASENAME=`basename ${configFile}`
        rm -f "${HEADER_FILE}"
        cat <<EOT > "${HEADER_FILE}"
#ifdef __BIG_ENDIAN__
  #error "${CONFIG_BASENAME}: Does not have support for ppc architecture"
#else
 #ifdef __LP64__
  #include "${CONFIG_BASENAME}_x86_64.h"
 #else
  #include "${CONFIG_BASENAME}_i386.h"
 #endif
#endif
EOT
      fi
    done

    echo "Compiling psqlODBC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS ${ARCH_FLAGS}" make || _die "Couldn't compile sources"

    echo "Installing psqlODBC into the sources"
    make install || _die "Couldn't install psqlODBC"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -R $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library"
    cp -R $PG_PGHOME_OSX/lib/libssl.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library"
    cp -R $PG_PGHOME_OSX/lib/libcrypto.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library"

    _rewrite_so_refs $PG_PATH_OSX/psqlODBC/staging/osx lib @loader_path/..

    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_STAGING/lib/psqlodbcw.so"
    install_name_tool -change "libssl.1.0.0.dylib" "@loader_path/../lib/libssl.1.0.0.dylib" "$PG_STAGING/lib/psqlodbcw.so"

EOT-PSQLODBC
    cd $WD
    scp psqlODBC/build-psqlodbc.sh $PG_SSH_OSX:$PG_PATH_OSX/psqlODBC
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/psqlODBC; sh ./build-psqlodbc.sh" || _die "Failed to build the psqlODBC on OSX VM"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/psqlODBC/staging/osx; tar -jcvf psqlodbc-staging.tar.bz2 *" || _die "Failed to create archive of the psqlodbc staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/psqlODBC/staging/osx/psqlodbc-staging.tar.bz2 $WD/psqlODBC/staging/osx || _die "Failed to scp psqlodbc staging"

    # Extract the staging archive
    cd $WD/psqlODBC/staging/osx
    tar -jxvf psqlodbc-staging.tar.bz2 || _die "Failed to extract the psqlodbc staging archive"
    rm -f psqlodbc-staging.tar.bz2
    echo "END BUILD psqlODBC OSX"
}


################################################################################
# psqlODBC Post-Process
################################################################################

_postprocess_psqlODBC_osx() {
    
    echo "BEGIN POST psqlODBC OSX"    

    echo "*******************************************************"
    echo " Post Process : psqlODBC(OSX)"
    echo "*******************************************************"

    cd $WD/psqlODBC

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/psqlODBC || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/psqlODBC/createshortcuts.sh

    cp scripts/osx/getodbcinstpath.sh staging/osx/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/osx/getodbcinstpath.sh)"
    chmod ugo+x staging/osx/installer/psqlODBC/getodbcinstpath.sh

    #Setup the launch scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pg-launchOdbcDocs.applescript.in staging/osx/scripts/pg-launchOdbcDocs.applescript || _die "Failed to copy the pg-launchOdbcDocs.applescript.in script (scripts/osx/scripts/pg-launchOdbcDocs.applescript)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchOdbcDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchOdbcDocs.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/psqlODBC $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/psqlODBC
    chmod a+x $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/psqlODBC
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ psqlODBC $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with psqlODBC ($WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh
    
    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app.tar.bz2 psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf psqlodbc*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app; mv psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx-signed.app  psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD
    
    echo "END POST psqlODBC OSX"
}


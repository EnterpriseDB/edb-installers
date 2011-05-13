#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_osx() {

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

    chmod -R ugo+w psqlODBC.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/osx)"
    mkdir -p $WD/psqlODBC/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/osx || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# psqlODBC Build
################################################################################

_build_psqlODBC_osx() {

    echo "*******************************************************"
    echo " Build : psqlODBC(OSX)"
    echo "*******************************************************"

    PG_STAGING=$PG_PATH_OSX/psqlODBC/staging/osx
    SOURCE_DIR=$PG_PATH_OSX/psqlODBC/source/psqlODBC.osx
    cd $SOURCE_DIR

    #Hack for psqlODBC-08.04.0200 
    cp $PG_PGHOME_OSX/lib/libpq.5.dylib . || _die "Failed to copy the libpq to the build directory"

    CONFIG_FILES="config"
    ARCHS="i386 ppc x86_64"
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
 #ifdef __LP64__
  #error "${CONFIG_BASENAME}: Does not have support for ppc64 architecture"
 #else
  #include "${CONFIG_BASENAME}_ppc.h"
 #endif
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
    _rewrite_so_refs $WD/psqlODBC/staging/osx lib @loader_path/..
    install_name_tool -change "libpq.5.dylib" "@loader_path/libpq.5.dylib" "$PG_STAGING/lib/psqlodbcw.so"

    chmod a+rx $PG_STAGING/lib/*.dylib || _die "Failed to change mode of all the libraries"

}


################################################################################
# psqlODBC Post-Process
################################################################################

_postprocess_psqlODBC_osx() {

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

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/psqlODBC
    chmod a+x $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/psqlODBC
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ psqlODBC $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with psqlODBC ($WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}


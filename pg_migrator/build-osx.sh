#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_pg_migrator_osx() {

    echo "***********************************"
    echo "* Preparing - pg_migrator (osx) *"
    echo "***********************************"

    # pg_migrator is depend on server
    if [ ! -d "$PG_PATH_OSX/server/source/postgres.osx" ]; then exit -1; fi || _die "Server sources not found at this location \"$PG_PATH_OSX/server/source/postgres.osx\".\nWe need to build server before building pg_migrator."
    if [ ! -f "$PG_PATH_OSX/server/source/postgres.osx/src/port/libpgport.a" ]; then exit -1; fi || _die "Looks like we have not built server yet.\nWe need to build server before building pg_migrator."

    # Enter the source directory and cleanup if required
    cd $WD/pg_migrator/source

    if [ -e pg_migrator.osx ];
    then
      echo "Removing existing pg_migrator.osx source directory"
      rm -rf pg_migrator.osx  || _die "Couldn't remove the existing pg_migrator.osx source directory (source/pg_migrator.osx)"
    fi
   
    echo "Creating source directory ($WD/pg_migrator/source/pg_migrator.osx)"
    mkdir -p $WD/pg_migrator/source/pg_migrator.osx || _die "Couldn't create the pg_migrator.osx directory"

    # Grab a copy of the source tree
    cp -R pg_migrator-$PG_VERSION_PGMIGRATOR/* pg_migrator.osx || _die "Failed to copy the source code (source/pg_migrator-$PG_VERSION_PGMIGRATOR)"
    chmod -R ugo+w pg_migrator.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pg_migrator/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pg_migrator/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pg_migrator/staging/osx)"
    mkdir -p $WD/pg_migrator/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pg_migrator/staging/osx || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# pg_migrator Build
################################################################################

_build_pg_migrator_osx() {

    echo "**********************************"
    echo "* Building - pg_migrator (osx) *"
    echo "**********************************"

    cd $WD/pg_migrator/source/pg_migrator.osx

    make top_builddir=$PG_PATH_OSX/server/source/postgres.osx|| _die "Could not build pg_migrator on osx"

    mkdir $WD/pg_migrator/staging/osx/bin || _die "Couldn't create the bin directory under staging directory"
    mkdir $WD/pg_migrator/staging/osx/lib || _die "Couldn't create the lib directory under staging directory"

    cp $WD/pg_migrator/source/pg_migrator.osx/src/pg_migrator $WD/pg_migrator/staging/osx/bin || _die "Couldn't copy pg_migrator binary to bin (staing directory)"
    cp $WD/pg_migrator/source/pg_migrator.osx/func/pg_migrator.so $WD/pg_migrator/staging/osx/lib || _die "Couldn't copy pg_migrator.so binary to lib (staing directory)"
    cp $WD/pg_migrator/source/pg_migrator.osx/CHANGES $WD/pg_migrator/staging/osx/CHANGES.pg_migrator || _die "Couldn't copy CHANGES to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/DEVELOPERS $WD/pg_migrator/staging/osx/DEVELOPERS.pg_migrator || _die "Couldn't copy DEVELOPERS to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/IMPLEMENTATION $WD/pg_migrator/staging/osx/IMPLEMENTATION.pg_migrator || _die "Couldn't copy IMPLEMENTATION to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/IMPLEMENTATION.jp $WD/pg_migrator/staging/osx/IMPLEMENTATION_jp.pg_migrator || _die "Couldn't copy IMPLEMENTATION.jp to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/INSTALL $WD/pg_migrator/staging/osx/INSTALL.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/INSTALL.jp $WD/pg_migrator/staging/osx/INSTALL_jp.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/LICENSE $WD/pg_migrator/staging/osx/LICENSE.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/README $WD/pg_migrator/staging/osx/README.pg_migrator || _die "Couldn't copy INSTALL to staging directory"

    install_name_tool -change "$PG_PGHOME_OSX/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/pg_migrator/staging/osx/bin/pg_migrator"
    install_name_tool -change "$PG_PGHOME_OSX/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_PATH_OSX/pg_migrator/staging/osx/lib/pg_migrator.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_pg_migrator_osx() {

    echo "*****************************************"
    echo "* Post-processing - pg_migrator (osx) *"
    echo "*****************************************"

    cd $WD/pg_migrator

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r pgmigrator-$PG_VERSION_PGMIGRATOR-$PG_BUILDNUM_PGMIGRATOR-osx.zip pgmigrator-$PG_VERSION_PGMIGRATOR-$PG_BUILDNUM_PGMIGRATOR-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgmigrator-$PG_VERSION_PGMIGRATOR-$PG_BUILDNUM_PGMIGRATOR-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


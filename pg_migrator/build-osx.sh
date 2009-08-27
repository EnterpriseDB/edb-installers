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
    mkdir -p $WD/pg_migrator/staging/osx/UserValidation || _die "Couldn't create the staging/UserValidation directory"
    chmod ugo+w $WD/pg_migrator/staging/osx || _die "Couldn't set the permissions on the staging directory"
    chmod ugo+w $WD/pg_migrator/staging/osx/UserValidation || _die "Couldn't set the permissions on the staging/UserValidation directory"

    cp $WD/MetaInstaller/scripts/osx/sysinfo.sh $WD/pg_migrator/staging/osx/UserValidation/sysinfo.sh || _die "Couldn't copy the sysinfo.sh script to staging directory"

}

################################################################################
# pg_migrator Build
################################################################################

_build_pg_migrator_osx() {

    echo "**********************************"
    echo "* Building - pg_migrator (osx) *"
    echo "**********************************"

    cd $WD/pg_migrator/source/pg_migrator.osx
    PG_STAGING=$PG_PATH_OSX/pg_migrator/staging/osx

    make top_builddir=$PG_PATH_OSX/server/source/postgres.osx|| _die "Could not build pg_migrator on osx"

    mkdir $PG_STAGING/bin || _die "Couldn't create the bin directory under staging directory"
    mkdir $PG_STAGING/lib || _die "Couldn't create the lib directory under staging directory"

    cp $WD/pg_migrator/source/pg_migrator.osx/src/pg_migrator $PG_STAGING/bin || _die "Couldn't copy pg_migrator binary to bin (staging directory)"
    cp $WD/pg_migrator/source/pg_migrator.osx/func/pg_migrator.so $PG_STAGING/lib || _die "Couldn't copy pg_migrator.so binary to lib (staging directory)"
    cp $WD/pg_migrator/source/pg_migrator.osx/CHANGES $PG_STAGING/CHANGES.pg_migrator || _die "Couldn't copy CHANGES to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/DEVELOPERS $PG_STAGING/DEVELOPERS.pg_migrator || _die "Couldn't copy DEVELOPERS to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/IMPLEMENTATION $PG_STAGING/IMPLEMENTATION.pg_migrator || _die "Couldn't copy IMPLEMENTATION to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/IMPLEMENTATION.jp $PG_STAGING/IMPLEMENTATION_jp.pg_migrator || _die "Couldn't copy IMPLEMENTATION.jp to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/INSTALL $PG_STAGING/INSTALL.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/INSTALL.jp $PG_STAGING/INSTALL_jp.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/LICENSE $PG_STAGING/LICENSE.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.osx/README $PG_STAGING/README.pg_migrator || _die "Couldn't copy INSTALL to staging directory"

    install_name_tool -change "$PG_PGHOME_OSX/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_STAGING/bin/pg_migrator"
    install_name_tool -change "$PG_PGHOME_OSX/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "$PG_STAGING/lib/pg_migrator.so"

    if [ ! -f $WD/TuningWizard/staging/osx/UserValidation/validateUserClient.o ];
    then
      echo "Building validateUserClient utility"
      cp -R $PG_PATH_OSX/MetaInstaller/scripts/osx/validateUser $PG_PATH_OSX/pg_migrator/source/pg_migrator.osx/validateUser || _die "Failed copying validateUser script while building"
      cd $WD/pg_migrator/source/pg_migrator.osx/validateUser
      gcc -DWITH_OPENSSL -I. -o validateUserClient.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto || _die "Failed to build the validateUserClient utility"
      cp validateUserClient.o $PG_STAGING/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient utility to staging directory"
    else
      echo "Using validateUserClient utility from TuningWizard package"
      cp $WD/TuningWizard/staging/osx/UserValidation/validateUserClient.o $PG_STAGING/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient utility from TuningWizard package"
    fi
    chmod ugo+x $PG_STAGING/UserValidation/*

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


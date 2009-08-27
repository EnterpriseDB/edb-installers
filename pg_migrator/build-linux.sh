#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_pg_migrator_linux() {

    echo "***********************************"
    echo "* Preparing - pg_migrator (linux) *"
    echo "***********************************"

    # pg_migrator is depend on server
    ssh $PG_SSH_LINUX "if [ ! -d \"$PG_PATH_LINUX/server/source/postgres.linux\" ]; then exit -1; fi" || _die "Server sources not found at this location \"$PG_PATH_LINUX/server/source/postgres.linux\".\nWe need to build server before building pg_migrator."
    ssh $PG_SSH_LINUX "if [ ! -f \"$PG_PATH_LINUX/server/source/postgres.linux/src/port/libpgport.a\" ]; then exit -1; fi" || _die "Looks like we have not built server yet.\nWe need to build server before building pg_migrator."

    # Enter the source directory and cleanup if required
    cd $WD/pg_migrator/source

    if [ -e pg_migrator.linux ];
    then
      echo "Removing existing pg_migrator.linux source directory"
      rm -rf pg_migrator.linux  || _die "Couldn't remove the existing pg_migrator.linux source directory (source/pg_migrator.linux)"
    fi
   
    echo "Creating staging directory ($WD/pg_migrator/source/pg_migrator.linux)"
    mkdir -p $WD/pg_migrator/source/pg_migrator.linux || _die "Couldn't create the pg_migrator.linux directory"

    # Grab a copy of the source tree
    cp -R pg_migrator-$PG_VERSION_PGMIGRATOR/* pg_migrator.linux || _die "Failed to copy the source code (source/pg_migrator-$PG_VERSION_PGMIGRATOR)"
    chmod -R ugo+w pg_migrator.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pg_migrator/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pg_migrator/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pg_migrator/staging/linux)"
    mkdir -p $WD/pg_migrator/staging/linux || _die "Couldn't create the staging directory"
    mkdir -p $WD/pg_migrator/staging/linux/UserValidation || _die "Couldn't create the staging/UserValidation directory"
    mkdir -p $WD/pg_migrator/staging/linux/UserValidation/lib || _die "Couldn't create the staging/UserValidation/lib directory"
    chmod ugo+w $WD/pg_migrator/staging/linux || _die "Couldn't set the permissions on the staging directory"
    chmod ugo+w $WD/pg_migrator/staging/linux/UserValidation || _die "Couldn't set the permissions on the staging/UserValidation directory"
    chmod ugo+w $WD/pg_migrator/staging/linux/UserValidation/lib || _die "Couldn't set the permissions on the staging/UserValidation/lib directory"
 
    echo "Copying validateUserClient scripts from MetaInstaller"
    cp $WD/MetaInstaller/scripts/linux/sysinfo.sh $WD/pg_migrator/staging/linux/UserValidation || _die "Couldn't copy MetaInstaller/scripts/linux/sysinfo.sh scripts"

}

################################################################################
# pg_migrator Build
################################################################################

_build_pg_migrator_linux() {

    echo "**********************************"
    echo "* Building - pg_migrator (linux) *"
    echo "**********************************"

    cd $WD/pg_migrator/source/pg_migrator.linux

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pg_migrator/source/pg_migrator.linux; make top_builddir=$PG_PATH_LINUX/server/source/postgres.linux" || _die "Could not build pg_migrator on linux"

    mkdir $WD/pg_migrator/staging/linux/bin || _die "Couldn't create the bin directory under staging directory"
    mkdir $WD/pg_migrator/staging/linux/lib || _die "Couldn't create the lib directory under staging directory"

    cp $WD/pg_migrator/source/pg_migrator.linux/src/pg_migrator $WD/pg_migrator/staging/linux/bin || _die "Couldn't copy pg_migrator binary to bin (staging directory)"
    cp $WD/pg_migrator/source/pg_migrator.linux/func/pg_migrator.so $WD/pg_migrator/staging/linux/lib || _die "Couldn't copy pg_migrator.so binary to lib (staging directory)"
    cp $WD/pg_migrator/source/pg_migrator.linux/CHANGES $WD/pg_migrator/staging/linux/CHANGES.pg_migrator || _die "Couldn't copy CHANGES to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/DEVELOPERS $WD/pg_migrator/staging/linux/DEVELOPERS.pg_migrator || _die "Couldn't copy DEVELOPERS to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/IMPLEMENTATION $WD/pg_migrator/staging/linux/IMPLEMENTATION.pg_migrator || _die "Couldn't copy IMPLEMENTATION to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/IMPLEMENTATION.jp $WD/pg_migrator/staging/linux/IMPLEMENTATION_jp.pg_migrator || _die "Couldn't copy IMPLEMENTATION.jp to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/INSTALL $WD/pg_migrator/staging/linux/INSTALL.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/INSTALL.jp $WD/pg_migrator/staging/linux/INSTALL_jp.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/LICENSE $WD/pg_migrator/staging/linux/LICENSE.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux/README $WD/pg_migrator/staging/linux/README.pg_migrator || _die "Couldn't copy INSTALL to staging directory"

    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_PATH_LINUX/pg_migrator/staging/linux/UserValidation/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_PATH_LINUX/pg_migrator/staging/linux/UserValidation/lib" || _die "Failed to copy the dependency library"

    # Build the validateUserClient binary
    if [ ! -f $WD/TuningWizard/staging/linux/UserValidation/validateUserClient.o ]; then
        cp -R $WD/MetaInstaller/scripts/validateUser $WD/pg_migrator/source/pg_migrator.linux/validateUser || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pg_migrator/source/pg_migrator.linux/validateUser; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
        cp $WD/pg_migrator/source/pg_migrator.linux/validateUser/validateUserClient.o $WD/pg_migrator/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    else
       cp $WD/TuningWizard/staging/linux/UserValidation/validateUserClient.o $WD/pg_migrator/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi
    chmod ugo+x $WD/pg_migrator/staging/linux/UserValidation/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}


################################################################################
# pg_migrator Post Processing
################################################################################

_postprocess_pg_migrator_linux() { 

    echo "*****************************************"
    echo "* Post-processing - pg_migrator (linux) *"
    echo "*****************************************"

    cd $WD/pg_migrator

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer for linux"

    cd $WD
}


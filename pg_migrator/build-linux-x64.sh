#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_pg_migrator_linux_x64() {

    echo "***************************************"
    echo "* Preparing - pg_migrator (linux-x64) *"
    echo "***************************************"

    # Check if postgresql (server) has already been built or not
    # pg_migrator is depend on server
    ssh $PG_SSH_LINUX_X64 "if [ ! -d \"$PG_PATH_LINUX_X64/server/source/postgres.linux-x64\" ]; then exit -1; fi" || _die "Server sources not found at this location \"$PG_PATH_LINUX_X64/server/source/postgres.linux-x64\".\nWe need to build server before building pg_migrator."
    ssh $PG_SSH_LINUX_X64 "if [ ! -f \"$PG_PATH_LINUX_X64/server/source/postgres.linux-x64/src/port/libpgport.a\" ]; then exit -1; fi" || _die "Looks like we have not built server yet.\nWe need to build server before building pg_migrator."

    # Enter the source directory and cleanup if required
    cd $WD/pg_migrator/source

    if [ -e pg_migrator.linux-x64 ];
    then
      echo "Removing existing pg_migrator.linux-x64 source directory"
      rm -rf pg_migrator.linux-x64  || _die "Couldn't remove the existing pg_migrator.linux-x64 source directory (source/pg_migrator.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/pg_migrator/source/pg_migrator.linux-x64)"
    mkdir -p $WD/pg_migrator/source/pg_migrator.linux-x64 || _die "Couldn't create the pg_migrator.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pg_migrator-$PG_VERSION_PGMIGRATOR/* pg_migrator.linux-x64 || _die "Failed to copy the source code (source/pg_migrator-$PG_VERSION_PGMIGRATOR)"
    chmod -R ugo+w pg_migrator.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pg_migrator/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pg_migrator/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pg_migrator/staging/linux)"
    mkdir -p $WD/pg_migrator/staging/linux-x64 || _die "Couldn't create the staging directory"
    mkdir -p $WD/pg_migrator/staging/linux-x64/UserValidation || _die "Couldn't create the staging/UserValidation directory"
    mkdir -p $WD/pg_migrator/staging/linux-x64/UserValidation/lib || _die "Couldn't create the staging/UserValidation/lib directory"
    chmod ugo+w $WD/pg_migrator/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    chmod ugo+w $WD/pg_migrator/staging/linux-x64/UserValidation || _die "Couldn't set the permissions on the staging/UserValidation directory"
    chmod ugo+w $WD/pg_migrator/staging/linux-x64/UserValidation/lib || _die "Couldn't set the permissions on the staging/UserValidation/lib directory"
 
    echo "Copying validateUserClient scripts from MetaInstaller"
    cp $WD/MetaInstaller/scripts/linux/sysinfo.sh $WD/pg_migrator/staging/linux-x64/UserValidation || _die "Couldn't copy MetaInstaller/scripts/linux/sysinfo.sh scripts"

}

################################################################################
# pg_migrator Build
################################################################################

_build_pg_migrator_linux_x64() {

    echo "**************************************"
    echo "* Building - pg_migrator (linux-x64) *"
    echo "**************************************"

    cd $WD/pg_migrator/source/pg_migrator.linux-x64

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pg_migrator/source/pg_migrator.linux-x64; make top_builddir=$PG_PATH_LINUX_X64/server/source/postgres.linux-x64" || _die "Could not build pg_migrator on linux-x64"

    mkdir $WD/pg_migrator/staging/linux-x64/bin || _die "Couldn't create the bin directory under staging directory"
    mkdir $WD/pg_migrator/staging/linux-x64/lib || _die "Couldn't create the lib directory under staging directory"

    cp $WD/pg_migrator/source/pg_migrator.linux-x64/src/pg_migrator $WD/pg_migrator/staging/linux-x64/bin || _die "Couldn't copy pg_migrator binary to bin (staing directory)"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/func/pg_migrator.so $WD/pg_migrator/staging/linux-x64/lib || _die "Couldn't copy pg_migrator.so binary to lib (staing directory)"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/CHANGES $WD/pg_migrator/staging/linux-x64/CHANGES.pg_migrator || _die "Couldn't copy CHANGES to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/DEVELOPERS $WD/pg_migrator/staging/linux-x64/DEVELOPERS.pg_migrator || _die "Couldn't copy DEVELOPERS to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/IMPLEMENTATION $WD/pg_migrator/staging/linux-x64/IMPLEMENTATION.pg_migrator || _die "Couldn't copy IMPLEMENTATION to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/IMPLEMENTATION.jp $WD/pg_migrator/staging/linux-x64/IMPLEMENTATION_jp.pg_migrator || _die "Couldn't copy IMPLEMENTATION.jp to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/INSTALL $WD/pg_migrator/staging/linux-x64/INSTALL.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/INSTALL.jp $WD/pg_migrator/staging/linux-x64/INSTALL_jp.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/LICENSE $WD/pg_migrator/staging/linux-x64/LICENSE.pg_migrator || _die "Couldn't copy INSTALL to staging directory"
    cp $WD/pg_migrator/source/pg_migrator.linux-x64/README $WD/pg_migrator/staging/linux-x64/README.pg_migrator || _die "Couldn't copy INSTALL to staging directory"

    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libssl.so* $PG_PATH_LINUX_X64/pg_migrator/staging/linux-x64/UserValidation/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypto.so* $PG_PATH_LINUX_X64/pg_migrator/staging/linux/UserValidation/lib" || _die "Failed to copy the dependency library"

    # Build the validateUserClient binary
    if [ ! -f $WD/TuningWizard/staging/linux-x64/UserValidation/validateUserClient.o ]; then
        cp -R $WD/MetaInstaller/scripts/validateUser $WD/pg_migrator/source/pg_migrator.linux-x64/validateUser || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/pg_migrator/source/pg_migrator.linux-x64/validateUser; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
        cp $WD/pg_migrator/source/pg_migrator.linux-x64/validateUser/validateUserClient.o $WD/pg_migrator/staging/linux-x64/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    else
       cp $WD/TuningWizard/staging/linux-x64/UserValidation/validateUserClient.o $WD/pg_migrator/staging/linux-x64/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi
    chmod ugo+x $WD/pg_migrator/staging/linux-x64/UserValidation/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}


################################################################################
# pg_migrator Post Processing
################################################################################

_postprocess_pg_migrator_linux_x64() {

    echo "*********************************************"
    echo "* Post-processing - pg_migrator (linux-x64) *"
    echo "*********************************************"
 
    cd $WD/pg_migrator

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer for linux-x64"

    cd $WD
}


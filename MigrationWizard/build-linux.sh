#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationWizard_linux() {
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationWizard/source

    if [ -e migrationwizard.linux ];
    then
      echo "Removing existing migrationwizard.linux source directory"
      rm -rf migrationwizard.linux  || _die "Couldn't remove the existing migrationwizard.linux source directory (source/migrationwizard.linux)"
    fi

    echo "Creating migrationwizard source directory ($WD/MigrationWizard/source/migrationwizard.linux)"
    mkdir -p migrationwizard.linux || _die "Couldn't create the migrationwizard.linux directory"
    chmod ugo+w migrationwizard.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationwizard source tree
    cp -R wizard/* migrationwizard.linux || _die "Failed to copy the source code (source/migrationwizard-$PG_VERSION_MIGRATIONWIZARD)"
    chmod -R ugo+w migrationwizard.linux || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationWizard/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationWizard/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationWizard/staging/linux)"
    mkdir -p $WD/MigrationWizard/staging/linux || _die "Couldn't create the staging directory"
    mkdir -p $WD/MigrationWizard/staging/linux/UserValidation || _die "Couldn't create the staging/UserValidation directory"
    mkdir -p $WD/MigrationWizard/staging/linux/UserValidation/lib || _die "Couldn't create the staging/UserValidation/lib directory"
    chmod ugo+w $WD/MigrationWizard/staging/linux || _die "Couldn't set the permissions on the staging directory"
    chmod ugo+w $WD/MigrationWizard/staging/linux/UserValidation || _die "Couldn't set the permissions on the staging/UserValidation directory"
    chmod ugo+w $WD/MigrationWizard/staging/linux/UserValidation/lib || _die "Couldn't set the permissions on the staging/UserValidation/lib directory"

    echo "Copying validateUserClient scripts from MetaInstaller"
    cp $WD/MetaInstaller/scripts/linux/sysinfo.sh $WD/MigrationWizard/staging/linux/UserValidation || _die "Couldn't copy MetaInstaller/scripts/linux/sysinfo.sh scripts"

}


################################################################################
# PG Build
################################################################################

_build_MigrationWizard_linux() {

    # build migrationwizard    
    PG_STAGING=$PG_PATH_LINUX/MigrationWizard/staging/linux    

    echo "Building migrationwizard"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant clean" || _die "Couldn't build the migrationwizard"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant" || _die "Couldn't build the migrationwizard"
  
    echo "Building migrationwizard distribution"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant dist" || _die "Couldn't build the migrationwizard distribution"

    # Copying the MigrationWizard binary to staging directory
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; mkdir $PG_STAGING/MigrationWizard" || _die "Couldn't create the migrationwizard staging directory (MigrationWizard/staging/linux/MigrationWizard)"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux; cp -R dist/* $PG_STAGING/MigrationWizard" || _die "Couldn't copy the binaries to the migrationwizard staging directory (MigrationWizard/staging/linux/MigrationWizard)"

    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_STAGING/UserValidation/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_STAGING/UserValidation/lib" || _die "Failed to copy the dependency library (libcrypto)"

    # Build the validateUserClient binary
    if [ ! -f $WD/TuningWizard/source/tuningwizard.linux/validateUser/validateUserClient.o ];
    then
        cp -R $WD/MetaInstaller/scripts/linux/validateUser $WD/MigrationWizard/source/migrationwizard.linux/validateUser || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationWizard/source/migrationwizard.linux/validateUser; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
        cp $WD/MigrationWizard/source/migrationwizard.linux/validateUser/validateUserClient.o $WD/MigrationWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    else
       cp $WD/TuningWizard/source/tuningwizard.linux/validateUser/validateUserClient.o $WD/MigrationWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi

    chmod ugo+x $WD/MigrationWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationWizard_linux() {

    cd $WD/MigrationWizard

    mkdir -p staging/linux/installer/MigrationWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/MigrationWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/MigrationWizard/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/MigrationWizard/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/MigrationWizard/removeshortcuts.sh    

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchMigrationWizard.sh staging/linux/scripts/launchMigrationWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchMigrationWizard.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchMigrationWizard.desktop staging/linux/scripts/xdg/pg-launchMigrationWizard.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}


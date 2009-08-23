#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_TuningWizard_linux() {
      
    # Enter the source directory and cleanup if required
    cd $WD/TuningWizard/source

    if [ -e tuningwizard.linux ];
    then
      echo "Removing existing tuningwizard.linux source directory"
      rm -rf tuningwizard.linux  || _die "Couldn't remove the existing tuningwizard.linux source directory (source/tuningwizard.linux)"
    fi

    echo "Creating tuningwizard source directory ($WD/TuningWizard/source/tuningwizard.linux)"
    mkdir -p tuningwizard.linux || _die "Couldn't create the tuningwizard.linux directory"
    chmod ugo+w tuningwizard.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the tuningwizard source tree
    cp -R wizard/* tuningwizard.linux || _die "Failed to copy the source code (source/tuningwizard-$PG_VERSION_TUNINGWIZARD)"
    chmod -R ugo+w tuningwizard.linux || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/TuningWizard/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/TuningWizard/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/TuningWizard/staging/linux)"
    mkdir -p $WD/TuningWizard/staging/linux || _die "Couldn't create the staging directory"
    mkdir -p $WD/TuningWizard/staging/linux/UserValidation || _die "Couldn't create the staging/UserValidation directory"
    mkdir -p $WD/TuningWizard/staging/linux/UserValidation/lib || _die "Couldn't create the staging/UserValidation/lib directory"
    chmod ugo+w $WD/TuningWizard/staging/linux || _die "Couldn't set the permissions on the staging directory"
    chmod ugo+w $WD/TuningWizard/staging/linux/UserValidation || _die "Couldn't set the permissions on the staging/UserValidation directory"
    chmod ugo+w $WD/TuningWizard/staging/linux/UserValidation/lib || _die "Couldn't set the permissions on the staging/UserValidation/lib directory"

    echo "Copying validateUserClient scripts from MetaInstaller"
    cp $WD/MetaInstaller/scripts/linux/sysinfo.sh $WD/TuningWizard/staging/linux/UserValidation || _die "Couldn't copy MetaInstaller/scripts/linux/sysinfo.sh scripts"

}


################################################################################
# TuningWizard Build
################################################################################

_build_TuningWizard_linux() {

    # build tuningwizard
    PG_STAGING=$PG_PATH_LINUX/TuningWizard/staging/linux    

    echo "Configuring the tuningwizard source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/TuningWizard/source/tuningwizard.linux; cmake CMakeLists.txt" || _die "Failed to configure TuningWizard(cmake)"
  
    echo "Building tuningwizard"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/TuningWizard/source/tuningwizard.linux; make" || _die "Failed to build TuningWizard"

    # Copying the TuningWizard binary to staging directory
    ssh $PG_SSH_LINUX "mkdir $PG_STAGING/TuningWizard" || _die "Failed to create TuningWizard staging directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/TuningWizard/source/tuningwizard.linux; cp TuningWizard $PG_STAGING/TuningWizard" || _die "Failed to copy TuningWizard binary to staging directory."

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/TuningWizard/source/tuningwizard.linux; mkdir $PG_STAGING/TuningWizard/lib" || _die "Failed to create the lib directory"
    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_STAGING/UserValidation/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_STAGING/UserValidation/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypt.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcom_err.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libexpat.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libgssapi_krb5.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libkrb5.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libk5crypto.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libtiff.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libuuid.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"

    # Build the validateUserClient binary
    if [ ! -f $WD/MetaInstaller/source/MetaInstaller.linux/validateUser/validateUserClient.o ]; then
        cp -R $WD/MetaInstaller/scripts/validateUser $WD/TuningWizard/source/tuningwizard.linux/validateUser || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/TuningWizard/source/tuningwizard.linux/validateUser; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
        cp $WD/TuningWizard/source/tuningwizard.linux/validateUser/validateUserClient.o $WD/TuningWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    else
       cp $WD/MetaInstaller/source/MetaInstaller.linux/validateUser/validateUserClient.o $WD/TuningWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi
    chmod ugo+x $WD/TuningWizard/staging/linux/UserValidation/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}
    

################################################################################
# TuningWizard Post Processing
################################################################################

_postprocess_TuningWizard_linux() {

    cd $WD/TuningWizard

    mkdir -p staging/linux/installer/TuningWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/TuningWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/TuningWizard/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/TuningWizard/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/TuningWizard/removeshortcuts.sh    

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchTuningWizard.sh staging/linux/scripts/launchTuningWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchTuningWizard.sh

    cp -R scripts/linux/runTuningWizard.sh staging/linux/scripts/runTuningWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/runTuningWizard.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchTuningWizard.desktop staging/linux/scripts/xdg/pg-launchTuningWizard.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_TuningWizard_linux_x64() {
      
    # Enter the source directory and cleanup if required
    cd $WD/TuningWizard/source

    if [ -e tuningwizard.linux-x64 ];
    then
      echo "Removing existing tuningwizard.linux-x64 source directory"
      rm -rf tuningwizard.linux-x64  || _die "Couldn't remove the existing tuningwizard.linux-x64 source directory (source/tuningwizard.linux-x64)"
    fi

    echo "Creating tuningwizard source directory ($WD/TuningWizard/source/tuningwizard.linux-x64)"
    mkdir -p tuningwizard.linux-x64 || _die "Couldn't create the tuningwizard.linux-x64 directory"
    chmod ugo+w tuningwizard.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the tuningwizard source tree
    cp -R wizard/* tuningwizard.linux-x64 || _die "Failed to copy the source code (source/tuningwizard-$PG_VERSION_TUNINGWIZARD)"
    chmod -R ugo+w tuningwizard.linux-x64 || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/TuningWizard/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/TuningWizard/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/TuningWizard/staging/linux-x64)"
    mkdir -p $WD/TuningWizard/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/TuningWizard/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_TuningWizard_linux_x64() {

    # build tuningwizard    
    PG_STAGING=$PG_PATH_LINUX_X64/TuningWizard/staging/linux-x64    

    echo "Configuring the tuningwizard source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/TuningWizard/source/tuningwizard.linux-x64; cmake CMakeLists.txt"
  
    echo "Building tuningwizard"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/TuningWizard/source/tuningwizard.linux-x64; make"

    # Copying the TuningWizard binary to staging directory
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/TuningWizard/source/tuningwizard.linux-x64; mkdir $PG_STAGING/TuningWizard"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/TuningWizard/source/tuningwizard.linux-x64; cp TuningWizard $PG_STAGING/TuningWizard"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/TuningWizard/source/tuningwizard.linux-x64; mkdir $PG_STAGING/TuningWizard/lib" || _die "Failed to create the lib directory"
    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libssl.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypto.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypt.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcom_err.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libexpat.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libgssapi_krb5.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libkrb5.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libk5crypto.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libtiff.so* $PG_STAGING/TuningWizard/lib" || _die "Failed to copy the dependency library"

}
    


################################################################################
# PG Build
################################################################################

_postprocess_TuningWizard_linux_x64() {

    cd $WD/TuningWizard

    mkdir -p staging/linux-x64/installer/TuningWizard || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/TuningWizard/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/TuningWizard/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/TuningWizard/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/TuningWizard/removeshortcuts.sh    

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchTuningWizard.sh staging/linux-x64/scripts/launchTuningWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/launchTuningWizard.sh

    cp -R scripts/linux/runTuningWizard.sh staging/linux-x64/scripts/runTuningWizard.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/runTuningWizard.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux-x64/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchTuningWizard.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchTuningWizard.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD
}


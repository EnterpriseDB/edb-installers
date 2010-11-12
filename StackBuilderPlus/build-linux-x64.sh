#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus_linux_x64() {

    echo "********************************************"
    echo "* Preparing - StackBuilderPlus (linux-x64) *"
    echo "********************************************"

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    if [ -e StackBuilderPlus.linux-x64 ];
    then
      echo "Removing existing StackBuilderPlus.linux-x64 source directory"
      rm -rf StackBuilderPlus.linux-x64  || _die "Couldn't remove the existing StackBuilderPlus.linux-x64 source directory (source/StackBuilderPlus.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/StackBuilderPlus/source/StackBuilderPlus.linux-x64)"
    mkdir -p $WD/StackBuilderPlus/source/StackBuilderPlus.linux-x64 || _die "Couldn't create the StackBuilderPlus.linux-x64 directory"

    echo "Creating source directory ($WD/StackBuilderPlus/source/updatemanager.linux-x64)"
    mkdir -p $WD/StackBuilderPlus/source/updatemanager.linux-x64 || _die "Couldn't create the updatemanager.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R STACKBUILDER-PLUS/* StackBuilderPlus.linux-x64 || _die "Failed to copy the source code (source/STACKBUILDER-PLUS)"
    chmod -R ugo+w StackBuilderPlus.linux-x64 || _die "Couldn't set the permissions on the source directory (STACKBUILDER-PLUS)"

    cp -R SS-UPDATEMANAGER/* updatemanager.linux-x64 || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemanager.linux-x64 || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/linux-x64)"
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64 || _die "Couldn't create the staging directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64/bin || _die "Couldn't create the staging/bin directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64/lib || _die "Couldn't create the staging/lib directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64/share || _die "Couldn't create the staging/share directory"
    chmod ugo+w $WD/StackBuilderPlus/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_linux_x64() {

    echo "*******************************************"
    echo "* Building - StackBuilderPlus (linux-x64) *"
    echo "*******************************************"

    cd $WD/StackBuilderPlus/source/StackBuilderPlus.linux-x64

    # Configure
    echo "Configuring the StackBuilder Plus source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/StackBuilderPlus/source/StackBuilderPlus.linux-x64/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64 ."

    # Build the app
    echo "Building & installing StackBuilderPlus"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/StackBuilderPlus/source/StackBuilderPlus.linux-x64/; make all" || _die "Failed to build StackBuilderPlus"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/StackBuilderPlus/source/StackBuilderPlus.linux-x64/; make install" || _die "Failed to install StackBuilderPlus"

    echo "Building & installing UpdateManager"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/StackBuilderPlus/source/updatemanager.linux-x64; $PG_QMAKE_LINUX_X64 UpdateManager.pro" || _die "Failed to configure UpdateManager on linux-x64"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/StackBuilderPlus/source/updatemanager.linux-x64; make" || _die "Failed to build UpdateManger on linux-x64"
      
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64/UpdateManager/bin
    mkdir -p $WD/StackBuilderPlus/staging/linux-x64/UpdateManager/lib

    echo "Copying UpdateManager binary to staging directory"
    cp $WD/StackBuilderPlus/source/updatemanager.linux-x64/UpdateManager $WD/StackBuilderPlus/staging/linux-x64/UpdateManager/bin

    echo "Copying dependent libraries to staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtXml.so.* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/UpdateManager/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtNetwork.so.* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/UpdateManager/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtCore.so.* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/UpdateManager/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtGui.so.* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/UpdateManager/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libpng12.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /lib64/libssl.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libssl.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /lib64/libcrypto.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libcrypto.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libexpat.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libexpat.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libgssapi_krb5.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libgssapi_krb5.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libkrb5.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libkrb5.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /lib64/libcom_err.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libcom_err.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libk5crypto.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libk5crypto.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libjpeg.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libjpeg.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libtiff.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libtiff.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libz.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libz.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libfreetype.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libfreetype.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libfontconfig.so* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libfontconfig.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libpango-* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libpangoft2* $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (linux-x64)"

   ssh $PG_SSH_LINUX_X64 "chmod a+r $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/lib/*" || _die "Failed to set the permissions on the lib directory"
   ssh $PG_SSH_LINUX_X64 "chmod a+r $PG_PATH_LINUX_X64/StackBuilderPlus/staging/linux-x64/UpdateManager/lib/*" || _die "Failed to set the permissions on the lib directory"
    cd $WD
}


################################################################################
# Post Processing StackBuilderPlus
################################################################################

_postprocess_stackbuilderplus_linux_x64() {

    echo "**************************************************"
    echo "* Post-processing - StackBuilderPlus (linux-x64) *"
    echo "**************************************************"
 
    cd $WD/StackBuilderPlus

    mkdir -p staging/linux-x64/installer/StackBuilderPlus || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux-x64/UpdateManager/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/StackBuilderPlus/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/StackBuilderPlus/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    cp scripts/linux/configlibs.sh staging/linux-x64/installer/StackBuilderPlus/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/configlibs.sh)"
    _replace @@PLATFORM@@ "linux64" staging/linux-x64/installer/StackBuilderPlus/configlibs.sh || _die "Failed to place platform placeholder value"
    chmod ugo+x staging/linux-x64/installer/StackBuilderPlus/*.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchSBPUpdateMonitor.sh staging/linux-x64/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchSBPUpdateMonitor.sh)"
    cp scripts/linux/launchStackBuilderPlus.sh staging/linux-x64/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/linux/launchStackBuilderPlus.sh)"
    cp scripts/linux/runStackBuilderPlus.sh staging/linux-x64/scripts/runStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/linux/runStackBuilderPlus.sh)"

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/edb-stackbuilderplus.png staging/linux-x64/scripts/images/ || _die "Failed to copy the menu pick images (resources/edb-stackbuilderplus.png)"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images/  || _die "Failed to copy the menu pick images (pg-postgresql.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    mkdir -p staging/linux-x64/UpdateManager/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/ || _die "Failed to copy a menu pick directory"
    cp resources/xdg/edb-stackbuilderplus.desktop staging/linux-x64/scripts/xdg/ || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/edb-sbp-update-monitor.desktop staging/linux-x64/UpdateManager/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer for linux-x64"

    cd $WD
}


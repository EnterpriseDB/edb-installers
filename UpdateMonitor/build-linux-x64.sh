#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_linux_x64() {

    echo "********************************************"
    echo "* Preparing - UpdateMonitor (linux-x64) *"
    echo "********************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e UpdateMonitor.linux-x64 ];
    then
      echo "Removing existing UpdateMonitor.linux-x64 source directory"
      rm -rf UpdateMonitor.linux-x64  || _die "Couldn't remove the existing UpdateMonitor.linux-x64 source directory (source/UpdateMonitor.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.linux-x64)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.linux-x64 || _die "Couldn't create the updatemonitor.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.linux-x64 || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemonitor.linux-x64 || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/UpdateMonitor/staging/linux-x64)"
    mkdir -p $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_linux_x64() {

    echo "*******************************************"
    echo "* Building - UpdateMonitor (linux-x64) *"
    echo "*******************************************"

    cd $WD/UpdateMonitor/source/UpdateMonitor.linux-x64

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/UpdateMonitor/source/updatemonitor.linux-x64; $PG_QMAKE_LINUX_X64 UpdateManager.pro" || _die "Failed to configure UpdateMonitor on linux-x64"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/UpdateMonitor/source/updatemonitor.linux-x64; make" || _die "Failed to build UpdateManger on linux-x64"
      
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/bin
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib

    echo "Copying UpdateMonitor binary to staging directory"
    cp $WD/UpdateMonitor/source/updatemonitor.linux-x64/UpdateMonitor $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/bin

    echo "Copying dependent libraries to staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtXml.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtNetwork.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtCore.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /usr/lib64/libQtGui.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux-x64)"
   ssh $PG_SSH_LINUX_X64 "chmod a+r $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib/*" || _die "Failed to set the permissions on the lib directory"
    cd $WD
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_linux_x64() {

    echo "**************************************************"
    echo "* Post-processing - UpdateMonitor (linux-x64) *"
    echo "**************************************************"
 
    cd $WD/UpdateMonitor

    mkdir -p staging/linux-x64/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux-x64/UpdateMonitor/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/linux/configlibs.sh staging/linux-x64/installer/UpdateMonitor/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/configlibs.sh)"
    _replace @@PLATFORM@@ "linux64" staging/linux-x64/installer/UpdateMonitor/configlibs.sh || _die "Failed to place platform placeholder value"
    chmod ugo+x staging/linux-x64/installer/UpdateMonitor/*.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchUpdateMonitor.sh staging/linux-x64/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchUpdateMonitor.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchUpdateMonitor.sh

    mkdir -p staging/linux-x64/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/linux-x64/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    _replace @@COMPONENT_FILE@@ "component.xml" installer.xml || _die "Failed to replace the registration_plus component file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer for linux-x64"

    cd $WD
}


#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_linux() {

    echo "****************************************"
    echo "* Preparing - UpdateMonitor (linux) *"
    echo "****************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e UpdateMonitor.linux ];
    then
      echo "Removing existing UpdateMonitor.linux source directory"
      rm -rf UpdateMonitor.linux  || _die "Couldn't remove the existing UpdateMonitor.linux source directory (source/UpdateMonitor.linux)"
    fi
   
    if [ -e GetLatestPGInstalled.linux ];
    then
      echo "Removing existing GetLatestPGInstalled.linux source directory"
      rm -rf GetLatestPGInstalled.linux  || _die "Couldn't remove the existing GetLatestPGInstalled.linux source directory (source/GetLatestPGInstalled.linux)"
    fi
   
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.linux)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.linux || _die "Couldn't create the updatemonitor.linux directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.linux || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemonitor.linux || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"
    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.linux

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/UpdateMonitor/staging/linux)"
    mkdir -p $WD/UpdateMonitor/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/linux || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_linux() {

    echo "***************************************"
    echo "* Building - UpdateMonitor (linux) *"
    echo "***************************************"

    cd $WD/UpdateMonitor/source/GetLatestPGInstalled.linux
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/GetLatestPGInstalled.linux;  g++ -I/usr/local/include/wx-2.8/ -I/usr/local/lib/wx/include/gtk2-unicode-release-2.8/ -L/usr/local/lib -lwx_baseud-2.8 -o GetLatestPGInstalled  GetLatestPGInstalled.cpp" || _die "Failed to build GetLatestPGInstalled" 

    cd $WD/UpdateMonitor/source/UpdateMonitor.linux

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/updatemonitor.linux; $PG_QMAKE_LINUX UpdateManager.pro" || _die "Failed to configuring UpdateMonitor on linux"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/updatemonitor.linux; make" || _die "Failed to build UpdateMonitor on linux"

    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/bin
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/lib
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/bin
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/lib
	
    echo "Copying UpdateMonitor binary to staging directory"
    cp $WD/UpdateMonitor/source/GetLatestPGInstalled.linux/GetLatestPGInstalled $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/bin
    cp $WD/UpdateMonitor/source/updatemonitor.linux/UpdateManager $WD/UpdateMonitor/staging/linux/UpdateMonitor/bin

    
    echo "Copying dependent libraries to staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /usr/local/lib/libwx_baseud-2.8.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libwx_baseud-2.8.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtXml.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtNetwork.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtCore.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtGui.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux)"
   ssh $PG_SSH_LINUX "chmod a+r $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib/*" || _die "Failed to set the read permissions on the lib directory"
    cd $WD
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_linux() { 

    echo "**********************************************"
    echo "* Post-processing - UpdateMonitor (linux) *"
    echo "**********************************************"

    cd $WD/UpdateMonitor

    mkdir -p staging/linux/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux/UpdateMonitor/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/linux/launchUpdateMonitor.sh staging/linux/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchUpdateMonitor.sh)"
    chmod ugo+x staging/linux/UpdateMonitor/scripts/launchUpdateMonitor.sh

    mkdir -p staging/linux/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/linux/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer for linux"

    cd $WD
}


#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_linux_x64() {
    
    echo "BEGIN PREP updatemonitor Linux-x64"

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

    if [ -e GetLatestPGInstalled.linux-x64 ];
    then
      echo "Removing existing GetLatestPGInstalled.linux-x64 source directory"
      rm -rf GetLatestPGInstalled.linux-x64  || _die "Couldn't remove the existing GetLatestPGInstalled.linux-x64 source directory (source/GetLatestPGInstalled.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.linux-x64)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.linux-x64 || _die "Couldn't create the updatemonitor.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.linux-x64 || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.linux-x64

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/UpdateMonitor/staging/linux-x64)"
    mkdir -p $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP updatemonitor Linux-x64"
}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_linux_x64() {
    
    echo "BEGIN BUILD updatemonitor Linux-x64"   

    echo "*******************************************"
    echo "* Building - UpdateMonitor (linux-x64) *"
    echo "*******************************************"

    cd $WD/UpdateMonitor/source/GetLatestPGInstalled.linux-x64
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/UpdateMonitor/source/GetLatestPGInstalled.linux-x64; LD_LIBRARY_PATH=/opt/local/Current/lib:$LD_LIBRARY_PATH  g++ -I/opt/local/Current/include/wx-2.8/ -I/opt/local/Current/lib/wx/include/gtk2-unicode-release-2.8/ -L/opt/local/Current/lib -lwx_baseud-2.8 -o GetLatestPGInstalled  GetLatestPGInstalled.cpp" || _die "Failed to build GetLatestPGInstalled"

    cd $WD/UpdateMonitor/source/updatemonitor.linux-x64

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/UpdateMonitor/source/updatemonitor.linux-x64; $PG_QT_LINUX_X64_UM/bin/qmake  UpdateManager.pro" || _die "Failed to configure UpdateMonitor on linux-x64"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/UpdateMonitor/source/updatemonitor.linux-x64; LD_LIBRARY_PATH=/opt/local/Current/lib:$LD_LIBRARY_PATH make" || _die "Failed to build UpdateManger on linux-x64"
      
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/bin
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/instscripts/bin
    mkdir -p $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/instscripts/lib

    echo "Copying UpdateMonitor binary to staging directory"
    cp $WD/UpdateMonitor/source/GetLatestPGInstalled.linux-x64/GetLatestPGInstalled $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/instscripts/bin
    cp $WD/UpdateMonitor/source/updatemonitor.linux-x64/UpdateManager $WD/UpdateMonitor/staging/linux-x64/UpdateMonitor/bin

    echo "Copying dependent libraries to staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp /opt/local/Current/lib/libwx_baseud-2.8.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libwx_baseud-2.8.so) in staging directory (linux)-x64"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libiconv.so* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libiconv.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libpng12.so* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp $PG_QT_LINUX_X64_UM/lib/libQtXml.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp $PG_QT_LINUX_X64_UM/lib/libQtNetwork.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp $PG_QT_LINUX_X64_UM/lib/libQtCore.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux-x64)"
    ssh $PG_SSH_LINUX_X64 "cp $PG_QT_LINUX_X64_UM/lib/libQtGui.so.* $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux-x64)"
   ssh $PG_SSH_LINUX_X64 "chmod a+r $PG_PATH_LINUX_X64/UpdateMonitor/staging/linux-x64/UpdateMonitor/lib/*" || _die "Failed to set the permissions on the lib directory"
    cd $WD
    
    cp $WD/UpdateMonitor/resources/licence.txt $WD/UpdateMonitor/staging/linux-x64/updatemonitor_license.txt || _die "Unable to copy updatemonitor_license.txt"
    chmod 444 $WD/UpdateMonitor/staging/linux-x64/updatemonitor_license.txt || _die "Unable to change permissions for license file."
 
    echo "END BUILD updatemonitor Linux-x64"
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_linux_x64() {

    echo "BEGIN POST updatemonitor Linux-x64"

    echo "**************************************************"
    echo "* Post-processing - UpdateMonitor (linux-x64) *"
    echo "**************************************************"
 
    cd $WD/UpdateMonitor
    
    pushd staging/linux-x64
    generate_3rd_party_license "updatemonitor"
    popd

    mkdir -p staging/linux-x64/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux-x64/UpdateMonitor/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/linux/launchUpdateMonitor.sh staging/linux-x64/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchUpdateMonitor.sh)"
    chmod ugo+x staging/linux-x64/UpdateMonitor/scripts/launchUpdateMonitor.sh

    mkdir -p staging/linux-x64/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/linux-x64/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"
    
    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer for linux-x64"

    cd $WD

    echo "END POST updatemonitor Linux-x64"
}


#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_linux() {
   
    echo "BEGIN PREP updatemonitor Linux"

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
    
    echo "END PREP updatemonitor Linux"
}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_linux() {

    PG_STAGING=$PG_PATH_LINUX/UpdateMonitor/staging/linux

    echo "BEGIN BUILD updatemonitor Linux"

    echo "***************************************"
    echo "* Building - UpdateMonitor (linux) *"
    echo "***************************************"

    cd $WD/UpdateMonitor/source/GetLatestPGInstalled.linux
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/GetLatestPGInstalled.linux; LD_LIBRARY_PATH=/opt/local/Current/lib:$LD_LIBRARY_PATH g++ -I/opt/local/Current/include/wx-2.8/ -I/opt/local/Current/lib/wx/include/gtk2-unicode-release-2.8/ -L/opt/local/Current/lib -lwx_baseud-2.8 -o GetLatestPGInstalled  GetLatestPGInstalled.cpp" || _die "Failed to build GetLatestPGInstalled" 

    cd $WD/UpdateMonitor/source/updatemonitor.linux

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/updatemonitor.linux; $PG_QMAKE_LINUX UpdateManager.pro" || _die "Failed to configuring UpdateMonitor on linux"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/UpdateMonitor/source/updatemonitor.linux; LD_LIBRARY_PATH=/opt/local/Current/lib:$LD_LIBRARY_PATH make" || _die "Failed to build UpdateMonitor on linux"
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/bin
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/lib
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/bin
    mkdir -p $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/lib
	
    echo "Copying UpdateMonitor binary to staging directory"
    cp $WD/UpdateMonitor/source/GetLatestPGInstalled.linux/GetLatestPGInstalled $WD/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/bin
    cp $WD/UpdateMonitor/source/updatemonitor.linux/UpdateManager $WD/UpdateMonitor/staging/linux/UpdateMonitor/bin

    
    echo "Copying dependent libraries to staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libwx_baseud-2.8.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libwx_baseud-2.8.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libiconv.so* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libiconv.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libpng12.so* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtXml.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtNetwork.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtCore.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtGui.so.* $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux)"
   ssh $PG_SSH_LINUX "chmod a+r $PG_PATH_LINUX/UpdateMonitor/staging/linux/UpdateMonitor/lib/*" || _die "Failed to set the read permissions on the lib directory"
    cd $WD
   
   cp $WD/UpdateMonitor/resources/licence.txt $WD/UpdateMonitor/staging/linux/updatemonitor_license.txt || _die "Unable to copy updatemonitor_license.txt"
   chmod 444 $WD/UpdateMonitor/staging/linux/updatemonitor_license.txt || _die "Unable to change permissions for license file."
   
   Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/UpdateMonitor ];
    then
        echo "Removing existing $WD/output/symbols/linux/UpdateMonitor directory"
        rm -rf $WD/output/symbols/linux/UpdateMonitor  || _die "Couldn't remove the existing $WD/output/symbols/linux/UpdateMonitor directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/UpdateMonitor/staging/linux/symbols $WD/output/symbols/linux/UpdateMonitor || _die "Failed to move $WD/UpdateMonitor/staging/linux/symbols to $WD/output/symbols/linux/UpdateMonitor directory"

    echo "END BUILD updatemonitor Linux"
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_linux() { 
 
    echo "BEGIN POST updatmonitor Linux"

    echo "**********************************************"
    echo "* Post-processing - UpdateMonitor (linux) *"
    echo "**********************************************"

    cd $WD/UpdateMonitor
    
    pushd staging/linux
    generate_3rd_party_license "updatemonitor"
    popd
   
    mkdir -p staging/linux/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux/UpdateMonitor/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/linux/launchUpdateMonitor.sh staging/linux/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchUpdateMonitor.sh)"
    chmod ugo+x staging/linux/UpdateMonitor/scripts/launchUpdateMonitor.sh

    mkdir -p staging/linux/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/linux/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"
    
    # Set permissions to all files and folders in staging
    _set_permissions linux

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer for linux"

    cd $WD
    
    echo "END POST updatemonitor Linux"
}


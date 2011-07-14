#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_solaris_x64() {

    echo "********************************************"
    echo "* Preparing - UpdateMonitor (solaris-x64) *"
    echo "********************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e updatemonitor.solaris-x64 ];
    then
      echo "Removing existing updatemonitor.solaris-x64 source directory"
      rm -rf updatemonitor.solaris-x64  || _die "Couldn't remove the existing updatemonitor.solaris-x64 source directory (source/updatemonitor.solaris-x64)"
    fi
   
    if [ -e updatemonitor.solaris-x64.zip ];
    then
      echo "Removing existing updatemonitor.solaris-x64 zip file"
      rm -rf updatemonitor.solaris-x64.zip  || _die "Couldn't remove the existing updatemonitor.solaris-x64 zip file (source/updatemonitor.solaris-x64.zip)"
    fi
  
    if [ -e GetLatestPGInstalled.solaris-x64 ];
    then
      echo "Removing existing GetLatestPGInstalled.solaris-x64 source directory"
      rm -rf GetLatestPGInstalled.solaris-x64  || _die "Couldn't remove the existing GetLatestPGInstalled.solaris-x64 source directory (source/GetLatestPGInstalled.solaris-x64)"
    fi

    if [ -e GetLatestPGInstalled.solaris-x64.zip ];
    then
      echo "Removing existing GetLatestPGInstalled.solaris-x64 zip file"
      rm -rf GetLatestPGInstalled.solaris-x64.zip  || _die "Couldn't remove the existing GetLatestPGInstalled.solaris-x64 zip file (source/GetLatestPGInstalled.solaris-x64.zip)"
    fi
 
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.solaris-x64)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.solaris-x64 || _die "Couldn't create the updatemonitor.solaris-x64 directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.solaris-x64 || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemonitor.solaris-x64 || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"
    zip -r updatemonitor.solaris-x64.zip updatemonitor.solaris-x64 || _die "Failed to zip the updatemonitor source directory"

    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.solaris-x64
    zip -r GetLatestPGInstalled.solaris-x64.zip GetLatestPGInstalled.solaris-x64 || _die "Failed to zip the updatemonitor source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/solaris-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/solaris-x64 || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64" || _die "Failed to remove the UpdateMonitor staging directory from Soalris VM"
    fi
    
    ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/UpdateMonitor/source" || _die "Failed to remove the UpdateMonitor source directory from Soalris VM"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/UpdateMonitor/source" || _die "Failed to create the UpdateMonitor source directory on Soalris VM"
    scp updatemonitor.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/UpdateMonitor/source/ 
    scp GetLatestPGInstalled.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/UpdateMonitor/source/ 
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/UpdateMonitor/source; unzip updatemonitor.solaris-x64.zip" || _die "Failed to unzip the updatemonitor source directory on Soalris VM"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/UpdateMonitor/source; unzip GetLatestPGInstalled.solaris-x64.zip" || _die "Failed to unzip the updatemonitor source directory on Soalris VM"

    echo "Creating staging directory ($WD/UpdateMonitor/staging/solaris-x64)"
    mkdir -p $WD/UpdateMonitor/staging/solaris-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/solaris-x64 || _die "Couldn't set the permissions on the staging directory"
    
}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_solaris_x64() {

    echo "*******************************************"
    echo "* Building - UpdateMonitor (solaris-x64) *"
    echo "*******************************************"

    cd $WD/UpdateMonitor/source

    cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64" 
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_X64: || _die "Failed to scp the setenv.sh file"

    cd $WD/UpdateMonitor/source/GetLatestPGInstalled.solaris-x64
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/UpdateMonitor/source/GetLatestPGInstalled.solaris-x64;  g++ -I/usr/local/include/wx-2.8/ -I/usr/local/lib/wx/include/gtk2-unicode-release-2.8/ -L/usr/local/lib -lwx_baseud-2.8 -o GetLatestPGInstalled  GetLatestPGInstalled.cpp" || _die "Failed to build GetLatestPGInstalled"

    cd $WD/UpdateMonitor/source/UpdateMonitor.solaris-x64

    echo "Building & installing UpdateMonitor"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/UpdateMonitor/source/updatemonitor.solaris-x64; $PG_QMAKE_SOLARIS_X64 UpdateManager.pro" || _die "Failed to configure UpdateMonitor on solaris-x64"
    ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/UpdateMonitor/source/updatemonitor.solaris-x64; gmake" || _die "Failed to build UpdateManger on solaris-x64"
      
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/bin" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/lib" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/instscripts/bin" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/instscripts/lib" || _die "Failed to create the bin directory" 

    echo "Copying UpdateMonitor binary to staging directory"
    ssh $PG_SSH_SOLARIS_X64 "cp $PG_PATH_SOLARIS_X64/UpdateMonitor/source/updatemonitor.solaris-x64/UpdateMonitor $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/bin" || _die "Failed to copy the UpdateMonitor binary"
    ssh $PG_SSH_SOLARIS_X64 "cp $PG_PATH_SOLARIS_X64/UpdateMonitor/source/GetLatestPGInstalled.solaris-x64/GetLatestPGInstalled $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/instscripts/bin" || _die "Failed to copy the GetLatestPGInstallerd binary"

    echo "Copying dependent libraries to staging directory (solaris-x64)"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libwx_baseud-2.8.so.* $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/instscripts/lib" || _die "Failed to copy dependent library (libwx_baseud-2.8.so) in staging directory (solaris-x64)"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libQtXml.so.* $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (solaris-x64)"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libQtNetwork.so.* $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (solaris-x64)"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libQtCore.so.* $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (solaris-x64)"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libQtGui.so.* $PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/UpdateMonitor/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (solaris-x64)"

    scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/UpdateMonitor/staging/solaris-x64/* $WD/UpdateMonitor/staging/solaris-x64/ || _die "Failed to copy back the staging directory from Solaris VM"

    cd $WD
}


################################################################################
# Post Processing UpdateMonitor
################################################################################

_postprocess_updatemonitor_solaris_x64() {

    echo "**************************************************"
    echo "* Post-processing - UpdateMonitor (solaris-x64) *"
    echo "**************************************************"
 
    cd $WD/UpdateMonitor

    mkdir -p staging/solaris-x64/installer/UpdateMonitor || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/solaris-x64/UpdateMonitor/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/solaris/configlibs.sh staging/solaris-x64/installer/UpdateMonitor/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/configlibs.sh)"
    chmod ugo+x staging/solaris-x64/installer/UpdateMonitor/*.sh

    mkdir -p staging/solaris-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/solaris/launchUpdateMonitor.sh staging/solaris-x64/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchUpdateMonitor.sh)"
    chmod ugo+x staging/solaris-x64/scripts/launchUpdateMonitor.sh

    mkdir -p staging/solaris-x64/UpdateMonitor/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/edb-um-update-monitor.desktop staging/solaris-x64/UpdateMonitor/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    _replace @@COMPONENT_FILE@@ "component.xml" installer.xml || _die "Failed to replace the registration_plus component file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-intel || _die "Failed to build the installer for solaris-x64"
    mv $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-solaris-intel.bin  $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-solaris-x64.bin
   
    cd $WD
}


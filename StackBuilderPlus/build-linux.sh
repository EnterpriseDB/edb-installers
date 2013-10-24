#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus_linux() {

    echo "****************************************"
    echo "* Preparing - StackBuilderPlus (linux) *"
    echo "****************************************"

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    if [ -e StackBuilderPlus.linux ];
    then
      echo "Removing existing StackBuilderPlus.linux source directory"
      rm -rf StackBuilderPlus.linux  || _die "Couldn't remove the existing StackBuilderPlus.linux source directory (source/StackBuilderPlus.linux)"
    fi
   
    echo "Creating source directory ($WD/StackBuilderPlus/source/StackBuilderPlus.linux)"
    mkdir -p $WD/StackBuilderPlus/source/StackBuilderPlus.linux || _die "Couldn't create the StackBuilderPlus.linux directory"

    echo "Creating source directory ($WD/StackBuilderPlus/source/updatemanager.linux)"
    mkdir -p $WD/StackBuilderPlus/source/updatemanager.linux || _die "Couldn't create the updatemanager.linux directory"

    # Grab a copy of the source tree
    cp -R STACKBUILDER-PLUS/* StackBuilderPlus.linux || _die "Failed to copy the source code (source/STACKBUILDER-PLUS)"
    chmod -R ugo+w StackBuilderPlus.linux || _die "Couldn't set the permissions on the source directory (STACKBUILDER-PLUS)"

    cp -R SS-UPDATEMANAGER/* updatemanager.linux || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemanager.linux || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/linux)"
    mkdir -p $WD/StackBuilderPlus/staging/linux || _die "Couldn't create the staging directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux/bin || _die "Couldn't create the staging/bin directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux/lib || _die "Couldn't create the staging/lib directory"
    mkdir -p $WD/StackBuilderPlus/staging/linux/share || _die "Couldn't create the staging/share directory"
    chmod ugo+w $WD/StackBuilderPlus/staging/linux || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_linux() {

    echo "***************************************"
    echo "* Building - StackBuilderPlus (linux) *"
    echo "***************************************"

    cd $WD/StackBuilderPlus/source/StackBuilderPlus.linux

    # Configure
    echo "Configuring the StackBuilder Plus source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/StackBuilderPlus/source/StackBuilderPlus.linux/; cmake -DCMAKE_C_FLAGS_DEBUG=ON -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_PATH_LINUX/StackBuilderPlus/staging/linux ."

    # Build the app
    echo "Building & installing StackBuilderPlus"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/StackBuilderPlus/source/StackBuilderPlus.linux/; make all" || _die "Failed to build StackBuilderPlus on linux"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/StackBuilderPlus/source/StackBuilderPlus.linux/; make install" || _die "Failed to install StackBuilderPlus on linux"

    echo "Building & installing UpdateManager"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/StackBuilderPlus/source/updatemanager.linux; $PG_QMAKE_LINUX UpdateManager.pro" || _die "Failed to configuring UpdateManager on linux"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/StackBuilderPlus/source/updatemanager.linux; make" || _die "Failed to build UpdateManager on linux"

    mkdir -p $WD/StackBuilderPlus/staging/linux/UpdateManager/bin
    mkdir -p $WD/StackBuilderPlus/staging/linux/UpdateManager/lib

    echo "Copying UpdateManager binary to staging directory"
    cp $WD/StackBuilderPlus/source/updatemanager.linux/UpdateManager $WD/StackBuilderPlus/staging/linux/UpdateManager/bin

    
    echo "Copying dependent libraries to staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtXml.so.* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/UpdateManager/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtNetwork.so.* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/UpdateManager/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtCore.so.* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/UpdateManager/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp $PG_QT_LINUX/lib/libQtGui.so.* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/UpdateManager/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /usr/lib/libpng12.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libssl.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libssl.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libcrypto.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libcrypto.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libexpat.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libexpat.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libgssapi_krb5.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libgssapi_krb5.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libkrb5.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libkrb5.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libcom_err.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libcom_err.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libk5crypto.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libk5crypto.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libjpeg.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libjpeg.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libtiff.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libtiff.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libz.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libz.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libfreetype.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libfreetype.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libfontconfig.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libfontconfig.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /usr/lib/libpango-* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /usr/lib/libpangoft2* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libuuid.so.16 $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libuuid.so.16) in staging directory (linux)"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/lib/libiconv.so* $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib" || _die "Failed to copy dependent library (libiconv.so) in staging directory (linux)"

   ssh $PG_SSH_LINUX "chmod a+r $PG_PATH_LINUX/StackBuilderPlus/staging/linux/lib/*" || _die "Failed to set the read permissions on the lib directory"
   ssh $PG_SSH_LINUX "chmod a+r $PG_PATH_LINUX/StackBuilderPlus/staging/linux/UpdateManager/lib/*" || _die "Failed to set the read permissions on the lib directory"

   # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_LINUX/StackBuilderPlus/staging/linux" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/StackBuilderPlus ];
    then
        echo "Removing existing $WD/output/symbols/linux/StackBuilderPlus directory"
        rm -rf $WD/output/symbols/linux/StackBuilderPlus || _die "Couldn't remove the existing $WD/output/symbols/linux/StackBuilderPlus directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/StackBuilderPlus/staging/linux/symbols $WD/output/symbols/linux/StackBuilderPlus || _die "Failed to move $WD/StackBuilderPlus/staging/linux/symbols to $WD/output/symbols/linux/StackBuilderPlus directory"

   cd $WD
}


################################################################################
# Post Processing StackBuilderPlus
################################################################################

_postprocess_stackbuilderplus_linux() { 

    echo "**********************************************"
    echo "* Post-processing - StackBuilderPlus (linux) *"
    echo "**********************************************"

    cd $WD/StackBuilderPlus

    mkdir -p staging/linux/installer/StackBuilderPlus || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/linux/UpdateManager/scripts || _die "Failed to create a directory for the installer scripts"

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/linux -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/linux -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/linux -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/linux -name \*.sh -exec chmod 755 {} \;
    
    cp scripts/linux/createshortcuts.sh staging/linux/installer/StackBuilderPlus/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/StackBuilderPlus/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    cp scripts/linux/configlibs.sh staging/linux/installer/StackBuilderPlus/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/configlibs.sh)"
    _replace @@PLATFORM@@ "linux32" staging/linux/installer/StackBuilderPlus/configlibs.sh || _die "Failed to replace the platform placeholder value"
    chmod ugo+x staging/linux/installer/StackBuilderPlus/*.sh

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    chmod 755 staging/linux/scripts
    cp scripts/linux/launchSBPUpdateMonitor.sh staging/linux/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/linux/launchSBPUpdateMonitor.sh)"
    cp scripts/linux/launchStackBuilderPlus.sh staging/linux/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/linux/launchStackBuilderPlus.sh)"
    cp scripts/linux/runStackBuilderPlus.sh staging/linux/scripts/runStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/linux/runStackBuilderPlus.sh)"

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    chmod 755 staging/linux/installer/xdg
    cp $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    chmod 755 staging/linux/scripts/images
    cp resources/edb-stackbuilderplus.png staging/linux/scripts/images/  || _die "Failed to copy the menu pick images (edb-stackbuilderplus.png)"
    cp resources/pg-postgresql.png staging/linux/scripts/images/  || _die "Failed to copy the menu pick images (pg-postgresql.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    chmod 755 staging/linux/scripts/xdg
    mkdir -p staging/linux/UpdateManager/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    chmod 755 staging/linux/UpdateManager/scripts/xdg
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/ || _die "Failed to copy a menu pick directory"
    cp resources/xdg/edb-stackbuilderplus.desktop staging/linux/scripts/xdg/ || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/edb-sbp-update-monitor.desktop staging/linux/UpdateManager/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    # Set 644 for all files and folders
    find staging/linux/ -type f | xargs -I{} chmod 644 {}
    
    # Set Permissions for links and folders
    find staging/linux/ -xtype l | xargs -I{} chmod 777 {}
    find staging/linux/ -type d | xargs -I{} chmod 755 {}

    # " executable" requires a ' ' prefix to ensure it is not a filename
    find staging/linux/ -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find staging/linux/ -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer for linux"

    cd $WD
}


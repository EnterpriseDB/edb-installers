#!/bin/bash

################################################################################
# Build preparation UpdateMonitor
################################################################################

_prep_updatemonitor_osx() {
    
    echo "BEGIN PREP UpdateMonitor OSX"    

    echo "**************************************"
    echo "* Preparing - UpdateMonitor (osx) *"
    echo "**************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e updatemonitor.osx ];
    then
      echo "Removing existing updatemonitor.osx source directory"
      rm -rf updatemonitor.osx  || _die "Couldn't remove the existing updatemonitor.osx source directory (source/updatemonitor.osx)"
    fi

    if [ -e GetLatestPGInstalled.osx ];
    then
      echo "Removing existing GetLatestPGInstalled.osx source directory"
      rm -rf GetLatestPGInstalled.osx  || _die "Couldn't remove the existing GetLatestPGInstalled.osx source directory (source/GetLatestPGInstalled.osx)"
    fi
   
    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.osx)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.osx || _die "Couldn't create the updatemonitor.osx directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.osx || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.osx
    tar -jcvf updatemonitor.tar.bz2 updatemonitor.osx
    tar -jcvf getlatestpginstalled.tar.bz2 GetLatestPGInstalled.osx 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/UpdateMonitor/staging/osx)"
    mkdir -p $WD/UpdateMonitor/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/UpdateMonitor/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/UpdateMonitor ]; then rm -rf $PG_PATH_OSX/UpdateMonitor/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/UpdateMonitor/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/UpdateMonitor/source/updatemonitor.tar.bz2 getlatestpginstalled.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/UpdateMonitor/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/UpdateMonitor
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/UpdateMonitor/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/UpdateMonitor || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/UpdateMonitor/source; tar -jxvf updatemonitor.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/UpdateMonitor/source; tar -jxvf getlatestpginstalled.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/UpdateMonitor; tar -jxvf scripts.tar.bz2"

    echo "END PREP updatemonitor OSX"
}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_osx() {

    echo "BEGIN BUILD UpdatMonitor OSX"

    echo "*************************************"
    echo "* Building - UpdateMonitor (osx) *"
    echo "*************************************"
cat <<EOT-UPDATEMONITOR > $WD/UpdateMonitor/build-updatemonitor.sh
     
    source ../settings.sh
    source ../common.sh
     
    cd $PG_PATH_OSX/UpdateMonitor/source/GetLatestPGInstalled.osx    
    g++ -I/usr/local/lib/wx/include/mac-unicode-debug-2.8 -I/usr/local/include/wx-2.8 -arch i386 -L/usr/local/lib -lwx_base_carbonud-2.8 -o GetLatestPGInstalled GetLatestPGInstalled.cpp

    cd $PG_PATH_OSX/UpdateMonitor/source/GetLatestPGInstalled.osx    
     g++ -I/usr/local/lib/wx/include/mac-unicode-debug-2.8 -I/usr/local/include/wx-2.8 -arch i386 -L/usr/local/lib -lwx_base_carbonud-2.8 -o GetLatestPGInstalled GetLatestPGInstalled.cpp

    cd $PG_PATH_OSX/UpdateMonitor/source/updatemonitor.osx

    # Append mac specific setting in the UpdateMonitor Project
    cat <<EOT > /tmp/UpdateMonitor.pro

mac {
    QMAKE_MAC_SDK = $SDK_PATH
    CONFIG += x86_64
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.6
}

EOT
    cat /tmp/UpdateMonitor.pro >> UpdateManager.pro
    $PG_QMAKE_OSX -spec macx-g++ UpdateManager.pro
    make

    if [ ! -d UpdateManager.app ]; then
        _die "Failed building UpdateMonitor"
    fi

    mv UpdateManager.app UpdateMonitor.app || _die "Failed to rename the UpdateManager.app"    
    cd UpdateMonitor.app/Contents/MacOS || _die "Incomplete UpdateMonitor.app"

    echo "Copying dependent library QtCore"
    cp -R $PG_QTFRAMEWORK_OSX/QtCore.framework QtCore.framework
    echo "Copying dependent library QtGui"
    cp -R $PG_QTFRAMEWORK_OSX/QtGui.framework  QtGui.framework
    echo "Copying dependent library QtNetwork"
    cp -R $PG_QTFRAMEWORK_OSX/QtNetwork.framework  QtNetwork.framework
    echo "Copying dependent library QtXml"
    cp -R $PG_QTFRAMEWORK_OSX/QtXml.framework  QtXml.framework

    # Remove unnecessary files i.e. Headers & debug from the Qt
    QT_HEADERS_FILES=`find . | grep Headers`
    for f in $QT_HEADERS_FILES
    do
        rm -rf $f
    done
    QT_DEBUG_FILES=`find . | grep "_debug"`
    for f in $QT_DEBUG_FILES
    do
        rm -rf $f
    done

    #Copy our custom Info.plist
    cp $PG_PATH_OSX/UpdateMonitor/source/updatemonitor.osx/Info.plist $WD/UpdateMonitor/source/updatemonitor.osx/UpdateMonitor.app/Contents/Info.plist || _die "Failed to change the Info.plist"     

    cd $WD/UpdateMonitor/source
    echo "Copy the UpdateMonitor app bundle into place"
    cp -R $PG_PATH_OSX/UpdateMonitor/source/updatemonitor.osx/UpdateMonitor.app $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor.app || _die "Failed to copy UpdateMonitor into the staging directory"

    mkdir -p $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/bin
    mkdir -p $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/lib
    
    cp $PG_PATH_OSX/UpdateMonitor/source/GetLatestPGInstalled.osx/GetLatestPGInstalled $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/bin
    cp /usr/local/lib/libwx_base_carbonud-2.8.0.dylib $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/lib
    cp -pR /usr/local/lib/libiconv*.dylib $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/lib
    cp -pR /usr/local/lib/libz*.dylib $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts/lib

     _rewrite_so_refs $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts bin @loader_path/..
     _rewrite_so_refs $PG_PATH_OSX/UpdateMonitor/staging/osx/UpdateMonitor/instscripts lib @loader_path/..
EOT-UPDATEMONITOR
    cd $WD
    scp UpdateMonitor/build-updatemonitor.sh $PG_SSH_OSX:$PG_PATH_OSX/UpdateMonitor
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/UpdateMonitor; sh ./build-updatemonitor.sh" || _die "Failed to build UpdateMonitor on OSX"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/UpdateMonitor/staging/osx; tar -jcvf updatemonitor-staging.tar.bz2 *" || _die "Failed to create archive of the updatemonitor staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/UpdateMonitor/staging/osx/updatemonitor-staging.tar.bz2 $WD/UpdateMonitor/staging/osx || _die "Failed to scp updatemonitor staging"

    # Extract the staging archive
    cd $WD/UpdateMonitor/staging/osx
    tar -jxvf updatemonitor-staging.tar.bz2 || _die "Failed to extract the updatemonitor staging archive"
    rm -f updatemonitor-staging.tar.bz2
 
    cp $WD/UpdateMonitor/resources/licence.txt $WD/UpdateMonitor/staging/osx/updatemonitor_license.txt || _die "Unable to copy updatemonitor_license.txt"
    chmod 444 $WD/UpdateMonitor/staging/osx/updatemonitor_license.txt || _die "Unable to change permissions for license file."

    echo "END BUILD updatemonitor OSX"
}


################################################################################
# UpdateMonitor PostProcess
################################################################################

_postprocess_updatemonitor_osx() {
    
    echo "BEGIN POST UpdateMonitor OSX" 

    echo "********************************************"
    echo "* Post-processing - UpdateMonitor (osx) *"
    echo "********************************************"

    cd $WD/UpdateMonitor

    mkdir -p staging/osx/installer/UpdateMonitor || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/osx/UpdateMonitor/installer/UpdateMonitor || _die "Failed to create a directory for the install scripts"

    mkdir -p staging/osx/UpdateMonitor/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/launchUpdateMonitor.sh staging/osx/UpdateMonitor/scripts/launchUpdateMonitor.sh || _die "Failed to copy the launch script (scripts/osx/launchSBPUpdateMonitor.sh)"
    chmod ugo+x staging/osx/UpdateMonitor/scripts/*.sh
    cp scripts/osx/launchupdatemonitor.applescript.in staging/osx/UpdateMonitor/scripts/launchupdatemonitor.applescript || _die "Failed to copy the launch script (scripts/osx/launchupdatemonitor.applescript.in)"
    cp scripts/osx/startupcfg.sh staging/osx/UpdateMonitor/installer/UpdateMonitor/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/UpdateMonitor/installer/UpdateMonitor/*.sh

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/UpdateMonitor/scripts/images || _die "Failed to create a directory for the menu pick images"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/psqlODBC $WD/scripts/risePrivileges || _die "Failed to copy privileges escalation applet"
        rm -rf $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer (UpdateMonitor)"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/UpdateMonitor
    chmod a+x $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/UpdateMonitor
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ UpdateMonitor $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/installbuilder.sh
    chmod a+x $WD/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app/Contents/MacOS/installbuilder.sh

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app.tar.bz2 updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf updatemonitor*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX/versions.sh; tar -jxvf updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app; mv updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx-signed.app  updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.zip updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD
    
    echo "END POST UpdateMonitor OSX"
   
}

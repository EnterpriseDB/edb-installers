#!/bin/bash

################################################################################
# Build preparation StackBuilderPlus
################################################################################

_prep_stackbuilderplus_osx() {

    echo "**************************************"
    echo "* Preparing - StackBuilderPlus (osx) *"
    echo "**************************************"

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    if [ -e stackbuilderplus.osx ];
    then
      echo "Removing existing stackbuilderplus.osx source directory"
      rm -rf stackbuilderplus.osx  || _die "Couldn't remove the existing stackbuilderplus.osx source directory (source/stackbuilderplus.osx)"
    fi
   
    echo "Creating source directory ($WD/StackBuilderPlus/source/stackbuilderplus.osx)"
    mkdir -p $WD/StackBuilderPlus/source/stackbuilderplus.osx || _die "Couldn't create the stackbuilderplus.osx directory"
 
    echo "Creating source directory ($WD/StackBuilderPlus/source/updatemanager.osx)"
    mkdir -p $WD/StackBuilderPlus/source/updatemanager.osx || _die "Couldn't create the updatemanager.osx directory"

    # Grab a copy of the source tree
    cp -R STACKBUILDER-PLUS/* stackbuilderplus.osx || _die "Failed to copy the source code (source/STACKBUILDER-PLUS)"
    chmod -R ugo+w stackbuilderplus.osx || _die "Couldn't set the permissions on the source directory (STACKBUILDER-PLUS)"

    cp -R SS-UPDATEMANAGER/* updatemanager.osx || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemanager.osx || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/osx)"
    mkdir -p $WD/StackBuilderPlus/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/StackBuilderPlus/staging/osx || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_osx() {

    echo "*************************************"
    echo "* Building - StackBuilderPlus (osx) *"
    echo "*************************************"

    cd $WD/StackBuilderPlus/source/stackbuilderplus.osx

    cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.5 -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON .  || _die "Failed to configure StackBuilderPlus"
    make all || _die "Failed to build StackBuilderPlus"

    cd $WD/StackBuilderPlus/source/updatemanager.osx

    # Append mac specific setting in the UpdateManager Project
    cat <<EOT > /tmp/UpdateManager.pro

mac {
    QMAKE_MAC_SDK=$PG_OSX_SDK
    CONFIG+=x86 ppc
    QMAKE_MACOSX_DEPLOYMENT_TARGET=$PG_OSX_DEPLOYMENT_TARGET
}

EOT
    cat /tmp/UpdateManager.pro >> UpdateManager.pro
    qmake UpdateManager.pro
    xcodebuild -configuration Release

    if [ ! -d UpdateManager.app ]; then
        _die "Failed building UpdateManager"
    fi

    cd UpdateManager.app/Contents/MacOS

    echo "Copying dependent library QtCore"
    cp -R /Library/Frameworks/QtCore.framework QtCore.framework
    echo "Copying dependent library QtGui"
    cp -R /Library/Frameworks/QtGui.framework  QtGui.framework
    echo "Copying dependent library QtNetwork"
    cp -R /Library/Frameworks/QtNetwork.framework  QtNetwork.framework
    echo "Copying dependent library QtXml"
    cp -R /Library/Frameworks/QtXml.framework  QtXml.framework

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
    cp $WD/StackBuilderPlus/source/updatemanager.osx/Info.plist $WD/StackBuilderPlus/source/updatemanager.osx/updatemanager.app/Contents/Info.plist || _die "Failed to change the Info.plist"     

    cd $WD/StackBuilderPlus/source
    # Copy the StackBuilder app bundle into place
    echo "Copy the StackBuilderPlus app bundle into place"
    cp -R $WD/StackBuilderPlus/source/stackbuilderplus.osx/stackbuilderplus.app $WD/StackBuilderPlus/staging/osx/stackbuilderplus.app || _die "Failed to copy StackBuilderPlus into the staging directory"
    echo "Copy the UpdateManager app bundle into place"
    cp -R $WD/StackBuilderPlus/source/updatemanager.osx/UpdateManager.app $WD/StackBuilderPlus/staging/osx/UpdateManager.app || _die "Failed to copy StackBuilderPlus into the staging directory"

    cd $WD
}


################################################################################
# StackBuilderPlus PostProcess
################################################################################

_postprocess_stackbuilderplus_osx() {

    echo "********************************************"
    echo "* Post-processing - StackBuilderPlus (osx) *"
    echo "********************************************"

    cd $WD/StackBuilderPlus

    mkdir -p staging/osx/installer/StackBuilderPlus || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/osx/UpdateManager/installer/StackBuilderPlus || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/StackBuilderPlus/createshortcuts.sh || _die "Failed to copy the script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/StackBuilderPlus/createshortcuts.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    mkdir -p staging/osx/UpdateManager/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/stackbuilderplus.applescript.in staging/osx/scripts/stackbuilderplus.applescript || _die "Failed to copy the launch script (scripts/osx/stackbuilderplus.applescript.in)"
    cp scripts/osx/launchSBPUpdateMonitor.sh staging/osx/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch script (scripts/osx/launchSBPUpdateMonitor.sh)"
    cp scripts/osx/launchupdatemanager.applescript.in staging/osx/UpdateManager/scripts/launchupdatemanager.applescript || _die "Failed to copy the launch script (scripts/osx/launchupdatemanager.applescript.in)"
    cp scripts/osx/startupcfg.sh staging/osx/UpdateManager/installer/StackBuilderPlus/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    cp scripts/osx/launchStackBuilderPlus.sh staging/osx/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch script (scripts/osx/launchStackBuilderPlus.sh)"
    chmod ugo+x staging/osx/scripts/*.sh

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/edb-stackbuilderplus.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/edb-stackbuilderplus.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/psqlODBC $WD/scripts/risePrivileges || _die "Failed to copy privileges escalation applet"
        rm -rf $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer (StackBuilderPlus)"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/StackBuilderPlus
    chmod a+x $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/StackBuilderPlus
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ StackBuilderPlus $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/installbuilder.sh
    chmod a+x $WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.zip stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
}


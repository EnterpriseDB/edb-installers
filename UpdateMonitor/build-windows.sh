#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_windows() {

    echo "BEGIN PREP updatemonitor Windows"     
 
    echo "****************************************"
    echo "* Preparing - UpdateMonitor (win32) *"
    echo "****************************************"

    # Enter the source directory and cleanup if required
    cd $WD/UpdateMonitor/source

    if [ -e updatemonitor.windows ];
    then
      echo "Removing existing updatemonitor.windows source directory"
      rm -rf updatemonitor.windows  || _die "Couldn't remove the existing updatemonitor.windows source directory (source/UpdateMonitor.windows)"
    fi

    if [ -e GetLatestPGInstalled.windows ];
    then
      echo "Removing existing GetLatestPGInstalled.windows source directory"
      rm -rf GetLatestPGInstalled.windows  || _die "Couldn't remove the existing GetLatestPGInstalled.windows source directory (source/UpdateMonitor.windows)"
    fi

    echo "Creating source directory ($WD/UpdateMonitor/source/updatemonitor.windows)"
    mkdir -p $WD/UpdateMonitor/source/updatemonitor.windows || _die "Couldn't create the updatemonitor.windows directory"

    # Grab a copy of the source tree
    cp -R SS-UPDATEMANAGER/* updatemonitor.windows || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"

    cd updatemonitor.windows
    patch -p1 <$WD/../patches/convert_updatemonitor_to_qt5_3.patch
    cd $WD/UpdateMonitor/source

    chmod -R ugo+w updatemonitor.windows || _die "Couldn't set the permissions on the source directory (updatemonitor.windows)"
    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.windows

    # Copy vcxproj file with Updated path
    #cp $WD/../patches/GetLatestPGInstalled.vcproj GetLatestPGInstalled.windows

    # Remove existing archieve
    if [ -f updatemonitor.zip ];
    then
        rm -f updatemonitor.zip
    fi

    # Remove existing archieve
    if [ -f GetLatestPGInstalled.zip ];
    then
        rm -f GetLatestPGInstalled.zip
    fi

    echo "Archieving UpdateMonitor sources"
    zip -r updatemonitor.zip updatemonitor.windows || _die "Couldn't create archieve of the UpdateMonitor sources (updatemonitor.zip)"
    zip -r GetLatestPGInstalled.zip GetLatestPGInstalled.windows || _die "Couldn't create archieve of the UpdateMonitor sources (GetLatestPGInstalled.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/UpdateMonitor/staging/windows)"
    mkdir -p $WD/UpdateMonitor/staging/windows || _die "Couldn't create the staging directory"
    mkdir -p $WD/UpdateMonitor/staging/windows/share || _die "Couldn't create the staging/share directory"
    chmod ugo+w $WD/UpdateMonitor/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemonitor.zip del /Q updatemonitor.zip" || _die"Couldn't remove the $PG_PATH_WINDOWS\\UpdateMonitor.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST GetLatestPGInstalled.zip del /Q GetLatestPGInstalled.zip" || _die"Couldn't remove the $PG_PATH_WINDOWS\\UpdateMonitor.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemonitor.windows rd /S /Q updatemonitor.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\updatemonitor.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST GetLatestPGInstalled.windows rd /S /Q GetLatestPGInstalled.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\GetLatestPGInstalled.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemonitor.staging.build rd /S /Q updatemonitor.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS\\UpdateMonitor.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-um.bat del /Q build-um.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-um.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST um_output.zip del /Q um_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\um_output.zipon Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST vc-build.bat del /Q vc-build.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\vc-build.bat on Windows VM"

    echo "Copying UpdateMonitor sources to Windows VM"
    scp updatemonitor.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the UpdateMonitor archieve to Windows VM (updatemonitor.zip)"
    scp GetLatestPGInstalled.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the UpdateMonitor archieve to Windows VM (GetLatestPGInstalled.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip updatemonitor.zip" || _die "Couldn't extract UpdateMonitor archieve on Windows VM (updatemonitor.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip GetLatestPGInstalled.zip" || _die "Couldn't extract GetLatestPGInstalled archieve on Windows VM (GetLatestPGInstalled.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir -p updatemonitor.staging.build" || _die "Couldn't create updatemonitor.staging.build directory on Windows VM"
    
    echo "END PREP updatemonitor Windows"
}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_windows() {

    echo "BEGIN BUILD updatemonitor Windows"

    echo "**************************************"
    echo "* Build - UpdateMonitor (win32)   *"
    echo "**************************************"

    # build UpdateMonitor
    PG_STAGING=$PG_PATH_WINDOWS\\\\updatemonitor.staging.build

    cd $WD/UpdateMonitor/source/updatemonitor.windows

    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET INCLUDE=$PG_PGBUILD_WINDOWS\\include;%INCLUDE%
@SET LIB=$PG_PGBUILD_WINDOWS\\lib;%LIB%
@SET PGDIR=$PG_PATH_WINDOWS\\output
@SET SPHINXBUILD=C:\\Python27-x86\\Scripts\\sphinx-build.exe

IF "%2" == "UPGRADE" GOTO upgrade

msbuild %1 /p:Configuration=%2
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT
   
    scp vc-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy vc-build.bat in staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\GetLatestPGInstalled.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat GetLatestPGInstalled.vcproj UPGRADE" || _die "Error building UpdateMonitor binaries on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\GetLatestPGInstalled.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat GetLatestPGInstalled.vcxproj Release" || _die "Error building UpdateMonitor binaries on Windows VM"

    cat <<EOT > "build-um.bat"
@ECHO OFF
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

SET QT_PATH=$PG_QTPATH_WINDOWS_UM\qtbase
SET SOURCE_PATH=%CD%
SET QMAKE=%QT_PATH%\bin\qmake.exe
SET QT_MINGW_MAKE=$PG_QTPATH_WINDOWS_UM\mingw\bin\mingw32-make.exe
SET ERRMSG=No error found
SET PATH=%PATH%;%QT_PATH%\bin
SET QMAKESPEC=%QT_PATH%\mkspecs\win32-msvc2013

ECHO ***************************************
ECHO * Build and Install the UpdateMonitor *
ECHO ***************************************

cd "%SOURCE_PATH%\updatemonitor.windows"
"%QMAKE%" UpdateManager.pro || SET ERRMSG=ERROR: Couldn't configure the UpdateMonitor on Windows && GOTO EXIT_WITH_ERROR
nmake -f Makefile.Release || SET ERRMSG=ERROR: Couldn't build the UpdateManager && GOTO EXIT_WITH_ERROR
mkdir %SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\bin
mkdir %SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\instscripts\bin
copy release\UpdManager.exe %SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\bin\ || SET ERRMSG=ERROR: Couldn't copy the UpdateMonitor binary to staging directory && GOTO EXIT_WITH_ERROR
copy %SOURCE_PATH%\GetLatestPGInstalled.windows\release\GetLatestPGInstalled.exe %SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\instscripts\bin\ || SET ERRMSG=ERROR: Couldn't copy the UpdateMonitor binary to staging directory && GOTO EXIT_WITH_ERROR
copy "$PG_WXWIN_WINDOWS\lib\vc_dll\wxbase28u_vc_custom.dll" %SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\instscripts\bin\ || SET ERRMSG=ERROR: Couldn't copy dependent library (wxbase28u_vc_custom.dll) && GOTO EXIT_WITH_ERROR

ECHO *******************************************************************************************
ECHO * Collecting dependent libraries and Archieving all binaries in one file (um_output.zip) *
ECHO *******************************************************************************************
cd "%SOURCE_PATH%\updatemonitor.staging.build\UpdateMonitor\bin"
echo Copying Qt5Core dll
copy "%QT_PATH%\bin\Qt5Core.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Core.dll) && GOTO EXIT_WITH_ERROR
echo Copying Qt5Network dll
copy "%QT_PATH%\bin\Qt5Network.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Network.dll) && GOTO EXIT_WITH_ERROR
echo Copying Qt5Gui.dll
copy "%QT_PATH%\bin\Qt5Gui.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Gui.dll) && GOTO EXIT_WITH_ERROR
echo Copying Qt5Xml.dll
copy "%QT_PATH%\bin\Qt5Xml.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Xml.dll) && GOTO EXIT_WITH_ERROR
copy "%QT_PATH%\bin\Qt5Widgets.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Widgets.dll) && GOTO EXIT_WITH_ERROR
copy "%QT_PATH%\bin\libGLESv2.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (libGLESv2.dll) && GOTO EXIT_WITH_ERROR
copy "%QT_PATH%\bin\libEGL.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (libEGL.dll) && GOTO EXIT_WITH_ERROR
xcopy /f %QT_PATH%\plugins\platforms\qwindows.dll .\plugins\platforms\ /s /i || SET ERRMSG=ERROR: Couldn't copy dependent library (qwindows.dll) && GOTO EXIT_WITH_ERROR
copy "$PG_PGBUILD_WINDOWS\vcredist\vcredist_x86.exe" . || SET ERRMSG=ERROR: Couldn't copy dependent library (Qt5Xml.dll) && GOTO EXIT_WITH_ERROR

REM cd "%SOURCE_PATH%\updatemonitor.staging.build"
REM zip -r ..\um_output.zip * || SET ERRMSG=ERROR: Couldn't archieve the UpdateMonitor binaries && GOTO EXIT_WITH_ERROR

ECHO Completed Successfully.
exit 0

:EXIT_WITH_ERROR
ECHO %ERRMSG%
exit -1

EOT
#creating qt.conf file to load qt platform plugin windows
   cat <<EOT > "qt.conf"
[Paths]
Libraries=./plugins
EOT
    scp build-um.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy build-um.bat in staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-um.bat" || _die "Error building UpdateMonitor binaries on Windows VM"

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS\\\\updatemonitor.staging)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemonitor.staging rd /S /Q updatemonitor.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\updatemonitor.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y updatemonitor.staging.build\\\\* updatemonitor.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS "cmd /c echo PG_VERSION_UPDATE_MONITOR=$PG_VERSION_UPDATE_MONITOR > $PG_PATH_WINDOWS\\\\updatemonitor.staging/versions-windows.sh" || _die "Failed to write updatemonitor version number into versions-windows.sh"
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_BUILDNUM_UPDATE_MONITOR=$PG_BUILDNUM_UPDATE_MONITOR >> $PG_PATH_WINDOWS\\\\updatemonitor.staging/versions-windows.sh" || _die "Failed to write updatemonitor build number into versions-windows.sh"

    echo "END BUILD updtemonitor Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_updatemonitor_windows() {
    
    echo "BEGIN POST updatemonitor Windows"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/UpdateMonitor/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/UpdateMonitor/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/UpdateMonitor/staging/windows)"
    mkdir -p $WD/UpdateMonitor/staging/windows || _die "Couldn't create the staging directory"
    mkdir -p $WD/UpdateMonitor/staging/windows/share || _die "Couldn't create the staging/share directory"
    chmod ugo+w $WD/UpdateMonitor/staging/windows || _die "Couldn't set the permissions on the staging directory"

    _registration_plus_postprocess "$WD/UpdateMonitor/staging"  "UpdateMonitor" "iUMVersion" "/etc/postgres-reg.ini" "UpdateMonitor" "UpdateMonitor" "UpdateMonitor" "$PG_VERSION_UPDATE_MONITOR"

    cd $WD/UpdateMonitor/staging/windows
    echo "Copying built tree to Windows host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST um_output.zip del /S /Q um_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\um_output.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\updatemonitor.staging; cmd /c zip -r um_output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$OUTPUT_DIR)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\updatemonitor.staging\\\\um_output.zip $WD/UpdateMonitor/staging/windows/um_output.zip || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\um_output.zip)"
    unzip -o $WD/UpdateMonitor/staging/windows/um_output.zip -d $WD/UpdateMonitor/staging/windows || _die "Failed to unpack the built source tree ($WD/UpdateMonitor/staging/windows/um_output.zip)"
    rm -f $WD/UpdateMonitor/staging/windows/um_output.zip

##    # Remove output archieve, if exists
##    if [ -f um_output.zip ];
##    then
##        rm -f um_output.zip
##    fi
##
##    cd $WD/UpdateMonitor/staging/windows
##    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/um_output.zip .
##
##    unzip um_output.zip
##    rm -f um_output.zip

    dos2unix $WD/UpdateMonitor/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/UpdateMonitor/staging/windows/versions-windows.sh
    PG_BUILD_UPDATE_MONITOR=$(expr $PG_BUILD_UPDATE_MONITOR + $SKIPBUILD)

    cp $WD/UpdateMonitor/source/updatemonitor.windows/qt.conf $WD/UpdateMonitor/staging/windows/UpdateMonitor/bin

    win32_sign "UpdManager.exe" "$WD/UpdateMonitor/staging/windows/UpdateMonitor/bin"

    cp $WD/UpdateMonitor/resources/licence.txt $WD/UpdateMonitor/staging/windows/updatemonitor_license.txt || _die "Unable to copy updatemonitor_license.txt"
    chmod 444 $WD/UpdateMonitor/staging/windows/updatemonitor_license.txt || _die "Unable to change permissions for license file."
    cd $WD/UpdateMonitor

    pushd staging/windows
    generate_3rd_party_license "updatemonitor"
    popd

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/launchUpdateMonitor.vbs staging/windows/scripts/launchUpdateMonitor.vbs || _die "Failed to copy the start-up script (launchUpdateMonitor.vbs)"

    if [ -f installer-win.xml ];    
    then
        rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml
    _replace "registration_plus_component" "registration_plus_component_windows" installer-win.xml || _die "Failed to replace the registration_plus component file name"
    _replace "registration_plus_preinstallation" "registration_plus_preinstallation_windows" installer-win.xml || _die "Failed to replace the registration_plus preinstallation file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_UPDATE_MONITOR -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-windows.exe $WD/output/edb-updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-${BUILD_FAILED}windows.exe

    # Sign the installer
    win32_sign "edb-updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-${BUILD_FAILED}windows.exe"

    cd $WD
    
    echo "END POST updatemonitor Windows"
}


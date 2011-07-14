#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_updatemonitor_windows() {

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
    chmod -R ugo+w updatemonitor.windows || _die "Couldn't set the permissions on the source directory (updatemonitor.windows)"
    cp -R $WD/UpdateMonitor/resources/GetLatestPGInstalled GetLatestPGInstalled.windows

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
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemonitor.staging rd /S /Q updatemonitor.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\UpdateMonitor.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-um.bat del /Q build-um.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-um.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST um_output.zip del /Q um_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\um_output.zipon Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST vc-build.bat del /Q vc-build.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\vc-build.bat on Windows VM"

    echo "Copying UpdateMonitor sources to Windows VM"
    scp updatemonitor.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the UpdateMonitor archieve to Windows VM (updatemonitor.zip)"
    scp GetLatestPGInstalled.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the UpdateMonitor archieve to Windows VM (GetLatestPGInstalled.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip updatemonitor.zip" || _die "Couldn't extract UpdateMonitor archieve on Windows VM (updatemonitor.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip GetLatestPGInstalled.zip" || _die "Couldn't extract GetLatestPGInstalled archieve on Windows VM (GetLatestPGInstalled.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir -p updatemonitor.staging" || _die "Couldn't create updatemonitor.staging directory on Windows VM"

}

################################################################################
# UpdateMonitor Build
################################################################################

_build_updatemonitor_windows() {

    echo "**************************************"
    echo "* Build - UpdateMonitor (win32)   *"
    echo "**************************************"

    # build UpdateMonitor
    PG_STAGING=$PG_PATH_WINDOWS\\\\updatemonitor.staging

    cd $WD/UpdateMonitor/source/updatemonitor.windows
    
    cat <<EOT > "vc-build.bat"

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET PGDIR=$PG_PATH_WINDOWS\output

vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT
    scp vc-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy vc-build.bat in staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\GetLatestPGInstalled.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat GetLatestPGInstalled.vcproj RELEASE" || _die "Error building UpdateMonitor binaries on Windows VM"

    cat <<EOT > "build-um.bat"
@ECHO OFF

SET QT_PATH=$PG_QTPATH_WINDOWS
SET SOURCE_PATH=%CD%
SET QMAKE=%QT_PATH%\qt\bin\qmake.exe
SET QT_MINGW_MAKE=%QT_PATH%\mingw\bin\mingw32-make.exe
SET ERRMSG=No error found!

ECHO ***************************************
ECHO * Build and Install the UpdateMonitor *
ECHO ***************************************

cd "%SOURCE_PATH%\updatemonitor.windows"
"%QMAKE%" UpdateManager.pro || SET ERRMSG=ERROR: Couldn't configure the UpdateMonitor on Windows && GOTO EXIT_WITH_ERROR
"%QT_MINGW_MAKE%" release || SET ERRMSG=ERROR: Couldn't build the UpdateMonitor && GOTO EXIT_WITH_ERROR
mkdir %SOURCE_PATH%\updatemonitor.staging\UpdateMonitor\bin 
mkdir %SOURCE_PATH%\updatemonitor.staging\UpdateMonitor\instscripts\bin 
copy release\UpdManager.exe %SOURCE_PATH%\updatemonitor.staging\UpdateMonitor\bin\ || SET ERRMSG=ERROR: Couldn't copy the UpdateMonitor binary to staging directory && GOTO EXIT_WITH_ERROR
copy %SOURCE_PATH%\GetLatestPGInstalled.windows\release\GetLatestPGInstalled.exe %SOURCE_PATH%\updatemonitor.staging\UpdateMonitor\instscripts\bin\ || SET ERRMSG=ERROR: Couldn't copy the UpdateMonitor binary to staging directory && GOTO EXIT_WITH_ERROR

ECHO *******************************************************************************************
ECHO * Collecting dependent libraries and Archieving all binaries in one file (um_output.zip) *
ECHO *******************************************************************************************
cd "%SOURCE_PATH%\updatemonitor.staging\UpdateMonitor\bin"
copy "%QT_PATH%\qt\bin\mingwm10.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (mingwm10.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtCore4 dll
copy "%QT_PATH%\qt\bin\QtCore4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtCore4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtNetwork4 dll
copy "%QT_PATH%\qt\bin\QtNetwork4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtNetwork4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtGui4.dll
copy "%QT_PATH%\qt\bin\QtGui4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtGui4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtXml4.dll
copy "%QT_PATH%\qt\bin\QtXml4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtXml4.dll) && GOTO EXIT_WITH_ERROR

cd "%SOURCE_PATH%\updatemonitor.staging"
zip -r ..\um_output.zip * || SET ERRMSG=ERROR: Couldn't archieve the UpdateMonitor binaries && GOTO EXIT_WITH_ERROR

ECHO Completed Successfully.
exit 0

:EXIT_WITH_ERROR
ECHO %ERRMSG%
exit -1

EOT
    scp build-um.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy build-um.bat in staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-um.bat" || _die "Error building UpdateMonitor binaries on Windows VM"

    # Remove output archieve, if exists
    if [ -f um_output.zip ];
    then
        rm -f um_output.zip
    fi

    cd $WD/UpdateMonitor/staging/windows
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/um_output.zip .

    unzip um_output.zip
    rm -f um_output.zip

     #win32_sign "updatemonitor.exe" "$WD/UpdateMonitor/staging/windows/bin"

}


################################################################################
# PG Build
################################################################################

_postprocess_updatemonitor_windows() {
 
    cd $WD/UpdateMonitor

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/launchUpdateMonitor.vbs staging/windows/scripts/launchUpdateMonitor.vbs || _die "Failed to copy the start-up script (launchUpdateMonitor.vbs)"

    if [ -f installer-win.xml ];    
    then
        rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml
    _replace "registration_plus_component" "registration_plus_component_processed" installer-win.xml || _die "Failed to replace the registration_plus compon
ent file name"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "updatemonitor-$PG_VERSION_UPDATE_MONITOR-$PG_BUILDNUM_UPDATE_MONITOR-windows.exe"
	
    cd $WD
}


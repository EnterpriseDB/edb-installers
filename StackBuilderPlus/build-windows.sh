#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus_windows() {

    echo "****************************************"
    echo "* Preparing - StackBuilderPlus (win32) *"
    echo "****************************************"

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    if [ -e stackbuilderplus.windows ];
    then
      echo "Removing existing stackbuilderplus.windows source directory"
      rm -rf stackbuilderplus.windows  || _die "Couldn't remove the existing stackbuilderplus.windows source directory (source/StackBuilderPlus.windows)"
    fi

    echo "Creating source directory ($WD/StackBuilderPlus/source/stackbuilderplus.windows)"
    mkdir -p $WD/StackBuilderPlus/source/stackbuilderplus.windows || _die "Couldn't create the stackbuilderplus.windows directory"
    echo "Creating source directory ($WD/StackBuilderPlus/source/updatemanager.windows)"
    mkdir -p $WD/StackBuilderPlus/source/updatemanager.windows || _die "Couldn't create the updatemanager.windows directory"

    # Grab a copy of the source tree
    cp -R STACKBUILDER-PLUS/* stackbuilderplus.windows || _die "Failed to copy the source code (source/STACKBUILDER-PLUS)"
    chmod -R ugo+w stackbuilderplus.windows || _die "Couldn't set the permissions on the source directory (stackbuilderplus.windows)"

    cp -R SS-UPDATEMANAGER/* updatemanager.windows || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemanager.windows || _die "Couldn't set the permissions on the source directory (updatemanager.windows)"

    # Remove existing archieve
    if [ -f stackbuilderplus.zip ];
    then
        rm -f stackbuilderplus.zip
    fi

    echo "Archieving StackBuilderPlus sources"
    zip -r stackbuilderplus.zip stackbuilderplus.windows updatemanager.windows || _die "Couldn't create archieve of the StackBuilderPlus sources (stackbuilder.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/windows)"
    mkdir -p $WD/StackBuilderPlus/staging/windows || _die "Couldn't create the staging directory"
    mkdir -p $WD/StackBuilderPlus/staging/windows/share || _die "Couldn't create the staging/share directory"
    chmod ugo+w $WD/StackBuilderPlus/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST stackbuilderplus.zip del /Q stackbuilderplus.zip" || _die"Couldn't remove the $PG_PATH_WINDOWS\\StackBuilderPlus.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST stackbuilderplus.windows rd /S /Q stackbuilderplus.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\stackbuilderplus.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST updatemanager.windows rd /S /Q updatemanager.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\StackBuilderPlus.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST stackbuilderplus.staging rd /S /Q stackbuilderplus.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\StackBuilderPlus.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-sbp.bat del /Q build-sbp.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-sbp.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST sbp_output.zip del /Q sbp_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\sbp_output.zipon Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST vc-build.bat del /Q vc-build.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\vc-build.bat on Windows VM"

    echo "Copying StackBuilderPlus sources to Windows VM"
    scp stackbuilderplus.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the StackBuilderPlus archieve to Windows VM (stackbuilderplus.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip stackbuilderplus.zip" || _die "Couldn't extract StackBuilderPlus archieve on Windows VM (stackbuilderplus.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir -p stackbuilderplus.staging" || _die "Couldn't create stackbuilderplus.staging directory on Windows VM"

}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_windows() {

    echo "**************************************"
    echo "* Build - StackBuilderPlus (win32)   *"
    echo "**************************************"

    # build StackBuilderPlus
    PG_STAGING=$PG_PATH_WINDOWS\\\\stackbuilder.staging

    cd $WD/StackBuilderPlus/source/stackbuilderplus.windows
    
    cat <<EOT > "vc-build.bat"

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET PGDIR=$PG_PATH_WINDOWS\output

vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT
    scp vc-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy vc-build.bat in staging directory on Windows VM"

    cat <<EOT > "build-sbp.bat"
@ECHO OFF

SET QT_PATH=$PG_QTPATH_WINDOWS
SET SOURCE_PATH=%CD%
SET QMAKE=%QT_PATH%\qt\bin\qmake.exe
SET QT_MINGW_MAKE=%QT_PATH%\mingw\bin\mingw32-make.exe
SET ERRMSG=No error found!
SET PATH=%PATH%;$PG_MINGW_WINDOWS;$PG_MINGW_WINDOWS\bin;$PG_MINGW_WINDOWS\libexec\gcc\mingw32\3.4.5

ECHO ******************************************
ECHO * Build and Install the StackBuilderPlus *
ECHO ******************************************

cd "%SOURCE_PATH%\stackbuilderplus.windows"

cmake.exe -D WX_ROOT_DIR=C:\pgBuild\wxWidgets -D MSGFMT_EXECUTABLE=C:\pgBuild\gettext\bin\msgfmt -D CMAKE_INSTALL_PREFIX="%SOURCE_PATH%\stackbuilderplus.staging" . || SET ERRMSG=ERROR: Couldn't configure StackBuilderPlus on Windows && GOTO EXIT_WITH_ERROR

CALL "%SOURCE_PATH%\vc-build.bat" stackbuilderplus.vcproj RELEASE || SET ERRMSG=ERROR: Couldn't build StackBuilderPlus on Windows && GOTO EXIT_WITH_ERROR
CALL "%SOURCE_PATH%\vc-build.bat" INSTALL.vcproj RELEASE || SET ERRMSG=ERROR:Couldn't install StackBuilderPlus to staging directory && GOTO EXIT_WITH_ERROR

ECHO ***************************************
ECHO * Build and Install the UpdateManager *
ECHO ***************************************

cd "%SOURCE_PATH%\updatemanager.windows"
"%QMAKE%" UpdateManager.pro || SET ERRMSG=ERROR: Couldn't configure the UpdateManager on Windows && GOTO EXIT_WITH_ERROR
"%QT_MINGW_MAKE%" release || SET ERRMSG=ERROR: Couldn't build the UpdateManager && GOTO EXIT_WITH_ERROR
mkdir %SOURCE_PATH%\stackbuilderplus.staging\UpdateManager\bin 
copy release\UpdManager.exe %SOURCE_PATH%\stackbuilderplus.staging\UpdateManager\bin\ || SET ERRMSG=ERROR: Couldn't copy the UpdateManager binary to staging directory && GOTO EXIT_WITH_ERROR

ECHO *******************************************************************************************
ECHO * Collecting dependent libraries and Archieving all binaries in one file (sbp_output.zip) *
ECHO *******************************************************************************************
cd "%SOURCE_PATH%\stackbuilderplus.staging\UpdateManager\bin"
copy "%QT_PATH%\qt\bin\mingwm10.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (mingwm10.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtCore4 dll
copy "%QT_PATH%\qt\bin\QtCore4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtCore4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtNetwork4 dll
copy "%QT_PATH%\qt\bin\QtNetwork4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtNetwork4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtGui4.dll
copy "%QT_PATH%\qt\bin\QtGui4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtGui4.dll) && GOTO EXIT_WITH_ERROR
echo Copying QtXml4.dll
copy "%QT_PATH%\qt\bin\QtXml4.dll" . || SET ERRMSG=ERROR: Couldn't copy dependent library (QtXml4.dll) && GOTO EXIT_WITH_ERROR

cd "%SOURCE_PATH%\stackbuilderplus.staging"
zip -r ..\sbp_output.zip * || SET ERRMSG=ERROR: Couldn't archieve the StackBuilderPlus binaries && GOTO EXIT_WITH_ERROR

ECHO Completed Successfully.
exit 0

:EXIT_WITH_ERROR
ECHO %ERRMSG%
exit -1

EOT
    scp build-sbp.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy build-sbp.bat in staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-sbp.bat" || _die "Error building StackBuilderPlus binaries on Windows VM"

    # Remove output archieve, if exists
    if [ -f sbp_output.zip ];
    then
        rm -f sbp_output.zip
    fi

    cd $WD/StackBuilderPlus/staging/windows
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/sbp_output.zip .

    unzip sbp_output.zip
    rm -f sbp_output.zip

    win32_sign "stackbuilderplus.exe" "$WD/StackBuilderPlus/staging/windows/bin"

}


################################################################################
# PG Build
################################################################################

_postprocess_stackbuilderplus_windows() {
 
    cd $WD/StackBuilderPlus

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/launchSBPUpdateMonitor.vbs staging/windows/scripts/launchSBPUpdateMonitor.vbs || _die "Failed to copy the start-up script (launchSBPUpdateMonitor.vbs)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-windows.exe"
	
    cd $WD
}


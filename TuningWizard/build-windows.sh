#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_TuningWizard_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/TuningWizard/source
    
    if [ -e $WD/TuningWizard/source/tuningwizard.windows ];
    then
        echo "Removing existing tuningwizard.windows source directory"
        rm -rf $WD/TuningWizard/source/tuningwizard.windows || _die "Couldn't remove the existing tuningwizard.windows source directory (source/tuningwizard.windows)"
    fi
    
    # Remove any existing zip files
    if [ -f $WD/TuningWizard/source/TuningWizard.zip ];
    then
        echo "Removing existing source archive"
        rm -rf $WD/TuningWizard/source/TuningWizard.zip || _die "Couldn't remove the existing source archive"
    fi
    
    # Cleanup the build host
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF EXIST \"tuningwizard.windows\" rd /S /Q tuningwizard.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF EXIST \"build-tuningwizard.bat\" del /q build-tuningwizard.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF EXIST \"tuningwizard.zip\" del /q tuningwizard.zip" 
    
    # Cleanup local files
    if [ -f $WD/TuningWizard/source/build-tuningwizard.bat ];
    then
        echo "Removing existing build-tuningwizard.bat script"
        rm -rf $WD/TuningWizard/source/build-tuningwizard.bat || _die "Couldn't remove the existing build-tuningwizard.bat script"
    fi
    
    # Grab a copy of the source tree
    cp -R $WD/TuningWizard/source/wizard $WD/TuningWizard/source/tuningwizard.windows || _die "Failed to copy the source code (source/tuningwizard.windows)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/TuningWizard/staging/windows ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/TuningWizard/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/TuningWiard/staging/windows)"
    mkdir -p $WD/TuningWizard/staging/windows || _die "Couldn't create the staging directory"

    if [ -f $WD/TuningWizards/scripts/windows/vc-build.bat ];
    then
       echo "Removing existing vc-build.bat script"
       rm -f $WD/TuningWizards/scripts/windows/vc-build.bat || _die "Couldn't remove the vc-build.bat script"
    fi

}

################################################################################
# EDB Build
################################################################################

_build_TuningWizard_windows() {
    
    # Create a build script for VC++
    cd $WD/TuningWizard/source
    
    cat <<EOT > "build-tuningwizard.bat"

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=%PGBUILD%\wxWidgets

cd "$PG_PATH_WINDOWS"
SET SOURCE_PATH=%CD%

REM Extracting TuningWizard sources
if NOT EXIST "tuningwizard.zip" GOTO zip-not-found
unzip tuningwizard.zip

cd tuningwizard.windows
REM Configure TuningWizard
cmake -D WX_LIB_DIR=%WXWIN%\lib\vc_lib -D wxWidgets_CONFIGURATION=mswu CMakeLists.txt

REM Compiling TuningWizard
devenv TuningWizard.vcproj /build release

GOTO end

:zip-not-found
    echo "tuningwizard.zip not found

:end
    cd $PG_PATH_WINDOWS
EOT

    # Copy the scripts to the build host
    echo "Copying build-tuningwizard.bat to Windows build VM"
    scp build-tuningwizard.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the build-tuningwizard.bat to the windows build host (build-tuningwizard.bat)"

    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/TuningWizard/source/
    echo "Copying source tree to Windows build VM"
    zip -r tuningwizard.zip tuningwizard.windows || _die "Failed to pack the source tree (tuningwizard.windows)"
    scp tuningwizard.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (tuningwizard.zip)"
   
    # Build the code
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c $PG_PATH_WINDOWS\\\\build-tuningwizard.bat" || _die "Failed to build tuningwizard on the build host"

    mkdir -p $WD/TuningWizard/staging/windows/TuningWizard || _die "Failed to create the TuningWizard under the staging directory"
    
    # Copy the application files into place
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\tuningwizard.windows\\\\release\\\\TuningWizard.exe $WD/TuningWizard/staging/windows/TuningWizard/TuningWizard.exe
    scp $PG_SSH_WINDOWS:C:/pgBuild/vcredist/vcredist_x86.exe $WD/TuningWizard/staging/windows/ || _die "Failed to copy the VC++ runtimes from the windows build host"

    cd $WD
}


################################################################################
# Post Process Build
################################################################################

_postprocess_TuningWizard_windows() {

    cd $WD/TuningWizard
 
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    
    # Sign the installer
    win32_sign "tuningwizard-$PG_VERSION_TUNINGWIZARD-$PG_BUILDNUM_TUNINGWIZARD-windows.exe"
	
    cd $WD
}


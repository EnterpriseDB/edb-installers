#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_windows() {

    echo "BEGIN PREP Npgsql Windows"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.windows ];
    then
      echo "Removing existing Npgsql.windows source directory"
      rm -rf Npgsql.windows  || _die "Couldn't remove the existing Npgsql.windows source directory (source/Npgsql.windows)"
    fi
   
    if [ -e Npgsql.zip ];
    then
      echo "Removing existing Npgsql.zip file"
      rm -rf Npgsql.zip || _die "Couldn't remove the existing Npgsql.zip file (source/Npgsql.zip)"
    fi

    echo "Creating Npgsql source directory ($WD/Npgsql/source/Npgsql.windows)"
    mkdir -p Npgsql.windows || _die "Couldn't create the Npgsql.windows directory"
    chmod ugo+w Npgsql.windows || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the Npgsql source tree
    cp -R npgsql-$PG_VERSION_NPGSQL/* Npgsql.windows || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"

    cd $WD/Npgsql/source

    echo "Archieving Npgsql sources"
    zip -r Npgsql.zip Npgsql.windows/ || _die "Couldn't create archieve of the Npgsql sources (Npgsql.zip)"
    chmod -R ugo+w Npgsql.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/windows)"
    mkdir -p $WD/Npgsql/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.zip del /S /Q Npgsql.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.windows rd /S /Q Npgsql.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.staging rd /S /Q Npgsql.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST npgsql-staging.zip del /S /Q npgsql-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\npgsql-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-Npgsql.bat del /S /Q build-Npgsql.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-Npgsql.bat on Windows VM"

    echo "Copying Npgsql sources to Windows VM"
    scp Npgsql.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the Npgsql archieve to windows VM (Npgsql.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip Npgsql.zip" || _die "Couldn't extract Npgsql archieve on windows VM (Npgsql.zip)"

 
    echo "END PREP Npgsql Windows"
}

################################################################################
# PG Build
################################################################################

_build_Npgsql_windows() {

    echo "BEGIN BUILD Npgsql Windows"

    cd $WD/Npgsql/source

    cat <<EOT > "build-Npgsql.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

REM batch file splits single argument containing "=" sign into two
REM Following code handles this scenario

cd Npgsql.windows
CALL "$PG_NUGET_WINDOWS\nuget.exe" restore Npgsql.sln

IF "%~3" == "" ( SET VAR3=""
) ELSE (
SET VAR3="%3=%4"
)
msbuild %1 /p:Configuration=%2 %VAR3%
GOTO end

:end

EOT
    scp build-Npgsql.bat  $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the script to the windows build host (build-Npgsql.bat)"

    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c $PG_PATH_WINDOWS\\\\build-Npgsql.bat Npgsql.sln Release $PLATFORM_TOOLSET" || _die "Failed to build npgsql on the windows build host"

    # We need to copy them to staging directory
    ssh $PG_SSH_WINDOWS  "mkdir -p $PG_PATH_WINDOWS/Npgsql.staging/bin" || _die "Failed to create the bin directory"
    ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Npgsql.windows/src/Npgsql/bin/Release/* $PG_PATH_WINDOWS/Npgsql.staging/bin" || _die "Failed to copy Npgsql binary to staging directory"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying npgsql built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\Npgsql.staging; cmd /c zip -r ..\\\\npgsql-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/Npgsql.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip $WD/Npgsql/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip)"
    unzip $WD/Npgsql/staging/windows/npgsql-staging.zip -d $WD/Npgsql/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/npgsql-staging.zip)"
    rm $WD/Npgsql/staging/windows/npgsql-staging.zip

    cp $WD/Npgsql/source/Npgsql.windows/LICENSE.txt $WD/Npgsql/staging/windows/ || _die "Unable to copy LICENSE.txt"

    cd $WD
    
    echo "END BUILD Npgsql Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_windows() {

    echo "BEGIN POST Npgsql Windows"
 
    cd $WD/Npgsql
    
    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe"

    cd $WD

    echo "END POST Npgsql Windows"
}


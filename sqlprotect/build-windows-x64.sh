#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_windows_x64() {
    
    echo "BEGIN PREP sqlprotect Windows-x64"

    cd $WD/server/source

    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.windows-x64/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.windows-x64/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi

    # create a copy of the sqlprotect tree
    cd postgres.windows-x64/contrib
    git clone git@github.com:EnterpriseDB/edb-sql-protect.git SQLPROTECT

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/windows-x64)"
    mkdir -p $WD/sqlprotect/staging/windows-x64/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    echo "Archiving sqlprotect sources"
    cd $WD/server/source
    if [ -e sqlprotect.zip ];
    then
      echo "Removing existing source archive"
      rm sqlprotect.zip || _die "Couldn't remove sqlprotect.zip"
    fi
    zip sqlprotect.zip postgres.windows-x64/contrib/SQLPROTECT/* || _die "Couldn't create archive of the sqlprotect sources (sqlprotect.zip)"

    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST sqlprotect.zip del /S /Q sqlprotect.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\sqlprotect.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST sqlprotect.staging.build rd /S /Q sqlprotect.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\sqlprotect.staging.build directory on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST sqlprotect-staging.zip del /S /Q sqlprotect-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\sqlprotect-staging.zip on Windows VM"

    # Removing sqlprotect if it already exists
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/contrib; cmd /c if EXIST SQLPROTECT del /S /Q SQLPROTECT" || _die "Couldn't remove sqlprotect on windows VM (sqlprotect)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/release; cmd /c if EXIST sqlprotect del /S /Q sqlprotect" || _die "Couldn't remove sqlprotect on windows VM (sqlprotect)"

    # Copy sources on windows VM
    echo "Copying sqlprotect sources to Windows VM"
    scp sqlprotect.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Couldn't copy the sqlprotect archive to windows VM (sqlprotect.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c  unzip sqlprotect.zip" || _die "Couldn't extract postgresql archieve on windows VM (sqlprotect.zip)"
    chmod -R ugo+r $WD/sqlprotect/staging/windows-x64
    
    echo "END PREP sqlprotect Windows-x64"
}

################################################################################
# PG Build
################################################################################

_build_sqlprotect_windows_x64() {
    
    echo "BEGIN BUILD sqlprotect Windows-x64"    

    cat <<EOT > "$WD/server/source/build64-sqlprotect.bat"

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64

@SET PATH=%PATH%;$PG_PERL_WINDOWS_X64\bin

build.bat sqlprotect Release

EOT

    scp $WD/server/source/build64-sqlprotect.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc || _die "Failed to copy the build32.bat"
 
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc; ./build64-sqlprotect.bat" || _die "could not build sqlprotect on windows vm"

   # We need to copy shared objects to staging directory
   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/lib/postgresql" || _die "Failed to create the lib directory"
   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/share" || _die "Failed to create the share directory"
   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/doc" || _die "Failed to create the doc directory"
   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/debug_symbols" || _die "Failed to create the debug symbols directory"

   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/postgres.windows-x64/release/sqlprotect/sqlprotect.dll $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/lib/postgresql" || _die "Failed to copy sqlprotect.dll to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/postgres.windows-x64/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/share" || _die "Failed to copy sqlprotect.sql to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/postgres.windows-x64/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/doc" || _die "Failed to copy README-sqlprotect.txt to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/postgres.windows-x64/Release/sqlprotect/*.pdb $PG_PATH_WINDOWS_X64/sqlprotect.staging.build/debug_symbols" || _die "Failed to copy debug symbols to staging directory"

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS_X64\\\\sqlprotect.staging)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST sqlprotect.staging rd /S /Q sqlprotect.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\sqlprotect.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c xcopy /E /Q /Y sqlprotect.staging.build\\\\* sqlprotect.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_VERSION_SQLPROTECT=$PG_VERSION_SQLPROTECT > $PG_PATH_WINDOWS_X64\\\\sqlprotect.staging/versions-windows-x64.sh" || _die "Failed to write sqlprotect version number into versions-windows-x64.sh"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_BUILDNUM_SQLPROTECT=$PG_BUILDNUM_SQLPROTECT >> $PG_PATH_WINDOWS_X64\\\\sqlprotect.staging/versions-windows-x64.sh" || _die "Failed to write sqlprotect build number into versions-windows-x64.sh"

   # Remove the existing sqlprotect directory in server
   if [ -e postgres.windows-x64/contrib/SQLPROTECT ];
   then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.windows-x64/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
   fi
   
   echo "END BUILD sqlprotect Windows-x64"
}



################################################################################
# PG Build
################################################################################

_postprocess_sqlprotect_windows_x64() {
    
    echo "BEGIN POST sqlprotect Windows-x64" 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/sqlprotect/staging/windows-x64)"
    mkdir -p $WD/sqlprotect/staging/windows-x64/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying sqlprotect build tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST sqlprotect-staging.zip del /S /Q sqlprotect-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\sqlprotect-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\sqlprotect.staging; zip -r ..\\\\sqlprotect-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/sqlprotect.staging)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/sqlprotect-staging.zip $WD/sqlprotect/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/sqlprotect-staging.zip)"
    unzip $WD/sqlprotect/staging/windows-x64/sqlprotect-staging.zip -d $WD/sqlprotect/staging/windows-x64 || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/sqlprotect-staging.zip)"
    rm $WD/sqlprotect/staging/windows-x64/sqlprotect-staging.zip

    dos2unix $WD/sqlprotect/staging/windows-x64/versions-windows-x64.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/sqlprotect/staging/windows-x64/versions-windows-x64.sh
    PG_BUILD_SQLPROTECT=$(expr $PG_BUILD_SQLPROTECT + $SKIPBUILD)

    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/windows-x64/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/windows-x64/sqlprotect_license.txt || _die "Unable to change permissions for license file"

    # Copy the debug symbols from staging directory to output directory.
    mkdir -p $WD/output/symbols/windows-x64/sqlprotect
    cp -r $WD/sqlprotect/staging/windows-x64/debug_symbols/* $WD/output/symbols/windows-x64/sqlprotect

    cd $WD/sqlprotect

    if [ -f installer-win-x64.xml ]; then
        rm -f installer-win-x64.xml
    fi
    cp installer.xml installer-win-x64.xml

    _replace @@WIN64MODE@@ "1" installer-win-x64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ "windows-x64" installer-win-x64.xml || _die "Failed to replace the WINDIR setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win-x64.xml windows || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SQLPROTECT -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-windows-x64.exe $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}windows-x64.exe

    # Sign the installer
    win32_sign "edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}windows-x64.exe"

    cd $WD

    echo "END POST sqlprotect Windows-x64"
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_windows_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.windows-x64 ];
    then
      echo "Removing existing psqlODBC.windows-x64 source directory"
      rm -rf psqlODBC.windows-x64  || _die "Couldn't remove the existing psqlODBC.windows-x64 source directory (source/psqlODBC.windows-x64)"
    fi
    if [ -e psqlODBC.zip ];
    then
      echo "Removing existing psqlODBC.zip source file"
      rm -f psqlODBC.zip  || _die "Couldn't remove the existing psqlODBC.zip source file (source/psqlODBC.zip)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.windows-x64)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.windows-x64 || _die "Couldn't create the psqlODBC.windows-x64 directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.windows-x64 || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"
    cd psqlODBC.windows-x64
    #patch -p1 < $WD/tarballs/psqlodbc-win64.patch
    cd ..

    echo "Archieving psqlODBC sources"
    zip -r psqlODBC.zip psqlODBC.windows-x64/ || _die "Couldn't create archieve of the psqlODBC sources (psqlODBC.zip)"

    chmod -R ugo+w psqlODBC.windows-x64 || _die "Couldn't set the permissions on the source directory"

    if [ -e $WD/psqlODBC/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/windows-x64)"
    mkdir -p $WD/psqlODBC/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    # Remove any existing staging directory that might exist, and create a clean one
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC.zip del /S /Q psqlODBC.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST build-psqlODBC.bat del /S /Q build-psqlODBC.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\build-psqlODBC.bat on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC.windows-x64 rd /S /Q psqlODBC.windows-x64" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC.windows-x64 directory on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC.staging.build rd /S /Q psqlODBC.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC.staging.build directory on Windows VM"

    # Copy sources on windows-x64 VM
    echo "Copying psqlODBC sources to Windows VM"
    scp psqlODBC.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Couldn't copy the psqlODBC archieve to windows-x64 VM (psqlODBC.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip psqlODBC.zip" || _die "Couldn't extract psqlODBC archieve on windows-x64 VM (psqlODBC.zip)"
    
}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_windows_x64() {

    cd $WD/psqlODBC

    #Building psqlODBC

    cat <<EOT > "build-psqlODBC.bat"

CALL "$PG_VSINSTALLDIR_WINDOWS_X64\Professional\VC\Auxiliary\Build\vcvarsall.bat" amd64

@SET OPENSSL_PATH=$PG_PGBUILD_WINDOWS_X64
@SET PG_HOME_PATH=$PG_PATH_WINDOWS_X64\output
@SET PATH=%PG_HOME_PATH%\bin;%PATH%

cd $PG_PATH_WINDOWS_X64\psqlODBC.windows-x64
REM Compiling psqlODBC (ANSI)
nmake /f win64.mak ANSI_VERSION=yes PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib LINKMT=no CPU=X64 USE_SSPI=yes CFG=Release ALL

REM Compiling psqlODBC (UNICODE)
nmake /f win64.mak CFG=Release ALL PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib  LINKMT=no CPU=X64 USE_SSPI=yes

EOT

    scp build-psqlODBC.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c build-psqlODBC.bat" || _die "Failed to build psqlODBC"

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS_X64\\\\psqlODBC.staging)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC.staging rd /S /Q psqlODBC.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\psqlODBC.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c xcopy /E /Q /Y psqlODBC.windows-x64\\\\_Unicode_Release\\\\*.dll psqlODBC.staging" || _die "Couldn't copy the existing staging directory (Unicode Release)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c xcopy /E /Q /Y psqlODBC.windows-x64\\\\_ANSI_Release\\\\*.dll psqlODBC.staging" || _die "Couldn't copy the existing staging directory (ANSI Release)"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_VERSION_PSQLODBC=$PG_VERSION_PSQLODBC > $PG_PATH_WINDOWS_X64\\\\psqlODBC.staging/versions-windows-x64.sh" || _die "Failed to write psqlODBC version number into versions-windows-x64.sh"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_BUILDNUM_PSQLODBC=$PG_BUILDNUM_PSQLODBC >> $PG_PATH_WINDOWS_X64\\\\psqlODBC.staging/versions-windows-x64.sh" || _die "Failed to write psqlODBC build number into versions-windows-x64.sh"

}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_windows_x64() {

    if [ -e $WD/psqlODBC/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/psqlODBC/staging/windows-x64)"
    mkdir -p $WD/psqlODBC/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/psqlODBC/staging/windows-x64/bin  || _die "Failed to create directory for psqlODBC"
    mkdir -p $WD/psqlODBC/staging/windows-x64/etc  || _die "Failed to create etc directory for psqlODBC"

    # Zip up the installed code, copy it back here, and unpack.
    PSQLODBC_MAJOR_VERSION=`echo $PG_VERSION_PSQLODBC | cut -f1,2 -d "." | sed -e 's:\.::g'`

    echo "Copying psqlODBC built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC-staging.zip del /S /Q psqlODBC-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\psqlODBC.staging; cmd /c zip -r ..\\\\psqlODBC-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC.staging)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-staging.zip $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-staging.zip)"
    unzip -o $WD/psqlODBC/staging/windows-x64/bin/psqlODBC-staging.zip -d $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/bin/psqlODBC-staging.zip)"
    rm $WD/psqlODBC/staging/windows-x64/bin/psqlODBC-staging.zip
    mv $WD/psqlODBC/staging/windows-x64/bin/versions-windows-x64.sh $WD/psqlODBC/staging/windows-x64 || _die "Failed to move versions-windows-x64.sh"

    dos2unix $WD/psqlODBC/staging/windows-x64/versions-windows-x64.sh || _die "Failed to convert format of versions-windows-x64.sh from dos to unix"
    source $WD/psqlODBC/staging/windows-x64/versions-windows-x64.sh
    PG_BUILD_PSQLODBC=$(expr $PG_BUILD_PSQLODBC + $SKIPBUILD)

    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output/lib/libpq.dll $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_OPENSSL_WINDOWS_X64/bin/libssl-3-x64.dll $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the dependent dll"
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_OPENSSL_WINDOWS_X64/bin/libcrypto-3-x64.dll $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the dependent dll"
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/bin/libintl-8.dll $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the dll (libintl.dll)"
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/bin/libiconv-2.dll $WD/psqlODBC/staging/windows-x64/bin || _die "Failed to copy the dll (libiconv-2.dll)"

    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/vcredist/vcredist_x64.exe $WD/psqlODBC/staging/windows-x64/ || _die "Failed to copy the vcredist"

    cd $WD/psqlODBC
    
    pushd staging/windows-x64
    generate_3rd_party_license "psqlODBC"
    popd

    mkdir -p staging/windows-x64/scripts/images || _die "Failed to create directory for menu images"
    cp resources/*.ico staging/windows-x64/scripts/images || _die "Failed to copy menu icon image"

    if [ -f installer-win64.xml ]; then
        rm -f installer-win64.xml
    fi
    cp installer.xml installer-win64.xml

    _replace @@WIN64MODE@@ "1" installer-win64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ windows-x64 installer-win64.xml || _die "Failed to replace the WINDIR setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win64.xml windows || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $PG_BUILD_PSQLODBC -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    # Rename the installer
    mv $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows-x64.exe $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-${BUILD_FAILED}windows-x64.exe

    # Sign the installer
    win32_sign "psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-${BUILD_FAILED}windows-x64.exe"
	
    cd $WD

}


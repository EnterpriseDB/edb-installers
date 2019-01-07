#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_windows() {

    echo "BEGIN PREP psqlODBC Windows"    

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.windows ];
    then
      echo "Removing existing psqlODBC.windows source directory"
      rm -rf psqlODBC.windows  || _die "Couldn't remove the existing psqlODBC.windows source directory (source/psqlODBC.windows)"
    fi
    if [ -e psqlODBC.zip ];
    then
      echo "Removing existing psqlODBC.zip source file"
      rm -f psqlODBC.zip  || _die "Couldn't remove the existing psqlODBC.zip source file (source/psqlODBC.zip)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.windows)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.windows || _die "Couldn't create the psqlODBC.windows directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.windows || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    echo "Archieving psqlODBC sources"
    zip -r psqlODBC.zip psqlODBC.windows/ || _die "Couldn't create archieve of the psqlODBC sources (psqlODBC.zip)"

    chmod -R ugo+w psqlODBC.windows || _die "Couldn't set the permissions on the source directory"

    if [ -e $WD/psqlODBC/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/windows)"
    mkdir -p $WD/psqlODBC/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Remove any existing staging directory that might exist, and create a clean one
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST psqlODBC.zip del /S /Q psqlODBC.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\psqlODBC.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-psqlODBC.bat del /S /Q build-psqlODBC.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-psqlODBC.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST psqlODBC.windows rd /S /Q psqlODBC.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\psqlODBC.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST psqlODBC.staging.build rd /S /Q psqlODBC.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS\\psqlODBC.staging.build directory on Windows VM"

    # Copy sources on windows VM
    echo "Copying psqlODBC sources to Windows VM"
    scp psqlODBC.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the psqlODBC archieve to windows VM (psqlODBC.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip psqlODBC.zip" || _die "Couldn't extract psqlODBC archieve on windows VM (psqlODBC.zip)"
    
    echo "END PREP psqlODBC Windows"
}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_windows() {
    
    echo "BEGIN BUILD psqlODBC Windows"    

    cd $WD/psqlODBC

    #Building psqlODBC

    cat <<EOT > "build-psqlODBC.bat"

@CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

@SET OPENSSL_PATH=$PG_PGBUILD_WINDOWS
@SET PG_HOME_PATH=$PG_PATH_WINDOWS\output
@SET PATH=%PG_HOME_PATH%\bin;%PATH%

cd $PG_PATH_WINDOWS\psqlODBC.windows
REM Compiling psqlODBC (ANSI)
nmake /f win64.mak ANSI_VERSION=yes PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib LINKMT=no USE_SSPI=yes CFG=Release ALL

REM Compiling psqlODBC (UNICODE)
nmake /f win64.mak CFG=Release ALL PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib  LINKMT=no USE_SSPI=yes

EOT

    scp build-psqlODBC.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-psqlODBC.bat" || _die "Failed to build psqlODBC"

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS\\\\psqlODBC.staging)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST psqlODBC.staging rd /S /Q psqlODBC.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\psqlODBC.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y psqlODBC.windows\\\\_Unicode_Release\\\\*.dll psqlODBC.staging" || _die "Couldn't copy the existing staging directory (Unicode Release)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y psqlODBC.windows\\\\_ANSI_Release\\\\*.dll psqlODBC.staging" || _die "Couldn't copy the existing staging directory (ANSI Release)"

    ssh $PG_SSH_WINDOWS "cmd /c echo PG_VERSION_PSQLODBC=$PG_VERSION_PSQLODBC > $PG_PATH_WINDOWS\\\\psqlODBC.staging/versions-windows.sh" || _die "Failed to write psqlODBC version number into versions-windows.sh"
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_BUILDNUM_PSQLODBC=$PG_BUILDNUM_PSQLODBC >> $PG_PATH_WINDOWS\\\\psqlODBC.staging/versions-windows.sh" || _die "Failed to write psqlODBC build number into versions-windows.sh"

    echo "END BUILD psqlODBC Windows"
}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_windows() {

    echo "BEGIN POST psqlODBC Windows"

    if [ -e $WD/psqlODBC/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/psqlODBC/staging/windows)"
    mkdir -p $WD/psqlODBC/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/windows || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/psqlODBC/staging/windows/bin  || _die "Failed to create directory for psqlODBC"
    mkdir -p $WD/psqlODBC/staging/windows/etc  || _die "Failed to create etc directory for psqlODBC"

    # Zip up the installed code, copy it back here, and unpack.
    PSQLODBC_MAJOR_VERSION=`echo $PG_VERSION_PSQLODBC | cut -f1,2 -d "." | sed -e 's:\.::g'`

    echo "Copying psqlODBC built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST psqlODBC-staging.zip del /S /Q psqlODBC-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\psqlODBC-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\psqlODBC.staging; cmd /c zip -r ..\\\\psqlODBC-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/psqlODBC.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/psqlODBC-staging.zip $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/psqlODBC-staging.zip)"
    unzip -o $WD/psqlODBC/staging/windows/bin/psqlODBC-staging.zip -d $WD/psqlODBC/staging/windows/bin || _die "Failed to unpack the built source tree ($WD/staging/windows/bin/psqlODBC-staging.zip)"
    rm $WD/psqlODBC/staging/windows/bin/psqlODBC-staging.zip
    mv $WD/psqlODBC/staging/windows/bin/versions-windows.sh $WD/psqlODBC/staging/windows || _die "Failed to move versions-windows.sh"

    dos2unix $WD/psqlODBC/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/psqlODBC/staging/windows/versions-windows.sh
    PG_BUILD_PSQLODBC=$(expr $PG_BUILD_PSQLODBC + $SKIPBUILD)

    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output/lib/libpq.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/ssleay32.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/libeay32.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/libintl-8.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dll (libintl-8.dll)"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/libiconv-2.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dll (libiconv-2.dll)"

    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/lib/engines/capi.dll $WD/psqlODBC/staging/windows/bin || _die "Failed to copy the dll (capi.dll)"

    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/ssl/openssl.cnf $WD/psqlODBC/staging/windows/etc || _die "Failed to copy the openssl.cnf"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/vcredist/vcredist_x86.exe $WD/psqlODBC/staging/windows/ || _die "Failed to copy the vcredist"
 
    cd $WD/psqlODBC
 
    pushd staging/windows
    generate_3rd_party_license "psqlODBC"
    popd

    mkdir -p staging/windows/scripts/images || _die "Failed to create directory for menu images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy menu icon image"

    if [ -f installer-win.xml ]; then
        rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml
    
    _replace @@WIN64MODE@@ "0" installer-win.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ windows installer-win.xml || _die "Failed to replace the WINDIR setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $PG_BUILD_PSQLODBC -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    # Rename the installer
    mv $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows.exe $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-${BUILD_FAILED}windows.exe

    # Sign the installer
    win32_sign "psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-${BUILD_FAILED}windows.exe"
	
    cd $WD

    echo "END POST psqlODBC Windows"

}


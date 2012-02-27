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
    patch -p1 < $WD/tarballs/psqlodbc-win64.patch
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
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC.staging rd /S /Q psqlODBC.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC.staging directory on Windows VM"

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

CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

@SET OPENSSL_PATH=C:\pgBuild\OpenSSL
@SET PG_HOME_PATH=$PG_PATH_WINDOWS_X64\output
@SET PATH=%PG_HOME_PATH%\bin;%PATH%

cd $PG_PATH_WINDOWS_X64\psqlODBC.windows-x64
REM Compiling psqlODBC (ANSI)
nmake /f win64.mak ANSI_VERSION=yes PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib\VC LINKMT=no CPU=X64 USE_SSPI=yes CFG=Release ALL

REM Compiling psqlODBC (UNICODE)
nmake /f win64.mak CFG=Release ALL PG_INC=%PG_HOME_PATH%\include PG_LIB=%PG_HOME_PATH%\lib SSL_INC=%OPENSSL_PATH%\include SSL_LIB=%OPENSSL_PATH%\lib\VC  LINKMT=no CPU=X64 USE_SSPI=yes

EOT

    scp build-psqlODBC.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c build-psqlODBC.bat"

    # Zip up the installed code, copy it back here, and unpack.

    PSQLODBC_MAJOR_VERSION=`echo $PG_VERSION_PSQLODBC | cut -f1,2 -d "." | sed -e 's:\.::g'`

    mkdir -p $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin  || _die "Failed to create directory for psqlODBC"
    echo "Copying psqlODBC built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\psqlODBC.windows-x64\\\\X64ANSI; zip -r ..\\\\..\\\\psqlODBC-windows-x64.zip *.dll" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC.windows-x64)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-windows-x64.zip $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-windows-x64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC-windows-x64.zip del /S /Q psqlODBC-windows-x64.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC-windows-x64.zip on Windows VM"
    unzip -o $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin/psqlODBC-windows-x64.zip -d $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/psqlODBC-windows-x64.zip)"
    rm $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin/psqlODBC-windows-x64.zip

    echo "Copying psqlODBC built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\psqlODBC.windows-x64\\\\X64; zip -r ..\\\\..\\\\psqlODBC-windows-x64.zip *.dll" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC.windows-x64)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-windows-x64.zip $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/psqlODBC-windows-x64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST psqlODBC-windows-x64.zip del /S /Q psqlODBC-windows-x64.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\psqlODBC-windows-x64.zip on Windows VM"
    unzip -o $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin/psqlODBC-windows-x64.zip -d $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/psqlODBC-windows-x64.zip)"
    rm $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin/psqlODBC-windows-x64.zip

    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output/lib/libpq.dll $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/OpenSSL/bin/ssleay32.dll $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/OpenSSL/bin/libeay32.dll $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the dependent dll" 
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/libiconv/bin/libiconv-2.dll $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the dll (libiconv-2.dll)"
    scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/gettext/bin/libintl-8.dll $WD/psqlODBC/staging/windows-x64/$PSQLODBC_MAJOR_VERSION/bin || _die "Failed to copy the dll (libintl-8.dll)"

}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_windows_x64() {

    cd $WD/psqlODBC

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

    # Sign the installer
    win32_sign "psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows-x64.exe"
	
    cd $WD

}


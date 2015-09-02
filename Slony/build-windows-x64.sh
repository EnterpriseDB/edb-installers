#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_windows_x64() {

    echo "BEGIN PREP Slony Windows-x64"
      
    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e Slony.windows-x64 ];
    then
      echo "Removing existing Slony.windows-x64 source directory"
      rm -rf Slony.windows-x64  || _die "Couldn't remove the existing Slony.windows-x64 source directory (source/Slony.windows-x64)"
    fi

    if [ -e Slony.zip ];
    then
      echo "Removing existing Slony.zip file"
      rm -rf Slony.zip || _die "Couldn't remove the existing Slony.windows-x64 source directory (source/Slony.zip)"
    fi

    echo "Creating Slony source directory ($WD/Slony/source/Slony.windows-x64)"
    mkdir -p Slony.windows-x64 || _die "Couldn't create the Slony.windows-x64 directory"
    chmod ugo+w Slony.windows-x64 || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the Slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* Slony.windows-x64 || _die "Failed to copy the source code (source/Slony-$PG_VERSION_Slony)"

    cd Slony.windows-x64
    patch -p1 <$WD/tarballs/slony_for_VS12.patch || _die "Failed to apply patch."
    patch -p0 <$WD/tarballs/slony_pg95.patch || _die "Failed to apply patch for pg95."
    cd $WD/Slony/source

    echo "Archieving Slony sources"
    zip -r Slony.zip Slony.windows-x64/ || _die "Couldn't create archieve of the Slony sources (Slony.zip)"
    chmod -R ugo+w Slony.windows-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/windows-x64)"
    mkdir -p $WD/Slony/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST Slony.zip del /S /Q Slony.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\Slony.zip on Windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST Slony.windows-x64 rd /S /Q Slony.windows-x64" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\Slony.windows-x64 directory on Windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST Slony.staging rd /S /Q Slony.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\Slony.staging directory on Windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST slony-staging.zip del /S /Q slony-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\slony-staging.zip on Windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST build-Slony.bat del /S /Q build-Slony.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\build-Slony.bat on Windows-x64 VM"

    echo "Copying Slony sources to Windows-x64 VM"
    scp Slony.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Couldn't copy the Slony archieve to windows-x64 VM (Slony.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip Slony.zip" || _die "Couldn't extract Slony archieve on windows-x64 VM (Slony.zip)"

    echo "END PREP Slony Windows-x64"        
}


################################################################################
# PG Build
################################################################################

_build_Slony_windows_x64() {

    echo "BEGIN BUILD Slony Windows-x64"    

    # build Slony    
    PG_STAGING=`echo $PG_PATH_WINDOWS_X64 | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGHOME_WINDOWS=$PG_PATH_WINDOWS_X64/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION

    cat <<EOT > "build-Slony.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

@SET PG_INC=$PG_PATH_WINDOWS_X64\output\include
@SET PG_LIB=$PG_PATH_WINDOWS_X64\output\lib
@SET GETTEXT_LIB=$PG_PGBUILD_WINDOWS_X64\lib
@SET GETTEXT_INC=$PG_PGBUILD_WINDOWS_X64\include
@SET PTHREADS_INC=$PG_PGBUILD_WINDOWS_X64\include
@SET PTHREADS_LIB=$PG_PGBUILD_WINDOWS_X64\lib
@SET PGVER=$PG_MAJOR_VERSION
@SET SLONY_VERSION=$PG_VERSION_SLONY
@SET PGSHARE=\"\"

cd Slony.windows-x64\src\slonik
nmake /E /F win32.mak slonik.exe
cd ..\backend
nmake /E /F win32.mak slony1_funcs.%SLONY_VERSION%.dll
cd ..\slon
nmake /E /F win32.mak slon.exe

EOT

   scp build-Slony.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64
   ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c build-Slony.bat" 
    
   # Slony installs it's files into postgresql directory
   # We need to copy them to staging directory
   ssh $PG_SSH_WINDOWS_X64  "mkdir -p $PG_PATH_WINDOWS_X64/Slony.staging/bin" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/slon/slon.exe $PG_PATH_WINDOWS_X64/Slony.staging/bin" || _die "Failed to copy slon binary to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/slonik/slonik.exe $PG_PATH_WINDOWS_X64/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PGBUILD_WINDOWS_X64/bin/pthreadVC2.dll $PG_PATH_WINDOWS_X64/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"

   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/Slony.staging/lib" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_funcs.$PG_VERSION_SLONY.dll $PG_PATH_WINDOWS_X64/Slony.staging/lib" || _die "Failed to copy slony_funcs.dll to staging directory"

   ssh $PG_SSH_WINDOWS_X64 "mkdir -p $PG_PATH_WINDOWS_X64/Slony.staging/Slony" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_base.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_base.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_base.v83.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_base.v83.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_base.v84.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_base.v84.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_funcs.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_funcs.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_funcs.v83.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_funcs.v83.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"
   ssh $PG_SSH_WINDOWS_X64 "cp $PG_PATH_WINDOWS_X64/Slony.windows-x64/src/backend/slony1_funcs.v84.sql $PG_PATH_WINDOWS_X64/Slony.staging/Slony/slony1_funcs.v84.$PG_VERSION_SLONY.sql" || _die "Failed to share files to staging directory"

   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying slony built tree to Unix host"
   ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\Slony.staging; cmd /c zip -r ..\\\\slony-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/Slony.staging)"
   scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/slony-staging.zip $WD/Slony/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/slony-staging.zip)"
   unzip $WD/Slony/staging/windows-x64/slony-staging.zip -d $WD/Slony/staging/windows-x64 || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/slony-staging.zip)"
   rm $WD/Slony/staging/windows-x64/slony-staging.zip

   echo "END BUILD Slony Windows-x64"
}
    


################################################################################
# PG Build
################################################################################

_postprocess_Slony_windows_x64() {

    echo "BEGIN POST Slony Windows-x64"

    cd $WD/Slony

    mkdir -p staging/windows-x64/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/configureslony.bat staging/windows-x64/installer/Slony/configureslony.bat || _die "Failed to copy the configureSlony script (scripts/windows-x64/configureslony.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    pushd staging/windows-x64
    generate_3rd_party_license "slony"
    popd

    if [ -f installer-win64.xml ]; then
        rm -f installer-win64.xml
    fi
    cp installer.xml installer-win64.xml

    _replace @@WINDIR@@ windows-x64 installer-win64.xml || _die "Failed to replace the WINDIR setting in the installer.xml"
    _replace @@WIN64MODE@@ "1" installer-win64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win64.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows-x64.exe"
	    
    cd $WD

    echo "END POST Slony Windows-x64"
}



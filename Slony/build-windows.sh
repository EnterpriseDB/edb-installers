#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_windows() {
      
    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e Slony.windows ];
    then
      echo "Removing existing Slony.windows source directory"
      rm -rf Slony.windows  || _die "Couldn't remove the existing Slony.windows source directory (source/Slony.windows)"
    fi

    echo "Creating Slony source directory ($WD/Slony/source/Slony.windows)"
    mkdir -p Slony.windows || _die "Couldn't create the Slony.windows directory"
    chmod ugo+w Slony.windows || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the Slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* Slony.windows || _die "Failed to copy the source code (source/Slony-$PG_VERSION_Slony)"
    echo "Archieving Slony sources"
    zip -r Slony.zip Slony.windows/ || _die "Couldn't create archieve of the Slony sources (Slony.zip)"
    chmod -R ugo+w Slony.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/windows)"
    mkdir -p $WD/Slony/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.zip del /S /Q Slony.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.windows rd /S /Q Slony.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.staging rd /S /Q Slony.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-Slony.bat del /S /Q build-Slony.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-Slony.bat on Windows VM"

    echo "Copying Slony sources to Windows VM"
    scp Slony.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the Slony archieve to windows VM (Slony.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip Slony.zip" || _die "Couldn't extract Slony archieve on windows VM (Slony.zip)"

        
}


################################################################################
# PG Build
################################################################################

_build_Slony_windows() {

    # build Slony    
    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGHOME_WINDOWS=$PG_PATH_WINDOWS/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION 


    cat <<EOT > "build-Slony.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

@SET PG_INC=$PG_PATH_WINDOWS\output\include
@SET PG_LIB=$PG_PATH_WINDOWS\output\lib
@SET GETTEXT_INC=$PG_PGBUILD_WINDOWS\gettext\include
@SET GETTEXT_LIB=$PG_PGBUILD_WINDOWS\gettext\lib
@SET PTHREADS_INC=$PG_PGBUILD_WINDOWS\pthreads\include
@SET PTHREADS_LIB=$PG_PGBUILD_WINDOWS\pthreads\lib
@SET PGSHARE=\"\"

cd Slony.windows\src\slonik
nmake /E /F win32.mak slonik.exe
cd ..\backend
nmake /E /F win32.mak slony1_funcs.dll
cd ..\slon
nmake /E /F win32.mak slon.exe

EOT

   scp build-Slony.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-Slony.bat" 
   
    # Create manifest file for slon.exe and slonik.exe
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cd Slony.windows/src/slon; cmd /c \"$PG_MANIFEST_WINDOWS\"  -manifest slon.exe.manifest -outputresource:slon.exe" || _die "Failed to create manifest file for slon.exe"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cd Slony.windows/src/slonik; cmd /c \"$PG_MANIFEST_WINDOWS\"  -manifest slonik.exe.manifest -outputresource:slonik.exe" || _die "Failed to create manifest file for slonik.exe"
    
   # Slony installs it's files into postgresql directory
   # We need to copy them to staging directory
   ssh $PG_SSH_WINDOWS  "mkdir -p $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/slon/slon.exe $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slon binary to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/slon/slon.exe.manifest $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slon binary manifest file to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/slonik/slonik.exe.manifest $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slonik binary manifest file to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/slonik/slonik.exe $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGBUILD_WINDOWS/pthreads/lib/pthreadVC2.dll $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"
   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/Slony.staging/lib" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/backend/slony1_funcs.dll $PG_PATH_WINDOWS/Slony.staging/lib" || _die "Failed to copy slony_funcs.dll to staging directory"

   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/Slony.staging/Slony" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Slony.windows/src/backend/slony*.sql $PG_PATH_WINDOWS/Slony.staging/Slony" || _die "Failed to share files to staging directory"

   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying slony built tree to Unix host"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\Slony.staging; cmd /c zip -r ..\\\\slony-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/Slony.staging)"
   scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/slony-staging.zip $WD/Slony/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/slony-staging.zip)"
   unzip $WD/Slony/staging/windows/slony-staging.zip -d $WD/Slony/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/slony-staging.zip)"
   rm $WD/Slony/staging/windows/slony-staging.zip
}
    


################################################################################
# PG Build
################################################################################

_postprocess_Slony_windows() {

    cd $WD/Slony

    mkdir -p staging/windows/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/configureslony.bat staging/windows/installer/Slony/configureslony.bat || _die "Failed to copy the configureSlony script (scripts/windows/configureslony.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    pushd staging/windows
    generate_3rd_party_license "slony"
    popd

    _replace @@WINDIR@@ windows installer.xml || _die "Failed to replace the WINDIR setting in the installer.xml"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows.exe"
	    
    cd $WD
}


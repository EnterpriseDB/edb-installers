#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Npgsql_osx() {

    echo "BEGIN PREP Npgsql OSX"

    echo "*******************************"
    echo "*  Pre Process: Npgsql (OSX)  *"
    echo "*******************************"

    # Enter the source directory and cleanup if required
    cd $WD/Npgsql/source

    if [ -e Npgsql.osx ];
    then
      echo "Removing existing Npgsql.osx source directory"
      rm -rf Npgsql.osx  || _die "Couldn't remove the existing Npgsql.osx source directory (source/Npgsql.osx)"
    fi
  
    if [ -e Npgsql.zip ];
    then
      echo "Removing existing Npgsql.zip file"
      rm -rf Npgsql.zip || _die "Couldn't remove the existing Npgsql.zip file (source/Npgsql.zip)"
    fi

    echo "Creating Npgsql source directory ($WD/Npgsql/source/Npgsql.osx)"
    mkdir -p Npgsql.osx || _die "Couldn't create the Npgsql.osx directory"
    chmod ugo+w Npgsql.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the Npgsql source tree
    cp -R npgsql-$PG_VERSION_NPGSQL/* Npgsql.osx || _die "Failed to copy the source code (source/Npgsql-$PG_VERSION_Npgsql)"

    cd $WD/Npgsql/source

    echo "Archieving Npgsql sources"
    zip -r Npgsql.zip Npgsql.osx/ || _die "Couldn't create archieve of the Npgsql sources (Npgsql.zip)"
    chmod -R ugo+w Npgsql.osx || _die "Couldn't set the permissions on the source directory"
 
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Npgsql/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Npgsql/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Npgsql/staging/osx)"
    mkdir -p $WD/Npgsql/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Npgsql/staging/osx || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.zip del /S /Q Npgsql.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.osx rd /S /Q Npgsql.osx" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.osx directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Npgsql.staging rd /S /Q Npgsql.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Npgsql.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST npgsql-staging.zip del /S /Q npgsql-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\npgsql-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-Npgsql.bat del /S /Q build-Npgsql.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-Npgsql.bat on Windows VM"

    echo "Copying Npgsql sources to Windows VM"
    scp Npgsql.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the Npgsql archieve to windows VM (Npgsql.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip Npgsql.zip" || _die "Couldn't extract Npgsql archieve on windows VM (Npgsql.zip)"
 
    echo "END PREP Npgsql OSX"

}

################################################################################
# PG Build
################################################################################

_build_Npgsql_osx() {
  
    echo "BEGIN BUILD Npgsql OSX"

    cd $WD/Npgsql/source

    cat <<EOT > "build-Npgsql.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

REM batch file splits single argument containing "=" sign into two
REM Following code handles this scenario

cd Npgsql.osx
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
    ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/Npgsql.osx/src/Npgsql/bin/Release/* $PG_PATH_WINDOWS/Npgsql.staging/bin" || _die "Failed to copy Npgsql binary to staging directory"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying npgsql built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\Npgsql.staging; cmd /c zip -r ..\\\\npgsql-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/Npgsql.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip $WD/Npgsql/staging/osx || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/npgsql-staging.zip)"
    unzip $WD/Npgsql/staging/osx/npgsql-staging.zip -d $WD/Npgsql/staging/osx || _die "Failed to unpack the built source tree ($WD/staging/osx/npgsql-staging.zip)"
    rm $WD/Npgsql/staging/osx/npgsql-staging.zip    

    cp $WD/Npgsql/source/Npgsql.osx/LICENSE.txt $WD/Npgsql/staging/osx/ || _die "Unable to copy LICENSE.txt"

    cd $WD

    echo "END BUILD Npgsql OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_Npgsql_osx() {

    echo "BEGIN POST Npgsql OSX"

    echo "********************************"
    echo "*  Post Process: Npgsql (OSX)  *"
    echo "********************************"
 
    cd $WD/Npgsql

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/npgsql || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/npgsql/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/npgsql/createshortcuts.sh

    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/pg-launchDocsAPI.applescript.in staging/osx/scripts/pg-launchDocsAPI.applescript || _die "Failed to copy the pg-launchDocsAPI.applescript script (scripts/osx/pg-launchDocsAPI.applescript)"
    cp scripts/osx/pg-launchUserManual.applescript.in staging/osx/scripts/pg-launchUserManual.applescript || _die "Failed to copy the pg-launchUserManual.applescript script (scripts/osx/pg-launchUserManual.applescript)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByR

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/Npgsql $WD/scripts/risePrivileges || _die "Failed to copy the pri

        rm -rf $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app
    fi

    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/Npgsql
    chmod a+x $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/Npgsql
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Npgsql $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with Npgsql ($WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/Contents/MacOS/installbuilder.sh
    
    # Zip up the output
    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app.tar.bz2 npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf npgsql*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app; mv npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx-signed.app  npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.app/" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."
 
    cd $WD

    echo "END POST Npgsql OSX"
}


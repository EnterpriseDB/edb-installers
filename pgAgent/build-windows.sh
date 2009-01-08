#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.windows ];
    then
      echo "Removing existing pgAgent.windows source directory"
      rm -rf pgAgent.windows  || _die "Couldn't remove the existing pgAgent.windows source directory (source/pgAgent.windows)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.windows)"
    mkdir -p $WD/pgAgent/source/pgAgent.windows || _die "Couldn't create the pgAgent.windows directory"
    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.windows || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    chmod -R ugo+w pgAgent.windows || _die "Couldn't set the permissions on the source directory"

    echo "Archieving pgAgent sources"
    zip -r pgAgent.zip pgAgent.windows/ || _die "Couldn't create archieve of the pgAgent sources (pgAgent.zip)"

    cd $WD/pgAgent/scripts/windows
    echo "Archieving pgAgent scripts(validateuser)"
    zip -r scripts.zip validateuser/ || _die "Couldn't create archieve of the pgAgent scripts(validateuser) (scripts.zip)"
    cd $WD/pgAgent/source

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/windows)"
    mkdir -p $WD/pgAgent/staging/windows || _die "Couldn't create the staging directory"  
    chmod ugo+w $WD/pgAgent/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Clean sources on Windows VM

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgAgent.zip del /S /Q pgAgent.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pgAgent.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST scripts.zip del /S /Q scripts.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\scripts.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgAgent.windows rd /S /Q pgAgent.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pgAgent.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST validateuser rd /S /Q validateuser"

    # Copy sources on windows VM
    echo "Copying pgAgent sources to Windows VM"

    scp pgAgent.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the pgAgent archieve to windows VM (pgAgent.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pgAgent.zip" || _die "Couldn't extract pgAgent archieve on windows VM (pgAgent.zip)"

    scp $WD/pgAgent/scripts/windows/scripts.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the scripts archieve to windows VM (scripts.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip scripts.zip" || _die "Couldn't extract scripts archieve on windows VM (scripts.zip)"
    rm $WD/pgAgent/scripts/windows/scripts.zip

}

################################################################################
# PG Build
################################################################################

_build_pgAgent_windows() {

    cd $WD/pgAgent
    SOURCE_DIR=$PG_PATH_WINDOWS/pgAgent.windows

    echo "configuring pgAgent sources"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; export PGDIR=$PG_PATH_WINDOWS/output ; cmake CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"
    echo "Building pgAgent"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; export PGDIR=$PG_PATH_WINDOWS/output ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgagent.vcproj RELEASE" || _die "Failed to build pgAgent on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/validateuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj RELEASE" || _die "Failed to build validateuser on the build host"

    echo "copying application files into Release Folder"

    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgAgent.windows\\\\pgagent.sql $PG_PATH_WINDOWS\\\\pgAgent.windows\\\\release" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgAgent.windows\\\\pgaevent $PG_PATH_WINDOWS\\\\pgAgent.windows\\\\release" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\validateuser\\\\release\\\\validateuser.exe $PG_PATH_WINDOWS\\\\pgAgent.windows\\\\release" || _die "Failed to copy a program file on the windows build host"
 
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR\\\\release; cmd /c zip -r ..\\\\release.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$SOURCE_DIR/release)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/pgAgent.windows/release.zip $WD/pgAgent/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$SOURCE_DIR/release.zip)"
    unzip $WD/pgAgent/staging/windows/release.zip -d $WD/pgAgent/staging/windows/ || _die "Failed to unpack the built source tree ($WD/pgAgent/staging/windows/release.zip)"
    rm $WD/pgAgent/staging/windows/release.zip
}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_windows() {


    cp -R $WD/pgAgent/source/pgAgent.windows/* $WD/pgAgent/staging/windows || _die "Failed to copy the pgAgent Source into the staging directory"
    
    cd $WD/pgAgent

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/check-connection.bat staging/windows/installer/pgAgent/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    chmod ugo+x staging/windows/installer/pgAgent/check-connection.bat

    cp scripts/windows/install-pgagent.bat staging/windows/installer/pgAgent/install-pgagent.bat || _die "Failed to copy the install script (scripts/windows/install-pgagent.bat)"
    chmod ugo+x staging/windows/installer/pgAgent/install-pgagent.bat

    cp scripts/windows/uninstall-pgagent.bat staging/windows/installer/pgAgent/uninstall-pgagent.bat || _die "Failed to copy the uninstall script (scripts/windows/uninstall-pgagent.bat)"
    chmod ugo+x staging/windows/installer/pgAgent/uninstall-pgagent.bat

    cp scripts/windows/configure-pgagent.bat staging/windows/installer/pgAgent/configure-pgagent.bat || _die "Failed to copy the configure script (scripts/windows/configure-pgagent.bat)"
    chmod ugo+x staging/windows/installer/pgAgent/configure-pgagent.bat

    cp staging/windows/validateuser.exe staging/windows/installer/pgAgent || _die "Failed to copy the validateuser binary (scripts/windows/configure-pgagent.bat)"

    # Setup the pgAgent Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the pgAgent Launch Scripts"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD

}


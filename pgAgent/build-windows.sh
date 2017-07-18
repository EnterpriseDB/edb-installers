#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pgAgent_windows() {

    echo "BEGIN PREP pgAgent Windows"

    echo "#####################################"
    echo "# pgAgent : WIN : Build preparation #"
    echo "#####################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.windows ];
    then
      echo "Removing existing pgAgent.windows source directory"
      rm -rf pgAgent.windows  || _die "Couldn't remove the existing pgAgent.windows source directory (source/pgAgent.windows)"
    fi

    if [ -f pgAgent.zip ];
    then
      echo "Removing the existing pgAgent achieve from the build machine"
      rm -f pgAgent.zip
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.windows)"
    mkdir -p $WD/pgAgent/source/pgAgent.windows || _die "Couldn't create the pgAgent.windows directory"
    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.windows || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"

    cd pgAgent.windows
    patch -p1 < $WD/../patches/pgAgent_dynamic_link.patch
    cd $WD/pgAgent/source

    chmod -R ugo+w pgAgent.windows || _die "Couldn't set the permissions on the source directory"

    # Copy validateuser to pgAgent directory
    cp -R $WD/pgAgent/scripts/windows/validateuser $WD/pgAgent/source/pgAgent.windows/validateuser || _die "Failed to copy scripts(validateuser)"

    # Copy createuser to pgAgent directory
    cp -R $WD/pgAgent/scripts/windows/createuser $WD/pgAgent/source/pgAgent.windows/createuser || _die "Failed to copy scripts(createuser)"

    # Copy CreatePGPassconfForUser to pgAgent directory
    cp -R $WD/pgAgent/scripts/windows/CreatePGPassconfForUser  $WD/pgAgent/source/pgAgent.windows/CreatePGPassconfForUser || _die "Failed to copy scripts(createuser)"

    echo "Archieving pgAgent sources"
    zip -r pgAgent.zip pgAgent.windows/ || _die "Couldn't create archieve of the pgAgent sources (pgAgent.zip)"

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
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST vc-build.bat del /S /Q vc-build.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\vc-build.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgAgent.windows rd /S /Q pgAgent.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pgAgent.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgAgent.output.build rd /S /Q pgAgent.output.build" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pgAgent.output.build directory on Windows VM"

    # Copy sources on windows VM
    echo "Copying pgAgent sources to Windows VM"
    scp pgAgent.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the pgAgent archieve to windows VM (pgAgent.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pgAgent.zip" || _die "Couldn't extract pgAgent archieve on windows VM (pgAgent.zip)"
    
    echo "END PREP pgAgent Windows"
}

################################################################################
# pgAgent Build
################################################################################

_build_pgAgent_windows() {

    echo "BEGIN BUILD pgAgent Windows"

    echo "###############################"
    echo "# pgAgent : WIN : Build       #"
    echo "###############################"

    cd $WD/pgAgent
    SOURCE_DIR=$PG_PATH_WINDOWS/pgAgent.windows
    OUTPUT_DIR=$PG_PATH_WINDOWS\\\\pgAgent.output.build
    STAGING_DIR=$WD/pgAgent/staging/windows

    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET PGDIR=$PG_PATH_WINDOWS\output

IF "%2" == "UPGRADE" GOTO upgrade

msbuild %1 /p:Configuration=%2
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT
    scp vc-build.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the vc-build.bat to the windows build host (vcbuild.bat)"

    echo "Configuring pgAgent sources"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; PGDIR=$PG_PATH_WINDOWS/output WXWIN=$PG_WXWIN_WINDOWS $PG_CMAKE_WINDOWS/bin/cmake -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR -D CMAKE_CXX_FLAGS=\"/D _UNICODE /EHsc\" ." || _die "Couldn't configure the pgAgent sources"
    echo "Building pgAgent"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; export PGDIR=$PG_PATH_WINDOWS/output ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgagent.vcxproj RELEASE" || _die "Failed to build pgAgent on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/pgaevent; export PGDIR=$PG_PATH_WINDOWS/output ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgaevent.vcxproj RELEASE" || _die "Failed to build pgaevent on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat run.vcxproj RELEASE" || _die "Failed to build project run on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/validateuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/validateuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/createuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/createuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/CreatePGPassconfForUser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat CreatePGPassconfForUser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/CreatePGPassconfForUser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat CreatePGPassconfForUser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"

    echo "Installing pgAgent"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c $PG_CMAKE_WINDOWS/bin/cmake -DBUILD_TYPE=RELEASE -P cmake_install.cmake" || _die "Failed to install pgAgent in output directory"
    
    echo "copying application files into the output directory"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy validateuser\\\\release\\\\validateuser.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy createuser\\\\release\\\\createuser.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy CreatePGPassconfForUser\\\\release\\\\CreatePGPassconfForUser.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy /Y $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe $OUTPUT_DIR" || _die "Failed to copy the VC++ runtimes on the windows build host"
 
    echo "Removing last successful staging directory ($PG_PATH_WINDOWS\\\\pgAgent.output)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgAgent.output rd /S /Q pgAgent.output" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\pgAgent.output" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y pgAgent.output.build\\\\* pgAgent.output\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS "cmd /c echo PG_VERSION_PGAGENT=$PG_VERSION_PGAGENT > $PG_PATH_WINDOWS\\\\pgAgent.output/versions-windows.sh" || _die "Failed to write pgAgent version number into versions-windows.sh"
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_BUILDNUM_PGAGENT=$PG_BUILDNUM_PGAGENT >> $PG_PATH_WINDOWS\\\\pgAgent.output/versions-windows.sh" || _die "Failed to write pgAgent build number into versions-windows.sh"
    
    echo "END BUILD pgAgent Windows"
}


################################################################################
# pgAgent Post Process
################################################################################

_postprocess_pgAgent_windows() {
    
    echo "BEGIN POST pgAgent Windows"    

    echo "#####################################"
    echo "# pgAgent : WIN : Post Process      #"
    echo "#####################################"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/pgAgent/staging/windows)"
    mkdir -p $WD/pgAgent/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgAgent/staging/windows || _die "Couldn't set the permissions on the staging directory"

    cd $WD/pgAgent/staging/windows
    echo "Copying built tree to Windows host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST pgagent_output.zip del /S /Q pgagent_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\pgagent_output.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\pgAgent.output; cmd /c zip -r pgagent_output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\pgAgent.output)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\pgAgent.output\\\\pgagent_output.zip $WD/pgAgent/staging/windows/pgagent_output.zip || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\pgAgent.output/pgagent_output.zip)"
    unzip -o $WD/pgAgent/staging/windows/pgagent_output.zip -d $WD/pgAgent/staging/windows || _die "Failed to unpack the built source tree ($WD/pgAgent/staging/windows/pgagent_output.zip)"
    rm -f $WD/pgAgent/staging/windows/pgagent_output.zip

    dos2unix $WD/pgAgent/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/pgAgent/staging/windows/versions-windows.sh
    PG_BUILD_PGAGENT=$(expr $PG_BUILD_PGAGENT + $SKIPBUILD)

    mkdir -p $WD/pgAgent/staging/windows/bin

    echo "Copying dependent libraries from the windows VM to staging directory"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output/bin/psql.exe $WD/pgAgent/staging/windows/bin || _die "Failed to copy psql.exe"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output/bin/libpq.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy the dependent dll (libpq.dll)"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/ssleay32.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy the dependent dll (ssleay32.dll)"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS//bin/libeay32.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy the dependent dll (libeay32.dll)"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/libiconv-2.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy the dependent dll (libiconv-2.dll)"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/bin/libintl-8.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy the dependent dll (libintl-8.dll)"
    scp $PG_SSH_WINDOWS:$PG_WXWIN_WINDOWS/lib/vc_dll/wxbase28u_vc_custom.dll $WD/pgAgent/staging/windows/bin || _die "Failed to copy a dependency DLL on the windows build host (wxbase28u_vc_custom.dll)"
    # Setup the installer scripts
    mkdir -p $WD/pgAgent/staging/windows/installer/pgAgent || _die "Failed to create a directory for the install scripts"
    cp -f $WD/pgAgent/staging/windows/validateuser.exe $WD/pgAgent/staging/windows/installer/pgAgent/ || _die "Failed to copy validateuser.exe (staging/windows/validateuser.exe)"
    cp -f $WD/pgAgent/staging/windows/createuser.exe $WD/pgAgent/staging/windows/installer/pgAgent/ || _die "Failed to copy createuser.exe (staging/windows/createuser.exe)"

    # Copy scripts into staging directory
    cp -f $WD/pgAgent/scripts/windows/*.bat $WD/pgAgent/staging/windows/installer/pgAgent/ || _die "Failed to copy the install scripts (scripts/windows/*.bat)"
    chmod ugo+x $WD/pgAgent/staging/windows/installer/pgAgent/*

    cd $WD/pgAgent
 
    pushd staging/windows
    generate_3rd_party_license "pgAgent"
    popd

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $PG_BUILD_PGAGENT -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    # Rename the installer
    mv $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-windows.exe $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}windows.exe

	# Sign the installer
	win32_sign "pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}windows.exe"
	
    cd $WD

    echo "END POST pgAgent Windows"

}


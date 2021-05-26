#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pgAgent_windows_x64() {

    echo "BEGIN PREP pgAgent Windows"

    echo "#####################################"
    echo "# pgAgent : WIN : Build preparation #"
    echo "#####################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.windows-x64 ];
    then
      echo "Removing existing pgAgent.windows-x64 source directory"
      rm -rf pgAgent.windows-x64  || _die "Couldn't remove the existing pgAgent.windows-x64 source directory (source/pgAgent.windows-x64)"
    fi

    if [ -f pgAgent.zip ];
    then
      echo "Removing the existing pgAgent achieve from the build machine"
      rm -f pgAgent.zip
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.windows-x64)"
    mkdir -p $WD/pgAgent/source/pgAgent.windows-x64 || _die "Couldn't create the pgAgent.windows-x64 directory"
    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.windows-x64 || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"

    cd pgAgent.windows-x64
    patch -p1 < $WD/../patches/pgAgent_dynamic_link.patch
    cd $WD/pgAgent/source

    chmod -R ugo+w pgAgent.windows-x64 || _die "Couldn't set the permissions on the source directory"

    # Copy validateuser to pgAgent directory
    cp -R $WD/server/scripts/windows/validateuser $WD/pgAgent/source/pgAgent.windows-x64/validateuser || _die "Failed to copy scripts(validateuser)"

    # Copy createuser to pgAgent directory
    cp -R $WD/server/scripts/windows/createuser $WD/pgAgent/source/pgAgent.windows-x64/createuser || _die "Failed to copy scripts(createuser)"

    # Copy CreatePGPassconfForUser to pgAgent directory
    cp -R $WD/pgAgent/scripts/windows/CreatePGPassconfForUser  $WD/pgAgent/source/pgAgent.windows-x64/CreatePGPassconfForUser || _die "Failed to copy scripts(createuser)"

    echo "Archieving pgAgent sources"
    zip -r pgAgent.zip pgAgent.windows-x64/ || _die "Couldn't create archieve of the pgAgent sources (pgAgent.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/windows-x64)"
    mkdir -p $WD/pgAgent/staging/windows-x64 || _die "Couldn't create the staging directory"  
    chmod ugo+w $WD/pgAgent/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    # Clean sources on Windows VM

    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgAgent.zip del /S /Q pgAgent.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\pgAgent.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST vc-build-x64.bat del /S /Q vc-build-x64.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\vc-build-x64.bat on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgAgent.windows-x64 rd /S /Q pgAgent.windows-x64" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\pgAgent.windows-x64 directory on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgAgent.output.build rd /S /Q pgAgent.output.build" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\pgAgent.output.build directory on Windows VM"

    # Copy sources on windows-x64 VM
    echo "Copying pgAgent sources to Windows VM"
    scp pgAgent.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Couldn't copy the pgAgent archieve to windows-x64 VM (pgAgent.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip pgAgent.zip" || _die "Couldn't extract pgAgent archieve on windows-x64 VM (pgAgent.zip)"
    
    echo "END PREP pgAgent Windows"
}

################################################################################
# pgAgent Build
################################################################################

_build_pgAgent_windows_x64() {

    echo "BEGIN BUILD pgAgent Windows"

    echo "###############################"
    echo "# pgAgent : WIN : Build       #"
    echo "###############################"

    cd $WD/pgAgent
    SOURCE_DIR=$PG_PATH_WINDOWS_X64/pgAgent.windows-x64
    OUTPUT_DIR=$PG_PATH_WINDOWS_X64\\\\pgAgent.output.build
    STAGING_DIR=$WD/pgAgent/staging/windows-x64

    cat <<EOT > "vc-build-x64.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\\vcvarsall.bat" amd64
@SET PGBUILD=$PG_PGBUILD_WINDOWS_X64
@SET BOOST_ROOT=$PG_BOOST_WINDOWS_X64
@SET PGDIR=$PG_PATH_WINDOWS_X64\output
IF "%2" == "UPGRADE" GOTO upgrade
msbuild %1 /p:Configuration=%2
GOTO end
:upgrade
devenv /upgrade %1
:end
EOT
    scp vc-build-x64.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the vc-build-x64.bat to the windows-x64 build host (vcbuild.bat)"

    echo "Configuring pgAgent sources"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR; PGDIR=$PG_PATH_WINDOWS_X64/output BOOST_ROOT=$PG_BOOST_WINDOWS_X64 $PG_CMAKE_WINDOWS_X64/bin/cmake -G \"${CMAKE_BUILD_GENERATOR_X64} Win64\" -DSTATIC_BUILD=NO -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR -D CMAKE_CXX_FLAGS=\" /EHsc\" ." || _die "Couldn't configure the pgAgent sources"


    #ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR; PGDIR=$PG_PATH_WINDOWS_X64/output BOOST_ROOT=$PG_BOOST_WINDOWS_X64  $PG_CMAKE_WINDOWS_X64/bin/cmake -G \"${CMAKE_BUILD_GENERATOR_X64} Win64\" -DSTATIC_BUILD=NO -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR -D CMAKE_CXX_FLAGS=\" /EHsc\" ." || _die "Couldn't configure the pgAgent sources"

    # ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR; PGDIR=$PG_PATH_WINDOWS_X64/outputt BOOST_INCLUDEDIR=$PG_BOOST_WINDOWS_X64\\Include\\boost-1_66 BOOST_LIBRARYDIR=$PG_BOOST_WINDOWS_X64\\lib Boost_LIBRARIES=$PG_BOOST_WINDOWS_X64\\lib  BOOST_ROOT=$PG_BOOST_WINDOWS_X64  $PG_CMAKE_WINDOWS_X64/bin/cmake -DSTATIC_BUILD=NO -DCMAKE_INSTALL_PREFIX=$OUTPUT_DIR -D CMAKE_CXX_FLAGS=\" /EHsc\" ." || _die "Couldn't configure the pgAgent sources"

    echo "Building pgAgent"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR; export PGDIR=$PG_PATH_WINDOWS_X64/output ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pgagent.vcxproj RELEASE" || _die "Failed to build pgAgent on the build host"

    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/pgaevent; export PGDIR=$PG_PATH_WINDOWS_X64/output ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pgaevent.vcxproj RELEASE" || _die "Failed to build pgaevent on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat run.vcxproj RELEASE" || _die "Failed to build project run on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/validateuser ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat validateuser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/validateuser ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat validateuser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/createuser ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat createuser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/createuser ; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat createuser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/CreatePGPassconfForUser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat CreatePGPassconfForUser.vcproj UPGRADE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR/CreatePGPassconfForUser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat CreatePGPassconfForUser.vcxproj RELEASE" || _die "Failed to build validateuser on the build host"

    echo "Installing pgAgent"
    ssh $PG_SSH_WINDOWS_X64 "cd $SOURCE_DIR; cmd /c $PG_CMAKE_WINDOWS_X64/bin/cmake -DBUILD_TYPE=RELEASE -P cmake_install.cmake" || _die "Failed to install pgAgent in output directory"
   

    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to make bin directory in output.build directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share" || _die "Failed to make share directory in output.build directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share\\\\extension" || _die "Failed to make share/extension directory in output.build directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\pgagent.exe $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy pgagent.exe on the windows build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\pgaevent.dll $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy pgaevent.dll on the windows build host"
     ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_BOOST_WINDOWS_X64\\\\lib\\\\boost_filesystem*mt-x64*.dll  $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy boost_filesystem.dll on the windows build host"
     ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_BOOST_WINDOWS_X64\\\\lib\\\\boost_system*mt-x64*.dll  $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy boost_system.dll on the windows build host"
     ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_BOOST_WINDOWS_X64\\\\lib\\\\boost_thread*mt-x64*.dll  $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy boost_thread.dll on the windows build host"
     ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_BOOST_WINDOWS_X64\\\\lib\\\\boost_chrono*mt-x64*.dll  $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\bin" || _die "Failed to copy boost_chrono.dll on the windows build host"
     ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\pgagent.sql $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share\\\\extension" || _die "Failed to copy pgagent.sql on the windows build host"
   # ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\pgagent_upgrade.sql $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share\\\\extension" || _die "Failed to copy pgagnet_upgrde.sql on the windows build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\output\\\\share\\\\extension\\\\pgagent.control $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share\\\\extension" || _die "Failed to copy pgagent.control on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c move $PG_PATH_WINDOWS_X64\\\\output\\\\share\\\\extension\\\\pgagent*.sql $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\share\\\\extension" || _die "Failed to copy pgagent sql files on the windows-x64 build host"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\installer" || _die "Failed to make installer directory in output.build directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\installer\\\\pgAgent" || _die "Failed to make installer/pgAgent directory in output.build directory"
    echo "copying application files into the output.build directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgAgent.windows-x64\\\\validateuser\\\\x64\\\\release\\\\validateuser.exe $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\installer\\\\pgAgent" || _die "Failed to copy the validateuser proglet on the windows-x64 build host"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgAgent.windows-x64\\\\createuser\\\\x64\\\\release\\\\createuser.exe $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\installer\\\\pgAgent" || _die "Failed to copy a createuser.exe on the windows build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgAgent.windows-x64\\\\CreatePGPassconfForUser\\\\x64\\\\release\\\\CreatePGPassconfForUser.exe $PG_PATH_WINDOWS_X64\\\\pgAgent.output.build\\\\installer\\\\pgAgent" || _die "Failed to copy a CreatePGPassconfForUser.exe on the windows build host"

    #ssh $PG_SSH_WINDOWS_X64 "cmd /c copy /Y $PG_PGBUILD_WINDOWS_X64\\\\vcredist\\\\vcredist_x86.exe $OUTPUT_DIR" || _die "Failed to copy the VC++ runtimes on the windows-x64 build host"
 
    echo "Removing last successful staging directory ($PG_PATH_WINDOWS_X64\\\\pgAgent.output)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgAgent.output rd /S /Q pgAgent.output" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgAgent.output" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c xcopy /E /Q /Y pgAgent.output.build\\\\* pgAgent.output\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_VERSION_PGAGENT=$PG_VERSION_PGAGENT > $PG_PATH_WINDOWS_X64\\\\pgAgent.output/versions-windows-x64.sh" || _die "Failed to write pgAgent version number into versions-windows-x64.sh"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_BUILDNUM_PGAGENT=$PG_BUILDNUM_PGAGENT >> $PG_PATH_WINDOWS_X64\\\\pgAgent.output/versions-windows-x64.sh" || _die "Failed to write pgAgent build number into versions-windows-x64.sh"
    
    echo "END BUILD pgAgent Windows"
    exit
}


################################################################################
# pgAgent Post Process
################################################################################

_postprocess_pgAgent_windows_x64() {
    
    echo "BEGIN POST pgAgent Windows"    

    echo "#####################################"
    echo "# pgAgent : WIN : Post Process      #"
    echo "#####################################"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/pgAgent/staging/windows-x64)"
    mkdir -p $WD/pgAgent/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgAgent/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    cd $WD/pgAgent/staging/windows-x64
    echo "Copying built tree to Windows host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgagent_output.zip del /S /Q pgagent_output.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\\pgagent_output.zip on Windows VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\pgAgent.output; cmd /c zip -r pgagent_output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64\\\\pgAgent.output)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64\\\\pgAgent.output\\\\pgagent_output.zip $WD/pgAgent/staging/windows-x64/pgagent_output.zip || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64\\\\pgAgent.output/pgagent_output.zip)"
    unzip -o $WD/pgAgent/staging/windows-x64/pgagent_output.zip -d $WD/pgAgent/staging/windows-x64 || _die "Failed to unpack the built source tree ($WD/pgAgent/staging/windows-x64/pgagent_output.zip)"
    rm -f $WD/pgAgent/staging/windows-x64/pgagent_output.zip

    dos2unix $WD/pgAgent/staging/windows-x64/versions-windows-x64.sh || _die "Failed to convert format of versions-windows-x64.sh from dos to unix"
    source $WD/pgAgent/staging/windows-x64/versions-windows-x64.sh
    PG_BUILD_PGAGENT=$(expr $PG_BUILD_PGAGENT + $SKIPBUILD)

    mkdir -p $WD/pgAgent/staging/windows-x64/pgAgent
    mv $WD/pgAgent/staging/windows-x64/bin $WD/pgAgent/staging/windows-x64/pgAgent
    mv $WD/pgAgent/staging/windows-x64/share $WD/pgAgent/staging/windows-x64/pgAgent

    #echo "Copying dependent libraries from the windows-x64 VM to staging directory"
    #scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output/bin/psql.exe $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy psql.exe"
    #scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output/bin/libpq.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy the dependent dll (libpq.dll)"
    #scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/bin/ssleay32.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy the dependent dll (ssleay32.dll)"
    #scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64//bin/libeay32.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy the dependent dll (libeay32.dll)"
    #scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/bin/libiconv-2.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy the dependent dll (libiconv-2.dll)"
    #scp $PG_SSH_WINDOWS_X64:$PG_PGBUILD_WINDOWS_X64/bin/libintl-8.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy the dependent dll (libintl-8.dll)"
    #scp $PG_SSH_WINDOWS_X64:$PG_WXWIN_WINDOWS/lib/vc_dll/wxbase28u_vc_custom.dll $WD/pgAgent/staging/windows-x64/bin || _die "Failed to copy a dependency DLL on the windows-x64 build host (wxbase28u_vc_custom.dll)"
    # Setup the installer scripts
    #mkdir -p $WD/pgAgent/staging/windows-x64/installer/pgAgent || _die "Failed to create a directory for the install scripts"
    #cp -f $WD/pgAgent/staging/windows-x64/validateuser.exe $WD/pgAgent/staging/windows-x64/installer/pgAgent/ || _die "Failed to copy validateuser.exe (staging/windows-x64/validateuser.exe)"
    #cp -f $WD/pgAgent/staging/windows-x64/createuser.exe $WD/pgAgent/staging/windows-x64/installer/pgAgent/ || _die "Failed to copy createuser.exe (staging/windows-x64/createuser.exe)"

    # Copy scripts into staging directory
    #cp -f $WD/pgAgent/scripts/windows-x64/*.bat $WD/pgAgent/staging/windows-x64/installer/pgAgent/ || _die "Failed to copy the install scripts (scripts/windows-x64/*.bat)"
    chmod ugo+x $WD/pgAgent/staging/windows-x64/installer/pgAgent/*
    cd $WD/pgAgent
 
    pushd staging/windows-x64
    generate_3rd_party_license "pgAgent"
    popd
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows --setvars windowsArchitecture=x64 || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $PG_BUILD_PGAGENT -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    # Rename the installer
    mv $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-windows-x64.exe $WD/output/pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}windows-x64.exe

	# Sign the installer
	win32_sign "pgagent-pg$PG_CURRENT_VERSION-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-${BUILD_FAILED}windows-x64.exe"
	
    cd $WD

    echo "END POST pgAgent Windows"

}


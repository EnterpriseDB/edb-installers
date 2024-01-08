#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.windows ];
    then
      echo "Removing existing edbmtk.windows source directory"
      rm -rf edbmtk.windows  || _die "Couldn't remove the existing edbmtk.windows source directory (source/edbmtk.windows)"
    fi

    if [ -f $WD/edbmtk/source/mw-build.bat ]; then
      rm -rf $WD/edbmtk/source/mw-build.bat
    fi

    if [ -f $WD/edbmtk/source/edbmtk.zip ]; then
      rm -rf $WD/edbmtk/source/edbmtk.zip
    fi

    echo "Creating edbmtk source directory ($WD/edbmtk/source/edbmtk.windows)"
    mkdir -p edbmtk.windows || _die "Couldn't create the edbmtk.windows directory"
    cp -R EDB-MTK/* edbmtk.windows || _die "Failed to copy the mtk source code"

    # Download edb-jdbc17.jar from redux store
    wget http://redux-store.ox.uk.enterprisedb.com/store/live_jdbc_jars/edb-jdbc17.jar
    mv edb-jdbc17.jar edbmtk.windows/lib || _die "Failed to copy edb-jdbc17.jar from redux store to source."

    chmod ugo+w edbmtk.windows || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$EDB_VERSION_PGJDBC/postgresql-$EDB_VERSION_PGJDBC.jdbc4.jar edbmtk.windows/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Grab a copy of the edbmtk source tree
    cp -R EDB-MTK/* edbmtk.windows || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w edbmtk.windows || _die "Couldn't set the permissions on the source directory"

    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST dbserver_guid_mtk rd /S /Q dbserver_guid_mtk" || _die "Couldn't remove the dbserver_guid_mtk"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST dbserver_guid.zip del /S /Q dbserver_guid.zip" || _die "Couldn't remove the $EDB_PATH_WINDOWS\\dbserver_guid.zip on Windows VM"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/windows)"
    mkdir -p $WD/edbmtk/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/windows || _die "Couldn't set the permissions on the staging directory"
}

################################################################################
# PG Build
################################################################################

build_edbmtk_Windows32(){
    zip -r edbmtk.zip edbmtk.windows || _die "Failed to pack the source tree (edbmtk.windows)"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST \"edbmtk.zip\" del /q edbmtk.zip" || _die "Failed to remove the source tree on the windows build host (edbmtk.zip)"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST \"mw-build.bat\" del /q mw-build.bat" || _die "Failed to remove the build script (mw-build.bat)"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST \"edbmtk.windows\" rd /s /q edbmtk.windows" || _die "Failed to remove the source tree on the windows build host (edbmtk.windows)"

    scp edbmtk.zip $EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (edbmtk.zip)"
    scp mw-build.bat $EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS || _die "Failed to copy the build script to windows VM (mw-build.bat)"


    echo "Building edbmtk"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c mw-build.bat" || _die "Couldn't build the edbmtk"
}

_build_edbmtk_windows() {

    echo ############################################
    echo # Build Migration ToolKit (windows)
    echo ############################################

    # build edbmtk    
    EDB_STAGING=$EDB_PATH_WINDOWS

    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/edbmtk/source/
    cat <<EOT > "mw-build.bat"

@SET JAVA_HOME=$EDB_JAVA_HOME_WINDOWS

cd "$EDB_PATH_WINDOWS"
SET SOURCE_PATH=%CD%
SET JAVA_HOME=$EDB_JAVA_HOME_WINDOWS
REM Extracting edbmtk sources
if NOT EXIST "edbmtk.zip" GOTO zip-not-found
unzip edbmtk.zip

echo Building edbmtk...
cd "%SOURCE_PATH%\\edbmtk.windows"
cmd /c $EDB_ANT_WINDOWS\\bin\\ant clean
cmd /c $EDB_ANT_WINDOWS\\bin\\ant install-as
  
cd %SOURCE_PATH%\\edbmtk.windows

cmd /c del /q install\\bin\\*.sh

REM cmd /c del /q install\\lib\\postgresql-*.jdbc4.jar

REM zip -r dist.zip install
echo "Build operation completed successfully"
goto end

:OnError
   echo %ERRORMSG%

:end

EOT

cat <<EOT > "vc-build-utilities.bat"
REM Setting Visual Studio Environment
CALL "$EDB_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

IF "%2" == "UPGRADE" GOTO upgrade

msbuild %1 /p:Configuration=%2
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT


echo "Copying source tree to Windows build VM"

    #Build components
    build_components "$COMPONENTS_WINDOWS_UNSUPPORTED" "$COMPONENTS_WINDOWS_DISABLED" "Windows32" "$PACKAGE"

    mkdir -p $WD/edbmtk/source/dbserver_guid_mtk
    cp -r $WD/server/scripts/windows/dbserver_guid/* cd $WD/edbmtk/source/dbserver_guid_mtk

    zip -r dbserver_guid.zip vc-build-utilities.bat dbserver_guid_mtk || _die "Failed to pack the scripts source tree (dbserver_guid_mtk)"
    scp dbserver_guid.zip $EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS || _die "Failed to copy the scripts source tree to the windows build host (dbserver_guid.zip)"
    rm -f dbserver_guid.zip
    rm -rf dbserver_guid_mtk

    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; unzip -o dbserver_guid.zip" || _die "Failed to unpack the scripts source tree on the windows build host (dbserver_guid.zip)"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS\\\\dbserver_guid_mtk; cmd /c $EDB_PATH_WINDOWS\\\\vc-build-utilities.bat dbserver_guid.vcxproj Release" || _die "Failed to build dbserver_guid on the windows build host"

    echo "Removing last successful staging directory ($EDB_PATH_WINDOWS/edbmtk.output)"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST edbmtk.output rd /S /Q edbmtk.output" || _die "Couldn't remove the $EDB_PATH_WINDOWS\\edbmtk.output directory on Windows VM"
    ssh $EDB_SSH_WINDOWS "cmd /c mkdir $EDB_PATH_WINDOWS\\\\edbmtk.output" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c xcopy /E /Q /Y edbmtk.windows\\\\install\\\\* edbmtk.output\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $EDB_SSH_WINDOWS "cmd /c echo EDB_VERSION_EDBMTK=$EDB_VERSION_EDBMTK > $EDB_PATH_WINDOWS\\\\edbmtk.output/versions-windows.sh" || _die "Failed to write edbmtk version number into versions-windows.sh"
    ssh $EDB_SSH_WINDOWS "cmd /c echo EDB_BUILDNUM_EDBMTK=$EDB_BUILDNUM_EDBMTK >> $EDB_PATH_WINDOWS\\\\edbmtk.output/versions-windows.sh" || _die "Failed to write edbmtk build number into versions-windows.sh"

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_windows() {
 
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/edbmtk/staging/windows)"
    mkdir -p $WD/edbmtk/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/windows || _die "Couldn't set the permissions on the staging directory"

    mkdir -p $WD/edbmtk/staging/windows/scripts
    scp $EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS/dbserver_guid_mtk/Release/dbserver_guid.exe $WD/edbmtk/staging/windows/scripts || _die "Failed to copy the dbserver_guid.exe (edbmtk/staging/windows/scripts)"

    mkdir -p $WD/edbmtk/staging/windows/installer/edbmtk
    scp $EDB_SSH_WINDOWS:$EDB_PGBUILD_WINDOWS/vcredist/vcredist_x86.exe $WD/edbmtk/staging/windows/installer/edbmtk || _die "Failed to copy the VC++ runtimes on the windows build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to host"
    ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS; cmd /c if EXIST edbmtk.output.zip del /S /Q edbmtk.output.zip" || _die "Couldn't remove the $EDB_PATH_WINDOWS\\edbmtk.output.zip on Windows VM"
   ssh $EDB_SSH_WINDOWS "cd $EDB_PATH_WINDOWS\\\\edbmtk.output; cmd /c zip -r ..\\\\edbmtk.output.zip *" || _die "Failed to pack the built source tree ($EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS/edbmtk.output)"
    scp $EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS/edbmtk.output.zip $WD/edbmtk/staging/windows || _die "Failed to copy the built source tree ($EDB_SSH_WINDOWS:$EDB_PATH_WINDOWS/edbmtk.output.zip)"
    unzip $WD/edbmtk/staging/windows/edbmtk.output.zip -d $WD/edbmtk/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/edbmtk.output.zip)"
    rm $WD/edbmtk/staging/windows/edbmtk.output.zip

    dos2unix $WD/edbmtk/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/edbmtk/staging/windows/versions-windows.sh
    EDB_BUILD_EDBMTK=$(expr $EDB_BUILD_EDBMTK + $SKIPBUILD)

    cd $WD/edbmtk

    pushd staging/windows
    generate_3rd_party_license "${EDBMTK_INSTALLER_NAME_PREFIX}"
    popd

    cp $WD/server/scripts/windows/installruntimes.vbs $WD/edbmtk/staging/windows/installer/edbmtk/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"

    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f1 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/windows/bin/runMTK.bat || _die "Failed to put $CORE_EDBMTK_VERSION in runMTK.bat"

    mkdir -p staging/windows/etc/sysconfig || _die "Failed to create etc/sysconfig directory"

    cp scripts/common/edbmtk.config.win staging/windows/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to create file edbmtk-$CORE_EDBMTK_VERSION.config"
    cp $WD/scripts/common_scripts/runJavaApplication.vbs staging/windows/etc/sysconfig/ || _die "Failed to copy runJavaApplication.vbs"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/windows/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to put CORE_EDBMTK_VERSION in edbmtk-$CORE_EDBMTK_VERSION.config"

    # Build the installer
    "$EDB_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $EDB_BUILD_EDBMTK -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    CMD_INSTALLER_NAME="$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-${BUILD_FAILED}windows.exe"

    echo "Installer_Name:$CMD_INSTALLER_NAME" >> $CMD_PRODUCT_INFO_LOG
    echo "Version:$CMD_INSTALLER_VERSION" >> $CMD_PRODUCT_INFO_LOG

    # Rename the installer
    mv $WD/output/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-windows.exe $WD/output/$CMD_INSTALLER_NAME

    if [ $SIGNING -eq 1 ]; then
        win32_sign "$CMD_INSTALLER_NAME"
    fi

    #Copy staging directory
    copy_binaries edbmtk windows

    cd $WD
}


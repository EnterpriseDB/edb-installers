#!/bin/bash

_registration_plus_preprocess_windows_x64()
{
  PG_REG_COMP_PLATFORM=windows-x64
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS_X64\\\\registration_plus

  if [ x"$PG_REGISTRATION_PLUS_COMP_BUILT_WIN_X64" = x"" ]; then
    echo "Removing registration_plus source directory ($PG_REG_COMP_PATH)"
    if [ -d $PG_REG_COMP_PATH ]; then
      rm -rf $PG_REG_COMP_PATH
    fi

    echo "Creating registration_plus source directory ($PG_REG_COMP_PATH)"
    mkdir -p $PG_REG_COMP_PATH

    echo "Removing registration_plus staging directory ($PG_REG_COMP_STAGING)"
    if [ -d $PG_REG_COMP_STAGING ]; then
      rm -rf $PG_REG_COMP_STAGING
    fi

    echo "Creating registration_plus staging directory ($PG_REG_COMP_STAGING)"
    mkdir -p $PG_REG_COMP_STAGING || _die "Failed to create staging directory (registration_plus-$PG_REG_COMP_PLATFORM)"
    chmod ugo+x $PG_REG_COMP_STAGING || _die "Couldn't set the permissions on the staging directory (registration_plus-$PG_REG_COMP_PLATFORM)"

    echo "Coyping utilities sources in registration_plus source directory..."
    echo cp -R $WD/resources/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/
    cp -R $WD/resources/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/ || _die "Failed to copy dbserver_guid sources (registration_plus-$PG_REG_COMP_PLATFORM)"

    echo "Removing registration_plus source directory on windows-x64 host (if any)..."
    ssh $PG_SSH_WINDOWS_X64 "cmd /c IF EXIST $PG_REG_COMP_HOST_PATH rd /s /q $PG_REG_COMP_HOST_PATH"

    echo "Creating registration_plus source directory on windows-x64 host..."
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_REG_COMP_HOST_PATH"

    cd $PG_REG_COMP_PATH
    echo "Copying  registration_plus component sources on windows-x64 host..."
    zip -r registration_plus.zip dbserver_guid 
    scp registration_plus.zip $PG_SSH_WINDOWS_X64:$PG_REG_COMP_HOST_PATH
    rm -f registration_plus.zip

    echo "Extracting registration_plus component sources on windows-x64 host..."
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_REG_COMP_HOST_PATH;  unzip registration_plus.zip"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c del /q $PG_REG_COMP_HOST_PATH\\\\registration_plus.zip"
  fi
}

_registration_plus_build_windows_x64()
{
  PG_REG_COMP_PLATFORM=windows-x64
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS_X64\\\\registration_plus

  cd $PG_REG_COMP_PATH

  if [ x"$PG_REGISTRATION_PLUS_COMP_BUILT_WIN_X64" = x"" ]; then
    cat<<EOT > build-reg-comp.bat
@ECHO OFF
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

cd $PG_REG_COMP_HOST_PATH\\dbserver_guid
devenv /upgrade dbserver_guid.vcproj
msbuild dbserver_guid.vcxproj /p:Configuration=Release
if NOT EXIST $PG_REG_COMP_HOST_PATH\\dbserver_guid\\release\\dbserver_guid.exe GOTO dbserver_guid-build-failed

GOTO end

:dbserver_guid-build-failed
  echo Couldn't build dbserver_guid...
  exit 1

:end
  echo %0 ran successfully
  exit 0

EOT

    scp build-reg-comp.bat $PG_SSH_WINDOWS_X64:$PG_REG_COMP_HOST_PATH
    rm -f build-reg-comp.bat
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_REG_COMP_HOST_PATH; cmd /c build-reg-comp.bat" || _die "Building registration_plus component failed..."

    scp $PG_SSH_WINDOWS_X64:$PG_REG_COMP_HOST_PATH\\\\dbserver_guid\\\\release\\\\dbserver_guid.exe     $PG_REG_COMP_STAGING/dbserver_guid.exe || _die "Failed to get dbserver_guid utility from the windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy \"$PG_SDK_WINDOWS_X64\\\\Bootstrapper\\\\Packages\\\\vcredist_x64\\\\vcredist_x64.exe\" $PG_REG_COMP_HOST_PATH\\\\dbserver_guid\\\\release" || _die "Failed to copy the VC++ runtimes on the windows build host"
    scp $PG_SSH_WINDOWS_X64:$PG_REG_COMP_HOST_PATH\\\\dbserver_guid\\\\release\\\\vcredist_x64.exe     $PG_REG_COMP_STAGING/vcredist_x64.exe || _die "Failed to get vc++ runtimes from the windows VM"

    PG_REGISTRATION_PLUS_COMP_BUILT_WIN_X64=Done
  fi
}

_registration_plus_postprocess_windows_x64()
{
  if [ $# -ne 1 ]; then
    _die "Wrong number of parameters while calling _registration_plus_postprocess_linux (STAGING DIRECTORY)"
  fi

  PG_REG_COMP_PLATFORM=windows-x64
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM

  cp $1/registration_plus_component.xml $1/registration_plus_component_windows_x64.xml
  cp $1/registration_plus_preinstallation.xml  $1/registration_plus_preinstallation_windows_x64.xml
  _replace "@@WINDIR@@" "windows-x64" $1/registration_plus_component_windows_x64.xml
  _replace "@@WINDIR@@" "windows-x64" $1/registration_plus_preinstallation_windows_x64.xml
  
  if [ ! -d $1/$PG_REG_COMP_PLATFORM/UserValidation ]; then
    mkdir -p $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Failed to create UserValidation in staging directory ($1/$PG_REG_COMP_PLATFORM/UserValidation)"
  fi
  chmod ugo+x $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Couldn't set the permissions on the UserValidation directory"

  cp -rf $PG_REG_COMP_STAGING/* $1/$PG_REG_COMP_PLATFORM/UserValidation

}
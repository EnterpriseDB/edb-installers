#!/bin/bash

_registration_plus_preprocess_windows()
{
  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS\\\\registration_plus

  if [ x"$PG_REGISTRATION_PLUS_COMP_BUILT_WIN" = x"" ]; then
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
    echo cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/
    cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/ || _die "Failed to copy dbserver_guid sources (registration_plus-$PG_REG_COMP_PLATFORM)"

    echo "Removing registration_plus source directory on windows host (if any)..."
    ssh $PG_SSH_WINDOWS "cmd /c IF EXIST $PG_REG_COMP_HOST_PATH rd /s /q $PG_REG_COMP_HOST_PATH"

    echo "Creating registration_plus source directory on windows host..."
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_REG_COMP_HOST_PATH"

    cd $PG_REG_COMP_PATH
    echo "Copying  registration_plus component sources on windows host..."
    zip -r registration_plus.zip dbserver_guid 
    scp registration_plus.zip $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH
    rm -f registration_plus.zip

    echo "Extracting registration_plus component sources on windows host..."
    ssh $PG_SSH_WINDOWS "cd $PG_REG_COMP_HOST_PATH;  unzip registration_plus.zip"
    ssh $PG_SSH_WINDOWS "cmd /c del /q $PG_REG_COMP_HOST_PATH\\\\registration_plus.zip"
  fi
}

_registration_plus_build_windows()
{
  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS\\\\registration_plus

  cd $PG_REG_COMP_PATH

  if [ x"$PG_REGISTRATION_PLUS_COMP_BUILT_WIN" = x"" ]; then
    cat<<EOT > build-reg-comp.bat
@ECHO OFF
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

cd $PG_REG_COMP_HOST_PATH\\dbserver_guid
vcbuild /upgrade
vcbuild dbserver_guid.vcproj release
if NOT EXIST $PG_REG_COMP_HOST_PATH\\dbserver_guid\\release\\dbserver_guid.exe GOTO dbserver_guid-build-failed

GOTO end

:dbserver_guid-build-failed
  echo Couldn't build dbserver_guid...
  exit 1

:end
  echo %0 ran successfully
  exit 0

EOT

    scp build-reg-comp.bat $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH
    rm -f build-reg-comp.bat
    ssh $PG_SSH_WINDOWS "cd $PG_REG_COMP_HOST_PATH; cmd /c build-reg-comp.bat" || _die "Building registration_plus component failed..."

    scp $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH\\\\dbserver_guid\\\\release\\\\dbserver_guid.exe     $PG_REG_COMP_STAGING/dbserver_guid.exe || _die "Failed to get dbserver_guid utility from the windows VM"
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe     $PG_REG_COMP_STAGING/vcredist_x86.exe || _die "Failed to get vcredist_x86.exe utility from the windows VM"

    PG_REGISTRATION_PLUS_COMP_BUILT_WIN=Done
  fi
}

_registration_plus_postprocess_windows()
{
  if [ $# -ne 1 ]; then
    _die "Wrong number of parameters while calling _registration_plus_postprocess_linux (STAGING DIRECTORY)"
  fi

  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_STAGING=$WD/registration_plus/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_PATH=$WD/registration_plus/source/$PG_REG_COMP_PLATFORM

  cp $1/registration_plus_component.xml $1/registration_plus_component_windows.xml   
  cp $1/registration_plus_preinstallation.xml $1/registration_plus_preinstallation_windows.xml   
  _replace "@@WINDIR@@" "windows" $1/registration_plus_component_windows.xml
  _replace "@@WINDIR@@" "windows" $1/registration_plus_preinstallation_windows.xml

  if [ ! -d $1/$PG_REG_COMP_PLATFORM/UserValidation ]; then
    mkdir -p $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Failed to create UserValidation in staging directory ($1/$PG_REG_COMP_PLATFORM/UserValidation)"
  fi
  chmod ugo+x $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Couldn't set the permissions on the UserValidation directory"

  cp -rf $PG_REG_COMP_STAGING/* $1/$PG_REG_COMP_PLATFORM/UserValidation

}

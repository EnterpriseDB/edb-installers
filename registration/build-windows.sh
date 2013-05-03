#!/bin/bash

_registration_preprocess_windows()
{
  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS\\\\registration

  if [ x"$PG_REGISTRATION_COMP_BUILT_WIN" = x"" ]; then
    echo "Removing registration source directory ($PG_REG_COMP_PATH)"
    if [ -d $PG_REG_COMP_PATH ]; then
      rm -rf $PG_REG_COMP_PATH
    fi

    echo "Creating registration source directory ($PG_REG_COMP_PATH)"
    mkdir -p $PG_REG_COMP_PATH

    echo "Removing registration staging directory ($PG_REG_COMP_STAGING)"
    if [ -d $PG_REG_COMP_STAGING ]; then
      rm -rf $PG_REG_COMP_STAGING
    fi

    echo "Creating registration staging directory ($PG_REG_COMP_STAGING)"
    mkdir -p $PG_REG_COMP_STAGING || _die "Failed to create staging directory (registration-$PG_REG_COMP_PLATFORM)"
    chmod ugo+x $PG_REG_COMP_STAGING || _die "Couldn't set the permissions on the staging directory (registration-$PG_REG_COMP_PLATFORM)"

    echo "Coyping utilities sources in registration source directory..."
    echo cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/
    cp -R $WD/MetaInstaller/scripts/windows/dbserver_guid/dbserver_guid/dbserver_guid $PG_REG_COMP_PATH/ || _die "Failed to copy dbserver_guid sources (registration-$PG_REG_COMP_PLATFORM)"
    echo cp -R $WD/resources/validateUser.windows $PG_REG_COMP_PATH/
    cp -R $WD/resources/validateUser.windows $PG_REG_COMP_PATH/ || _die "Failed to copy validateUser.windows sources (registration-$PG_REG_COMP_PLATFORM)"

    echo "Removing registration source directory on windows host (if any)..."
    ssh $PG_SSH_WINDOWS "cmd /c IF EXIST $PG_REG_COMP_HOST_PATH rd /s /q $PG_REG_COMP_HOST_PATH"

    echo "Creating registration source directory on windows host..."
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_REG_COMP_HOST_PATH"

    cd $PG_REG_COMP_PATH
    echo "Copying  registration component sources on windows host..."
    zip -r registration.zip dbserver_guid validateUser.windows
    scp registration.zip $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH
    rm -f registration.zip

    echo "Extracting registration component sources on windows host..."
    ssh $PG_SSH_WINDOWS "cd $PG_REG_COMP_HOST_PATH;  unzip registration.zip"
    ssh $PG_SSH_WINDOWS "cmd /c del /q $PG_REG_COMP_HOST_PATH\\\\registration.zip"
  fi
}

_registration_build_windows()
{
  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_WINDOWS\\\\registration

  cd $PG_REG_COMP_PATH

  if [ x"$PG_REGISTRATION_COMP_BUILT_WIN" = x"" ]; then
    echo "Building validateUserClient utility for registration($PG_REG_COMP_PLATFORM)..."

    cat<<EOT > build-reg-comp.bat
@ECHO OFF
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

cd $PG_REG_COMP_HOST_PATH\\dbserver_guid
vcbuild /upgrade
vcbuild dbserver_guid.vcproj release
if NOT EXIST $PG_REG_COMP_HOST_PATH\\dbserver_guid\\release\\dbserver_guid.exe GOTO dbserver_guid-build-failed

cd $PG_REG_COMP_HOST_PATH\\validateUser.windows
vcbuild /upgrade
vcbuild validateUser.vcproj release
if NOT EXIST $PG_REG_COMP_HOST_PATH\\validateUser.windows\\release\\validateUserClient.exe GOTO validateuser-build-failed
GOTO end

:dbserver_guid-build-failed
  echo Couldn't build dbserver_guid...
  exit 1

:validateuser-build-failed
  echo Couldn't build validateUserClient...
  exit 1

:end
  echo %0 ran successfully
  exit 0

EOT

    scp build-reg-comp.bat $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH
    rm -f build-reg-comp.bat
    ssh $PG_SSH_WINDOWS "cd $PG_REG_COMP_HOST_PATH; cmd /c build-reg-comp.bat" || _die "Building registration component failed..."

    scp $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH\\\\dbserver_guid\\\\release\\\\dbserver_guid.exe     $PG_REG_COMP_STAGING/dbserver_guid.exe || _die "Failed to get dbserver_guid utility from the windows VM"
    scp $PG_SSH_WINDOWS:$PG_REG_COMP_HOST_PATH\\\\validateUser.windows\\\\release\\\\validateUserClient.exe $PG_REG_COMP_STAGING/validateUserClient.exe || _die "Failed to get validateUser utility from the windows VM"

    PG_REGISTRATION_COMP_BUILT_WIN=Done
  fi
}

_registration_postprocess_windows()
{
  if [ $# -ne 1 ]; then
    _die "Wrong number of parameters while calling _registration_postprocess_linux (STAGING DIRECTORY)"
  fi

  PG_REG_COMP_PLATFORM=windows
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM

  if [ ! -d $1/$PG_REG_COMP_PLATFORM/UserValidation ]; then
    mkdir -p $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Failed to create UserValidation in staging directory ($1/$PG_REG_COMP_PLATFORM/UserValidation)"
  fi
  chmod ugo+x $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Couldn't set the permissions on the UserValidation directory"

  cp -rf $PG_REG_COMP_STAGING/* $1/$PG_REG_COMP_PLATFORM/UserValidation

}

#!/bin/bash

_registration_preprocess_linux()
{
  PG_REG_COMP_PLATFORM=linux
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM

  if [ x"$PG_REGISTRATION_COMP_BUILT_LINUX" = x"" ]; then
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
    mkdir -p $PG_REG_COMP_STAGING || _die "Failed to create staging directory for registration ($PG_REG_COMP_PLATFORM)"
    mkdir -p $PG_REG_COMP_STAGING/lib || _die "Failed to create lib directory for registration ($PG_REG_COMP_PLATFORM)"
    chmod ugo+x $PG_REG_COMP_STAGING/lib || _die "Couldn't set the permissions on the lib directory for registration component ($PG_REG_COMP_PLATFORM)"

    echo "Coyping validateUser source in registration source directory..."
    cp -R $WD/resources/validateUser/* $PG_REG_COMP_PATH/ || _die "Failed to copy validateUser source files"
  fi
}

_registration_build_linux()
{
  PG_REG_COMP_PLATFORM=linux
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_LINUX/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_STAGING=$PG_PATH_LINUX/registration/staging/$PG_REG_COMP_PLATFORM

  cd $PG_REG_COMP_PATH

  if [ x"$PG_REGISTRATION_COMP_BUILT_LINUX" = x"" ]; then
    echo "Building validateUserClient utility for registration..."
    ssh $PG_SSH_LINUX "cd $PG_REG_COMP_HOST_PATH; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility for registration component"

    cp $PG_REG_COMP_PATH/validateUserClient.o $PG_REG_COMP_STAGING/ || _die "Failed to copy the validateUserClient to staging directory"
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_REG_COMP_HOST_STAGING/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_REG_COMP_HOST_STAGING/lib" || _die "Failed to copy the dependency library (libcrypto)"

    chmod ugo+x $PG_REG_COMP_STAGING/validateUserClient.o || _die "Couldn't set the permissions on the validateUserClient($PG_REG_COMP_PLATFORM)"
    chmod ugo+x $PG_REG_COMP_STAGING/lib/* || _die "Couldn't set the permissions on the dependent libraries for validateUserClient"
    PG_REGISTRATION_COMP_BUILT_LINUX=Done
  fi
}

_registration_postprocess_linux()
{
  if [ $# -ne 1 ]; then
    _die "Wrong number of parameters while calling _registration_postprocess_linux (STAGING DIRECTORY)"
  fi

  PG_REG_COMP_PLATFORM=linux
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM

  if [ ! -d $1/$PG_REG_COMP_PLATFORM/UserValidation ]; then
    mkdir -p $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Failed to create UserValidation in staging directory ($1/$PG_REG_COMP_PLATFORM/UserValidation)"
  fi
  chmod ugo+x $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Couldn't set the permissions on the UserValidation directory"

  cp -rf $PG_REG_COMP_STAGING/* $1/$PG_REG_COMP_PLATFORM/UserValidation

}

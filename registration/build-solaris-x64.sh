#!/bin/bash

_registration_preprocess_solaris_x64()
{
  PG_REG_COMP_PLATFORM=solaris-x64
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM

  if [ x"$PG_REGISTRATION_COMP_BUILT_SOLARIS_X64" = x"" ]; then
    echo "Removing registration source directory ($PG_REG_COMP_PATH)"
    if [ -d $PG_REG_COMP_PATH ]; then
      rm -rf $PG_REG_COMP_PATH
      ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/registration/source/$PG_REG_COMP_PLATFORM"|| _die "Failed to create lib directory for registration ($PG_REG_COMP_PLATFORM)"
    fi

    if [ -e $PG_REG_COMP_PATH/registration.zip ]; then
       rm -f $PG_REG_COMP_PATH/registration.zip
    fi

    echo "Creating registration source directory ($PG_REG_COMP_PATH)"
    mkdir -p $PG_REG_COMP_PATH
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/registration/source/$PG_REG_COMP_PLATFORM"|| _die "Failed to create lib directory for registration ($PG_REG_COMP_PLATFORM)"

    echo "Removing registration staging directory ($PG_REG_COMP_STAGING)"
    if [ -d $PG_REG_COMP_STAGING ]; then
      rm -rf $PG_REG_COMP_STAGING
      ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/registration/staging/$PG_REG_COMP_PLATFORM"|| _die "Failed to create lib directory for registration ($PG_REG_COMP_PLATFORM)"
    fi

    echo "Creating registration staging directory ($PG_REG_COMP_STAGING)"
    mkdir -p $PG_REG_COMP_STAGING || _die "Failed to create staging directory for registration ($PG_REG_COMP_PLATFORM)"
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/registration/staging/$PG_REG_COMP_PLATFORM/lib "|| _die "Failed to create lib directory for registration ($PG_REG_COMP_PLATFORM)"
    ssh $PG_SSH_SOLARIS_X64 "chmod ugo+x $PG_PATH_SOLARIS_X64/registration/staging/$PG_REG_COMP_PLATFORM/lib" || _die "Couldn't set the permissions on the lib directory for registration component ($PG_REG_COMP_PLATFORM)"

    echo "Coyping validateUser source in registration source directory..."
    cp -R $WD/MetaInstaller/scripts/solaris-x64/validateUser/* $PG_REG_COMP_PATH/ || _die "Failed to copy validateUser source files"
    cd $PG_REG_COMP_PATH
    zip -r registration.zip *
    scp registration.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/registration/source/$PG_REG_COMP_PLATFORM/
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/registration/source/$PG_REG_COMP_PLATFORM/; unzip registration.zip" || _die "Failed to unzip the registration source directory"

  fi
}

_registration_build_solaris_x64()
{
  PG_REG_COMP_PLATFORM=solaris-x64
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_PATH=$PG_PATH_SOLARIS_X64/registration/source/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_HOST_STAGING=$PG_PATH_SOLARIS_X64/registration/staging/$PG_REG_COMP_PLATFORM

  cd $PG_REG_COMP_PATH

  if [ x"$PG_REGISTRATION_COMP_BUILT_SOLARIS_X64" = x"" ]; then
    echo "Building validateUserClient utility for registration..."
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_REG_COMP_HOST_PATH; PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH gcc -m64 -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto -lnsl -lsocket" || _die "Failed to build the validateUserClient utility for registration component"

    ssh $PG_SSH_SOLARIS_X64 "cp $PG_REG_COMP_HOST_PATH/validateUserClient.o $PG_REG_COMP_HOST_STAGING/" || _die "Failed to copy the validateUserClient to staging directory"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libssl.so* $PG_REG_COMP_HOST_STAGING/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libcrypto.so* $PG_REG_COMP_HOST_STAGING/lib/" || _die "Failed to copy the dependency library (libcrypto)"

    scp $PG_SSH_SOLARIS_X64:$PG_REG_COMP_HOST_PATH/validateUserClient.o $PG_REG_COMP_STAGING/ || _die "Failed to copy back the staging directory from Solaris VM"
    scp -r $PG_SSH_SOLARIS_X64:$PG_REG_COMP_HOST_STAGING/lib $PG_REG_COMP_STAGING/ || _die "Failed to copy back the staging directory from Solaris VM"

    chmod ugo+x $PG_REG_COMP_STAGING/validateUserClient.o || _die "Couldn't set the permissions on the validateUserClient($PG_REG_COMP_PLATFORM)"
    chmod ugo+x $PG_REG_COMP_STAGING/lib/* || _die "Couldn't set the permissions on the dependent libraries for validateUserClient"
    PG_REGISTRATION_COMP_BUILT_SOLARIS_X64=Done
  fi
}

_registration_postprocess_solaris_x64()
{
  if [ $# -ne 1 ]; then
    _die "Wrong number of parameters while calling _registration_postprocess_solaris_x64 (STAGING DIRECTORY)"
  fi

  PG_REG_COMP_PLATFORM=solaris-x64
  PG_REG_COMP_STAGING=$WD/registration/staging/$PG_REG_COMP_PLATFORM
  PG_REG_COMP_PATH=$WD/registration/source/$PG_REG_COMP_PLATFORM

  if [ ! -d $1/$PG_REG_COMP_PLATFORM/UserValidation ]; then
    mkdir -p $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Failed to create UserValidation in staging directory ($1/$PG_REG_COMP_PLATFORM/UserValidation)"
  fi
  chmod ugo+x $1/$PG_REG_COMP_PLATFORM/UserValidation || _die "Couldn't set the permissions on the UserValidation directory"

  cp -rf $PG_REG_COMP_STAGING/* $1/$PG_REG_COMP_PLATFORM/UserValidation

}

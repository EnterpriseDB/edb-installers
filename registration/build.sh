#!/bin/bash

# Read the various build scripts
PG_REGISTRATION_PATH=$WD/registration

# Mac OS X
if [ $PG_ARCH_OSX = 1 ];
then
    source $PG_REGISTRATION_PATH/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $PG_REGISTRATION_PATH/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $PG_REGISTRATION_PATH/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $PG_REGISTRATION_PATH/build-windows.sh
fi

_registration_component_build()
{
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ];
    then
        _registration_preprocess_osx || exit 1
        _registration_build_osx    || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _registration_preprocess_linux || exit 1
        _registration_build_linux      || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _registration_preprocess_linux_x64 || exit 1
        _registration_build_linux_x64      || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _registration_preprocess_windows || exit 1
        _registration_build_windows      || exit 1
    fi

}

_registration_postprocess()
{
  if [ $# -ne 8 ]; then
    _die "Wrong number of parameters calling _registration_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX WINDOWS, TEMP DIRECTORY, COMONENT TYPE)"
  fi

  PG_REG_COMP_PATH=$WD/registration
  REG_XML_FILES="already_registered_parameter authentication_parameter component postinstallation preinstallation preuninstallation initialization"

  cd $1

  for REG_FILE in $REG_XML_FILES
  do
    # Remove existing file before copying new one
    rm -f $REG_FILE.xml
    cp $PG_REG_COMP_PATH/$REG_FILE.xml.in registration_$REG_FILE.xml
  done

  # registration parameter (already_registered_parameter.xml)
  _replace @@COMPTYPE@@  "$8" registration_already_registered_parameter.xml
  _replace @@COMPONENT@@ "$2" registration_already_registered_parameter.xml

  # Authentication parameter (authentication_parameter.xml)
  _replace @@COMPONENT@@ "$2" registration_authentication_parameter.xml
  _replace @@TEMPDIR@@   "$7" registration_authentication_parameter.xml

  # Registration Component (component.xml)
  _replace @@TEMPDIR@@   "$7" registration_component.xml

  # post-installation actions list (postinstallation.xml)
  _replace @@REGISTRY_INI@@        "$4" registration_postinstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_postinstallation.xml
  _replace @@REGISTRY_PREFIX_WIN@@ "$6" registration_postinstallation.xml
  _replace @@TEMPDIR@@             "$7" registration_postinstallation.xml

  # pre-installation actions list (preinstallation.xml)
  _replace @@COMPONENT@@           "$2" registration_preinstallation.xml
  _replace @@COMPONENT_VERSION@@   "$3" registration_preinstallation.xml
  _replace @@REGISTRY_INI@@        "$4" registration_preinstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_preinstallation.xml
  _replace @@REGISTRY_PREFIX_WIN@@ "$6" registration_preinstallation.xml
  _replace @@TEMPDIR@@             "$7" registration_preinstallation.xml

  # pre-uninstallation actions list (preuninstallation.xml)
  _replace @@REGISTRY_INI@@        "$4" registration_preuninstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_preuninstallation.xml

  # Mac OSX
  if [ $PG_ARCH_OSX = 1 ]; 
  then
    _registration_postprocess_osx $1
  fi

  # Linux
  if [ $PG_ARCH_LINUX = 1 ];
  then
    _registration_postprocess_linux $1
  fi

  # Linux x64
  if [ $PG_ARCH_LINUX_X64 = 1 ];
  then
    _registration_postprocess_linux_x64 $1
  fi
  
  # Windows
  if [ $PG_ARCH_WINDOWS = 1 ];
  then
    _registration_postprocess_windows $1
  fi

}


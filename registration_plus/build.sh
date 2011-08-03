#!/bin/bash

# Read the various build scripts
PG_REGISTRATION_PLUS_PATH=$WD/registration_plus

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $PG_REGISTRATION_PLUS_PATH/build-windows.sh
fi

# Windows-x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    source $PG_REGISTRATION_PLUS_PATH/build-windows-x64.sh
fi

_registration_plus_component_build()
{
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _registration_plus_preprocess_windows || exit 1
        _registration_plus_build_windows      || exit 1
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        _registration_plus_preprocess_windows_x64 || exit 1
        _registration_plus_build_windows_x64      || exit 1
    fi

}

_registration_plus_postprocess()
{
  if [ $# -ne 9 ]; then
    _die "Wrong number of parameters calling _registration_plus_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX WINDOWS, TEMP DIRECTORY, PRODUCT_DESCRIPTION, PRODUCT_VERSION)"
  fi

  PG_REG_COMP_PATH=$WD/registration_plus
  REG_XML_FILES="already_registered_parameter authentication_parameter component postinstallation preinstallation preuninstallation initialization"

  cd $1

  for REG_FILE in $REG_XML_FILES
  do
    # Remove existing file before copying new one
    rm -f $REG_FILE.xml
    cp $PG_REG_COMP_PATH/$REG_FILE.xml.in registration_plus_$REG_FILE.xml
  done

  # registration_plus parameter (already_registered_parameter.xml)
  _replace @@COMPONENT@@ "$2" registration_plus_already_registered_parameter.xml

  # Authentication parameter (authentication_parameter.xml)
  _replace @@COMPONENT@@ "$2" registration_plus_authentication_parameter.xml
  _replace @@TEMPDIR@@   "$7" registration_plus_authentication_parameter.xml
  _replace PRODUCT_DESCRIPTION   "$8" registration_plus_authentication_parameter.xml
  _replace PRODUCT_VERSION   "$9" registration_plus_authentication_parameter.xml
  _replace BASE_URL	      $BASE_URL  registration_plus_authentication_parameter.xml 

  # Registration Component (component.xml)
  _replace @@TEMPDIR@@   "$7" registration_plus_component.xml

  # post-installation actions list (postinstallation.xml)
  _replace @@REGISTRY_INI@@        "$4" registration_plus_postinstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_plus_postinstallation.xml
  _replace @@REGISTRY_PREFIX_WIN@@ "$6" registration_plus_postinstallation.xml
  _replace @@TEMPDIR@@             "$7" registration_plus_postinstallation.xml

  # pre-installation actions list (preinstallation.xml)
  _replace @@COMPONENT@@           "$2" registration_plus_preinstallation.xml
  _replace @@COMPONENT_VERSION@@   "$3" registration_plus_preinstallation.xml
  _replace @@REGISTRY_INI@@        "$4" registration_plus_preinstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_plus_preinstallation.xml
  _replace @@REGISTRY_PREFIX_WIN@@ "$6" registration_plus_preinstallation.xml
  _replace @@TEMPDIR@@             "$7" registration_plus_preinstallation.xml
  _replace PRODUCT_DESCRIPTION     "$8" registration_plus_preinstallation.xml
  _replace PRODUCT_VERSION         "$9" registration_plus_preinstallation.xml
  _replace BASE_URL          $BASE_URL   registration_plus_preinstallation.xml

  # pre-uninstallation actions list (preuninstallation.xml)
  _replace @@REGISTRY_INI@@        "$4" registration_plus_preuninstallation.xml
  _replace @@REGISTRY_PREFIX@@     "$5" registration_plus_preuninstallation.xml

  # Windows
  if [ $PG_ARCH_WINDOWS = 1 ];
  then
    _registration_plus_postprocess_windows $1
  fi

  # Windows-x64
  if [ $PG_ARCH_WINDOWS_X64 = 1 ];
  then
    _registration_plus_postprocess_windows_x64 $1
  fi

}


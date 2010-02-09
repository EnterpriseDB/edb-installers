#!/bin/bash

# PostgreSQL Installer build system
# Dave Page, EnterpriseDB

# Common utilties
source ./common.sh

# Package Versions 
source ./versions.sh

# Get the build settings
if [ ! -f ./settings.sh ];
then
  _die "The is no settings.sh file present. Please copy settings.sh.in and edit as required before rebuilding."
fi
source ./settings.sh

################################################################################
# Initialise the build system
################################################################################
_init() {

    # Grab the working directory
    WD=`pwd`
    
    # Set the package versions string
    PG_PACKAGE_VERSION=$PG_MAJOR_VERSION.`echo $PG_MINOR_VERSION | sed -e 's/\./-/'`

    # Setup CVS
    export CVS_RSH=ssh
}

################################################################################
# Check a Unix VM is accessible and can reach the buildfarm directory
################################################################################
_check_unix_vm() {
    RETVAL=`ssh $1 ls $2/settings.sh 2>&1`
    if [ "$RETVAL" != "$2/settings.sh" ];
    then
        _die "The build VM $1 is inaccessible or does not have access to the buildfarm repository at $2"
    fi
}

################################################################################
# Check a Windows VM is accessible and can reach the buildfarm directory
################################################################################
_check_windows_vm() {
    RETVAL=`ssh $1 ls $2 2>&1`
        RESULT1=`echo "$RETVAL" | grep 'No such file or directory' | wc -l`
        RESULT2=`echo "$RETVAL" | grep 'Operation timed out' | wc -l`
        if [ "$RESULT1" -ne "0" -o "$RESULT2" -ne "0" ];
        then
            _die "The build VM $1 is inaccessible or does not have access to the buildfarm repository at $2"
        fi
}

################################################################################
# Rock 'n' roll
################################################################################
if [ $# -ge 1 ];
then
  if [ $1 = "-skipbuild" ];
  then 
    SKIPBUILD=1
  else
    SKIPBUILD=0
  fi
else
  SKIPBUILD=0
fi

# Check the VMs
if [ $PG_ARCH_LINUX = 1 ];
then
    _check_unix_vm $PG_SSH_LINUX $PG_PATH_LINUX
fi

if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    _check_unix_vm $PG_SSH_LINUX_X64 $PG_PATH_LINUX_X64
fi

if [ $PG_ARCH_WINDOWS = 1 ];
then
    _check_windows_vm $PG_SSH_WINDOWS $PG_PATH_WINDOWS
fi


# Initialise the build system
_init

################################################################################
# Build each package. This may have interdepencies so must be built in order
################################################################################

# Package: Server
if [ $PG_PACKAGE_SERVER = 1 ];
then
    source ./server/build.sh

    if [ $SKIPBUILD = 0 ]; 
    then
        _prep_server || exit 1
        _build_server || exit 1
    fi

    _postprocess_server || exit 1
fi

# Package: PostGIS
if [ $PG_PACKAGE_POSTGIS = 1 ];
then
    cd $WD
    source ./PostGIS/build.sh

    if [ $SKIPBUILD = 0 ];
    then
        _prep_PostGIS || exit 1
        _build_PostGIS || exit 1
    fi

    _postprocess_PostGIS || exit 1
fi

# Package: Slony
if [ $PG_PACKAGE_SLONY = 1 ];
then
    cd $WD
    source ./Slony/build.sh

    if [ $SKIPBUILD = 0 ];
    then
        _prep_Slony || exit 1
        _build_Slony || exit 1
    fi
    _postprocess_Slony || exit 1
fi


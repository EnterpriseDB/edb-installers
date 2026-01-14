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

########
# Usage
########
usage()
{
        echo "Usage: $0 [Options]\n"
        echo "    Options:"
        echo "      [-skipbuild]"
        echo "    Examples:"
        echo "     $0 -skipbuild "
        echo ""
        exit 1;
}

################################################################################
# Initialise the build system
################################################################################
_init() {

    # Grab the working directory
    WD=`pwd`

    # Ensure we have an output directory
    if [ ! -d output ];
    then
        mkdir output || _die "Failed to create the output directory"
    fi

    # Set the package versions string
    PG_PACKAGE_VERSION=$PG_MAJOR_VERSION.`echo $PG_MINOR_VERSION | sed -e 's/\./-/'`
    PG_PACKAGE_MINOR_VERSION=`echo $PG_MINOR_VERSION | awk -F'.' '{print $1}'`

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

    # Check if chrpath exists on the given VM
    HAS_CHRPATH=`ssh $1 which chrpath 2>/dev/null`
    if [ x$HAS_CHRPATH == x ]; then
        _die "Need to install chrpath utility in order to build the installer on the build VM $1"
    fi
}

################################################################################
# Rock 'n' roll
################################################################################
while [ "$#" -gt "0" ]; do
        case "$1" in
                -skipbuild) SKIPBUILD=$1; shift 1;;              
				-h|-help) usage;;
                *) echo -e "error: no such option $1. -h for help"; exit 1;;
        esac
done

if [ "$SKIPBUILD" = "-skipbuild" ];
then
  SKIPBUILD=1
else
  SKIPBUILD=0
fi

# Initialise the build system
_init
cd $WD
echo "PG-INSTALLER repo details:"
echo "Branch: `git branch | sed -n -e 's/^\* \(.*\)/\1/p'`"
echo "Last commit:"
git log -n 1
echo "################################################"
echo " Build common utilities or modularized packages"
echo "################################################"


# Build each package. This may have interdepencies so must be built in order
echo "############################################################################"
echo " Build Packages"
echo "############################################################################"

# Package: Server
if [ $PG_PACKAGE_SERVER = 1 ];
then
    echo "### Package: Server"
    cd $WD
    source ./server/build.sh

    PG_BUILD_SERVER=0
    if [ $SKIPBUILD = 0 ];
    then
        _prep_server || exit 1
        _build_server || exit 1
    fi
    _postprocess_server || exit 1
fi

# Package: LanguagePack
if [ $PG_PACKAGE_LANGUAGEPACK = 1 ];
then
    cd $WD
    source ./languagepack/build.sh

    PG_BUILD_LANGUAGEPACK=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_languagepack && _build_languagepack)
        if [ $? == 0 ]; then
            PG_BUILD_LANGUAGEPACK=1
        fi
    fi
    (_postprocess_languagepack)
fi

# Package: PostGIS
if [ $PG_PACKAGE_POSTGIS = 1 ];
then
    echo "### Package: PostGIS"
    cd $WD
    source ./PostGIS/build.sh

    PG_BUILD_POSTGIS=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_PostGIS && _build_PostGIS)
        if [ $? == 0 ]; then
           PG_BUILD_POSTGIS=1
        fi
    fi
    (_postprocess_PostGIS)
fi

# Package: pgAgent
if [ $PG_PACKAGE_PGAGENT = 1 ];
then
    echo "### Package: pgAgent"
    cd $WD
    source ./pgAgent/build.sh

    PG_BUILD_PGAGENT=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_pgAgent && _build_pgAgent)
        if [ $? == 0 ]; then
           PG_BUILD_PGAGENT=1
        fi
    fi
    (_postprocess_pgAgent)
fi

# Package: pgbouncer
if [ $PG_PACKAGE_PGBOUNCER = 1 ];
then
    echo "### Package: pgbouncer"
    cd $WD
    source ./pgbouncer/build.sh

    PG_BUILD_PGBOUNCER=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_pgbouncer && _build_pgbouncer)
        if [ $? == 0 ]; then
           PG_BUILD_PGBOUNCER=1
        fi
    fi
    (_postprocess_pgbouncer)
fi


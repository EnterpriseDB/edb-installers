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
        echo "      [-skippvtpkg]"
        echo "    Examples:"
        echo "     $0 -skipbuild -skippvtpkg"
        echo "     $0 -skippvtpkg"
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
while [ "$#" -gt "0" ]; do
        case "$1" in
                -skipbuild) SKIPBUILD=$1; shift 1;;              
                -skippvtpkg) SKIPPVTPACKAGES=$1; shift 1;;
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

if [ "$SKIPPVTPACKAGES" = "-skippvtpkg" ];
then
  SKIPPVTPACKAGES=1
else
  SKIPPVTPACKAGES=0
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

if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    _check_windows_vm $PG_SSH_WINDOWS_X64 $PG_PATH_WINDOWS_X64
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

#echo "### Module: registartion_plus"
source $WD/registration_plus/build.sh

if [ $SKIPBUILD = 0 ];
then
  _registration_plus_component_build
fi

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
        (_prep_server && _build_server)
        if [ $? == 0 ]; then
            PG_BUILD_SERVER=1
        fi
    fi
    (_postprocess_server)
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

# Package: ApachePhp
if [ $PG_PACKAGE_APACHEPHP = 1 ];
then
    echo "### Package: ApachePhp"
    cd $WD
    source ./ApachePhp/build.sh

    PG_BUILD_APACHE=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_ApachePhp && _build_ApachePhp)
        if [ $? == 0 ]; then
            PG_BUILD_APACHE=1
        fi
    fi
    (_postprocess_ApachePhp)
fi

# Package: PEM-HTTPD
if [ $PG_PACKAGE_PEMHTTPD = 1 ];
then
    echo "### Package: PEM-HTTPD"
    cd $WD
    source ./PEM-HTTPD/build.sh

    PG_BUILD_PEMHTTPD=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_PEM-HTTPD && _build_PEM-HTTPD)
        if [ $? == 0 ]; then
           PG_BUILD_PEMHTTPD=1
        fi
    fi
    (_postprocess_PEM-HTTPD)
fi

# Package: phppgadmin
if [ $PG_PACKAGE_PHPPGADMIN = 1 ];
then
    echo "### Package: phppgadmin"
    cd $WD
    source ./phpPgAdmin/build.sh

    PG_BUILD_PHPPGADMIN=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_phpPgAdmin && _build_phpPgAdmin)
        if [ $? == 0 ]; then
           PG_BUILD_PHPPGADMIN=1
        fi
    fi
    (_postprocess_phpPgAdmin)
fi

# Package: pgJDBC
if [ $PG_PACKAGE_PGJDBC = 1 ];
then
    echo "### Package: pgJDBC"
    cd $WD
    source ./pgJDBC/build.sh

    PG_BUILD_PGJDBC=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_pgJDBC && _build_pgJDBC)
        if [ $? == 0 ]; then
           PG_BUILD_PGJDBC=1
        fi
    fi
    (_postprocess_pgJDBC)
fi

# Package: psqlODBC
if [ $PG_PACKAGE_PSQLODBC = 1 ];
then
    echo "### Package: psqlODBC"
    cd $WD
    source ./psqlODBC/build.sh

    PG_BUILD_PSQLODBC=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_psqlODBC && _build_psqlODBC)
        if [ $? == 0 ]; then
           PG_BUILD_PSQLODBC=1
        fi
    fi
    (_postprocess_psqlODBC)
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

# Package: Slony
if [ $PG_PACKAGE_SLONY = 1 ];
then
    echo "### Package: Slony"
    cd $WD
    source ./Slony/build.sh

    PG_BUILD_SLONY=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_Slony && _build_Slony)
        if [ $? == 0 ]; then
           PG_BUILD_SLONY=1
        fi
    fi
    (_postprocess_Slony)
fi

# Package: Npgsql
if [ $PG_PACKAGE_NPGSQL = 1 ];
then
    echo "### Package: Npgsql"
    cd $WD
    source ./Npgsql/build.sh

    PG_BUILD_NPGSQL=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_Npgsql && _build_Npgsql)
        if [ $? == 0 ]; then
           PG_BUILD_NPGSQL=1
        fi
    fi
    (_postprocess_Npgsql)
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

# Package: pgmemcache
if [ $PG_PACKAGE_PGMEMCACHE = 1 ];
then
    echo "### Package: pgmemcache"
    cd $WD
    source ./pgmemcache/build.sh

    PG_BUILD_PGMEMCACHE=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_pgmemcache && _build_pgmemcache)
        if [ $? == 0 ]; then
           PG_BUILD_PGMEMCACHE=1
        fi
    fi
    (_postprocess_pgmemcache)
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

#Package: MigrationToolKit
if [ $PG_PACKAGE_MIGRATIONTOOLKIT = 1 ];
then
    cd $WD
    source ./MigrationToolKit/build.sh

    PG_BUILD_MIGRATIONTOOLKIT=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_MigrationToolKit && _build_MigrationToolKit)
        if [ $? == 0 ]; then
           PG_BUILD_MIGRATIONTOOLKIT=1
        fi
    fi
    (_postprocess_MigrationToolKit)
fi

# Package: SQLPROTECT
if [ $PG_PACKAGE_SQLPROTECT = 1 ];
then
    cd $WD
    source ./sqlprotect/build.sh

    PG_BUILD_SQLPROTECT=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_sqlprotect && _build_sqlprotect)
        if [ $? == 0 ]; then
           PG_BUILD_SQLPROTECT=1
        fi
    fi
    (_postprocess_sqlprotect)
fi

# Package: UPDATE_MONITOR
if [ $PG_PACKAGE_UPDATE_MONITOR = 1 ];
then
    cd $WD
    source ./UpdateMonitor/build.sh

    PG_BUILD_UPDATE_MONITOR=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_updatemonitor && _build_updatemonitor)
        if [ $? == 0 ]; then
           PG_BUILD_UPDATE_MONITOR=1
        fi
    fi
    (_postprocess_updatemonitor)
fi

# Package: hdfs_fdw
if [ $PG_PACKAGE_HDFS_FDW = 1 ];
then
    cd $WD
    source ./hdfs_fdw/build.sh

    PG_BUILD_HDFS_FDW=0
    if [ $SKIPBUILD = 0 ];
    then
        (_prep_hdfs_fdw && _build_hdfs_fdw)
        if [ $? == 0 ]; then
          PG_BUILD_HDFS_FDW=1
        fi
    fi
    (_postprocess_hdfs_fdw)
fi

# Check for private builds
if [ $SKIPPVTPACKAGES = 0 ];
then
    if [ -e $WD/pvt_build.sh ];
    then
	[ -z "${PVT_BUILD_LOG}" ] && PVT_BUILD_LOG=$WD/output/build-pvt.log
        source $WD/pvt_build.sh > "${PVT_BUILD_LOG}" 2>&1
    fi
fi

# Archive the symbols
_archive_symbols

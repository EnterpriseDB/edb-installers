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
if [ $PG_PACKAGE_SERVER == 1 ];
then
    source ./server/build.sh

    if [ $SKIPBUILD == 0 ]; 
    then
        _prep_server || exit 1
        _build_server || exit 1
    fi

    _postprocess_server || exit 1
fi

# Package: DevServer
if [ $PG_PACKAGE_DEVSERVER == 1 ];
then
    source ./DevServer/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_DevServer || exit 1
        _build_DevServer || exit 1
    fi

    _postprocess_DevServer || exit 1
fi

# Package: ApachePhp
if [ $PG_PACKAGE_APACHEPHP == 1 ];
then
    cd $WD
    source ./ApachePhp/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_ApachePhp || exit 1
        _build_ApachePhp || exit 1
    fi

    _postprocess_ApachePhp || exit 1
fi

# Package: mediaWiki
if [ $PG_PACKAGE_MEDIAWIKI == 1 ];
then
    cd $WD
    source ./mediaWiki/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_mediaWiki || exit 1
        _build_mediaWiki || exit 1
    fi

    _postprocess_mediaWiki || exit 1
fi

# Package: phpWiki
if [ $PG_PACKAGE_PHPWIKI == 1 ];
then
    cd $WD
    source ./phpWiki/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_phpWiki || exit 1
        _build_phpWiki || exit 1
    fi

    _postprocess_phpWiki || exit 1
fi

# Package: phpBB
if [ $PG_PACKAGE_PHPBB == 1 ];
then
    cd $WD
    source ./phpBB/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_phpBB || exit 1
        _build_phpBB || exit 1
    fi

    _postprocess_phpBB || exit 1
fi

# Package: Drupal
if [ $PG_PACKAGE_DRUPAL == 1 ];
then
    cd $WD
    source ./Drupal/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_Drupal || exit 1
        _build_Drupal || exit 1
    fi

    _postprocess_Drupal || exit 1
fi

# Package: phppgadmin
if [ $PG_PACKAGE_PHPPGADMIN == 1 ];
then
    cd $WD
    source ./phpPgAdmin/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_phpPgAdmin || exit 1
        _build_phpPgAdmin || exit 1
    fi

    _postprocess_phpPgAdmin || exit 1
fi

# Package: pgJDBC
if [ $PG_PACKAGE_PGJDBC == 1 ];
then
    cd $WD
    source ./pgJDBC/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_pgJDBC || exit 1
        _build_pgJDBC || exit 1
    fi

    _postprocess_pgJDBC || exit 1
fi

# Package: psqlODBC
if [ $PG_PACKAGE_PSQLODBC == 1 ];
then
    cd $WD
    source ./psqlODBC/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_psqlODBC || exit 1
        _build_psqlODBC || exit 1
    fi

    _postprocess_psqlODBC || exit 1
fi

# Package: PostGIS
if [ $PG_PACKAGE_POSTGIS == 1 ];
then
    cd $WD
    source ./PostGIS/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_PostGIS || exit 1
        _build_PostGIS || exit 1
    fi

    _postprocess_PostGIS || exit 1
fi

# Package: Slony
if [ $PG_PACKAGE_SLONY == 1 ];
then
    cd $WD
    source ./Slony/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_Slony || exit 1
        _build_Slony || exit 1
    fi
    _postprocess_Slony || exit 1
fi

# Package: TuningWizard
if [ $PG_PACKAGE_TUNINGWIZARD == 1 ];
then
    cd $WD
    source ./TuningWizard/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_TuningWizard || exit 1
        _build_TuningWizard || exit 1
    fi
    _postprocess_TuningWizard || exit 1
fi

# Package: MigrationWizard
if [ $PG_PACKAGE_MIGRATIONWIZARD == 1 ];
then
    cd $WD
    source ./MigrationWizard/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_MigrationWizard || exit 1
        _build_MigrationWizard || exit 1
    fi
    _postprocess_MigrationWizard || exit 1
fi

# Package: pgphonehome
if [ $PG_PACKAGE_PGPHONEHOME == 1 ];
then
    cd $WD
    source ./pgphonehome/build.sh

    if [ $SKIPBUILD == 0 ];
    then
        _prep_pgphonehome || exit 1
        _build_pgphonehome || exit 1
    fi
    _postprocess_pgphonehome || exit 1
fi


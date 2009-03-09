#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_metainstaller_linux() {
    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/installers
    
    if [ -e linux ];
    then
      echo "Removing existing linux installers directory"
      rm -rf linux  || _die "Couldn't remove the existing linux installers directory (installers/linux)"
    fi

    mkdir linux

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    
       
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-linux.bin"  $WD/MetaInstaller/installers/linux || _die "Failed to copy the postgresql installer (installers/linux/postgresql-$PG_PACKAGE_VERSION-linux.bin)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux.bin"  $WD/MetaInstaller/installers/linux || _die "Failed to copy the slony installer (installers/linux/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux.bin)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux.bin"  $WD/MetaInstaller/installers/linux || _die "Failed to copy the pgjdbc installer (installers/linux/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux.bin)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux.bin"  $WD/MetaInstaller/installers/linux || _die "Failed to copy the psqlodbc installer (installers/linux/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux.bin)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux.bin"  $WD/MetaInstaller/installers/linux || _die "Failed to copy the postgis installer (installers/linux/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux.bin)"

    cd $WD/MetaInstaller/resources/scripts/linux

    rm -rf *.o
    rm -rf lib
    rm -rf pgcontrol
}

################################################################################
# Build
################################################################################

_build_metainstaller_linux() {

  cd $WD/MetaInstaller/resources/scripts/linux
  mkdir pgcontrol
  cd $WD/server/staging/linux/bin
  cp -R pg_controldata  $WD/MetaInstaller/resources/scripts/linux/pgcontrol || _die "Failed to copy the pg_controldata  (MetaInstaller/resources/scripts/linux/pgcontrol)"
  cd $WD/server/staging/linux
  cp -R lib  $WD/MetaInstaller/resources/scripts/linux/pgcontrol || _die "Failed to copy the lib/  (MetaInstaller/resources/scripts/linux/pgcontrol)"
  ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MetaInstaller/resources/; sh ./build-linux.sh" || _die "Failed to build C components"
}

################################################################################
# Post process
################################################################################

_postprocess_metainstaller_linux() {
    cd  $WD/MetaInstaller
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml linux || _die "Failed to build the installer"
    cd $WD
}


#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_metainstaller_linux_x64() {
    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/installers
    if [ -e linux-x64 ];
    then
      echo "Removing existing linux-x64 installers directory"
      rm -rf linux-x64  || _die "Couldn't remove the existing linux-x64 installers directory (installers/linux-x64)"
    fi

    mkdir linux-x64

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
       
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-linux-x64.bin"  $WD/MetaInstaller/installers/linux-x64 || _die "Failed to copy the postgresql installer (installers/linux-x64/postgresql-$PG_PACKAGE_VERSION-linux-x64.bin)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux-x64.bin"  $WD/MetaInstaller/installers/linux-x64 || _die "Failed to copy the slony installer (installers/linux-x64/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux-x64.bin)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux-x64.bin"  $WD/MetaInstaller/installers/linux-x64 || _die "Failed to copy the pgjdbc installer (installers/linux-x64/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux-x64.bin)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux-x64.bin"  $WD/MetaInstaller/installers/linux-x64 || _die "Failed to copy the psqlodbc installer (installers/linux-x64/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux-x64.bin)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-x64.bin"  $WD/MetaInstaller/installers/linux-x64 || _die "Failed to copy the postgis installer (installers/linux-x64/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-x64.bin)"

    cd $WD/MetaInstaller/resources/scripts/linux-x64

    rm -rf *.o
    rm -rf lib
    rm -rf pgcontrol
}



################################################################################
# Build
################################################################################

_build_metainstaller_linux_x64() {

  cd $WD/MetaInstaller/resources/scripts/linux-x64
  mkdir pgcontrol
  cd $WD/server/staging/linux-x64/bin
  cp -R pg_controldata  $WD/MetaInstaller/resources/scripts/linux-x64/pgcontrol || _die "Failed to copy the pg_controldata  (MetaInstaller/resources/scripts/linux-x64/pgcontrol)"

  cd $WD/server/staging/linux-x64
  cp -R lib  $WD/MetaInstaller/resources/scripts/linux-x64/pgcontrol || _die "Failed to copy the lib/  (MetaInstaller/resources/scripts/linux-x64/pgcontrol)"

  cd $WD/PostGIS/scripts/linux
  cp -R check-connection.sh  $WD/MetaInstaller/resources/scripts/linux-x64 || _die "Failed to copy the check-connection.sh  (MetaInstaller/resources/scripts/linux-x64)"

  cp -R check-db.sh  $WD/MetaInstaller/resources/scripts/linux-x64 || _die "Failed to copy the check-db.sh  (MetaInstaller/resources/scripts/linux-x64)"
   
  cd $WD/server/scripts/linux
  cp -R getlocales.sh  $WD/MetaInstaller/resources/scripts/linux-x64 || _die "Failed to copy the getlocales.sh  (MetaInstaller/resources/scripts/linux-x64)"

  cp -R runpgcontroldata.sh  $WD/MetaInstaller/resources/scripts/linux-x64 || _die "Failed to copy the runpgcontroldata.sh  (MetaInstaller/resources/scripts/linux-x64)"

  cp -R startserver.sh  $WD/MetaInstaller/resources/scripts/linux-x64 || _die "Failed to copy the startserver.sh  (MetaInstaller/resources/scripts/linux-x64)"

  ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MetaInstaller/resources/; sh ./build-linux-x64.sh" || _die "Failed to build C components"

}

################################################################################
# Post process
################################################################################

_postprocess_metainstaller_linux_x64() {

    cd  $WD/MetaInstaller
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml linux-x64 || _die "Failed to build the installer"
    cd $WD
}

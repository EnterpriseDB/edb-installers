#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_metainstaller_linux_ppc64() {


    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/source

    if [ -e MetaInstaller.linux-ppc64 ];
    then
      echo "Removing existing MetaInstaller.linux-ppc64 source directory"
      rm -rf MetaInstaller.linux-ppc64  || _die "Couldn't remove the existing MetaInstaller.linux-ppc64 source directory (source/MetaInstaller.linux-ppc64)"
    fi

    echo "Creating source directory ($WD/MetaInstaller/source/MetaInstaller.linux-ppc64)"
    mkdir -p $WD/MetaInstaller/source/MetaInstaller.linux-ppc64 || _die "Couldn't create the MetaInstaller.linux-ppc64 directory"

    # Enter the staging directory and cleanup if required
   
    if [ -e $WD/MetaInstaller/staging/linux-ppc64 ];
    then
      echo "Removing existing linux-ppc64 staging directory"
      rm -rf $WD/MetaInstaller/staging/linux-ppc64  || _die "Couldn't remove the existing linux-ppc64 staging directory (staging/linux-ppc64)"
    fi

    echo "Creating staging directory ($WD/MetaInstaller/staging/linux-ppc64)"
    mkdir -p $WD/MetaInstaller/staging/linux-ppc64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MetaInstaller/staging/linux-ppc64 || _die "Couldn't set the permissions on the staging directory"
      
    # Grab a copy of the stackbuilderplus installer
    cp -R "$WD/output/stackbuilderplus-pg_$PG_VERSION_STR-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the stackbuilderplus installer (staging/linux/stackbuilderplus-pg_$PG_VERSION_STR-$PG_PACKAGE_SBP-$PG_BUILDNUM_SBP-linux-ppc64.bin)"

    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the postgresql installer (staging/linux-ppc64/postgresql-$PG_PACKAGE_VERSION-linux-ppc64.bin)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the slony installer (staging/linux-ppc64/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux-ppc64.bin)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the pgjdbc installer (staging/linux-ppc64/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux-ppc64.bin)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the psqlodbc installer (staging/linux-ppc64/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux-ppc64.bin)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the postgis installer (staging/linux-ppc64/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-ppc64.bin)"

    # Grab a copy of the npgsql installer
    echo "Grab NpgSQL installer..."
    cp -R "$WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the npgsql installer (staging/windows/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux-ppc64.bin)"

    # Grab a copy of the pgbouncer installer
    cp -R "$WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the pgbouncer installer (staging/linux-ppc64/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux-ppc64.bin"

    # Grab a copy of the pgmemcache installer
    cp -R "$WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the pgmemcache installer (staging/linux-ppc64/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux-ppc64.bin"

    # Grab a copy of the pgagent installer
    cp -R "$WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-linux-ppc64.bin"  $WD/MetaInstaller/staging/linux-ppc64 || _die "Failed to copy the pgagent installer (staging/linux-ppc64/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-linux-ppc64.bin"

    cd $WD/MetaInstaller
    mkdir -p staging/linux-ppc64/scripts/pgcontrol
  
    cp -R $WD/server/staging/linux-ppc64/bin/pg_controldata  $WD/MetaInstaller/staging/linux-ppc64/scripts/pgcontrol || _die "Failed to copy the pg_controldata  (MetaInstaller/staging/linux-ppc64/scripts/pgcontrol)"
    cd $WD/server/staging/linux-ppc64
    cp -R lib  $WD/MetaInstaller/staging/linux-ppc64/scripts/pgcontrol || _die "Failed to copy the lib/  (MetaInstaller/staging/linux-ppc64/scripts/pgcontrol)"
    cp -R $WD/PostGIS/scripts/linux/check-connection.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts || _die "Failed to copy the check-connection.sh  (MetaInstaller/staging/linux-ppc64/scripts)"
    cp -R $WD/PostGIS/scripts/linux/check-db.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts || _die "Failed to copy the check-db.sh  (MetaInstaller/staging/linux-ppc64/scripts)"
    cp -R $WD/server/scripts/linux/getlocales.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts || _die "Failed to copy the getlocales.sh  (MetaInstaller/staging/linux-ppc64/scripts)"
    cp -R $WD/server/scripts/linux/runpgcontroldata.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts || _die "Failed to copy the runpgcontroldata.sh  (MetaInstaller/staging/linux-ppc64/scripts)"
    cp -R $WD/server/scripts/linux/startserver.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts || _die "Failed to copy the startserver.sh  (MetaInstaller/staging/linux-ppc64/scripts)"
    cp -R $WD/MetaInstaller/scripts/linux-ppc64/*.sh  $WD/MetaInstaller/staging/linux-ppc64/scripts/ || _die "Failed to copy the scripts"

    if [ -e $WD/MetaInstaller/staging/linux-ppc64/scripts/lib ];
    then
      echo "Removing existing lib directory"
      rm -rf $WD/MetaInstaller/staging/linux-ppc64/scripts/lib
    fi

    mkdir $WD/MetaInstaller/staging/linux-ppc64/scripts/lib

    cp $WD/server/staging/linux-ppc64/lib/libssl.so* $WD/MetaInstaller/staging/linux-ppc64/scripts/lib/
    cp $WD/server/staging/linux-ppc64/lib/libcrypto.so* $WD/MetaInstaller/staging/linux-ppc64/scripts/lib/

    #ssh $PG_SSH_LINUX_X64 "cp -r /lib64/libssl.so* $PG_PATH_LINUX_X64/MetaInstaller/staging/linux-ppc64/scripts/lib/."
    #ssh $PG_SSH_LINUX_X64 "cp -r /lib64/libcrypto.so* $PG_PATH_LINUX_X64/MetaInstaller/staging/linux-ppc64/scripts/lib/."

}



################################################################################
# Build
################################################################################

_build_metainstaller_linux_ppc64() {

#  cp -R $WD/MetaInstaller/scripts/linux-ppc64/* $WD/MetaInstaller/source/MetaInstaller.linux-ppc64/ || _die "Failed to copy the utilities to source folder"
#
#    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MetaInstaller/source/MetaInstaller.linux-ppc64/getDynaTune/; gcc -DWITH_OPENSSL -I. -o dynaTuneClient.o getDynaTuneInfoClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the dynaTuneClient utility"
#    cp $WD/MetaInstaller/source/MetaInstaller.linux-ppc64/getDynaTune/dynaTuneClient.o $WD/MetaInstaller/staging/linux-ppc64/scripts/ || _die "Failed to copy the dynaTuneClient utility to the staging directory"
#
#   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MetaInstaller/source/MetaInstaller.linux-ppc64/isUserValidated/; gcc -DWITH_OPENSSL -I. -o isUserValidated.o WSisUserValidated.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the isUserValidated utility"
#    cp $WD/MetaInstaller/source/MetaInstaller.linux-ppc64/isUserValidated/isUserValidated.o $WD/MetaInstaller/staging/linux-ppc64/scripts/ || _die "Failed to copy the isUserValidated utility to the staging directory"
#
#    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MetaInstaller/source/MetaInstaller.linux-ppc64/modifyPostgresql/; gcc -o modifyPostgresql.o replaceDynatune.c" || _die "Failed to build the modifyPostgresql utility"
#    cp $WD/MetaInstaller/source/MetaInstaller.linux-ppc64/modifyPostgresql/modifyPostgresql.o $WD/MetaInstaller/staging/linux-ppc64/scripts/ || _die "Failed to copy the modifyPostgresql utility to the staging directory"
#
#    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/MetaInstaller/source/MetaInstaller.linux-ppc64/validateUser/; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
#    cp $WD/MetaInstaller/source/MetaInstaller.linux-ppc64/validateUser/validateUserClient.o $WD/MetaInstaller/staging/linux-ppc64/scripts/ || _die "Failed to copy the validateUserClient utility to the staging directory"

     cd $WD
}

################################################################################
# Post process
################################################################################

_postprocess_metainstaller_linux_ppc64() {

    cd  $WD/MetaInstaller
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml linux-ppc || _die "Failed to build the installer"
    # Rename the installer
    mv $WD/output/postgresplus-$PG_MAJOR_VERSION-linux-ppc-installer.bin $WD/output/postgresplus-$PG_PACKAGE_VERSION-linux-ppc64.bin || _die "Failed to rename the installer"

    cd $WD
}

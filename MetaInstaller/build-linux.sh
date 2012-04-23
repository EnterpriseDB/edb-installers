#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_metainstaller_linux() {


    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/source

    if [ -e MetaInstaller.linux ];
    then
      echo "Removing existing MetaInstaller.linux source directory"
      rm -rf MetaInstaller.linux  || _die "Couldn't remove the existing MetaInstaller.linux source directory (source/MetaInstaller.linux)"
    fi

    echo "Creating source directory ($WD/MetaInstaller/source/MetaInstaller.linux)"
    mkdir -p $WD/MetaInstaller/source/MetaInstaller.linux || _die "Couldn't create the MetaInstaller.linux directory"

    # Enter the staging directory and cleanup if required
   
    if [ -e $WD/MetaInstaller/staging/linux ];
    then
      echo "Removing existing linux staging directory"
      rm -rf $WD/MetaInstaller/staging/linux  || _die "Couldn't remove the existing linux staging directory (staging/linux)"
    fi

    echo "Creating staging directory ($WD/MetaInstaller/staging/linux)"
    mkdir -p $WD/MetaInstaller/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MetaInstaller/staging/linux || _die "Couldn't set the permissions on the staging directory"

    # Grab a copy of the stackbuilderplus installer
    cp -R "$WD/output/stackbuilderplus-pg_$PG_VERSION_STR-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the stackbuilderplus installer (staging/linux/stackbuilderplus-pg_$PG_VERSION_STR-$PG_PACKAGE_SBP-$PG_BUILDNUM_SBP-linux.run)"
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the postgresql installer (staging/linux/postgresql-$PG_PACKAGE_VERSION-linux.run)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the slony installer (staging/linux/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux.run)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the pgjdbc installer (staging/linux/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-linux.run)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the psqlodbc installer (staging/linux/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux.run)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the postgis installer (staging/linux/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux.run)"

    # Grab a copy of the npgsql installer
    echo "Grab NpgSQL installer..."
    cp -R "$WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the npgsql installer (staging/windows/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-linux.run)"

    # Grab a copy of the pgbouncer installer
    cp -R "$WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the pgbouncer installer (staging/linux/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-linux.run"

    # Grab a copy of the pgmemcache installer
    cp -R "$WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the pgmemcache installer (staging/linux/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-linux.run"

    # Grab a copy of the pgagent installer
    cp -R "$WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-linux.run"  $WD/MetaInstaller/staging/linux || _die "Failed to copy the pgagent installer (staging/linux/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-linux.run"
    
    cd $WD/MetaInstaller
    mkdir -p staging/linux/scripts/pgcontrol
  
    cp -R $WD/server/staging/linux/bin/pg_controldata  $WD/MetaInstaller/staging/linux/scripts/pgcontrol || _die "Failed to copy the pg_controldata  (MetaInstaller/staging/linux/scripts/pgcontrol)"
    cd $WD/server/staging/linux
    cp -R lib  $WD/MetaInstaller/staging/linux/scripts/pgcontrol || _die "Failed to copy the lib/  (MetaInstaller/staging/linux/scripts/pgcontrol)"
    cp -R $WD/server/scripts/linux/getlocales.sh  $WD/MetaInstaller/staging/linux/scripts || _die "Failed to copy the getlocales.sh  (MetaInstaller/staging/linux/scripts)"
    cp -R $WD/server/scripts/linux/runpgcontroldata.sh  $WD/MetaInstaller/staging/linux/scripts || _die "Failed to copy the runpgcontroldata.sh  (MetaInstaller/staging/linux/scripts)"
    cp -R $WD/server/scripts/linux/startserver.sh  $WD/MetaInstaller/staging/linux/scripts || _die "Failed to copy the startserver.sh  (MetaInstaller/staging/linux/scripts)"
    cp -R $WD/MetaInstaller/scripts/linux/*.sh  $WD/MetaInstaller/staging/linux/scripts/ || _die "Failed to copy the scripts"

    if [ -e $WD/MetaInstaller/staging/linux/scripts/lib ];
    then
      echo "Removing existing lib directory"
      rm -rf $WD/MetaInstaller/staging/linux/scripts/lib
    fi

    mkdir $WD/MetaInstaller/staging/linux/scripts/lib

    ssh $PG_SSH_LINUX "cp -r /usr/local/openssl/lib/libssl.so* $PG_PATH_LINUX/MetaInstaller/staging/linux/scripts/lib/."
    ssh $PG_SSH_LINUX "cp -r /usr/local/openssl/lib/libcrypto.so* $PG_PATH_LINUX/MetaInstaller/staging/linux/scripts/lib/."
    
}

################################################################################
# Build
################################################################################

_build_metainstaller_linux() {

    cp -R $WD/MetaInstaller/scripts/linux/* $WD/MetaInstaller/source/MetaInstaller.linux/ || _die "Failed to copy the utilities to source folder"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MetaInstaller/source/MetaInstaller.linux/getDynaTune/; gcc -DWITH_OPENSSL -I. -o dynaTuneClient.o getDynaTuneInfoClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the dynaTuneClient utility"
    cp $WD/MetaInstaller/source/MetaInstaller.linux/getDynaTune/dynaTuneClient.o $WD/MetaInstaller/staging/linux/scripts/ || _die "Failed to copy the dynaTuneClient utility to the staging directory"

   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MetaInstaller/source/MetaInstaller.linux/isUserValidated/; gcc -DWITH_OPENSSL -I. -o isUserValidated.o WSisUserValidated.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the isUserValidated utility"
    cp $WD/MetaInstaller/source/MetaInstaller.linux/isUserValidated/isUserValidated.o $WD/MetaInstaller/staging/linux/scripts/ || _die "Failed to copy the isUserValidated utility to the staging directory"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MetaInstaller/source/MetaInstaller.linux/modifyPostgresql/; gcc -o modifyPostgresql.o replaceDynatune.c" || _die "Failed to build the modifyPostgresql utility"
    cp $WD/MetaInstaller/source/MetaInstaller.linux/modifyPostgresql/modifyPostgresql.o $WD/MetaInstaller/staging/linux/scripts/ || _die "Failed to copy the modifyPostgresql utility to the staging directory"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MetaInstaller/source/MetaInstaller.linux/validateUser/; gcc -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto" || _die "Failed to build the validateUserClient utility"
    cp $WD/MetaInstaller/source/MetaInstaller.linux/validateUser/validateUserClient.o $WD/MetaInstaller/staging/linux/scripts/ || _die "Failed to copy the validateUserClient utility to the staging directory"
    
}

################################################################################
# Post process
################################################################################

_postprocess_metainstaller_linux() {
    cd  $WD/MetaInstaller
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml linux || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/postgresplus-$PG_MAJOR_VERSION-linux-installer.run $WD/output/postgresplus-$PG_PACKAGE_VERSION-linux.run || _die "Failed to rename the installer"

    cd $WD
}


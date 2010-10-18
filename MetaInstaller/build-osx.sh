#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_metainstaller_osx() {


    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/source

    if [ -e MetaInstaller.osx ];
    then
      echo "Removing existing MetaInstaller.osx source directory"
      rm -rf MetaInstaller.osx  || _die "Couldn't remove the existing MetaInstaller.osx source directory (source/MetaInstaller.osx)"
    fi

    echo "Creating source directory ($WD/MetaInstaller/source/MetaInstaller.osx)"
    mkdir -p $WD/MetaInstaller/source/MetaInstaller.osx || _die "Couldn't create the MetaInstaller.osx directory"


    # Enter the staging directory and cleanup if required
   
    if [ -e $WD/MetaInstaller/staging/osx ];
    then
      echo "Removing existing osx staging directory"
      rm -rf $WD/MetaInstaller/staging/osx  || _die "Couldn't remove the existing osx staging directory (staging/osx)"
    fi

    echo "Creating staging directory ($WD/MetaInstaller/staging/osx)"
    mkdir -p $WD/MetaInstaller/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MetaInstaller/staging/osx || _die "Couldn't set the permissions on the staging directory"

    cp "$WD/scripts/runAsRoot.sh" "$WD/MetaInstaller/staging/osx" || _die "Failed to copy the runAsRoot script"

    # Grab a copy of the stackbuilderplus installer
    cp -R "$WD/output/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the stackbuilderplus installer (staging/linux/stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.zip)"
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-osx.dmg"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the postgresql installer (staging/osx/postgresql-$PG_PACKAGE_VERSION-osx.zip)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the slony installer (staging/osx/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the pgjdbc installer (staging/osx/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the psqlodbc installer (staging/osx/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the postgis installer (staging/osx/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip)"

    # Grab a copy of the npgsql installer
    echo "Grab NpgSQL installer..."
    cp -R "$WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the npgsql installer (staging/windows/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip)"

   # Grab a copy of the pgbouncer installer
    cp -R "$WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the pgbouncer installer (staging/osx/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip"

    # Grab a copy of the pgmemcache installer
    cp -R "$WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the pgmemcache installer (staging/osx/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip"

    # Grab a copy of the pgagent installer
    cp -R "$WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip"  $WD/MetaInstaller/staging/osx || _die "Failed to copy the pgagent installer (staging/osx/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip)"

    cd $WD/MetaInstaller/staging/osx
   
    hdiutil attach postgresql-$PG_PACKAGE_VERSION-osx.dmg

    cd "/Volumes/PostgreSQL $PG_PACKAGE_VERSION"

    cp -R postgresql-$PG_PACKAGE_VERSION-osx.app $WD/MetaInstaller/staging/osx/postgresql-$PG_PACKAGE_VERSION-osx.app

    cd $WD/MetaInstaller/staging/osx

    hdiutil eject "/Volumes/PostgreSQL $PG_PACKAGE_VERSION"
    rm -f postgresql-$PG_PACKAGE_VERSION-osx.dmg

    # unzip stackbuilderplus
    unzip stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.zip
    rm -f stackbuilderplus-$PG_VERSION_SBP-$PG_BUILDNUM_SBP-osx.zip

    # unzip slony    
    unzip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip
    rm -f slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip

    # unzip pgjdbc
    unzip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip
    rm -f pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip

    # unzip psqlodbc
    unzip psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip
    rm -f psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip

    # unzip postgis
    unzip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip
    rm -f postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip

    # unzip npgsql
    unzip npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip
    rm -f npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-osx.zip

    # unzip pgbouncer
    unzip pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip
    rm -f pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip

    # unzip pmemcache
    unzip pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip
    rm -f pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-osx.zip

    # unzip pgagent
    unzip pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip
    rm -f pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip

    cd $WD/MetaInstaller
    mkdir -p staging/osx/scripts/pgcontrol/bin
    mkdir -p staging/osx/scripts/pgcontrol/lib
    cp -R $WD/server/staging/osx/bin/pg_controldata  staging/osx/scripts/pgcontrol/bin || _die "Failed to copy the pg_controldata  (staging/osx/scripts/pgcontrol/bin)"
    cp -R $WD/server/staging/osx/lib/libxml2.2.dylib  staging/osx/scripts/pgcontrol/lib || _die "Failed to copy the libxml2  (staging/osx/scripts/pgcontrol/lib)"
    cp -R $WD/server/scripts/osx/getlocales.sh staging/osx/scripts/ || _die "Failed to copy the getlocales.sh"
    cp -R $WD/server/scripts/osx/prerun_checks.sh  $WD/MetaInstaller/staging/osx/scripts || _die "Failed to copy the prerun_checks.sh"
    cp -R $WD/server/staging/osx/installer/server/preinstall.sh  staging/osx/scripts/ || _die "Failed to copy the preinstall.sh"

    cp -R $WD/MetaInstaller/scripts/osx/*.sh  staging/osx/scripts/ || _die "Failed to copy the scripts"


}



################################################################################
# Build
################################################################################

_build_metainstaller_osx() {
    
   # Build the utilities.

    cp -R $WD/MetaInstaller/scripts/osx/* $WD/MetaInstaller/source/MetaInstaller.osx/ || _die "Failed to copy the utilities to source folder"

    cd $WD/MetaInstaller/source/MetaInstaller.osx/getDynaTune
    gcc -DWITH_OPENSSL -I. -O0 -o dynaTuneClient.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 getDynaTuneInfoClient.c soapC.c stdsoap2.c soapClient.c -lssl -lcrypto  || _die "Failed to build the getDynaTune utility"
    cp dynaTuneClient.o $WD/MetaInstaller/staging/osx/scripts/ || _die "Failed to copy the getDynaTune utility to the staging directory"

    cd $WD/MetaInstaller/source/MetaInstaller.osx/isUserValidated
    gcc -DWITH_OPENSSL -I. -o isUserValidated.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 WSisUserValidated.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto || _die "Failes to build the isUserValidated utility"
    cp isUserValidated.o $WD/MetaInstaller/staging/osx/scripts/ || _die "Failed to copy the isUserValidated utility to the staging directory"
   
    cd $WD/MetaInstaller/source/MetaInstaller.osx/modifyPostgresql
    gcc -o modifyPostgresql.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 replaceDynatune.c || _die "Failes to build the modifyPostgresql utility"
    cp modifyPostgresql.o $WD/MetaInstaller/staging/osx/scripts/ || _die "Failed to copy the modifyPostgresql utility to the staging directory"

    cd $WD/MetaInstaller/source/MetaInstaller.osx/validateUser
    gcc -DWITH_OPENSSL -I. -o validateUserClient.o $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto || _die "Failes to build the validateUserClient utility"
    cp validateUserClient.o $WD/MetaInstaller/staging/osx/scripts/ || _die "Failed to copy the validateUserClient utility to the staging directory"

}


################################################################################
# Post process
################################################################################

_postprocess_metainstaller_osx() {
     echo "Building osx Meta Installer"
     cd  $WD/MetaInstaller

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp "$WD/output/postgresplus-$PG_MAJOR_VERSION-osx.app/Contents/MacOS/Postgres Plus" $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/postgresplus-$PG_MAJOR_VERSION-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges "$WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/Postgres Plus"
    chmod a+x "$WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/Postgres Plus"
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ "Postgres Plus" $WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with pgAgent ($WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh

    # Rename the installer
    mv $WD/output/postgresplus-$PG_MAJOR_VERSION-osx-installer.app $WD/output/postgresplus-$PG_PACKAGE_VERSION-osx.app || _die "Failed to rename the installer"
    
    # Now we need to turn this into a DMG file

    echo "Creating disk image"

    cd $WD/MetaInstaller/staging

    if [ -d metainstaller.img ];
    then
        rm -rf metainstaller.img
    fi

    mkdir metainstaller.img || _die "Failed to create DMG staging directory"

    mv $WD/output/postgresplus-$PG_PACKAGE_VERSION-osx.app metainstaller.img || _die "Failed to copy the installer bundle into the DMG staging directory"
    cp $WD/MetaInstaller/resources/README.osx metainstaller.img/README || _die "Failed to copy the installer README file into the DMG staging directory"

    hdiutil create -quiet -srcfolder metainstaller.img -format UDZO -volname "PostgresPlus $PG_PACKAGE_VERSION" -ov "postgresplus-$PG_PACKAGE_VERSION-osx.dmg" || _die "Failed to create the disk image (staging/postgresplus-$PG_PACKAGE_VERSION-osx.dmg)"

    mv postgresplus-$PG_PACKAGE_VERSION-osx.dmg $WD/output/

    rm -rf metainstaller.img
    cd $WD
}




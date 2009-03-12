#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_metainstaller_osx() {


    # Enter the source directory and cleanup if required
   
    cd $WD/MetaInstaller/installers
      
    if [ -e mac ];
    then
      echo "Removing existing mac installers directory"
      rm -rf mac  || _die "Couldn't remove the existing mac installers directory (installers/mac)"
    fi

    mkdir mac

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    
       
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-osx.dmg"  $WD/MetaInstaller/installers/mac || _die "Failed to copy the postgresql installer (installers/mac/postgresql-$PG_PACKAGE_VERSION-osx.zip)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip"  $WD/MetaInstaller/installers/mac || _die "Failed to copy the slony installer (installers/mac/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip"  $WD/MetaInstaller/installers/mac || _die "Failed to copy the pgjdbc installer (installers/mac/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip"  $WD/MetaInstaller/installers/mac || _die "Failed to copy the psqlodbc installer (installers/mac/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip"  $WD/MetaInstaller/installers/mac || _die "Failed to copy the postgis installer (installers/mac/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip)"

    cd $WD/MetaInstaller/installers/mac

   
    hdiutil attach postgresql-$PG_PACKAGE_VERSION-osx.dmg

    cd "/Volumes/PostgreSQL $PG_PACKAGE_VERSION"

    cp -R postgresql-$PG_PACKAGE_VERSION-osx.app $WD/MetaInstaller/installers/mac/postgresql-$PG_PACKAGE_VERSION-osx.app

    cd $WD/MetaInstaller/installers/mac

    hdiutil eject "/Volumes/PostgreSQL $PG_PACKAGE_VERSION"

    # unzip slony    
    unzip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip

    # unzip pgjdbc
    unzip pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-osx.zip

    # unzip psqlodbc
    unzip psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip

    # unzip postgis
    unzip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip

    # removing intermediate files

    cd $WD/MetaInstaller/resources/scripts/osx

    rm -rf *.o
    rm -rf pgcontrol
}



################################################################################
# Build
################################################################################

_build_metainstaller_osx() {
    cd $WD/MetaInstaller/resources/scripts/osx
    mkdir pgcontrol
    cd $WD/server/staging/osx/bin
    cp -R pg_controldata  $WD/MetaInstaller/resources/scripts/osx/pgcontrol || _die "Failed to copy the pg_controldata  (MetaInstaller/resources/scripts/osx/pgcontrol)"

    cd $WD/PostGIS/scripts/osx
    cp -R check-connection.sh  $WD/MetaInstaller/resources/scripts/osx || _die "Failed to copy the check-connection.sh  (MetaInstaller/resources/scripts/osx)"

    cp -R check-db.sh  $WD/MetaInstaller/resources/scripts/osx || _die "Failed to copy the check-db.sh  (MetaInstaller/resources/scripts/osx)"
   
    cd $WD/server/scripts/osx
    cp -R getlocales.sh  $WD/MetaInstaller/resources/scripts/osx || _die "Failed to copy the getlocales.sh  (MetaInstaller/resources/scripts/osx)"

    cp -R preinstall.sh  $WD/MetaInstaller/resources/scripts/osx || _die "Failed to copy the preinstall.sh  (MetaInstaller/resources/scripts/osx)"

    cp -R startserver.sh  $WD/MetaInstaller/resources/scripts/osx || _die "Failed to copy the startserver.sh  (MetaInstaller/resources/scripts/osx)"

    cd $WD/MetaInstaller/resources
    echo "Building osx components..."
    ./build-osx.sh    
}


################################################################################
# Post process
################################################################################

_postprocess_metainstaller_osx() {
echo "Building osx Meta Installer"
     cd  $WD/MetaInstaller
    # Build the installer

    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml osx || _die "Failed to build the installer"
    
    # Now we need to turn this into a DMG file

    echo "Creating disk image"

    cd $WD/MetaInstaller/staging

    if [ -d metainstaller.img ];
    then
        rm -rf metainstaller.img
    fi

    mkdir metainstaller.img || _die "Failed to create DMG staging directory"

    mv $WD/output/postgresplus-$PG_VERSION_METAINSTALLER-osx-installer.app metainstaller.img || _die "Failed to copy the installer bundle into the DMG staging directory"

    hdiutil create -quiet -srcfolder metainstaller.img -format UDZO -volname "PostgresPlus $PG_VERSION_METAINSTALLER" -ov "postgresplus-$PG_VERSION_METAINSTALLER-osx.dmg" || _die "Failed to create the disk image (staging/postgresplus-$PG_VERSION_METAINSTALLER-osx.dmg)"

    mv postgresplus-$PG_VERSION_METAINSTALLER-osx.dmg $WD/output/

    rm -rf metainstaller.img
    cd $WD
}




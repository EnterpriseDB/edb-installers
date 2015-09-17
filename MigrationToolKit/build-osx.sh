#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit_osx() {
    
    echo "BEGIN PREP MigrationToolKit OSX"    
      
    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationtoolkit.osx ];
    then
      echo "Removing existing migrationtoolkit.osx source directory"
      rm -rf migrationtoolkit.osx  || _die "Couldn't remove the existing migrationtoolkit.osx source directory (source/migrationtoolkit.osx)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.osx)"
    mkdir -p migrationtoolkit.osx || _die "Couldn't create the migrationtoolkit.osx directory"
    chmod ugo+w migrationtoolkit.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.osx || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc4.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the pg-jdbc driver"
    cp $WD/tarballs/edb-jdbc14.jar migrationtoolkit.osx/lib/ || _die "Failed to copy the edb-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/osx)"
    mkdir -p $WD/MigrationToolKit/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/osx || _die "Couldn't set the permissions on the staging directory"
        
    echo "END PREP MigrtonToolKit  OSX"
}


################################################################################
# PG Build
################################################################################

_build_MigrationToolKit_osx() {
    
    
    echo "BEGIN BUILD MigtationToolKit OSX"    

    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_OSX/MigrationToolKit/staging/osx
    PG_MW_SOURCE=$WD/MigrationToolKit/source/migrationtoolkit.osx

    cd $PG_MW_SOURCE

    echo "Building migrationtoolkit"
    $PG_ANT_HOME_OSX/bin/ant clean || _die "Couldn't clean the migrationtoolkit"
    $PG_ANT_HOME_OSX/bin/ant install-pg || _die "Couldn't build the migrationtoolkit"
  
    # Copying the MigrationToolKit binary to staging directory
    mkdir $PG_STAGING/MigrationToolKit || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolKit)"
    cp -R install/* $PG_STAGING/MigrationToolKit || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/osx/MigrationToolKit)"
    
    echo "END BUILD MigrationToolKit OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_MigrationToolKit_osx() {

    echo "BEGIN POST MigrationToolKit OSX"

    cd $WD/MigrationToolKit
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app.tar.bz2 migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf migrationtoolkit*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server." 
    scp migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX/versions.sh; tar -jxvf migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app; mv migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx-signed.app  migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.zip migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT-$PG_BUILDNUM_MIGRATIONTOOLKIT-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD

    echo "END POST MigrationToolKit OSX"
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_osx() {
    
    echo "BEGIN PREP sqlprotect OSX"

    cd $WD/server/source
	
    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.osx/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.osx/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi

    # create a copy of the sqlprotect tree
	cd postgres.osx/contrib
    git clone ssh://pginstaller@cvs.enterprisedb.com/git/SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/osx.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/osx.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/osx.build)"
    mkdir -p $WD/sqlprotect/staging/osx.build/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/osx.build || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP sqlprotect OSX"
}

################################################################################
# PG Build
################################################################################

_build_sqlprotect_osx() {
    
    echo "BEGIN BUILD sqlprotect OSX"    

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/lib/postgresql" || _die "Failed to create staging/osx.build/lib/postgresql"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/share" || _die "Failed to create staging/osx.build/share"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/doc" || _die "Failed to create staging/osx.build/doc"

    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_OSX/sqlprotect/staging/osx.build/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_OSX/sqlprotect/staging/osx.build/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_OSX/sqlprotect/staging/osx.build/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/osx.build
    
    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/osx.build/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/osx.build/sqlprotect_license.txt || _die "Unable to change permissions for license file"

    echo "Removing last successful staging directory ($WD/sqlprotect/staging/osx)"
    rm -rf $WD/sqlprotect/staging/osx || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/sqlprotect/staging/osx || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/sqlprotect/staging/osx || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/sqlprotect/staging/osx.build/* $WD/sqlprotect/staging/osx || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_SQLPROTECT=$PG_VERSION_SQLPROTECT" > $WD/sqlprotect/staging/osx/versions-osx.sh
    echo "PG_BUILDNUM_SQLPROTECT=$PG_BUILDNUM_SQLPROTECT" >> $WD/sqlprotect/staging/osx/versions-osx.sh

    echo "END BUILD sqlprotect OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_sqlprotect_osx() {

    echo "BEGIN POST sqlprotect OSX"    

    source $WD/sqlprotect/staging/osx/versions-osx.sh
    PG_BUILD_SQLPROTECT=$(expr $PG_BUILD_SQLPROTECT + $SKIPBUILD)

    _registration_plus_postprocess "$WD/sqlprotect/staging"  "SQL Protect" "sqlprotectVersion" "/etc/postgres-reg.ini" "sqlprotect-PG_$PG_MAJOR_VERSION" "sqlprotect-PG_$PG_MAJOR_VERSION" "SQL Protect" "$PG_VERSION_SQLPROTECT"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SQLPROTECT -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    cd $WD/sqlprotect
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app $WD/output/sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; rm -rf sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app; mv sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx-signed.app  sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    # Zip up the output
    cd $WD/output
    zip -r sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app/ || _die "Failed to remove the unpacked installer bundle"
    cd $WD
    
    echo "END POST sqlprotect OSX"
}


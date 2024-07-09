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
    git clone git@github.com-edb-sql-protect:EnterpriseDB/edb-sql-protect.git SQLPROTECT

    tar -jcvf sqlprotect.tar.bz2 SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/osx)"
    mkdir -p $WD/sqlprotect/staging/osx/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/sqlprotect ]; then rm -rf $PG_PATH_OSX/sqlprotect/staging/osx.build; fi" || _die "Couldn't remove sqlprotect/staging/osx.build on OS X build server"
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT ]; then rm -rf $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/server/source/postgres.osx/contrib/sqlprotect.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server/source/postgres.osx/contrib/ || _die "Failed to copy the source archives to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $WD/resources/create_debug_symbols.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; tar -jxvf sqlprotect.tar.bz2"
    
    echo "END PREP sqlprotect OSX"
}

################################################################################
# PG Build
################################################################################

_build_sqlprotect_osx() {
    
    echo "BEGIN BUILD sqlprotect OSX"    

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/lib/postgresql" || _die "Failed to create staging/osx/lib/postgresql"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/share" || _die "Failed to create staging/osx/share"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx.build/doc" || _die "Failed to create staging/osx/doc"

    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.dylib $PG_PATH_OSX/sqlprotect/staging/osx.build/lib/postgresql/" || _die "Failed to copy sqlprotect.dylib to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_OSX/sqlprotect/staging/osx.build/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
    ssh $PG_SSH_OSX "cp $PG_PATH_OSX/server/source/postgres.osx/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_OSX/sqlprotect/staging/osx.build/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_OSX/sqlprotect/staging/osx.build" || _die "Failed to execute create_debug_symbols.sh"

    echo "Removing last successful staging directory ($PG_PATH_OSX/sqlprotect/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/sqlprotect/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/sqlprotect/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR sqlprotect/staging/osx.build/* sqlprotect/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_SQLPROTECT=$PG_VERSION_SQLPROTECT > $PG_PATH_OSX/sqlprotect/staging/osx/versions-osx.sh" || _die "Failed to write sqlprotect version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_SQLPROTECT=$PG_BUILDNUM_SQLPROTECT >> $PG_PATH_OSX/sqlprotect/staging/osx/versions-osx.sh" || _die "Failed to write sqlprotect build number into versions-osx.sh"

    echo "END BUILD sqlprotect OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_sqlprotect_osx() {

    echo "BEGIN POST sqlprotect OSX"    

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/sqlprotect/staging/osx)"
    mkdir -p $WD/sqlprotect/staging/osx/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/osx || _die "Couldn't set the permissions on the staging directory"

    chmod -R ugo+r $WD/sqlprotect/staging/osx.build
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/sqlprotect/staging/osx; rm -f sqlprotect-staging.tar.bz2" || _die "Failed to remove archive of the sqlprotect staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/sqlprotect/staging/osx; tar -jcvf sqlprotect-staging.tar.bz2 *" || _die "Failed to create archive of the sqlprotect staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/sqlprotect/staging/osx/sqlprotect-staging.tar.bz2 $WD/sqlprotect/staging/osx || _die "Failed to scp sqlprotect staging"

    # Extract the staging archive
    cd $WD/sqlprotect/staging/osx
    tar -jxvf sqlprotect-staging.tar.bz2 || _die "Failed to extract the sqlprotect staging archive"
    rm -f sqlprotect-staging.tar.bz2

    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/osx/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/osx/sqlprotect_license.txt || _die "Unable to change permissions for license file"

    source $WD/sqlprotect/staging/osx/versions-osx.sh
    PG_BUILD_SQLPROTECT=$(expr $PG_BUILD_SQLPROTECT + $SKIPBUILD)

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
    mv $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-osx.app $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app
    
    cd $WD/output
    
    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app.tar.bz2 edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    scp edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"

    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app; mv edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx-signed.app  edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.*" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip edb-sqlprotect" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip edb-sqlprotect" || _die "Failed to notarize the app"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD
    
    echo "END POST sqlprotect OSX"
}


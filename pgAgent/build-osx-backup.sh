#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_osx() {

    echo "BEGIN PREP pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Build preparation #"
    echo "#####################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
	
    if [ -e pgAgent.osx ];
    then
      echo "Removing existing pgAgent.osx source directory"
      rm -rf pgAgent.osx  || _die "Couldn't remove the existing pgAgent.osx source directory (source/pgAgent.osx)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.osx)"
    mkdir -p $WD/pgAgent/source/pgAgent.osx || _die "Couldn't create the pgAgent.osx directory"
	
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.osx || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    tar -jcvf pgagent.tar.bz2 pgAgent.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/osx)"
    mkdir -p $WD/pgAgent/staging/osx || _die "Couldn't create the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/pgAgent ]; then rm -rf $PG_PATH_OSX/pgAgent/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/pgAgent/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/pgAgent/source/pgagent.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgAgent/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/pgAgent
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/pgAgent/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/pgAgent || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent/source; tar -jxvf pgagent.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent; tar -jxvf scripts.tar.bz2"
    
    echo "END PREP pgAgent OSX"

}

################################################################################
# pgAgent Build
################################################################################

_build_pgAgent_osx() {

    echo "BEGIN BUILD pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Build             #"
    echo "#####################################"

    cd $WD/pgAgent
cat <<EOT-PGAGENT > $WD/pgAgent/build-pgagent.sh

    source ../settings.sh
    source ../versions.sh
    source ../common.sh
    
    set -x
    PG_STAGING=$PG_PATH_OSX/pgAgent/staging/osx
    SOURCE_DIR=$PG_PATH_OSX/pgAgent/source/pgAgent.osx

    echo "Building pgAgent sources"
    cd \$SOURCE_DIR
    WXWIN=/usr/local PGDIR=$PG_PGHOME_OSX cmake -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.6  -DCMAKE_INSTALL_PREFIX=\$PG_STAGING -DSTATIC_BUILD=NO -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=i386 CMakeLists.txt || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    cd \$SOURCE_DIR
    make || _die "Couldn't compile the pgAgent sources"
    make install || _die "Couldn't install pgAgent"

    mkdir -p \$PG_STAGING/lib

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -pR $PG_PGHOME_OSX/bin/psql \$PG_STAGING/bin || _die "Failed to copy psql"
    cp -pR $PG_PGHOME_OSX/lib/libpq.*dylib \$PG_STAGING/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"
    cp -pR $PG_PGHOME_OSX/lib/libedit.*dylib \$PG_STAGING/lib || _die "Failed to copy the dependency library (libedit.0.dylib)"
    cp -pR $PG_PGHOME_OSX/lib/libssl.*dylib \$PG_STAGING/lib || _die "Failed to copy the dependency library (libedit.0.dylib)"
    cp -pR $PG_PGHOME_OSX/lib/libcrypto.*dylib \$PG_STAGING/lib || _die "Failed to copy the dependency library (libedit.0.dylib)"

    # Copy libxml2 as System's libxml can be old.
    cp -pR /usr/local/lib/libxml2*dylib \$PG_STAGING/lib || _die "Failed to copy the latest libxml2"
    cp -pR /usr/local/lib/libz*dylib \$PG_STAGING/lib || _die "Failed to copy the latest libxml2"
    cp -pR /usr/local/lib/libiconv*dylib \$PG_STAGING/lib || _die "Failed to copy the latest libxml2"
    cp -pR /usr/local/lib/libwx_base_carbonu-2.8*dylib \$PG_STAGING/lib || _die "Failed to copy the latest libxml2"

    otool -L $PG_PATH_OSX/pgAgent/staging/osx/bin/pgagent
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "\$PG_STAGING/bin/psql"
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" "\$PG_STAGING/bin/pgagent"
    _rewrite_so_refs $PG_PATH_OSX/pgAgent/staging/osx lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/pgAgent/staging/osx bin @loader_path/..

    chmod +r \$PG_STAGING/lib/*
    chmod +rx \$PG_STAGING/bin/* 
EOT-PGAGENT
    
    cd $WD
    scp pgAgent/build-pgagent.sh $PG_SSH_OSX:$PG_PATH_OSX/pgAgent
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent; sh ./build-pgagent.sh" || _die "Failed to build pgAgent on OSX VM"
    
    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/pgAgent/staging/osx; tar -jcvf pgagent-staging.tar.bz2 *" || _die "Failed to create archive of the pgagent staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/pgAgent/staging/osx/pgagent-staging.tar.bz2 $WD/pgAgent/staging/osx || _die "Failed to scp pgagent staging"

    # Extract the staging archive
    cd $WD/pgAgent/staging/osx
    tar -jxvf pgagent-staging.tar.bz2 || _die "Failed to extract the pgagent staging archive"
    rm -f pgagent-staging.tar.bz2
    
    echo "END BUILD pgAgent OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_osx() {

    echo "BEGIN POST pgAgent OSX"

    echo "#####################################"
    echo "# pgAgent : OSX : Post Process      #"
    echo "#####################################"

    # Setup the installer scripts.
    cd $WD/pgAgent/staging
    mkdir -p $WD/pgAgent/staging/osx/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $WD/pgAgent/scripts/osx/*.sh   $WD/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the installer scripts"
    cp -f $WD/pgAgent/scripts/osx/pgpass $WD/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the pgpass script (scripts/osx/pgpass)"
    chmod ugo+x $WD/pgAgent/staging/osx/installer/pgAgent/*

    cd $WD/pgAgent

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent
    chmod a+x $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgAgent $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with pgAgent ($WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh
    
    cd $WD/output
    
    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app.tar.bz2 pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgagent*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app; mv pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx-signed.app  pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

    cd $WD

    echo "END POST pgAgent OSX"

}


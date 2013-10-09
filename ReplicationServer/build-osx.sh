#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_osx() {
    
    echo "BEGIN PREP ReplicationServer OSX"

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.osx ];
    then
      echo "Removing existing ReplicationServer.osx source directory"
      rm -rf ReplicationServer.osx  || _die "Couldn't remove the existing ReplicationServer.osx source directory (source/ReplicationServer.osx)"
    fi

    if [ -e DataValidator.osx ];
    then
      echo "Removing existing DataValidator.osx source directory"
      rm -rf DataValidator.osx  || _die "Couldn't remove the existing DataValidator.osx source directory (source/DataValidator.osx)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.osx)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.osx || _die "Couldn't create the ReplicationServer.osx directory"
    echo "Creating staging directory ($WD/ReplicationServer/source/DataValidator.osx)"
    mkdir -p $WD/ReplicationServer/source/DataValidator.osx || _die "Couldn't create the DataValidator.osx directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.osx || _die "Failed to copy the source code (source/replicator)"
    chmod -R ugo+w ReplicationServer.osx || _die "Couldn't set the permissions on the source directory"
    cp -R DataValidator/* DataValidator.osx || _die "Failed to copy the source code (source/DataValidator)"
    chmod -R ugo+w DataValidator.osx || _die "Couldn't set the permissions on the source directory"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.osx/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/DataValidator.osx/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.osx/lib || _die "Failed to copy pg jdbc drivers" 
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/DataValidator.osx/lib || _die "Failed to copy pg jdbc drivers" 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/osx)"
    mkdir -p $WD/ReplicationServer/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/osx || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP ReplicationServer OSX"
}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_osx() {
    
    echo "BEGIN BUILD ReplicationServer OSX"

    cd $WD/ReplicationServer/source/ReplicationServer.osx 
    ant -f custom_build.xml dist || _die "Failed to build the Replication xDB Replicator"
    cp -R dist/* $WD/ReplicationServer/staging/osx/ || _die "Failed to copy the dist content to staging directory"
    ant -f custom_build.xml encrypt-util || _die "Failed to build the Replication xDB Replicator"
    cp -R dist/* $WD/ReplicationServer/staging/osx/ || _die "Failed to copy the dist content to staging directory"
    cd $WD/ReplicationServer/source/DataValidator.osx 
    ant -f custom_build.xml dist || _die "Failed to build the Replication xDB Replicator"
    cp -R dist/* $WD/ReplicationServer/staging/osx/repconsole/ || _die "Failed to copy the dist content to staging directory"

    mkdir -p $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/bin || _die "Failed to create the instscripts directory"
    mkdir -p $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/lib || _die "Failed to create the instscripts directory"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/lib || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libxml2* $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/lib || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/lib/libedit* $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/lib || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/bin || _die "Failed to copy psql in instscripts"
   
    cp -R $PG_PATH_OSX/MigrationToolKit/staging/osx/MigrationToolKit/lib/edb-migrationtoolkit.jar $PG_PATH_OSX/ReplicationServer/staging/osx/repserver/lib/repl-mtk || _die "Failed to copy edb-migrationtoolkit.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/staging/osx/repconsole/lib/jdbc || _die "Failed to copy pg jdbc drivers"
  

    cd $WD
    _replace "java -jar edb-repconsole.jar" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/osx/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar pubserver @@PUBPORT@@" "$WD/ReplicationServer/staging/osx/repserver/bin/runPubServer.sh" || _die "Failed to put the placehoder in runPubServer.sh file"
    _replace "java -jar edb-repserver.jar subserver 9012" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar subserver @@SUBPORT@@" "$WD/ReplicationServer/staging/osx/repserver/bin/runSubServer.sh" || _die "Failed to put the placehoder in runSubServer.sh file"

    chmod +rx $WD/ReplicationServer/staging/osx/repconsole/bin/*
    chmod +rx $WD/ReplicationServer/staging/osx/repserver/bin/*
    chmod +r $WD/ReplicationServer/staging/osx/repconsole/lib/*
    chmod +r $WD/ReplicationServer/staging/osx/repserver/lib/*

    echo "Building validateUserClient utility"
    cp -R $WD/resources/validateUser $WD/ReplicationServer/source/ReplicationServer.osx/validateUser || _die "Failed copying validateUser script while building"
    cd $WD/ReplicationServer/source/ReplicationServer.osx/validateUser
    gcc -DWITH_OPENSSL -I. -o validateUserClient.o $PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto || _die "Failed to build the validateUserClient utility"
    cp validateUserClient.o $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/validateUserClient.o || _die "Failed to copy validateUserClient utility to staging directory"
    chmod ugo+x $PG_PATH_OSX/ReplicationServer/staging/osx/instscripts/validateUserClient.o
    
    echo "END BUILD ReplicationServer OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_osx() {
    
    echo "BEGIN POST ReplicationServer OSX"

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"

    cp scripts/osx/createshortcuts.sh staging/osx/installer/xDBReplicationServer/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/xDBReplicationServer/createshortcuts.sh

    cp scripts/osx/createuser.sh staging/osx/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/osx/createuser.sh)"
    chmod ugo+x staging/osx/installer/xDBReplicationServer/createuser.sh

    cp staging/osx/edb-repencrypter.jar staging/osx/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/osx/edb-repencrypter.jar)"
    cp -R staging/osx/lib staging/osx/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/osx/lib)"
    # Setup Launch Scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/startupcfg_publication.sh staging/osx/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/osx/startupcfg_publication.sh)"
    chmod ugo+x staging/osx/scripts/startupcfg_publication.sh
    cp scripts/osx/startupcfg_subscription.sh staging/osx/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/osx/startupcfg_subscription.sh)"
    chmod ugo+x staging/osx/scripts/startupcfg_subscription.sh
    cp scripts/osx/replicationserver.applescript.in staging/osx/scripts/replicationserver.applescript || _die "Failed to copy the replicationserver.applescript script (scripts/osx/replicationserver.applescript)"
    chmod ugo+x staging/osx/scripts/replicationserver.applescript

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/xDBReplicationServer $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/xDBReplicationServer
    chmod a+x $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/xDBReplicationServer
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ xDBReplicationServer $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/Contents/MacOS/installbuilder.sh


    # Zip up the output
    cd $WD/output
    zip -r xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.zip xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

    echo "END POST ReplicationServer OSX"    
}


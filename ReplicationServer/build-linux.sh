#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.linux ];
    then
      echo "Removing existing ReplicationServer.linux source directory"
      rm -rf ReplicationServer.linux  || _die "Couldn't remove the existing ReplicationServer.linux source directory (source/ReplicationServer.linux)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.linux)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.linux || _die "Couldn't create the ReplicationServer.linux directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.linux || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.linux || _die "Couldn't set the permissions on the source directory"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.linux/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.linux/lib || _die "Failed to copy pg jdbc drivers" 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/linux)"
    mkdir -p $WD/ReplicationServer/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/linux || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_linux() {


    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; cp -R dist/* $PG_PATH_LINUX/ReplicationServer/staging/linux/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant -f custom_build.xml encrypt-util" || _die "Failed to build the DESEncrypter utility"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; cp -R dist/* $PG_PATH_LINUX/ReplicationServer/staging/linux/" || _die "Failed to copy the dist content to staging directory"
    

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p ReplicationServer/staging/linux/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p ReplicationServer/staging/linux/instscripts/bin" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; mkdir -p ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/bin/psql ReplicationServer/staging/linux/instscripts/bin" || _die "Failed to copy psql binary"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libpq.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libcrypto.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libssl.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libreadline.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libreadline.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libtermcap.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libtermcap.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxml2.so* ReplicationServer/staging/linux/instscripts/lib" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp MigrationToolKit/staging/linux/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/linux/repserver/lib/repl-mtk" || _die "Failed to copy edb-migrationtoolkit.jar"
    cd $WD
    _replace "java -jar edb-repconsole.jar" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/linux/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar pubserver @@PUBPORT@@" "$WD/ReplicationServer/staging/linux/repserver/bin/runPubServer.sh" || _die "Failed to put the placehoder in runPubServer.sh file"
    _replace "java -jar edb-repserver.jar subserver 9012" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar subserver @@SUBPORT@@" "$WD/ReplicationServer/staging/linux/repserver/bin/runSubServer.sh" || _die "Failed to put the placehoder in runSubServer.sh file"

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_linux() {
 

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/xDBReplicationServer/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/xDBReplicationServer/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/xDBReplicationServer/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/xDBReplicationServer/createshortcuts.sh

    cp scripts/linux/createuser.sh staging/linux/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/linux/createuser.sh)"
    chmod ugo+x staging/linux/installer/xDBReplicationServer/createuser.sh

    cp staging/linux/edb-repencrypter.jar staging/linux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/linux/edb-repencrypter.jar)"
    cp -R staging/linux/lib staging/linux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/linux/lib)"
    # Setup Launch Scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/startupcfg_publication.sh staging/linux/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/linux/startupcfg_publication.sh)"
    chmod ugo+x staging/linux/scripts/startupcfg_publication.sh
    cp scripts/linux/startupcfg_subscription.sh staging/linux/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/linux/startupcfg_subscription.sh)"
    chmod ugo+x staging/linux/scripts/startupcfg_subscription.sh

    # Setup the ReplicationServer xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchReplicationServer.desktop staging/linux/scripts/xdg/pg-launchReplicationServer.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


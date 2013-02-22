#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_hpux() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    # NOTE: As we are building jar files forReplication Server , same jar files generated for linux are sufficient for HPUX. That is why , we are building them on linux build machine.

    if [ -e ReplicationServer.linux ];
    then
      echo "Removing existing ReplicationServer.linux source directory"
      rm -rf ReplicationServer.linux  || _die "Couldn't remove the existing ReplicationServer.hpux source directory (source/ReplicationServer.linux)"
    fi
    if [ -e DataValidator.linux ];
    then
      echo "Removing existing DataValidator.linux source directory"
      rm -rf DataValidator.linux  || _die "Couldn't remove the existing DataValidator.linux source directory (source/DataValidator.linux)"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.linux)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.linux || _die "Couldn't create the ReplicationServer.linux directory"
    echo "Creating staging directory ($WD/ReplicationServer/source/DataValidator.linux)"
    mkdir -p $WD/ReplicationServer/source/DataValidator.linux || _die "Couldn't create the DataValidator.linux directory"

    # Grab a copy of the source tree
    cp -R $WD/ReplicationServer/source/XDB/replicator/* ReplicationServer.linux || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.linux || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the source tree
    cp -R $WD/ReplicationServer/source/XDB/DataValidator/* DataValidator.linux || _die "Failed to copy the source code (source/DataValidator-$PG_VERSION_DataValidator)"
    chmod -R ugo+w DataValidator.linux || _die "Couldn't set the permissions on the source directory"


    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.linux/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.linux/lib || _die "Failed to copy pg jdbc drivers"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/hpux)"
    mkdir -p $WD/ReplicationServer/staging/hpux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts || _die "Couldn't create the staging/hpux/instscripts directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts || _die "Couldn't set the permissions on the staging/hpux/instscripts directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Couldn't create the staging/hpux/instscripts/bin directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Couldn't set the permissions on the staging/hpux/instscripts/bin directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Couldn't create the staging/hpux/instscripts/lib directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Couldn't set the permissions on the staging/hpux/instscripts/lib directory"

    # Build Migration Toolkit for Replication Server installer. Building it on linux machine as we need only edb-migrationtoolkit.jar

    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ -e migrationToolKit.linux ];
    then
      echo "Removing existing migrationtoolkit.linux source directory"
      rm -rf migrationtoolkit.linux  || _die "Couldn't remove the existing migrationtoolkit.linux source directory (source/migrationtoolkit.linux)"
    fi

    echo "Creating migrationtoolkit source directory ($WD/MigrationToolKit/source/migrationtoolkit.linux)"
    mkdir -p migrationtoolkit.linux || _die "Couldn't create the migrationtoolkit.linux directory"
    chmod ugo+w migrationtoolkit.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the migrationtoolkit source tree
    cp -R EDB-MTK/* migrationtoolkit.linux || _die "Failed to copy the source code (source/migrationtoolkit-$PG_VERSION_MIGRATIONTOOLKIT)"
    chmod -R ugo+w migrationtoolkit.linux || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_VERSION_PGJDBC.jdbc3.jar migrationtoolkit.linux/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/MigrationToolKit/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/MigrationToolKit/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/MigrationToolKit/staging/hpux)"
    mkdir -p $WD/MigrationToolKit/staging/hpux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MigrationToolKit/staging/hpux || _die "Couldn't set the permissions on the staging directory"

    # Back to ReplicationServer/source directory.
    cd $WD/ReplicationServer/source

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_hpux() {

    # Build Migration Toolkit for Replication Server installer. Building it on linux machine as we need only edb-migrationtoolkit.jar
    # build migrationtoolkit    
    PG_STAGING=$PG_PATH_LINUX/MigrationToolKit/staging/hpux
    
    echo "Building migrationtoolkit"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant install-pg" || _die "Couldn't build the migrationtoolkit"

    # Copying the MigrationToolKit binary to staging directory
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; mkdir $PG_STAGING/MigrationToolKit" || _die "Couldn't create the migrationtoolkit staging directory (MigrationToolKit/staging/hpux/MigrationToolKit)"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/MigrationToolKit/source/migrationtoolkit.linux; cp -R install/* $PG_STAGING/MigrationToolKit" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (MigrationToolKit/staging/hpux/MigrationToolKit)"

    cd $WD

    # Build Replication Server
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; cp -R dist/* $PG_PATH_LINUX/ReplicationServer/staging/hpux/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant -f custom_build.xml encrypt-util" || _die "Failed to build the DESEncrypter utility"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/ReplicationServer.linux; cp -R dist/* $PG_PATH_LINUX/ReplicationServer/staging/hpux/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/DataValidator.linux; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ReplicationServer/source/DataValidator.linux; cp -R dist/* $PG_PATH_LINUX/ReplicationServer/staging/hpux/repconsole/" || _die "Failed to copy the dist content to staging directory"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp MigrationToolKit/staging/hpux/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/hpux/repserver/lib/repl-mtk" || _die "Failed to copy edb-migrationtoolkit.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/staging/hpux/repconsole/lib/jdbc/ || _die "Failed to copy pg jdbc drivers"
    cd $WD
    _replace "java -jar edb-repconsole.jar" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/hpux/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar pubserver @@PUBPORT@@" "$WD/ReplicationServer/staging/hpux/repserver/bin/runPubServer.sh" || _die "Failed to put the placehoder in runPubServer.sh file"
    _replace "java -jar edb-repserver.jar subserver 9012" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar subserver @@SUBPORT@@" "$WD/ReplicationServer/staging/hpux/repserver/bin/runSubServer.sh" || _die "Failed to put the placehoder in runSubServer.sh file"

    cd $WD

    cp $WD/binaries/AS91-HPUX/instscripts/psql $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Failed to copy psql binary"
    cp $WD/binaries/AS91-HPUX/instscripts/lib*.* $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Failed to copy libs"

    chmod +rx $WD/ReplicationServer/staging/hpux
    chmod +rx $WD/ReplicationServer/staging/hpux/repserver/bin/*
    chmod +rx $WD/ReplicationServer/staging/hpux/repconsole/bin/*
    chmod +r $WD/ReplicationServer/staging/hpux/repconsole/lib/*
    chmod +r $WD/ReplicationServer/staging/hpux/repconsole/lib/jdbc/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/jdbc/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/repl-mtk/*

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_hpux() {
 

    cd $WD/ReplicationServer

    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\.//g'`
    # Setup the installer scripts.
    mkdir -p staging/hpux/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"

    cp scripts/hpux/createuser.sh staging/hpux/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/hpux/createuser.sh)"
    chmod ugo+x staging/hpux/installer/xDBReplicationServer/createuser.sh

    cp staging/hpux/edb-repencrypter.jar staging/hpux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/hpux/edb-repencrypter.jar)"
    cp -R staging/hpux/lib staging/hpux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/hpux/lib)"

    # Setup Launch Scripts
    mkdir -p staging/hpux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/hpux/startupcfg_publication.sh staging/hpux/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/hpux/startupcfg_publication.sh)"
    chmod ugo+x staging/hpux/scripts/startupcfg_publication.sh
    cp scripts/hpux/startupcfg_subscription.sh staging/hpux/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/hpux/startupcfg_subscription.sh)"
    chmod ugo+x staging/hpux/scripts/startupcfg_subscription.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml hpux || _die "Failed to build the installer"

    cd $WD
}


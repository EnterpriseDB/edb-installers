#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_solaris_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.solaris-x64 ];
    then
      echo "Removing existing ReplicationServer.solaris-x64 source directory"
      rm -rf ReplicationServer.solaris-x64  || _die "Couldn't remove the existing ReplicationServer.solaris-x64 source directory (source/ReplicationServer.solaris-x64)"
    fi

    if [ -e ReplicationServer.solaris-x64.zip ];
    then
      echo "Removing existing ReplicationServer.solaris-x64 zip file"
      rm -rf ReplicationServer.solaris-x64.zip  || _die "Couldn't remove the existing ReplicationServer.solaris-x64 zip file (source/ReplicationServer.solaris-x64.zip)"
    fi

    if [ -e DataValidator.solaris-x64 ];
    then
      echo "Removing existing DataValidator.solaris-x64 source directory"
      rm -rf DataValidator.solaris-x64  || _die "Couldn't remove the existing DataValidator.solaris-x64 source directory (source/DataValidator.solaris-x64)"
    fi
   
    if [ -e DataValidator.solaris-x64.zip ];
    then
      echo "Removing existing DataValidator.solaris-x64 zip file"
      rm -rf DataValidator.solaris-x64.zip  || _die "Couldn't remove the existing DataValidator.solaris-x64 zip file (source/DataValidator.solaris-x64.zip)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.solaris-x64)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.solaris-x64 || _die "Couldn't create the ReplicationServer.solaris-x64 directory"
    echo "Creating staging directory ($WD/ReplicationServer/source/DataValidator.solaris-x64)"
    mkdir -p $WD/ReplicationServer/source/DataValidator.solaris-x64 || _die "Couldn't create the DataValidator.solaris-x64 directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.solaris-x64 || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.solaris-x64 || _die "Couldn't set the permissions on the source directory"

    cp -R DataValidator/* DataValidator.solaris-x64 || _die "Failed to copy the source code (source/DataValidator-$PG_VERSION_DataValidator)"
    chmod -R ugo+w DataValidator.solaris-x64 || _die "Couldn't set the permissions on the source directory"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.solaris-x64/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/DataValidator.solaris-x64/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.solaris-x64/lib || _die "Failed to copy pg jdbc drivers" 
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/DataValidator.solaris-x64/lib || _die "Failed to copy pg jdbc drivers" 

    zip -r ReplicationServer.solaris-x64.zip ReplicationServer.solaris-x64 || _die "Failed to zip the relication server source directory"
    zip -r DataValidator.solaris-x64.zip DataValidator.solaris-x64 || _die "Failed to zip the data validator source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/solaris-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/solaris-x64 || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64" || _die "Failed to remove the replication server staging directory from Solaris VM" 
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/solaris-x64)"
    mkdir -p $WD/ReplicationServer/staging/solaris-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/solaris-x64 || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/ReplicationServer/source" || _die "Failed to remove the replication server source directory from Solaris VM" 
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/ReplicationServer/source" || _die "Failed to create the replication server source directory on Solaris VM" 
    scp ReplicationServer.solaris-x64.zip DataValidator.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/ReplicationServer/source/
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source; unzip ReplicationServer.solaris-x64.zip" || _die "Failed to unzip the replication server source directory on Solaris VM" 
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source; unzip DataValidator.solaris-x64.zip" || _die "Failed to unzip the datavalidator source directory on Solaris VM" 
    ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64" || _die "Failed to create the replication server source directory on Solaris VM" 

    

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_solaris_x64() {

    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64; PATH=$PG_JAVA_HOME_SOLARIS_X64/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_X64 $PG_ANT_HOME_SOLARIS_X64/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64; cp -R dist/* $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64; PATH=$PG_JAVA_HOME_SOLARIS_X64/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_X64 $PG_ANT_HOME_SOLARIS_X64/bin/ant -f custom_build.xml encrypt-util" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64; cp -R dist/* $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/DataValidator.solaris-x64; PATH=$PG_JAVA_HOME_SOLARIS_X64/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_X64 $PG_ANT_HOME_SOLARIS_X64/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/DataValidator.solaris-x64; cp -R dist/* $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/repconsole/" || _die "Failed to copy the dist content to staging directory"

    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; mkdir -p ReplicationServer/staging/solaris-x64/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; mkdir -p ReplicationServer/staging/solaris-x64/instscripts/bin" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; mkdir -p ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/bin/psql ReplicationServer/staging/solaris-x64/instscripts/bin" || _die "Failed to copy psql binary"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libpq.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libpq.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libcrypto.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libcrypto.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libssl.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libssl.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libedit.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libedit.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libxml2.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libxslt.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libxml2.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libk5crypto.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libk5crypto.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libcom_err.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libcom_errso"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libkrb5.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libkrb5.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp server/staging/solaris-x64/lib/libkrb5support.so* ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libkrb5support.so"
    ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp MigrationToolKit/staging/solaris-x64/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/solaris-x64/repserver/lib/repl-mtk" || _die "Failed to copy edb-migrationtoolkit.jar"
    ssh $PG_SSH_SOLARIS_X64 "cp $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64/lib/postgresql-$PG_JAR_POSTGRESQL.jar $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/repconsole/lib/jdbc/" || _die "Failed to copy pg jdbc drivers" 
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/lib/libuuid.so* $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/instscripts/lib" || _die "Failed to copy libuuid2.so"
    ssh $PG_SSH_SOLARIS_X64 "cp /usr/local/bin/uuid $PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/instscripts/bin" || _die "Failed to copy uuid"

   # Build the validateUserClient binary
    if [ ! -f $WD/MetaInstaller/source/MetaInstaller.solaris-x64/validateUser/validateUserClient.o ]; then
        scp -r $WD/MetaInstaller/scripts/linux/validateUser $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64/ || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/ReplicationServer/source/ReplicationServer.solaris-x64/validateUser; PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH gcc -m64 -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto -lnsl -lsocket" || _die "Failed to build the validateUserClient utility"
        ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; cp ReplicationServer/source/ReplicationServer.solaris-x64/validateUser/validateUserClient.o ReplicationServer/staging/solaris-x64/instscripts/" || _die "Failed to copy validateUserClient.o"
    else
       cp $WD/MetaInstaller/source/MetaInstaller.solaris-x64/validateUser/validateUserClient.o $WD/ReplicationServer/staging/solaris-x64/instscripts/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi

    scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/ReplicationServer/staging/solaris-x64/* $WD/ReplicationServer/staging/solaris-x64/ || _die "Failed to copy back the staging directory from Solaris VM"

    cd $WD

    _replace "java -jar edb-repconsole.jar" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/solaris-x64/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar pubserver @@PUBPORT@@" "$WD/ReplicationServer/staging/solaris-x64/repserver/bin/runPubServer.sh" || _die "Failed to put the placehoder in runPubServer.sh file"
    _replace "java -jar edb-repserver.jar subserver 9012" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar subserver @@SUBPORT@@" "$WD/ReplicationServer/staging/solaris-x64/repserver/bin/runSubServer.sh" || _die "Failed to put the placehoder in runSubServer.sh file"

    chmod ugo+x $WD/ReplicationServer/staging/solaris-x64/instscripts/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_solaris_x64() {
 

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/solaris-x64/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"
    cp scripts/solaris/removeshortcuts.sh staging/solaris-x64/installer/xDBReplicationServer/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris-x64/removeshortcuts.sh)"
    chmod ugo+x staging/solaris-x64/installer/xDBReplicationServer/removeshortcuts.sh

    cp scripts/solaris/createshortcuts.sh staging/solaris-x64/installer/xDBReplicationServer/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/solaris-x64/createshortcuts.sh)"
    chmod ugo+x staging/solaris-x64/installer/xDBReplicationServer/createshortcuts.sh

    cp scripts/solaris/createuser.sh staging/solaris-x64/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/solaris-x64/createuser.sh)"
    chmod ugo+x staging/solaris-x64/installer/xDBReplicationServer/createuser.sh

    cp staging/solaris-x64/edb-repencrypter.jar staging/solaris-x64/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/solaris-x64/edb-repencrypter.jar)"
    cp -R staging/solaris-x64/lib staging/solaris-x64/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/solaris-x64/lib)" 
    # Setup Launch Scripts
    mkdir -p staging/solaris-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/solaris/startupcfg_publication.sh staging/solaris-x64/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/solaris-x64/startupcfg_publication.sh)"
    chmod ugo+x staging/solaris-x64/scripts/startupcfg_publication.sh
    cp scripts/solaris/startupcfg_subscription.sh staging/solaris-x64/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/solaris-x64/startupcfg_subscription.sh)"
    chmod ugo+x staging/solaris-x64/scripts/startupcfg_subscription.sh

    # Setup the ReplicationServer xdg Files
    mkdir -p staging/solaris-x64/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchReplicationServer.desktop staging/solaris-x64/scripts/xdg/pg-launchReplicationServer.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/solaris-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/solaris-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/solaris-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/solaris-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/solaris-x64/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-intel || _die "Failed to build the installer"
    mv $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-solaris-intel.bin $WD/output/xdbreplicationserver-$PG_VERSION_REPLICATIONSERVER-$PG_BUILDNUM_REPLICATIONSERVER-solaris-x64.bin
     
    cd $WD
}


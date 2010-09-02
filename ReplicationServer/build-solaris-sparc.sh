#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_solaris_sparc() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.solaris-sparc ];
    then
      echo "Removing existing ReplicationServer.solaris-sparc source directory"
      rm -rf ReplicationServer.solaris-sparc  || _die "Couldn't remove the existing ReplicationServer.solaris-sparc source directory (source/ReplicationServer.solaris-sparc)"
    fi

    if [ -e ReplicationServer.solaris-sparc.zip ];
    then
      echo "Removing existing ReplicationServer.solaris-sparc zip file"
      rm -rf ReplicationServer.solaris-sparc.zip  || _die "Couldn't remove the existing ReplicationServer.solaris-sparc zip file (source/ReplicationServer.solaris-sparc.zip)"
    fi

    if [ -e DataValidator.solaris-sparc ];
    then
      echo "Removing existing DataValidator.solaris-sparc source directory"
      rm -rf DataValidator.solaris-sparc  || _die "Couldn't remove the existing DataValidator.solaris-sparc source directory (source/DataValidator.solaris-sparc)"
    fi
   
    if [ -e DataValidator.solaris-sparc.zip ];
    then
      echo "Removing existing DataValidator.solaris-sparc zip file"
      rm -rf DataValidator.solaris-sparc.zip  || _die "Couldn't remove the existing DataValidator.solaris-sparc zip file (source/DataValidator.solaris-sparc.zip)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.solaris-sparc)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.solaris-sparc || _die "Couldn't create the ReplicationServer.solaris-sparc directory"
    echo "Creating staging directory ($WD/ReplicationServer/source/DataValidator.solaris-sparc)"
    mkdir -p $WD/ReplicationServer/source/DataValidator.solaris-sparc || _die "Couldn't create the DataValidator.solaris-sparc directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.solaris-sparc || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    cp -R DataValidator/* DataValidator.solaris-sparc || _die "Failed to copy the source code (source/DataValidator-$PG_VERSION_DataValidator)"
    chmod -R ugo+w DataValidator.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.solaris-sparc/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/DataValidator.solaris-sparc/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.solaris-sparc/lib || _die "Failed to copy pg jdbc drivers" 
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/DataValidator.solaris-sparc/lib || _die "Failed to copy pg jdbc drivers" 

    zip -r ReplicationServer.solaris-sparc.zip ReplicationServer.solaris-sparc || _die "Failed to zip the relication server source directory"
    zip -r DataValidator.solaris-sparc.zip DataValidator.solaris-sparc || _die "Failed to zip the data validator source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc" || _die "Failed to remove the replication server staging directory from Solaris VM" 
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/solaris-sparc)"
    mkdir -p $WD/ReplicationServer/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/ReplicationServer/source" || _die "Failed to remove the replication server source directory from Solaris VM" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/ReplicationServer/source" || _die "Failed to create the replication server source directory on Solaris VM" 
    scp ReplicationServer.solaris-sparc.zip DataValidator.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/ReplicationServer/source/
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source; unzip ReplicationServer.solaris-sparc.zip" || _die "Failed to unzip the replication server source directory on Solaris VM" 
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source; unzip DataValidator.solaris-sparc.zip" || _die "Failed to unzip the datavalidator source directory on Solaris VM" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc" || _die "Failed to create the replication server source directory on Solaris VM" 

    

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_solaris_sparc() {

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc; PATH=$PG_JAVA_HOME_SOLARIS_SPARC/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC $PG_ANT_HOME_SOLARIS_SPARC/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc; cp -R dist/* $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc; PATH=$PG_JAVA_HOME_SOLARIS_SPARC/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC $PG_ANT_HOME_SOLARIS_SPARC/bin/ant -f custom_build.xml encrypt-util" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc; cp -R dist/* $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/" || _die "Failed to copy the dist content to staging directory"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/DataValidator.solaris-sparc; PATH=$PG_JAVA_HOME_SOLARIS_SPARC/bin:\$PATH JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC $PG_ANT_HOME_SOLARIS_SPARC/bin/ant -f custom_build.xml dist" || _die "Failed to build the Replication xDB Replicator"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/DataValidator.solaris-sparc; cp -R dist/* $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/repconsole/" || _die "Failed to copy the dist content to staging directory"

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; mkdir -p ReplicationServer/staging/solaris-sparc/instscripts" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; mkdir -p ReplicationServer/staging/solaris-sparc/instscripts/bin" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; mkdir -p ReplicationServer/staging/solaris-sparc/instscripts/lib" || _die "Failed to create instscripts directory"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; cp MigrationToolKit/staging/solaris-sparc/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/solaris-sparc/repserver/lib/repl-mtk" || _die "Failed to copy edb-migrationtoolkit.jar"
    ssh $PG_SSH_SOLARIS_SPARC "cp $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc/lib/postgresql-$PG_JAR_POSTGRESQL.jar $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/repconsole/lib/jdbc/" || _die "Failed to copy pg jdbc drivers" 
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libuuid.so* $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/instscripts/lib" || _die "Failed to copy libuuid2.so"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/bin/uuid $PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/instscripts/bin" || _die "Failed to copy uuid"

   # Build the validateUserClient binary
    if [ ! -f $WD/MetaInstaller/source/MetaInstaller.solaris-sparc/validateUser/validateUserClient.o ]; then
        scp -r $WD/MetaInstaller/scripts/linux/validateUser $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc/ || _die "Failed to copy validateUser source files"
        ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/ReplicationServer/source/ReplicationServer.solaris-sparc/validateUser; PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH gcc -m64 -DWITH_OPENSSL -I. -o validateUserClient.o WSValidateUserClient.c soapC.c soapClient.c stdsoap2.c -lssl -lcrypto -lnsl -lsocket" || _die "Failed to build the validateUserClient utility"
        ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; cp ReplicationServer/source/ReplicationServer.solaris-sparc/validateUser/validateUserClient.o ReplicationServer/staging/solaris-sparc/instscripts/" || _die "Failed to copy validateUserClient.o"
    else
       cp $WD/MetaInstaller/source/MetaInstaller.solaris-sparc/validateUser/validateUserClient.o $WD/ReplicationServer/staging/solaris-sparc/instscripts/validateUserClient.o || _die "Failed to copy validateUserClient.o utility"
    fi

    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/ReplicationServer/staging/solaris-sparc/* $WD/ReplicationServer/staging/solaris-sparc/ || _die "Failed to copy back the staging directory from Solaris VM"

    PG_CACHE_PATH=$WD/server/source/postgres.solaris-sparc.cache
    XDB_STAGING=$WD/ReplicationServer/staging/solaris-sparc
    XDB_PLATFORM=Solaris-sparc

    cp $PG_CACHE_PATH/bin/psql $XDB_STAGING/instscripts/bin || _die "Failed to copy psql binary ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libpq.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libpq.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libcrypto.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libcrypto.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libssl.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libssl.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libreadline.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libreadline.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libxml2.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libxml2.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libxslt.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libxml2.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libk5crypto.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libk5crypto.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libcom_err.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libcom_errso ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libkrb5.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libkrb5.so ($XDB_PLATFORM)"
    cp $PG_CACHE_PATH/lib/libkrb5support.so* $XDB_STAGING/instscripts/lib || _die "Failed to copy libkrb5support.so ($XDB_PLATFORM)"

    cd $WD

    _replace "java -jar edb-repconsole.jar" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repconsole.jar" "$WD/ReplicationServer/staging/solaris-sparc/repconsole/bin/runRepConsole.sh" || _die "Failed to put the placehoder in runRepConsole.sh file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar pubserver @@PUBPORT@@" "$WD/ReplicationServer/staging/solaris-sparc/repserver/bin/runPubServer.sh" || _die "Failed to put the placehoder in runPubServer.sh file"
    _replace "java -jar edb-repserver.jar subserver 9012" "@@JAVA@@ -jar @@INSTALL_DIR@@/bin/edb-repserver.jar subserver @@SUBPORT@@" "$WD/ReplicationServer/staging/solaris-sparc/repserver/bin/runSubServer.sh" || _die "Failed to put the placehoder in runSubServer.sh file"

    chmod ugo+x $WD/ReplicationServer/staging/solaris-sparc/instscripts/validateUserClient.o || _die "Failed to give execution permission to validateUserClient.o"

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_solaris_sparc() {
 

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/solaris-sparc/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"
    cp scripts/solaris/removeshortcuts.sh staging/solaris-sparc/installer/xDBReplicationServer/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris-sparc/removeshortcuts.sh)"
    chmod ugo+x staging/solaris-sparc/installer/xDBReplicationServer/removeshortcuts.sh

    cp scripts/solaris/createshortcuts.sh staging/solaris-sparc/installer/xDBReplicationServer/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/solaris-sparc/createshortcuts.sh)"
    chmod ugo+x staging/solaris-sparc/installer/xDBReplicationServer/createshortcuts.sh

    cp scripts/solaris/createuser.sh staging/solaris-sparc/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/solaris-sparc/createuser.sh)"
    chmod ugo+x staging/solaris-sparc/installer/xDBReplicationServer/createuser.sh

    cp staging/solaris-sparc/edb-repencrypter.jar staging/solaris-sparc/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/solaris-sparc/edb-repencrypter.jar)"
    cp -R staging/solaris-sparc/lib staging/solaris-sparc/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/solaris-sparc/lib)" 
    # Setup Launch Scripts
    mkdir -p staging/solaris-sparc/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/solaris/startupcfg_publication.sh staging/solaris-sparc/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/solaris-sparc/startupcfg_publication.sh)"
    chmod ugo+x staging/solaris-sparc/scripts/startupcfg_publication.sh
    cp scripts/solaris/startupcfg_subscription.sh staging/solaris-sparc/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/solaris-sparc/startupcfg_subscription.sh)"
    chmod ugo+x staging/solaris-sparc/scripts/startupcfg_subscription.sh

    # Setup the ReplicationServer xdg Files
    mkdir -p staging/solaris-sparc/scripts/xdg || _die "Failed to create a directory for the launch scripts"
    cp resources/xdg/pg-launchReplicationServer.desktop staging/solaris-sparc/scripts/xdg/pg-launchReplicationServer.desktop || _die "Failed to copy the xdg files "
    cp resources/xdg/pg-postgresql.directory staging/solaris-sparc/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files "

    # Copy in the menu pick images
    mkdir -p staging/solaris-sparc/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/solaris-sparc/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/solaris-sparc/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"
    
    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/solaris-sparc/installer/xdg || _die "Failed to copy the xdg files "
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer"
     
    cd $WD
}


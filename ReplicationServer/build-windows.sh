#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    if [ -e ReplicationServer.windows ];
    then
      echo "Removing existing ReplicationServer.windows source directory"
      rm -rf ReplicationServer.windows  || _die "Couldn't remove the existing ReplicationServer.windows source directory (source/ReplicationServer.windows)"
    fi
   
    if [ -e ReplicationServer.zip ];
    then
      echo "Removing existing ReplicationServer.zip"
      rm -f ReplicationServer.zip  || _die "Couldn't remove the existing ReplicationServer.zip (source/ReplicationServer.zip)"
    fi
   
    echo "Creating staging directory ($WD/ReplicationServer/source/ReplicationServer.windows)"
    mkdir -p $WD/ReplicationServer/source/ReplicationServer.windows || _die "Couldn't create the ReplicationServer.windows directory"

    # Grab a copy of the source tree
    cp -R replicator/* ReplicationServer.windows || _die "Failed to copy the source code (source/ReplicationServer-$PG_VERSION_ReplicationServer)"
    chmod -R ugo+w ReplicationServer.windows || _die "Couldn't set the permissions on the source directory"

    # Copy validateuser to ReplicationServer directory
    cp -R $WD/ReplicationServer/scripts/windows/validateuser $WD/ReplicationServer/source/ReplicationServer.windows/validateuser || _die "Failed to copy scripts(validateuser)"

    # Copy createuser to ReplicationServer directory
    cp -R $WD/ReplicationServer/scripts/windows/createuser $WD/ReplicationServer/source/ReplicationServer.windows/createuser || _die "Failed to copy scripts(createuser)"

    # Copy ServiceWrapper to ReplicationServer directory
    cp -R $WD/resources/ServiceWrapper $WD/ReplicationServer/source/ReplicationServer.windows/ServiceWrapper || _die "Failed to copy scripts(ServiceWrapper)"

    #Copy the required jdbc drivers
    cp $WD/tarballs/edb-jdbc14.jar $WD/ReplicationServer/source/ReplicationServer.windows/lib || _die "Failed to copy the edb-jdbc-14.jar"
    cp $WD/ReplicationServer/source/pgJDBC-$PG_VERSION_PGJDBC/postgresql-$PG_JAR_POSTGRESQL.jar $WD/ReplicationServer/source/ReplicationServer.windows/lib || _die "Failed to copy pg jdbc drivers" 

    echo "Archieving ReplicationServer sources"
    zip -r ReplicationServer.zip ReplicationServer.windows/ || _die "Couldn't create archieve of the ReplicationServer sources (ReplicationServer.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/windows)"
    mkdir -p $WD/ReplicationServer/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Clean sources on Windows VM

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST ReplicationServer.zip del /S /Q ReplicationServer.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\ReplicationServer.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST ReplicationServer.windows rd /S /Q ReplicationServer.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\ReplicationServer.windows directory on Windows VM"

    # Copy sources on windows VM
    echo "Copying ReplicationServer sources to Windows VM"
    scp ReplicationServer.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the ReplicationServer archieve to windows VM (ReplicationServer.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip ReplicationServer.zip" || _die "Couldn't extract ReplicationServer archieve on windows VM (ReplicationServer.zip)"

}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_windows() {


     # build ReplicationServer   
    PG_STAGING=$PG_PATH_WINDOWS
    cd $WD/ReplicationServer
    SOURCE_DIR=$PG_PATH_WINDOWS/ReplicationServer.windows
    OUTPUT_DIR=$PG_PATH_WINDOWS\\\\ReplicationServer.windows\\\\dist
    STAGING_DIR=$WD/ReplicationServer/staging/windows
 
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR ; cmd /c $PG_ANT_WINDOWS\\\\bin\\\\ant -f custom_build.xml dist" || _die "Failed to build replication server on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/validateuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/createuser ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcproj RELEASE" || _die "Failed to build validateuser on the build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/ServiceWrapper ; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat ServiceWrapper.vcproj RELEASE" || _die "Failed to build validateuser on the build host"

    echo "copying application files into the output directory"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy validateuser\\\\release\\\\validateuser.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy createuser\\\\release\\\\createuser.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR; cmd /c copy ServiceWrapper\\\\release\\\\ServiceWrapper.exe $OUTPUT_DIR" || _die "Failed to copy a program file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy /Y C:\\\\pgBuild\\\\vcredist\\\\vcredist_x86.exe  $OUTPUT_DIR" || _die "Failed to copy the VC++ runtimes on the windows build host"

    # Zip up the installed code, copy it back here, and unpack.
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/; cmd /c zip -r dist.zip dist\\\\*" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$SOURCE_DIR/ReplicationServer.windows)"
    #Build encrypt-util
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR ; cmd /c $PG_ANT_WINDOWS\\\\bin\\\\ant -f custom_build.xml encrypt-util" || _die "Failed to build replication server on the build host"
    # Append to dist.zip
    ssh $PG_SSH_WINDOWS "cd $SOURCE_DIR/; cmd /c zip -r dist.zip dist\\\\*" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$SOURCE_DIR/ReplicationServer.windows)"
    echo "Copying built tree to host"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/ReplicationServer.windows/dist.zip $WD/ReplicationServer/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/ReplicationServer.windows/dist.zip)"
    unzip $WD/ReplicationServer/staging/windows/dist.zip -d $WD/ReplicationServer/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/dist.zip)"
    rm $WD/ReplicationServer/staging/windows/dist.zip
    cp -R $WD/ReplicationServer/staging/windows/dist/* $WD/ReplicationServer/staging/windows/ || _die "Failed to rename the dist folder"
    rm -rf $WD/ReplicationServer/staging/windows/dist

    mkdir -p $WD/ReplicationServer/staging/windows/instscripts/bin || _die "Failed to make the instscripts bin directory"
    mkdir -p $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to make the installer scripts directory"
    mkdir -p $WD/ReplicationServer/staging/windows/scripts || _die "Failed to make the scripts bin directory"
    
    mv $WD/ReplicationServer/staging/windows/validateuser.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/vcredist_x86.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/createuser.exe $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/ServiceWrapper.exe $WD/ReplicationServer/staging/windows/scripts || _die "Failed to copy the utilities"
    mv $WD/ReplicationServer/staging/windows/edb-repencrypter.jar $WD/ReplicationServer/staging/windows/installer/xDBReplicationServer || _die "Failed to copy the utilities"
    
    cd $WD
    cp -R server/staging/windows/lib/libpq* ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll ReplicationServer/staging/windows/instscripts/bin || _die "Failed to copy dependent libs"
    cp -R MigrationToolKit/staging/windows/MigrationToolKit/lib/edb-migrationtoolkit.jar ReplicationServer/staging/windows/repserver/lib/repl-mtk || _die "Failed to copy edb-migrationtoolkit.jar"

    _replace "java -jar edb-repconsole.jar" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repconsole.jar\"" "$WD/ReplicationServer/staging/windows/repconsole/bin/runRepConsole.bat" || _die "Failed to put the placehoder in runRepConsole.bat file"
    _replace "java -jar edb-repserver.jar pubserver 9011" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repserver.jar\" pubserver @@PUBPORT@@ \"@@CONFPATH@@\"" "$WD/ReplicationServer/staging/windows/repserver/bin/runPubServer.bat" || _die "Failed to put the placehoder in runPubServer.bat file"
    _replace "java -jar edb-repserver.jar subserver 9012" "\"@@JAVA@@\" -jar \"@@INSTALL_DIR@@\\\\bin\\\\edb-repserver.jar\" subserver @@SUBPORT@@ \"@@CONFPATH@@\"" "$WD/ReplicationServer/staging/windows/repserver/bin/runSubServer.bat" || _die "Failed to put the placehoder in runSubServer.bat file"

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_windows() {
 

    cd $WD/ReplicationServer

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"

    # Setup Launch Scripts
    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/windows/serviceWrapper.vbs staging/windows/scripts/ || _die "Failed to copy the serviceWrapper.vbs file"
    cp scripts/windows/runRepConsole.vbs staging/windows/scripts/ || _die "Failed to copy the serviceWrapper.vbs file"
    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD
}


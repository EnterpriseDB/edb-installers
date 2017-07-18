#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_hdfs_fdw_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/hdfs_fdw/source

    if [ -e hdfs_fdw.linux-x64 ];
    then
      echo "Removing existing hdfs_fdw.linux-x64 source directory"
      rm -rf hdfs_fdw.linux-x64  || _die "Couldn't remove the existing hdfs_fdw.linux-x64 source directory (source/hdfs_fdw.linux-x64)"
    fi

    echo "Creating source directory ($WD/hdfs_fdw/source/hdfs_fdw.linux-x64)"
    mkdir -p $WD/hdfs_fdw/source/hdfs_fdw.linux-x64 || _die "Couldn't create the hdfs_fdw.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R $WD/hdfs_fdw/source/hdfs_fdw/* hdfs_fdw.linux-x64 || _die "Failed to copy the source code (source/hdfs_fdw-linux-x64)"

    chmod -R 755 hdfs_fdw.linux-x64 || _die "Couldn't set the permissions on the source directory"

    cd $WD/hdfs_fdw/source

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hdfs_fdw/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hdfs_fdw/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hdfs_fdw/staging/linux-x64.build)"
    mkdir -p $WD/hdfs_fdw/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hdfs_fdw/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"
}

_build_hdfs_fdw_linux_x64() {

    # build hdfs_fdw
    PG_STAGING_HDFS_FDW=$PG_PATH_LINUX_X64/hdfs_fdw/staging/linux-x64.build

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; make" || _die "Failed to build libhive"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; export INSTALL_DIR=$PG_PGHOME_LINUX_X64;  make install" || _die "Failed to install libhive"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; make USE_PGXS=1" || _die "Failed to build hdfs_fdw"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; make USE_PGXS=1 install" || _die "Failed to install hdfs_fdw"

   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive/jdbc; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; javac MsgBuf.java" || _die "Failed to do javac MsgBuf.java"

   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive/jdbc; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; javac HiveJdbcClient.java" || _die "Failed to do javac HiveJdbcClient.java"

   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive/jdbc; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export JDK_INCLUDE=$PG_JAVA_HOME_LINUX_X64/include; export JVM_LIB=$PG_JAVA_HOME_LINUX_X64/jre/lib/amd64/server; jar cf HiveJdbcClient-1.0.jar *.class" || _die "Failed to do jar cf HiveJdbcClient-1.0.jar *.class"

    mkdir -p $WD/hdfs_fdw/staging/linux-x64.build/lib/postgresql
    mkdir -p $WD/hdfs_fdw/staging/linux-x64.build/share/postgresql/extension
    # Move the .so and the extension files from server staging to hdfs_fdw staging
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/lib/postgresql/hdfs_fdw.so $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to move hdfs_fdw .so to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/libhive.so $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to move libhive .so to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/share/postgresql/extension/hdfs_fdw* $PG_STAGING_HDFS_FDW/share/postgresql/extension/" || _die "Failed to move extension files to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive/jdbc/HiveJdbcClient-1.0.jar $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to move extension files to staging directory"

    echo "Changing the rpath"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib/postgresql/; chrpath --replace \"\\\${ORIGIN}\" hdfs_fdw.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib/postgresql/; chrpath --replace \"\\\${ORIGIN}:\\\${ORIGIN}/..\" libhive.so"
    #ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"

    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING_HDFS_FDW" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/hdfs_fdw ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/hdfs_fdw directory"
        rm -rf $WD/output/symbols/linux-x64/hdfs_fdw  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/hdfs_fdw directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/hdfs_fdw/staging/linux-x64.build/symbols $WD/output/symbols/linux-x64/hdfs_fdw || _die "Failed to move $WD/hdfs_fdw/staging/linux-x64.build/symbols to $WD/output/symbols/linux-x64/hdfs_fdw directory"

    echo "Removing last successful staging directory ($WD/hdfs_fdw/staging/linux-x64)"
    rm -rf $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/hdfs_fdw/staging/linux-x64.build/* $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_HDFS_FDW=$PG_VERSION_HDFS_FDW" > $WD/hdfs_fdw/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_HDFS_FDW=$PG_BUILDNUM_HDFS_FDW" >> $WD/hdfs_fdw/staging/linux-x64/versions-linux-x64.sh
    echo "PG_CURRENT_VERSION=$PG_CURRENT_VERSION" >> $WD/hdfs_fdw/staging/linux-x64/versions-linux-x64.sh

}


_postprocess_hdfs_fdw_linux_x64() {

    source $WD/hdfs_fdw/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_HDFS_FDW=$(expr $PG_BUILD_HDFS_FDW + $SKIPBUILD)

    cd $WD/hdfs_fdw

    mv staging/README.md staging/linux-x64/hdfs_fdw_README.md || _die "Failed to rename README.md in staging directory"
    mv staging/INSTALL staging/linux-x64/hdfs_fdw_INSTALL || _die "Failed to rename README.md in staging directory"

    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_HDFS_FDW -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/hdfs_fdw-pg$PG_CURRENT_VERSION-$PG_VERSION_HDFS_FDW-$PG_BUILDNUM_HDFS_FDW-linux-x64.run $WD/output/hdfs_fdw-pg$PG_CURRENT_VERSION-$PG_VERSION_HDFS_FDW-$PG_BUILDNUM_HDFS_FDW-${BUILD_FAILED}linux-x64.run

    cd $WD
}

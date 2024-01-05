#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.linux-x64 ];
    then
      echo "Removing existing edbmtk.linux-x64 source directory"
      rm -rf edbmtk.linux-x64  || _die "Couldn't remove the existing edbmtk.linux-x64 source directory (source/edbmtk.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/edbmtk/source/edbmtk.linux-x64)"
    mkdir -p $WD/edbmtk/source/edbmtk.linux-x64 || _die "Couldn't create the edbmtk.linux-x64 directory"
    chmod 755 edbmtk.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the binaries
    cp -R EDB-MTK/* edbmtk.linux-x64 || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_EDBMTK)"

    # Download edb-jdbc17.jar from redux store
    wget http://redux-store.ox.uk.enterprisedb.com/store/live_jdbc_jars/edb-jdbc17.jar
    mv edb-jdbc17.jar edbmtk.linux-x64/lib || _die "Failed to copy edb-jdbc17.jar from redux store to source."

    chmod -R 755 edbmtk.linux-x64 || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$EDB_VERSION_PGJDBC/postgresql-$EDB_VERSION_PGJDBC.jdbc4.jar edbmtk.linux-x64/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/linux-x64.build)"
    mkdir -p $WD/edbmtk/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"

    mkdir -p $WD/edbmtk/staging/linux-x64.build/scripts
    cp $WD/server/scripts/uuid_gen.c $WD/edbmtk/staging/linux-x64.build/scripts || _die "Failed to copy uuid_gen.c"
}

################################################################################
# PG Build
################################################################################

build_edbmtk_Linux64(){

    # build migrationtoolkit    
    EDB_STAGING=$EDB_PATH_LINUX_X64/edbmtk/staging/linux-x64.build

    echo "Building migrationtoolkit"
    ssh $EDB_SSH_LINUX_X64 "cd $EDB_PATH_LINUX_X64/edbmtk/source/edbmtk.linux-x64; JAVA_HOME=$EDB_JAVA_HOME_LINUX_X64 $EDB_ANT_HOME_LINUX_X64/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $EDB_SSH_LINUX_X64 "cd $EDB_PATH_LINUX_X64/edbmtk/source/edbmtk.linux-x64; JAVA_HOME=$EDB_JAVA_HOME_LINUX_X64 $EDB_ANT_HOME_LINUX_X64/bin/ant -f build.xml install-as" || _die "Couldn't build the migrationtoolkit"

    # Copying the MigrationToolKit binary to staging directory
    ssh $EDB_SSH_LINUX_X64 "cd $EDB_PATH_LINUX_X64/edbmtk/source/edbmtk.linux-x64; cp -R install/* $EDB_STAGING" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (edbmtk/staging/linux-x64.build)"
    rm -f $WD/edbmtk/staging/linux-x64.build/bin/*.bat || _die "Failed to remove .bat files from bin directory"

}

_build_edbmtk_linux_x64(){

    #Build components
    build_components "$COMPONENTS_LINUX_X64_UNSUPPORTED" "$COMPONENTS_LINUX_X64_DISABLED" "Linux64" "$PACKAGE"

    ssh $EDB_SSH_LINUX_X64 "cd $EDB_PATH_LINUX_X64/edbmtk/staging/linux-x64.build/scripts; gcc -I /opt/local/Current/include uuid_gen.c /opt/local/Current/lib/libuuid.a -o uuid_gen" || _die "Failed to build uuid_gen utility"

    echo "Removing last successful staging directory ($WD/edbmtk/staging/linux-x64)"
    rm -rf $WD/edbmtk/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/edbmtk/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/edbmtk/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/edbmtk/staging/linux-x64.build/* $WD/edbmtk/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "EDB_VERSION_EDBMTK=$EDB_VERSION_EDBMTK" > $WD/edbmtk/staging/linux-x64/versions-linux-x64.sh
    echo "EDB_BUILDNUM_EDBMTK=$EDB_BUILDNUM_EDBMTK" >> $WD/edbmtk/staging/linux-x64/versions-linux-x64.sh

}

################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_linux_x64() {

    source $WD/edbmtk/staging/linux-x64/versions-linux-x64.sh
    EDB_BUILD_EDBMTK=$(expr $EDB_BUILD_EDBMTK + $SKIPBUILD)
 
    cd $WD/edbmtk

    pushd staging/linux-x64
    generate_3rd_party_license "${EDBMTK_INSTALLER_NAME_PREFIX}"
    popd

    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f1 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/linux-x64/bin/runMTK.sh || _die "Failed to put $CORE_EDBMTK_VERSION in runMTK.sh"

    mkdir -p staging/linux-x64/etc/sysconfig || _die "Failed to create etc/sysconfig directory"

    cp scripts/common/edbmtk.config staging/linux-x64/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to create file edbmtk-$CORE_EDBMTK_VERSION.config"
    cp $WD/scripts/common_scripts/runJavaApplication.sh staging/linux-x64/etc/sysconfig/ || _die "Failed to copy runJavaApplication.sh"

    cp -R $WD/server/scripts/linux/sysinfo.sh $WD/edbmtk/staging/linux-x64/scripts || _die "Failed to copy the sysinfo.sh (edbmtk/staging/linux-x64/scripts)"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/linux-x64/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to put CORE_EDBMTK_VERSION in edbmtk-$CORE_EDBMTK_VERSION.config"

    chmod ugo+x staging/linux-x64/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/linux-x64 -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/linux-x64 -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/linux-x64 -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/linux-x64 -name \*.sh -exec chmod 755 {} \;

    chmod 755 $WD/edbmtk/staging/linux-x64/scripts/uuid_gen || _die "Failed to set permissions uuid_gen"

    # Build the installer
    "$EDB_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $EDB_BUILD_EDBMTK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    CMD_INSTALLER_NAME="$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-${BUILD_FAILED}linux-x64.run"

    echo "Installer_Name:$CMD_INSTALLER_NAME" >> $CMD_PRODUCT_INFO_LOG
    echo "Version:$CMD_INSTALLER_VERSION" >> $CMD_PRODUCT_INFO_LOG

    # Rename the installer
    mv $WD/output/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-linux-x64.run $WD/output/$CMD_INSTALLER_NAME

    #Copy staging directory
    copy_binaries edbmtk linux-x64

    cd $WD
}


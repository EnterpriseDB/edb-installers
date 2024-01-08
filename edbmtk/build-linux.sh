#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.linux ];
    then
      echo "Removing existing edbmtk.linux source directory"
      rm -rf edbmtk.linux  || _die "Couldn't remove the existing edbmtk.linux source directory (source/edbmtk.linux)"
    fi
   
    echo "Creating staging directory ($WD/edbmtk/source/edbmtk.linux)"
    mkdir -p $WD/edbmtk/source/edbmtk.linux || _die "Couldn't create the edbmtk.linux directory"
    chmod 755 edbmtk.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the binaries
    cp -R EDB-MTK/* edbmtk.linux || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_EDBMTK)"

    # Copy edb-jdbc17.jar from connectors
    cp $WD/connectors/staging/linux/jdbc/edb-jdbc17.jar edbmtk.linux/lib || _die "Failed to copy edb-jdbc17.jar from connectors staging directory to source."

    chmod -R 755 edbmtk.linux || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$EDB_VERSION_PGJDBC/postgresql-$EDB_VERSION_PGJDBC.jdbc4.jar edbmtk.linux/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/linux.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/linux.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/linux.build)"
    mkdir -p $WD/edbmtk/staging/linux.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/linux.build || _die "Couldn't set the permissions on the staging directory"

    mkdir -p $WD/edbmtk/staging/linux.build/scripts
    cp $WD/server/scripts/uuid_gen.c $WD/edbmtk/staging/linux.build/scripts || _die "Failed to copy uuid_gen.c"
    
}

################################################################################
# PG Build
################################################################################

build_edbmtk_Linux32(){

    # build migrationtoolkit    
    EDB_STAGING=$EDB_PATH_LINUX/edbmtk/staging/linux.build

    echo "Building migrationtoolkit"
    ssh $EDB_SSH_LINUX "cd $EDB_PATH_LINUX/edbmtk/source/edbmtk.linux; JAVA_HOME=$EDB_JAVA_HOME_LINUX $EDB_ANT_HOME_LINUX/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $EDB_SSH_LINUX "cd $EDB_PATH_LINUX/edbmtk/source/edbmtk.linux; JAVA_HOME=$EDB_JAVA_HOME_LINUX $EDB_ANT_HOME_LINUX/bin/ant -f build.xml install-as" || _die "Couldn't build the migrationtoolkit"

    # Copying the MigrationToolKit binary to staging directory
    ssh $EDB_SSH_LINUX "cd $EDB_PATH_LINUX/edbmtk/source/edbmtk.linux; cp -R install/* $EDB_STAGING" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (edbmtk/staging/linux.build)"
    rm -f $WD/edbmtk/staging/linux.build/bin/*.bat || _die "Failed to remove .bat files from bin directory"

}

_build_edbmtk_linux(){

    #Build components
    build_components "$COMPONENTS_LINUX_UNSUPPORTED" "$COMPONENTS_LINUX_DISABLED" "Linux32" "$PACKAGE"

    ssh $EDB_SSH_LINUX "cd $EDB_PATH_LINUX/edbmtk/staging/linux.build/scripts; gcc -I /opt/local/Current/include uuid_gen.c /opt/local/Current/lib/libuuid.a -o uuid_gen" || _die "Failed to build uuid_gen utility"

    echo "Removing last successful staging directory ($WD/edbmtk/staging/linux)"
    rm -rf $WD/edbmtk/staging/linux || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/edbmtk/staging/linux || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/edbmtk/staging/linux || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/edbmtk/staging/linux.build/* $WD/edbmtk/staging/linux || _die "Couldn't copy the existing staging directory"
    echo "EDB_VERSION_EDBMTK=$EDB_VERSION_EDBMTK" > $WD/edbmtk/staging/linux/versions-linux.sh
    echo "EDB_BUILDNUM_EDBMTK=$EDB_BUILDNUM_EDBMTK" >> $WD/edbmtk/staging/linux/versions-linux.sh

}
################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_linux() {

    source $WD/edbmtk/staging/linux/versions-linux.sh
    EDB_BUILD_EDBMTK=$(expr $EDB_BUILD_EDBMTK + $SKIPBUILD)
 
    cd $WD/edbmtk

    pushd staging/linux
    generate_3rd_party_license "${EDBMTK_INSTALLER_NAME_PREFIX}"
    popd

    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f1 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/linux/bin/runMTK.sh || _die "Failed to put $CORE_EDBMTK_VERSION in runMTK.sh"

    mkdir -p staging/linux/etc/sysconfig || _die "Failed to create etc/sysconfig directory"

    cp scripts/common/edbmtk.config staging/linux/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to create file edbmtk-$CORE_EDBMTK_VERSION.config"
    cp $WD/scripts/common_scripts/runJavaApplication.sh staging/linux/etc/sysconfig/ || _die "Failed to copy runJavaApplication.sh"

    cp -R $WD/server/scripts/linux/sysinfo.sh $WD/edbmtk/staging/linux/scripts || _die "Failed to copy the sysinfo.sh (edbmtk/staging/linux/scripts)"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/linux/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to put CORE_EDBMTK_VERSION in edbmtk-$CORE_EDBMTK_VERSION.config"

    chmod ugo+x staging/linux/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/linux -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/linux -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/linux -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/linux -name \*.sh -exec chmod 755 {} \;

    chmod 755 $WD/edbmtk/staging/linux/scripts/uuid_gen || _die "Failed to set permissions uuid_gen"

    # Build the installer
    "$EDB_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $EDB_BUILD_EDBMTK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    CMD_INSTALLER_NAME="$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-${BUILD_FAILED}linux.run"

    echo "Installer_Name:$CMD_INSTALLER_NAME" >> $CMD_PRODUCT_INFO_LOG
    echo "Version:$CMD_INSTALLER_VERSION" >> $CMD_PRODUCT_INFO_LOG

    # Rename the installer
    mv $WD/output/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-linux.run $WD/output/$CMD_INSTALLER_NAME

    #Copy staging directory
    copy_binaries edbmtk linux

    cd $WD
}


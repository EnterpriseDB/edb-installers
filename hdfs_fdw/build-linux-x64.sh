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
    if [ -e $WD/hdfs_fdw/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hdfs_fdw/staging/linux-x64)"
    mkdir -p $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hdfs_fdw/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
}

_build_hdfs_fdw_linux_x64() {

    # build hdfs_fdw
    PG_STAGING_HDFS_FDW=$PG_PATH_LINUX_X64/hdfs_fdw/staging/linux-x64

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive; export PGDIR=$PG_PGHOME_LINUX_X64; export THRIFT_HOME=/opt/local/Current/thrift; export BOOST_HOME=/opt/local/Current/boost; make" || _die "Failed to build libhive"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64/libhive; export PGDIR=$PG_PGHOME_LINUX_X64; export THRIFT_HOME=/opt/local/Current/thrift; export BOOST_HOME=/opt/local/Current/boost; make install" || _die "Failed to install libhive"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64; export LD_LIBRARY_PATH=/opt/local/Current/thrift/lib:$LD_LIBRARY_PATH; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; export THRIFT_HOME=/opt/local/Current/thrift; make USE_PGXS=1" || _die "Failed to build hdfs_fdw"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/hdfs_fdw/source/hdfs_fdw.linux-x64; export PATH=$PG_PGHOME_LINUX_X64/bin:$PATH; make USE_PGXS=1 install" || _die "Failed to install hdfs_fdw"

    # Copy in the dependency libraries
    mkdir -p $WD/hdfs_fdw/staging/linux-x64/lib/postgresql
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/thrift/lib/libthrift*.so* $PG_STAGING_HDFS_FDW/lib/postgresql/ && cd $PG_STAGING_HDFS_FDW/lib/postgresql/ && rm -f libthrift*nb*" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/thrift/lib/libfb303.so $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/boost/lib/libboost_system*.so* $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/boost/lib/libboost_filesystem*.so* $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to copy the dependency library"

    # Move the .so and the extension files from server staging to hdfs_fdw staging
    mkdir -p $WD/hdfs_fdw/staging/linux-x64/share/postgresql/extension
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/lib/postgresql/hdfs_fdw.so $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to move hdfs_fdw .so to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/lib/libhive.so $PG_STAGING_HDFS_FDW/lib/postgresql/" || _die "Failed to move libhive .so to staging directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_PGHOME_LINUX_X64/share/postgresql/extension/hdfs_fdw* $PG_STAGING_HDFS_FDW/share/postgresql/extension/" || _die "Failed to move extension files to staging directory"

    echo "Changing the rpath"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib/postgresql/; chrpath --replace \"\\\${ORIGIN}\" hdfs_fdw.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib/postgresql/; chrpath --replace \"\\\${ORIGIN}:\\\${ORIGIN}/..\" libhive.so"
    #ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING_HDFS_FDW/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"
}


_postprocess_hdfs_fdw_linux_x64() {

    cd $WD/hdfs_fdw

    pushd staging/linux-x64
    generate_3rd_party_license "hdfs_fdw"
    popd

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/linux-x64 -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/linux-x64 -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/linux-x64 -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/linux-x64 -name \*.sh -exec chmod 755 {} \;

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}

#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pgAgent_linux_x64() {

    echo "###########################################"
    echo "# pgAgent : LINUX-X64 : Build preparation #"
    echo "###########################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source

    if [ -e pgAgent.linux-x64 ];
    then
      echo "Removing existing pgAgent.linux-x64 source directory"
      rm -rf pgAgent.linux-x64  || _die "Couldn't remove the existing pgAgent.linux-x64 source directory (source/pgAgent.linux-x64)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.linux-x64)"
    mkdir -p $WD/pgAgent/source/pgAgent.linux-x64 || _die "Couldn't create the pgAgent.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.linux-x64 || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    chmod -R ugo+w pgAgent.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/linux-x64)"
    mkdir -p $WD/pgAgent/staging/linux-x64 || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgAgent_linux_x64() {

    echo "###########################################"
    echo "# pgAgent : LINUX-X64 : Build             #"
    echo "###########################################"

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_LINUX_X64/pgAgent/staging/linux-x64
    SOURCE_DIR=$PG_PATH_LINUX_X64/pgAgent/source/pgAgent.linux-x64

    echo "Building pgAgent sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap ' LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib PGDIR=$PG_PGHOME_LINUX_X64 cmake -DCMAKE_INSTALL_PREFIX=$PG_STAGING -DSTATIC_BUILD=NO CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"

    echo "Compiling pgAgent"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap ' LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib make" || _die "Couldn't compile the pgAgent sources"

    echo "Installing pgAgent"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; make install" || _die "Couldn't install pgAgent"

    mkdir -p $PG_STAGING/lib

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_STAGING/lib" || _die "Failed to create lib directory"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libgssapi_krb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libkrb5support.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libpq.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxslt)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libedit)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libldap*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libldap*)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/liblber*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libiconv*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libz*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"    
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/pgAdmin3/lib/libexpat.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/pgAdmin3/lib/libwx_baseu-2.8.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto
)"  
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/bin/psql* $PG_STAGING/bin" || _die "Failed to copy psql"


    ssh $PG_SSH_LINUX_X64 "chmod a+rx $PG_STAGING/bin" || _die "Failed to set permissions on bin directory"
    ssh $PG_SSH_LINUX_X64 "chmod a+rx $PG_STAGING/lib" || _die "Failed to set permissions on lib directory"
    ssh $PG_SSH_LINUX_X64 "chmod a+rx $PG_STAGING/bin/*" || _die "Failed to set permissions on binaries in bin directory"
    ssh $PG_SSH_LINUX_X64 "chmod a+rx $PG_STAGING/lib/*" || _die "Failed to set permissions on libraries in lib directory"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_linux_x64() {

    echo "###########################################"
    echo "# pgAgent : LINUX-X64 : Post Process      #"
    echo "###########################################"

    # Setup the installer scripts.
    mkdir -p $WD/pgAgent/staging/linux-x64/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $WD/pgAgent/scripts/linux/*.sh $WD/pgAgent/staging/linux-x64/installer/pgAgent  || _die "Failed to copy installer scripts (scripts/linux/*.sh)"
    cp -f $WD/pgAgent/scripts/linux/pgpass $WD/pgAgent/staging/linux-x64/installer/pgAgent || _die "Failed to copy the pgpass file (scripts/linux/pgpass)"
    chmod ugo+x $WD/pgAgent/staging/linux-x64/installer/pgAgent/*
    chmod o+rx $WD/pgAgent/staging/linux-x64/lib/*
    cd $WD/pgAgent

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


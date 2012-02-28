#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_linux() {

    echo "#######################################"
    echo "# pgAgent : LINUX : Build preparation #"
    echo "#######################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
    
    if [ -e pgAgent.linux ];
    then
      echo "Removing existing pgAgent.linux source directory"
      rm -rf pgAgent.linux  || _die "Couldn't remove the existing pgAgent.linux source directory (source/pgAgent.linux)"
    fi

    
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source pgAgent.linux || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT-Source)"
    chmod -R ugo+w pgAgent.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/linux)"
    mkdir -p $WD/pgAgent/staging/linux || _die "Couldn't create the staging directory"


}

################################################################################
# PG Build
################################################################################

_build_pgAgent_linux() {

    echo "#######################################"
    echo "# pgAgent : LINUX : Build             #"
    echo "#######################################"

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_LINUX/pgAgent/staging/linux
    SOURCE_DIR=$PG_PATH_LINUX/pgAgent/source/pgAgent.linux

    echo "Building pgAgent sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap ' LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib PGDIR=$PG_PGHOME_LINUX cmake -DCMAKE_INSTALL_PREFIX=$PG_STAGING -DSTATIC_BUILD=NO CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap ' LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib make" || _die "Couldn't compile the pgAgent sources"
    echo "Installing pgAgent"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make install" || _die "Couldn't compile the pgAgent sources"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "mkdir -p $PG_STAGING/lib" || _die "Failed to create lib direcotyr"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcrypt)"
    ssh $PG_SSH_LINUX "cp -R /lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libexpat.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libgssapi_krb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_baseu-2.8.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -R /lib/libtermcap.so* $PG_STAGING/lib" || _dme "Failed to copy the dependency library (libtermcap)"
    ssh $PG_SSH_LINUX "cp -R /lib/libkeyutils* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkeyutils)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxslt)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libedit)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libldap*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libldap*)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/liblber*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/bin/psql* $PG_STAGING/bin" || _die "Failed to copy psql"
    ssh $PG_SSH_LINUX "chmod a+rx $PG_STAGING/bin/*" || _die "Failed to set permissions"
    ssh $PG_SSH_LINUX "chmod a+rx $PG_STAGING/lib/*" || _die "Failed to set permissions"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_linux() {

    echo "#######################################"
    echo "# pgAgent : LINUX : Post Process      #"
    echo "#######################################"

    # Setup the installer scripts.
    mkdir -p $WD/pgAgent/staging/linux/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $WD/pgAgent/scripts/linux/*.sh $WD/pgAgent/staging/linux/installer/pgAgent/ || _die "Failed to copy installer scripts (scripts/linux/*.sh)"
    cp -f $WD/pgAgent/scripts/linux/pgpass $WD/pgAgent/staging/linux/installer/pgAgent/ || _die "Failed to copy the pgpass script (scripts/linux/pgpass)"
    chmod ugo+x $WD/pgAgent/scripts/linux/*
     
    cd $WD/pgAgent
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


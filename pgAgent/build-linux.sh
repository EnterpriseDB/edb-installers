#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_linux() {

    echo "BEGIN PREP pgAgent Linux"

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

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/linux)"
    mkdir -p $WD/pgAgent/staging/linux || _die "Couldn't create the staging directory"
    
    echo "END PREP pgAgent Linux"

}

################################################################################
# PG Build
################################################################################

_build_pgAgent_linux() {

    echo "BEGIN BUILD pgAgent Linux"

    echo "#######################################"
    echo "# pgAgent : LINUX : Build             #"
    echo "#######################################"

    cd $WD/pgAgent

    PG_STAGING=$PG_PATH_LINUX/pgAgent/staging/linux
    SOURCE_DIR=$PG_PATH_LINUX/pgAgent/source/pgAgent.linux

    echo "Building pgAgent sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap '; LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib:/opt/local/Current/lib; PATH=/opt/local/Current/bin:$PATH PGDIR=$PG_PGHOME_LINUX cmake -DCMAKE_INSTALL_PREFIX=$PG_STAGING -DSTATIC_BUILD=NO CMakeLists.txt " || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; LDFLAGS=' -L$PG_PGHOME_LINUX/lib -lldap ' LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib make" || _die "Couldn't compile the pgAgent sources"
    echo "Installing pgAgent"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make install" || _die "Couldn't compile the pgAgent sources"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "mkdir -p $PG_STAGING/lib" || _die "Failed to create lib direcotyr"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libgssapi_krb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libkrb5support.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libxslt)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libedit)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libsasl*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libsasl)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libldap*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libldap*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/liblber*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libiconv*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libz*.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/pgAdmin3/lib/libexpat.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/pgAdmin3/lib/libwx_baseu-2.8.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/bin/psql* $PG_STAGING/bin" || _die "Failed to copy psql"

    ssh $PG_SSH_LINUX "chmod a+rx $PG_STAGING/bin/*" || _die "Failed to set permissions"
    ssh $PG_SSH_LINUX "chmod a+rx $PG_STAGING/lib/*" || _die "Failed to set permissions"
    
    # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/pgAgent ];
    then
        echo "Removing existing $WD/output/symbols/linux/pgAgent directory"
        rm -rf $WD/output/symbols/linux/pgAgent  || _die "Couldn't remove the existing $WD/output/symbols/linux/pgAgent directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/pgAgent/staging/linux/symbols $WD/output/symbols/linux/pgAgent || _die "Failed to move $WD/pgAgent/staging/linux/symbols to $WD/output/symbols/linux/pgAgent directory"

    echo "END BUILD pgAgent Linux"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_linux() {
    
    echo "BEGIN POST pgAgent Linux"    

    echo "#######################################"
    echo "# pgAgent : LINUX : Post Process      #"
    echo "#######################################"

    # Setup the installer scripts.
    mkdir -p $WD/pgAgent/staging/linux/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $WD/pgAgent/scripts/linux/*.sh $WD/pgAgent/staging/linux/installer/pgAgent/ || _die "Failed to copy installer scripts (scripts/linux/*.sh)"
    cp -f $WD/pgAgent/scripts/linux/pgpass $WD/pgAgent/staging/linux/installer/pgAgent/ || _die "Failed to copy the pgpass script (scripts/linux/pgpass)"
    chmod ugo+x $WD/pgAgent/scripts/linux/*
     
    cd $WD/pgAgent

    pushd staging/linux
    generate_3rd_party_license "pgAgent"
    popd
    
    # Set permissions to all files and folders in staging
    _set_permissions linux
     
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

    echo "END POST pgAgent Linux"

}


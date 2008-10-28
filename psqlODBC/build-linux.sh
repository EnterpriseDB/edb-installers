#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.linux ];
    then
      echo "Removing existing psqlODBC.linux source directory"
      rm -rf psqlODBC.linux  || _die "Couldn't remove the existing psqlODBC.linux source directory (source/psqlODBC.linux)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.linux)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.linux || _die "Couldn't create the psqlODBC.linux directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.linux || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    # Grab a copy of the docs 
    cp -R docs psqlODBC.linux || _die "Failed to copy the source code (source/docs)"
    cp -R templates psqlODBC.linux || _die "Failed to copy the source code (source/templates)"

    chmod -R ugo+w psqlODBC.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/linux)"
    mkdir -p $WD/psqlODBC/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/linux || _die "Couldn't set the permissions on the staging directory"
    
}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_linux() {

    cd $WD/psqlODBC

    PG_STAGING=$PG_PATH_LINUX/psqlODBC/staging/linux
    SOURCE_DIR=$PG_PATH_LINUX/psqlODBC/source/psqlODBC.linux

    echo "Configuring psqlODBC sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; PATH=$PG_PGHOME_LINUX/bin:\$PATH ./configure --prefix=$PG_STAGING " || _die "Couldn't configure the psqlODBC sources"
    echo "Compiling psqlODBC"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make" || _die "Couldn't compile the psqlODBC sources"
    echo "Installing psqlODBC into the sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make install" || _die "Couldn't install the psqlODBC into statging directory" 
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; mkdir $PG_STAGING/docs " || _die "Failed to create the docs directory"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; mkdir $PG_STAGING/templates " || _die "Failed to create the template directory"

    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; cp -R docs/* $PG_STAGING/docs " || _die "Failed to copy the docs directory to staging directory"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; cp -R templates/* $PG_STAGING/templates " || _die "Failed to copy the templates directory to staging directory"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libexpat.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libgssapi_krb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    
}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_linux() {

    cd $WD/psqlODBC

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/psqlODBC || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/psqlODBC/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/removeshortcuts.sh
    
    cp scripts/linux/createshortcuts.sh staging/linux/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/createshortcuts.sh

    cp scripts/linux/getodbcinstpath.sh staging/linux/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/linux/getodbcinstpath.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/getodbcinstpath.sh

    #Setup the launch scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/scripts/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files (resources/)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Setup the psqlODBC xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the xdg entries"
    cp resources/xdg/pg-launchOdbcDocs.desktop staging/linux/scripts/xdg/pg-launchOdbcDocs.desktop || _die "Failed to copy the launch files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.linux-x64 ];
    then
      echo "Removing existing psqlODBC.linux-x64 source directory"
      rm -rf psqlODBC.linux-x64  || _die "Couldn't remove the existing psqlODBC.linux-x64 source directory (source/psqlODBC.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.linux-x64)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.linux-x64 || _die "Couldn't create the psqlODBC.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.linux-x64 || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    chmod -R ugo+w psqlODBC.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/linux-x64)"
    mkdir -p $WD/psqlODBC/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

    ODBCCONFIG=`ssh $PG_SSH_LINUX_X64 "echo \`which odbc_config\`"`
    if [ $ODBCCONFIG = "" ]; then
       _die "Couldn't find unixODBC"
    fi
    
}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_linux_x64() {

    cd $WD/psqlODBC

    PG_STAGING=$PG_PATH_LINUX_X64/psqlODBC/staging/linux-x64
    SOURCE_DIR=$PG_PATH_LINUX_X64/psqlODBC/source/psqlODBC.linux-x64

    echo "Configuring psqlODBC sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR;PATH=\"$PG_PGHOME_LINUX_X64/bin:\$PATH\" CFLAGS=\"-I\`odbc_config --include-prefix\` \" LDFLAGS=\" -Wl,--rpath -Wl,\`odbc_config --lib-prefix\` \`odbc_config --libs\` \" ./configure --prefix=$PG_STAGING " || _die "Couldn't configure the psqlODBC sources"
    echo "Compiling psqlODBC"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; make" || _die "Couldn't compile the psqlODBC sources"
    echo "Installing psqlODBC into the sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; make install" || _die "Couldn't install the psqlODBC into statging directory" 

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libexpat.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libgssapi_krb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/lib/libpq.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    
}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_linux_x64() {

    cd $WD/psqlODBC

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/psqlODBC || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/psqlODBC/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/removeshortcuts.sh
    
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/createshortcuts.sh

    cp scripts/linux/getodbcinstpath.sh staging/linux-x64/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/linux/getodbcinstpath.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/getodbcinstpath.sh

    #Setup the launch scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/scripts/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg files (resources/)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Setup the psqlODBC xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the xdg entries"
    cp resources/xdg/pg-launchOdbcDocs.desktop staging/linux-x64/scripts/xdg/pg-launchOdbcDocs.desktop || _die "Failed to copy the launch files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


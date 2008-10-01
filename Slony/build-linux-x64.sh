#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_linux_x64() {
      
    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.linux-x64 ];
    then
      echo "Removing existing slony.linux-x64 source directory"
      rm -rf slony.linux-x64  || _die "Couldn't remove the existing slony.linux-x64 source directory (source/slony.linux-x64)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.linux-x64)"
    mkdir -p slony.linux-x64 || _die "Couldn't create the slony.linux-x64 directory"
    chmod ugo+w slony.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.linux-x64 || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"
    chmod -R ugo+w slony.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/linux-x64)"
    mkdir -p $WD/Slony/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.so lib/postgresql/xxid.so"  || _die "Failed to remove slony binary files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/postgresql/slony*.sql && rm -f share/postgresql/xxid*.sql"  || _die "remove slony share files"
}


################################################################################
# PG Build
################################################################################

_build_Slony_linux_x64() {

    # build slony
    PG_STAGING=$PG_PATH_LINUX_X64/Slony/staging/linux-x64

    echo "Configuring the slony source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64/; ./configure --with-pgconfigdir=$PG_PGHOME_LINUX_X64/bin"  || _die "Failed to configure slony"

    echo "Building slony"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64; make" || _die "Failed to build slony"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64; make install" || _die "Failed to install slony"


}


################################################################################
# PG Build
################################################################################

_postprocess_Slony_linux_x64() {

    PG_STAGING=$PG_PATH_LINUX_X64/Slony/staging/linux-x64

    cd $WD/Slony

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory
    mkdir -p $WD/Slony/staging/linux-x64/bin
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slon $PG_STAGING/bin" || _die "Failed to copy slon binary to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slonik $PG_STAGING/bin" || _die "Failed to copy slonik binary to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slony_logshipper $PG_STAGING/bin" || _die "Failed to copy slony_logshipper binary to staging directory"
    
    mkdir -p $WD/Slony/staging/linux-x64/lib
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/postgresql/slony1_funcs.so $PG_STAGING/lib" || _die "Failed to copy slony_funs.so to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/postgresql/xxid.so $PG_STAGING/lib" || _die "Failed to copy xxid.so to staging directory"

    mkdir -p $WD/Slony/staging/linux-x64/Slony
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/share/postgresql/slony*.sql $PG_STAGING/Slony" || _die "Failed to share files to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/share/postgresql/xxid.*.sql $PG_STAGING/Slony" || _die "Failed to share files to staging directory"

    mkdir -p staging/linux-x64/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/linux-x64/createshortcuts.sh staging/linux-x64/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/createshortcuts.sh

    cp scripts/linux-x64/removeshortcuts.sh staging/linux-x64/installer/Slony/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/removeshortcuts.sh

    cp scripts/linux-x64/configureslony.sh staging/linux-x64/installer/Slony/configureslony.sh || _die "Failed to copy the createshortcuts script (scripts/linux-x64/configureslony.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/configureslony.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux-x64/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    cp -R scripts/linux-x64/launchSlonyDocs.sh staging/linux-x64/scripts/launchSlonyDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/enterprisedb-postgres.directory staging/linux-x64/scripts/xdg/enterprisedb-postgres.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchSlonyDocs.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchSlonyDocs.desktop || _die "Failed to copy a menu pick desktop"

 
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD
}


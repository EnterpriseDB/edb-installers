#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_linux_x64() {

    echo "BEGIN PREP Slony Linux-x64"
      
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

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/linux-x64.build)"
    mkdir -p $WD/Slony/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.$PG_VERSION_SLONY.so"  || _die "Failed to remove slony binary files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/postgresql/slony*.sql"  || _die "remove slony share files"
  
    echo "END PREP Slony Linux-x64"
}


################################################################################
# PG Build
################################################################################

_build_Slony_linux_x64() {

    echo "BEGIN BUILD Slony Linux-x64"

    # build slony
    PG_STAGING=$PG_PATH_LINUX_X64/Slony/staging/linux-x64.build

    echo "Configuring the slony source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64/; ./configure --enable-debug --with-pgconfigdir=$PG_PGHOME_LINUX_X64/bin --with-pgport=yes LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib"  || _die "Failed to configure slony"

    echo "Building slony"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64; LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib make" || _die "Failed to build slony"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/Slony/source/slony.linux-x64; make install" || _die "Failed to install slony"

    echo "Changing the rpath for the slonik binaries and libraries"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64/bin; for f in slon slonik slony_logshipper ; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64/lib/postgresql; chrpath --replace \"\\\${ORIGIN}/../../lib\" slony1_funcs.$PG_VERSION_SLONY.so"

    cd $WD/Slony

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory
    mkdir -p $WD/Slony/staging/linux-x64.build/bin
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slon $PG_STAGING/bin" || _die "Failed to copy slon binary to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slonik $PG_STAGING/bin" || _die "Failed to copy slonik binary to staging directory"
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/bin/slony_logshipper $PG_STAGING/bin" || _die "Failed to copy slony_logshipper binary to staging directory"
    chmod +rx $WD/Slony/staging/linux-x64.build/bin/*
 
    mkdir -p $WD/Slony/staging/linux-x64.build/lib
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/lib/postgresql/slony1_funcs.$PG_VERSION_SLONY.so $PG_STAGING/lib" || _die "Failed to copy slony_funs.so to staging directory"
    chmod +r $WD/Slony/staging/linux-x64.build/lib/*

    mkdir -p $WD/Slony/staging/linux-x64.build/Slony
    ssh $PG_SSH_LINUX_X64 "cp $PG_PGHOME_LINUX_X64/share/postgresql/slony*.sql $PG_STAGING/Slony" || _die "Failed to share files to staging directory"

    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/Slony ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/Slony directory"
        rm -rf $WD/output/symbols/linux-x64/Slony  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/Slony directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/Slony/staging/linux-x64.build/symbols $WD/output/symbols/linux-x64/Slony || _die "Failed to move $WD/Slony/staging/linux-x64.build/symbols to $WD/output/symbols/linux-x64/Slony directory"

    echo "Removing last successful staging directory ($WD/Slony/staging/linux-x64)"
    rm -rf $WD/Slony/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/Slony/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/Slony/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/Slony/staging/linux-x64.build/* $WD/Slony/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_SLONY=$PG_VERSION_SLONY" > $WD/Slony/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_SLONY=$PG_BUILDNUM_SLONY" >> $WD/Slony/staging/linux-x64/versions-linux-x64.sh

    cd $WD

    echo "END BUILD Slony Linux-x64"

}


################################################################################
# PG Build
################################################################################

_postprocess_Slony_linux_x64() {

    echo "BEGIN POST Slony Linux-x64"

    source $WD/Slony/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_SLONY=$(expr $PG_BUILD_SLONY + $SKIPBUILD)

    PG_STAGING=$PG_PATH_LINUX_X64/Slony/staging/linux-x64

    cd $WD/Slony

    mkdir -p staging/linux-x64/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/Slony/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/removeshortcuts.sh

    cp scripts/linux/configureslony.sh staging/linux-x64/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/linux/configureslony.sh)"
    chmod ugo+x staging/linux-x64/installer/Slony/configureslony.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    cp -R scripts/linux/launchSlonyDocs.sh staging/linux-x64/scripts/launchSlonyDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/launchSlonyDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    SLONY_VERSION_STR=`echo $PG_VERSION_SLONY | cut -f1,2 -d "." | sed 's/\./_/g'`

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchSlonyDocs.desktop staging/linux-x64/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Set permissions to all files and folders in staging
    _set_permissions linux-x64
    
    ssh $PG_SSH_LINUX_X64 "chmod 755 $PG_STAGING/Slony/slony*.sql" || _die "Failed to set the permissions for sql files"
 
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SLONY -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/slony-pg96-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-linux-x64.run $WD/output/slony-pg96-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-${BUILD_FAILED}linux-x64.run

    cd $WD

    echo "END POST Slony Linux-x64"
}


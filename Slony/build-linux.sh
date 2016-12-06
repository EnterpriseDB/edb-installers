#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_Slony_linux() {
    
    echo "BEGIN PREP Slony Linux"    

    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.linux ];
    then
      echo "Removing existing slony.linux source directory"
      rm -rf slony.linux  || _die "Couldn't remove the existing slony.linux source directory (source/slony.linux)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.linux)"
    mkdir -p slony.linux || _die "Couldn't create the slony.linux directory"
    chmod ugo+w slony.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.linux || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/linux)"
    mkdir -p $WD/Slony/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/linux || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.$PG_VERSION_SLONY.so"  || _die "Failed to remove slony binary files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f share/postgresql/slony*.sql"  || _die "remove slony share files"
    
    echo "END PREP Slony Linux"

}


################################################################################
# PG Build
################################################################################

_build_Slony_linux() {
  
    echo "BEGIN BUILD Slony Linux"

    # build slony
    PG_STAGING=$PG_PATH_LINUX/Slony/staging/linux

    echo "Configuring the slony source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/Slony/source/slony.linux/; LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib ./configure --enable-debug --with-pgconfigdir=$PG_PGHOME_LINUX/bin --with-pgport=yes"  || _die "Failed to configure slony"

    echo "Building slony"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/Slony/source/slony.linux; LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib make" || _die "Failed to build slony"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/Slony/source/slony.linux; make install" || _die "Failed to install slony"

    echo "Changing the rpath for the slonik binaries and libraries"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX/bin; for f in slon slonik slony_logshipper ; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX/lib/postgresql; chrpath --replace \"\\\${ORIGIN}/../../lib\" slony1_funcs.$PG_VERSION_SLONY.so"

    cd $WD

    echo "END BUILD Slony Linux"  

}


################################################################################
# PG Build
################################################################################

_postprocess_Slony_linux() {

    echo "BEGIN POST Slony Linux"

    PG_STAGING=$PG_PATH_LINUX/Slony/staging/linux

    cd $WD/Slony

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory
    mkdir -p $WD/Slony/staging/linux/bin
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/bin/slon $PG_STAGING/bin" || _die "Failed to copy slon binary to staging directory"
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/bin/slonik $PG_STAGING/bin" || _die "Failed to copy slonik binary to staging directory"
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/bin/slony_logshipper $PG_STAGING/bin" || _die "Failed to copy slony_logshipper binary to staging directory"
    chmod +rx $WD/Slony/staging/linux/bin/*

    mkdir -p $WD/Slony/staging/linux/lib
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/lib/postgresql/slony1_funcs.$PG_VERSION_SLONY.so $PG_STAGING/lib" || _die "Failed to copy slony_funs.so to staging directory"
    chmod +r $WD/Slony/staging/linux/lib/*

    mkdir -p $WD/Slony/staging/linux/Slony
    ssh $PG_SSH_LINUX "cp $PG_PGHOME_LINUX/share/postgresql/slony*.sql $PG_STAGING/Slony; chmod 755 $PG_STAGING/Slony/slony*.sql" || _die "Failed to share files to staging directory"

    # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/Slony ];
    then
        echo "Removing existing $WD/output/symbols/linux/Slony directory"
        rm -rf $WD/output/symbols/linux/Slony  || _die "Couldn't remove the existing $WD/output/symbols/linux/Slony directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/Slony/staging/linux/symbols $WD/output/symbols/linux/Slony || _die "Failed to move $WD/Slony/staging/linux/symbols to $WD/output/symbols/linux/Slony directory"

    mkdir -p staging/linux/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Slony/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/Slony/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/Slony/removeshortcuts.sh

    cp scripts/linux/configureslony.sh staging/linux/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/linux/configureslony.sh)"
    chmod ugo+x staging/linux/installer/Slony/configureslony.sh

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh
    cp -R scripts/linux/launchSlonyDocs.sh staging/linux/scripts/launchSlonyDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchSlonyDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    SLONY_VERSION_STR=`echo $PG_VERSION_SLONY | cut -f1,2 -d "." | sed 's/\./_/g'`

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchSlonyDocs.desktop staging/linux/scripts/xdg/pg-launchSlonyDocs-$SLONY_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
    
    echo "END POST Slony Linux"
}


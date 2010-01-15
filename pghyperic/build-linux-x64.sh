#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.linux-x64 ];
    then
      echo "Removing existing pghyperic.linux-x64 source directory"
      rm -rf pghyperic.linux-x64  || _die "Couldn't remove the existing pghyperic.linux-x64 source directory (source/pghyperic.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/pghyperic/source/pghyperic.linux-x64)"
    mkdir -p $WD/pghyperic/source/pghyperic.linux-x64 || _die "Couldn't create the pghyperic.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGHYPERIC/* pghyperic.linux-x64 || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGHYPERIC)"
    chmod -R ugo+w pghyperic.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/linux-x64)"
    mkdir -p $WD/pghyperic/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pghyperic/source/pghyperic.linux-x64/* $WD/pghyperic/staging/linux-x64 || _die "Failed to copy the pghyperic Source into the staging directory"
 

}

################################################################################
# PG Build
################################################################################

_build_pghyperic_linux_x64() {

     #Copy psql for postgres validation
     mkdir -p $WD/pghyperic/staging/linux-x64/instscripts || _die "Failed to create the instscripts directory"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/lib/libpq* $PG_PATH_LINUX_X64/linux-x64/instscripts/" || _die "Failed to copy libpq in instscripts"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux/bin/psql $PG_PATH_LINUX_X64/pghyperic/staging/linux-x64/instscripts/" || _die "Failed to copy psql in instscripts"

    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy psql in instscripts"

}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_linux_x64() {
 
    cd $WD/pghyperic

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/pghyperic || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/pghyperic/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pghyperic/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/pghyperic/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pghyperic/createshortcuts.sh

      # Copy the XDG scripts
      mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
      cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
      chmod ugo+x staging/linux-x64/installer/xdg/xdg*
 
      # Version string, for the xdg filenames
      PGHYPERIC_VERSION_STR=`echo $PG_VERSION_PGHYPERIC | sed 's/\./_/g'`
 
      # Copy in the menu pick images  and XDG items
      mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
      cp resources/pghyperic.png staging/linux-x64/scripts/images/pghyperic-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pghyperic-launch.png staging/linux-x64/scripts/images/pghyperic-launch-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pghyperic-start.png staging/linux-x64/scripts/images/pghyperic-start-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pghyperic-stop.png staging/linux-x64/scripts/images/pghyperic-stop-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
 
      mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
      cp resources/xdg/pghyperic.directory staging/linux-x64/scripts/xdg/pghyperic-$PGHYPERIC_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
      cp resources/xdg/pghyperic-launch.desktop staging/linux-x64/scripts/xdg/pghyperic-launch-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/pghyperic-start.desktop staging/linux-x64/scripts/xdg/pghyperic-start-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/pghyperic-stop.desktop staging/linux-x64/scripts/xdg/pghyperic-stop-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"

      # Copy the launch scripts
      cp scripts/linux/launchsvrctl.sh staging/linux-x64/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/launchsvrctl.sh
      cp scripts/linux/serverctl.sh staging/linux-x64/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/serverctl.sh
      cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
      chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


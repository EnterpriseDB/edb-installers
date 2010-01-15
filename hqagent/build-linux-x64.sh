#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_hqagent_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    if [ -e hqagent.linux-x64 ];
    then
      echo "Removing existing hqagent.linux-x64 source directory"
      rm -rf hqagent.linux-x64  || _die "Couldn't remove the existing hqagent.linux-x64 source directory (source/hqagent.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/hqagent/source/hqagent.linux-x64)"
    mkdir -p $WD/hqagent/source/hqagent.linux-x64 || _die "Couldn't create the hqagent.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_PGHYPERIC/* hqagent.linux-x64 || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_PGHYPERIC)"
    chmod -R ugo+w hqagent.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hqagent/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hqagent/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hqagent/staging/linux-x64)"
    mkdir -p $WD/hqagent/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hqagent/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/hqagent/source/hqagent.linux-x64/* $WD/hqagent/staging/linux-x64 || _die "Failed to copy the hqagent Source into the staging directory"
 

}

################################################################################
# PG Build
################################################################################

_build_hqagent_linux_x64() {

     #Copy psql for postgres validation
     mkdir -p $WD/hqagent/staging/linux-x64/instscripts || _die "Failed to create the instscripts directory"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/lib/libpq* $PG_PATH_LINUX_X64/linux-x64/instscripts/" || _die "Failed to copy libpq in instscripts"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux/bin/psql $PG_PATH_LINUX_X64/hqagent/staging/linux-x64/instscripts/" || _die "Failed to copy psql in instscripts"

    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq* $PG_PATH_LINUX/hqagent/staging/linux/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql $PG_PATH_LINUX/hqagent/staging/linux/instscripts/" || _die "Failed to copy psql in instscripts"

}


################################################################################
# PG Build
################################################################################

_postprocess_hqagent_linux_x64() {
 
    cd $WD/hqagent

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/hqagent || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/hqagent/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/hqagent/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/hqagent/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/hqagent/createshortcuts.sh

      # Copy the XDG scripts
      mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
      cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
      chmod ugo+x staging/linux-x64/installer/xdg/xdg*
 
      # Version string, for the xdg filenames
      PGHYPERIC_VERSION_STR=`echo $PG_VERSION_PGHYPERIC | sed 's/\./_/g'`
 
      # Copy in the menu pick images  and XDG items
      mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
      cp resources/hqagent.png staging/linux-x64/scripts/images/hqagent-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/hqagent-launch.png staging/linux-x64/scripts/images/hqagent-launch-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/hqagent-start.png staging/linux-x64/scripts/images/hqagent-start-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/hqagent-stop.png staging/linux-x64/scripts/images/hqagent-stop-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
 
      mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
      cp resources/xdg/hqagent.directory staging/linux-x64/scripts/xdg/hqagent-$PGHYPERIC_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
      cp resources/xdg/hqagent-launch.desktop staging/linux-x64/scripts/xdg/hqagent-launch-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/hqagent-start.desktop staging/linux-x64/scripts/xdg/hqagent-start-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/hqagent-stop.desktop staging/linux-x64/scripts/xdg/hqagent-stop-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"

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


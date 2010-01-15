#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_hqagent_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/hqagent/source

    if [ -e hqagent.linux ];
    then
      echo "Removing existing hqagent.linux source directory"
      rm -rf hqagent.linux  || _die "Couldn't remove the existing hqagent.linux source directory (source/hqagent.linux)"
    fi
   
    echo "Creating staging directory ($WD/hqagent/source/hqagent.linux)"
    mkdir -p $WD/hqagent/source/hqagent.linux || _die "Couldn't create the hqagent.linux directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_HQAGENT/* hqagent.linux || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_HQAGENT)"
    chmod -R ugo+w hqagent.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/hqagent/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/hqagent/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/hqagent/staging/linux)"
    mkdir -p $WD/hqagent/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/hqagent/staging/linux || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/hqagent/source/hqagent.linux/* $WD/hqagent/staging/linux || _die "Failed to copy the hqagent Source into the staging directory"

}

################################################################################
# HQ Agent Build
################################################################################

_build_hqagent_linux() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_hqagent_linux() {
    
    cd $WD/hqagent

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/hqagent || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/hqagent/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/hqagent/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/hqagent/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/hqagent/createshortcuts.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Version string, for the xdg filenames
    HQAGENT_VERSION_STR=`echo $PG_VERSION_HQAGENT | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/hqagent.png staging/linux/scripts/images/hqagent-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/hqagent-start.png staging/linux/scripts/images/hqagent-start-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/hqagent-stop.png staging/linux/scripts/images/hqagent-stop-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/hqagent.directory staging/linux/scripts/xdg/hqagent-$HQAGENT_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/hqagent-start.desktop staging/linux/scripts/xdg/hqagent-start-$HQAGENT_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/hqagent-stop.desktop staging/linux/scripts/xdg/hqagent-stop-$HQAGENT_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    # Copy the launch scripts
    cp scripts/linux/launchagentctl.sh staging/linux/scripts/launchagentctl.sh || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
    chmod ugo+x staging/linux/scripts/launchagentctl.sh
    cp scripts/linux/agentctl.sh staging/linux/scripts/agentctl.sh || _die "Failed to copy the agentctl script (scripts/linux/agentctl.sh)"
    chmod ugo+x staging/linux/scripts/agentctl.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    cd $WD
}


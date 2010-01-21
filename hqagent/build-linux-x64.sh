!/bin/bash

    
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
   
    echo "Creating source directory ($WD/hqagent/source/hqagent.linux-x64)"
    mkdir -p $WD/hqagent/source/hqagent.linux-x64 || _die "Couldn't create the hqagent.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R hqagent-$PG_VERSION_HQAGENT-x64/* hqagent.linux-x64 || _die "Failed to copy the source code (source/hqagent-$PG_VERSION_HQAGENT-x64)"
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
# HQAGENT Build
################################################################################

_build_hqagent_linux_x64() {

    cd $WD
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
    HQAGENT_VERSION_STR=`echo $PG_VERSION_HQAGENT | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/hqagent.png staging/linux-x64/scripts/images/hqagent-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/hqagent-start.png staging/linux-x64/scripts/images/hqagent-start-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/hqagent-stop.png staging/linux-x64/scripts/images/hqagent-stop-$HQAGENT_VERSION_STR.png || _die "Failed to copy a menu pick image"
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/hqagent.directory staging/linux-x64/scripts/xdg/hqagent-$HQAGENT_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/hqagent-start.desktop staging/linux-x64/scripts/xdg/hqagent-start-$HQAGENT_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/hqagent-stop.desktop staging/linux-x64/scripts/xdg/hqagent-stop-$HQAGENT_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    # Copy the launch scripts
    cp scripts/linux/launchagentctl.sh staging/linux-x64/scripts/launchagentctl.sh || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchagentctl.sh
    cp scripts/linux/agentctl.sh staging/linux-x64/scripts/agentctl.sh || _die "Failed to copy the agentctl script (scripts/linux/agentctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/agentctl.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    cd $WD

}


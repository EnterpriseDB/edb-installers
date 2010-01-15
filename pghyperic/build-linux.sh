#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.linux ];
    then
      echo "Removing existing pghyperic.linux source directory"
      rm -rf pghyperic.linux  || _die "Couldn't remove the existing pghyperic.linux source directory (source/pghyperic.linux)"
    fi
   
    echo "Creating staging directory ($WD/pghyperic/source/pghyperic.linux)"
    mkdir -p $WD/pghyperic/source/pghyperic.linux || _die "Couldn't create the pghyperic.linux directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGHYPERIC/* pghyperic.linux || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGHYPERIC)"
    chmod -R ugo+w pghyperic.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/linux)"
    mkdir -p $WD/pghyperic/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/linux || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pghyperic/source/pghyperic.linux/* $WD/pghyperic/staging/linux || _die "Failed to copy the pghyperic Source into the staging directory"

}

################################################################################
# PG Build
################################################################################

_build_pghyperic_linux() {

    #Copy psql for postgres validation
    mkdir -p $WD/pghyperic/staging/linux/instscripts || _die "Failed to create the instscripts directory"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy psql in instscripts"
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libtermcap.so* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxml2.so* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libreadline.so* $PG_PATH_LINUX/pghyperic/staging/linux/instscripts/" || _die "Failed to copy the dependency library"

}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_linux() {
    
    cd $WD/pghyperic

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pghyperic || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/pghyperic/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pghyperic/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/pghyperic/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pghyperic/createshortcuts.sh
    
    cp scripts/tune-os.sh staging/linux/installer/pghyperic/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/linux/installer/pghyperic/tune-os.sh
    
    cp scripts/hqdb.sql staging/linux/installer/pghyperic/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Version string, for the xdg filenames
    PGHYPERIC_VERSION_STR=`echo $PG_VERSION_PGHYPERIC | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pghyperic.png staging/linux/scripts/images/pghyperic-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pghyperic-launch.png staging/linux/scripts/images/pghyperic-launch-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pghyperic-start.png staging/linux/scripts/images/pghyperic-start-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pghyperic-stop.png staging/linux/scripts/images/pghyperic-stop-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pghyperic-agent-start.png staging/linux/scripts/images/pghyperic-agent-start-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pghyperic-agent-stop.png staging/linux/scripts/images/pghyperic-agent-stop-$PGHYPERIC_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pghyperic.directory staging/linux/scripts/xdg/pghyperic-$PGHYPERIC_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pghyperic-launch.desktop staging/linux/scripts/xdg/pghyperic-launch-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pghyperic-start.desktop staging/linux/scripts/xdg/pghyperic-start-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pghyperic-stop.desktop staging/linux/scripts/xdg/pghyperic-stop-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pghyperic-agent-start.desktop staging/linux/scripts/xdg/pghyperic-agent-start-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pghyperic-agent-stop.desktop staging/linux/scripts/xdg/pghyperic-agent-stop-$PGHYPERIC_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    # Copy the launch scripts
    cp scripts/linux/launchsvrctl.sh staging/linux/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x staging/linux/scripts/launchsvrctl.sh
    cp scripts/linux/serverctl.sh staging/linux/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x staging/linux/scripts/serverctl.sh
    cp scripts/linux/launchagentctl.sh staging/linux/scripts/launchagentctl.sh || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
    chmod ugo+x staging/linux/scripts/launchagentctl.sh
    cp scripts/linux/agentctl.sh staging/linux/scripts/agentctl.sh || _die "Failed to copy the agentctl script (scripts/linux/agentctl.sh)"
    chmod ugo+x staging/linux/scripts/agentctl.sh
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    cd $WD
}


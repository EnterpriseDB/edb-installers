#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pphq_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    if [ -e pphq.linux ];
    then
      echo "Removing existing pphq.linux source directory"
      rm -rf pphq.linux  || _die "Couldn't remove the existing pphq.linux source directory (source/pphq.linux)"
    fi
   
    echo "Creating staging directory ($WD/pphq/source/pphq.linux)"
    mkdir -p $WD/pphq/source/pphq.linux || _die "Couldn't create the pphq.linux directory"

    # Grab a copy of the source tree
    cp -R pphq-$PG_VERSION_PPHQ/* pphq.linux || _die "Failed to copy the source code (source/pphq-$PG_VERSION_PPHQ)"
    chmod -R ugo+w pphq.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/linux)"
    mkdir -p $WD/pphq/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/linux || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pphq/source/pphq.linux/* $WD/pphq/staging/linux || _die "Failed to copy the pphq Source into the staging directory"

}

################################################################################
# PG Build
################################################################################

_build_pphq_linux() {

    #Copy psql for postgres validation
    mkdir -p $WD/pphq/staging/linux/instscripts || _die "Failed to create the instscripts directory"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy psql in instscripts"
    ssh $PG_SSH_LINUX "cp -R /lib/libssl.so* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libcrypto.so* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libtermcap.so* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxml2.so* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libreadline.so* $PG_PATH_LINUX/pphq/staging/linux/instscripts/" || _die "Failed to copy the dependency library"

}


################################################################################
# PG Build
################################################################################

_postprocess_pphq_linux() {
    
    cd $WD/pphq

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/pphq || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/pphq/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pphq/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/pphq/createshortcuts.sh
    
    cp scripts/tune-os.sh staging/linux/installer/pphq/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/linux/installer/pphq/tune-os.sh
    
	cp scripts/change_version_str.sh staging/linux/installer/pphq/change_version_str.sh || _die "Failed to copy the change_version_str.sh script (scripts/change_version_str.sh)"
    chmod ugo+x staging/linux/installer/pphq/change_version_str.sh
    
    cp scripts/hqdb.sql staging/linux/installer/pphq/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Version string, for the xdg filenames
    PPHQ_VERSION_STR=`echo $PG_VERSION_PPHQ | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pphq.png staging/linux/scripts/images/pphq-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-launch.png staging/linux/scripts/images/pphq-launch-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-start.png staging/linux/scripts/images/pphq-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-stop.png staging/linux/scripts/images/pphq-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-agent-start.png staging/linux/scripts/images/pphq-agent-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-agent-stop.png staging/linux/scripts/images/pphq-agent-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pphq.directory staging/linux/scripts/xdg/pphq-$PPHQ_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pphq-launch.desktop staging/linux/scripts/xdg/pphq-launch-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-start.desktop staging/linux/scripts/xdg/pphq-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-stop.desktop staging/linux/scripts/xdg/pphq-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-start.desktop staging/linux/scripts/xdg/pphq-agent-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-stop.desktop staging/linux/scripts/xdg/pphq-agent-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"

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


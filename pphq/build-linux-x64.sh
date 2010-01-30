#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pphq_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    if [ -e pphq.linux-x64 ];
    then
      echo "Removing existing pphq.linux-x64 source directory"
      rm -rf pphq.linux-x64  || _die "Couldn't remove the existing pphq.linux-x64 source directory (source/pphq.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/pphq/source/pphq.linux-x64)"
    mkdir -p $WD/pphq/source/pphq.linux-x64 || _die "Couldn't create the pphq.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R pphq-$PG_VERSION_PPHQ-x64/* pphq.linux-x64 || _die "Failed to copy the source code (source/pphq-$PG_VERSION_PPHQ-x64)"
    chmod -R ugo+w pphq.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/linux-x64)"
    mkdir -p $WD/pphq/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pphq/source/pphq.linux-x64/* $WD/pphq/staging/linux-x64 || _die "Failed to copy the pphq Source into the staging directory"
 

}

################################################################################
# PG Build
################################################################################

_build_pphq_linux_x64() {

     #Copy psql for postgres validation
     mkdir -p $WD/pphq/staging/linux-x64/instscripts || _die "Failed to create the instscripts directory"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/lib/libpq* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy libpq in instscripts"
     ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/psql $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy psql in instscripts"

    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libssl.so* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypto.so* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libtermcap.so* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libxml2.so* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libreadline.so* $PG_PATH_LINUX_X64/pphq/staging/linux-x64/instscripts/" || _die "Failed to copy the dependency library"

}


################################################################################
# PG Build
################################################################################

_postprocess_pphq_linux_x64() {
 
    cd $WD/pphq

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/pphq || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/pphq/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pphq/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/pphq/createshortcuts.sh

    cp scripts/tune-os.sh staging/linux-x64/installer/pphq/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/linux-x64/installer/pphq/tune-os.sh

    cp scripts/change_version_str.sh staging/linux-x64/installer/pphq/change_version_str.sh || _die "Failed to copy the change_version_str.sh script (scripts/change_version_str.sh)"
    chmod ugo+x staging/linux-x64/installer/pphq/change_version_str.sh
    
	cp scripts/hqdb.sql staging/linux-x64/installer/pphq/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

      # Copy the XDG scripts
      mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
      cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
      chmod ugo+x staging/linux-x64/installer/xdg/xdg*
 
      # Version string, for the xdg filenames
      PPHQ_VERSION_STR=`echo $PG_VERSION_PPHQ | sed 's/\./_/g'`
 
      # Copy in the menu pick images  and XDG items
      mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
      cp resources/pphq.png staging/linux-x64/scripts/images/pphq-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pphq-launch.png staging/linux-x64/scripts/images/pphq-launch-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pphq-start.png staging/linux-x64/scripts/images/pphq-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
      cp resources/pphq-stop.png staging/linux-x64/scripts/images/pphq-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-agent-start.png staging/linux-x64/scripts/images/pphq-agent-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pphq-agent-stop.png staging/linux-x64/scripts/images/pphq-agent-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
 
      mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
      cp resources/xdg/pphq.directory staging/linux-x64/scripts/xdg/pphq-$PPHQ_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
      cp resources/xdg/pphq-launch.desktop staging/linux-x64/scripts/xdg/pphq-launch-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/pphq-start.desktop staging/linux-x64/scripts/xdg/pphq-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
      cp resources/xdg/pphq-stop.desktop staging/linux-x64/scripts/xdg/pphq-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-start.desktop staging/linux-x64/scripts/xdg/pphq-agent-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-stop.desktop staging/linux-x64/scripts/xdg/pphq-agent-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"


      # Copy the launch scripts
      cp scripts/linux/launchsvrctl.sh staging/linux-x64/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/launchsvrctl.sh
      cp scripts/linux/serverctl.sh staging/linux-x64/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/serverctl.sh
      cp scripts/linux/launchagentctl.sh staging/linux-x64/scripts/launchagentctl.sh || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/launchagentctl.sh
      cp scripts/linux/agentctl.sh staging/linux-x64/scripts/agentctl.sh || _die "Failed to copy the agentctl script (scripts/linux-x64/agentctl.sh)"
      chmod ugo+x staging/linux-x64/scripts/agentctl.sh
      cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
      chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


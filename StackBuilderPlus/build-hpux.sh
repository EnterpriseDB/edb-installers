#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus_hpux() {

    echo "****************************************"
    echo "* Preparing - StackBuilderPlus (hpux) *"
    echo "****************************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/hpux)"
    mkdir -p $WD/StackBuilderPlus/staging/hpux || _die "Couldn't create the staging directory"
    cp -R $WD/binaries/AS90-HPUX/stackbuilderplus/* $WD/StackBuilderPlus/staging/hpux
    chmod ugo+w $WD/StackBuilderPlus/staging/hpux || _die "Couldn't set the permissions on the staging directory"
}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_hpux() {

    cd $WD
}


################################################################################
# Post Processing StackBuilderPlus
################################################################################

_postprocess_stackbuilderplus_hpux() { 

    echo "**********************************************"
    echo "* Post-processing - StackBuilderPlus (hpux) *"
    echo "**********************************************"

    cd $WD/StackBuilderPlus

    mkdir -p staging/hpux/installer/StackBuilderPlus || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/hpux/UpdateManager/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/hpux/configlibs.sh staging/hpux/installer/StackBuilderPlus/configlibs.sh || _die "Failed to copy the configlibs script (scripts/hpux/configlibs.sh)"
    _replace @@PLATFORM@@ "hpux" staging/hpux/installer/StackBuilderPlus/configlibs.sh || _die "Failed to replace the platform placeholder value"
    chmod ugo+x staging/hpux/installer/StackBuilderPlus/*.sh

    mkdir -p staging/hpux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/hpux/launchSBPUpdateMonitor.sh staging/hpux/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/hpux/launchSBPUpdateMonitor.sh)"
    cp scripts/hpux/launchStackBuilderPlus.sh staging/hpux/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/hpux/launchStackBuilderPlus.sh)"
    cp scripts/hpux/runStackBuilderPlus.sh staging/hpux/scripts/runStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/hpux/runStackBuilderPlus.sh)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml hpux || _die "Failed to build the installer for hpux"

    cd $WD
}


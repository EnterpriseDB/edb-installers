#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphq_linux_x64() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ (LINUX-X64)"
    echo "*******************************************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/linux-x64)"
    mkdir -p $WD/pphq/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Build
################################################################################

_build_pphq_linux_x64() {

    echo "*******************************************************"
    echo " Build : PPHQ (LINUX-X64)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/linux-x64
    SERVER_STAGING=$WD/server/staging/linux-x64
    echo ""
    echo "Copying Postgres Plus installers to staging directory"
    mkdir -p $PPHQ_STAGING/pphq || _die "Failed to create the pphq installer directory"
    cp -r $WD/pphq/source/hq/build/archive/hyperic-hq-installer/* $PPHQ_STAGING/pphq/

    mkdir -p $PPHQ_STAGING/pphq/templates
    cp $WD/pphq/resources/*.prop $PPHQ_STAGING/pphq/templates

    #Copy psql for postgres validation
    mkdir -p $PPHQ_STAGING/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/bin || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/lib || _die "Failed to create the instscripts directory"
    cp $SERVER_STAGING/bin/psql $PPHQ_STAGING/instscripts/bin/ || _die "Failed to copy psql in instscripts"
    cp $SERVER_STAGING/lib/libpq* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy libpq in instscripts"
    cp $SERVER_STAGING/lib/libssl.so* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy the dependency library"
    cp $SERVER_STAGING/lib/libcrypto.so* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy the dependency library"
    cp $SERVER_STAGING/lib/libtermcap.so* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy the dependency library"
    cp $SERVER_STAGING/lib/libxml2.so* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy the dependency library"
    cp $SERVER_STAGING/lib/libreadline.so* $PPHQ_STAGING/instscripts/lib/ || _die "Failed to copy the dependency library"

}

################################################################################
# PPHQ Post-Process
################################################################################

_postprocess_pphq_linux_x64() {

    echo "*******************************************************"
    echo " Post Process : PPHQ (LINUX-X64)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/linux-x64
    PPHQ_DIR=$WD/pphq

    cd $PPHQ_DIR

    mkdir -p $PPHQ_STAGING/installer/pphq || _die "Failed to create a directory for the install scripts"
    cp $PPHQ_DIR/scripts/linux/removeshortcuts.sh $PPHQ_STAGING/installer/pphq/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/removeshortcuts.sh

    cp $PPHQ_DIR/scripts/tune-os.sh $PPHQ_STAGING/installer/pphq/tune-os.sh || _die "Failed to copy the tune-os.sh script (scripts/tune-os.sh)"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/tune-os.sh

    cp $PPHQ_DIR/scripts/linux/createshortcuts.sh $PPHQ_STAGING/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/createshortcuts.sh

    # Copy the XDG scripts
    mkdir -p $PPHQ_STAGING/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* $PPHQ_STAGING/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x $PPHQ_STAGING/installer/xdg/xdg*

    # Version string, for the xdg filenames
    PPHQ_VERSION_STR=`echo $PG_VERSION_PPHQ | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p $PPHQ_STAGING/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQ_DIR/resources/pphq.png $PPHQ_STAGING/scripts/images/pphq-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp $PPHQ_DIR/resources/pphq-launch.png $PPHQ_STAGING/scripts/images/pphq-launch-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp $PPHQ_DIR/resources/pphq-start.png $PPHQ_STAGING/scripts/images/pphq-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp $PPHQ_DIR/resources/pphq-stop.png $PPHQ_STAGING/scripts/images/pphq-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp $PPHQ_DIR/resources/pphq-agent-start.png $PPHQ_STAGING/scripts/images/pphq-agent-start-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp $PPHQ_DIR/resources/pphq-agent-stop.png $PPHQ_STAGING/scripts/images/pphq-agent-stop-$PPHQ_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p $PPHQ_STAGING/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pphq.directory $PPHQ_STAGING/scripts/xdg/pphq-$PPHQ_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pphq-launch.desktop $PPHQ_STAGING/scripts/xdg/pphq-launch-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-start.desktop $PPHQ_STAGING/scripts/xdg/pphq-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-stop.desktop $PPHQ_STAGING/scripts/xdg/pphq-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-start.desktop $PPHQ_STAGING/scripts/xdg/pphq-agent-start-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pphq-agent-stop.desktop $PPHQ_STAGING/scripts/xdg/pphq-agent-stop-$PPHQ_VERSION_STR.desktop || _die "Failed to copy a menu pick"


    # Copy the launch scripts
    cp $PPHQ_DIR/scripts/linux/launchsvrctl.sh $PPHQ_STAGING/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x $PPHQ_STAGING/scripts/launchsvrctl.sh
    cp $PPHQ_DIR/scripts/linux/serverctl.sh $PPHQ_STAGING/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x $PPHQ_STAGING/scripts/serverctl.sh
    cp $PPHQ_DIR/scripts/linux/launchagentctl.sh $PPHQ_STAGING/scripts/launchagentctl.sh || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
    chmod ugo+x $PPHQ_STAGING/scripts/launchagentctl.sh
    cp $PPHQ_DIR/scripts/linux/agentctl.sh $PPHQ_STAGING/scripts/agentctl.sh || _die "Failed to copy the agentctl script (scripts/linux-x64/agentctl.sh)"
    chmod ugo+x $PPHQ_STAGING/scripts/agentctl.sh
    cp $PPHQ_DIR/scripts/linux/launchbrowser.sh $PPHQ_STAGING/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x $PPHQ_STAGING/scripts/launchbrowser.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

}


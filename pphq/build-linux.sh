#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_pphq_linux() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ (LINUX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/linux

    if [ -e $PPHQ_STAGING ];
    then
      echo "Removing existing staging directory"
      rm -rf $PPHQ_STAGING || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($PPHQ_STAGING)"
    mkdir -p $PPHQ_STAGING || _die "Couldn't create the staging directory"
    chmod ugo+w $PPHQ_STAGING || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Build
################################################################################

_build_pphq_linux() {

    echo "*******************************************************"
    echo " Build : PPHQ (LINUX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/linux
    SERVER_STAGING=$WD/server/staging/linux

    mkdir -p $PPHQ_STAGING/pphq || _die "Failed to create the pphq installer directory"
    mkdir -p $PPHQ_STAGING/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/bin || _die "Failed to create the instscripts directory"
    mkdir -p $PPHQ_STAGING/instscripts/lib || _die "Failed to create the instscripts directory"

    echo "Copying Postgres Plus HQ installer to staging directory"
    cp -r $WD/pphq/source/hq/build/archive/hyperic-hq-installer/* $PPHQ_STAGING/pphq/

    mkdir -p $PPHQ_STAGING/pphq/templates
    cp $WD/pphq/resources/*.prop $PPHQ_STAGING/pphq/templates

    #Copy psql for postgres validation
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

_postprocess_pphq_linux() {

    echo "*******************************************************"
    echo " Post Process : PPHQ (LINUX)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/pphq/staging/linux
    PPHQ_DIR=$WD/pphq

    cd $PPHQ_DIR

    mkdir -p $PPHQ_STAGING/installer/pphq || _die "Failed to create a directory for the install scripts"
    cp $PPHQ_DIR/scripts/linux/createuser.sh $PPHQ_STAGING/installer/pphq/ || _die "Failed to copy the createuser script"
    cp $PPHQ_DIR/scripts/linux/removeshortcuts.sh $PPHQ_STAGING/installer/pphq/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script"
    cp $PPHQ_DIR/scripts/tune-os.sh $PPHQ_STAGING/installer/pphq/tune-os.sh || _die "Failed to copy the tune-os.sh script"
    cp $PPHQ_DIR/scripts/linux/createshortcuts.sh $PPHQ_STAGING/installer/pphq/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script"
    cp $PPHQ_DIR/scripts/linux/startupcfg.sh $PPHQ_STAGING/installer/pphq/startupcfg.sh || _die "Failed to copy the startupcfg.sh script"
    chmod ugo+x $PPHQ_STAGING/installer/pphq/*.sh

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
    cp $PPHQ_DIR/scripts/linux/agentctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the agentctl script"
    cp $PPHQ_DIR/scripts/linux/launchagentctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the launchagentctl script"
    cp $PPHQ_DIR/scripts/linux/launchbrowser.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the launchbrowser script"
    cp $PPHQ_DIR/scripts/linux/launchsvrctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the launchsvrctl script"
    cp $PPHQ_DIR/scripts/linux/runAgent.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the runAgent script"
    cp $PPHQ_DIR/scripts/linux/serverctl.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the serverctl script"
    cp $PPHQ_DIR/scripts/linux/runServer.sh $PPHQ_STAGING/scripts/ || _die "Failed to copy the serverctl script"
    chmod ugo+x $PPHQ_STAGING/scripts/*.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}


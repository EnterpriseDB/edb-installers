#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_pphqagent_linux_x64() {

    echo "*******************************************************"
    echo " Pre Process : PPHQ Agent (LINUX-X64)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/linux-x64
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PPHQAGENT_STAGING_DIR ];
    then
      echo "Removing existing staging directory"
      rm -rf $PPHQAGENT_STAGING_DIR || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($PPHQAGENT_STAGING_DIR)"
    mkdir -p $PPHQAGENT_STAGING_DIR || _die "Couldn't create the staging directory"
    chmod ugo+w $PPHQAGENT_STAGING_DIR || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# PPHQ Agent Build
################################################################################

_build_pphqagent_linux_x64() {

    echo "*******************************************************"
    echo " Build : PPHQ Agent (LINUX-X64)"
    echo "*******************************************************"

    PPHQ_STAGING=$WD/hqagent/staging/linux-x64

    echo "Copying PPHQ Agent binaries to staging directory"
    cd $PPHQ_STAGING/
    tar -zxf $WD/pphq/source/hq/build/archive/hyperic-hq-installer/agent-$PG_VERSION_HQAGENT.tgz || _die "Couldn't extract agent binaries"

    echo "Copying JRE to staging directory"
    tar -jxf $WD/tarballs/jre6-linux-x64.tar.bz2 || _die "Couldn't extract the JRE"

    echo "Cleaning up unnecessary files..."
    find . -name *ia64-linux* -delete \
        -o -name *ppc64-linux* -delete \
        -o -name *ppc-linux* -delete \
        -o -name *solaris* -delete \
        -o -name *freebsd* -delete \
        -o -name *aix* -delete \
        -o -name *hpux* -delete \
        -o -name *winnt* -delete \
        -o -name *macosx* -delete

    cd $WD

}

################################################################################
# PPHQ Agent Build
################################################################################

_postprocess_pphqagent_linux_x64() {

    echo "*******************************************************"
    echo " Post Process : PPHQ Agent (LINUX-X64)"
    echo "*******************************************************"

    PPHQAGENT_STAGING_DIR=$WD/hqagent/staging/linux-x64
    PPHQAGENT_DIR=$WD/hqagent
    PPHQ_DIR=$WD/pphq

    cd $PPHQAGENT_DIR

    # Setup the installer scripts.
    mkdir -p $PPHQAGENT_STAGING_DIR/installer/pphqagent || _die "Failed to create a directory for the install scripts"
    cp $PPHQ_DIR/scripts/linux/createuser.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the createuser script"
    cp $PPHQ_DIR/scripts/linux/startupcfg.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the startupcfg script"
    cp $PPHQAGENT_DIR/scripts/linux/removeshortcuts.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the removeshortcuts script"
    cp $PPHQAGENT_DIR/scripts/linux/createshortcuts.sh $PPHQAGENT_STAGING_DIR/installer/pphqagent/ || _die "Failed to copy the createshortcuts script"
    chmod ugo+x $PPHQAGENT_STAGING_DIR/installer/pphqagent/*.sh

    # Copy the XDG scripts
    mkdir -p $PPHQAGENT_STAGING_DIR/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* $PPHQAGENT_STAGING_DIR/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x $PPHQAGENT_STAGING_DIR/installer/xdg/xdg*

    HQAGENT_VERSION_STR=`echo $PG_VERSION_HQAGENT | sed 's/\./_/g'`

    # Copy in the menu pick images  and XDG items
    mkdir -p $PPHQAGENT_STAGING_DIR/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PPHQAGENT_DIR/resources/hqagent.png $PPHQAGENT_STAGING_DIR/scripts/images/hqagent.png || _die "Failed to copy a menu pick image"
    cp $PPHQAGENT_DIR/resources/hqagent-start.png $PPHQAGENT_STAGING_DIR/scripts/images/hqagent-start.png || _die "Failed to copy a menu pick image"
    cp $PPHQAGENT_DIR/resources/hqagent-stop.png $PPHQAGENT_STAGING_DIR/scripts/images/hqagent-stop.png || _die "Failed to copy a menu pick image"

    mkdir -p $PPHQAGENT_STAGING_DIR/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp $PPHQAGENT_DIR/resources/xdg/hqagent.directory $PPHQAGENT_STAGING_DIR/scripts/xdg/hqagent.directory || _die "Failed to copy a menu pick directory (hqagent.directory)"
    cp $PPHQ_DIR/resources/xdg/pphq-agent-start.desktop $PPHQAGENT_STAGING_DIR/scripts/xdg/hqagent-start.desktop || _die "Failed to copy a menu pick (hqagent-start.desktop)"
    cp $PPHQ_DIR/resources/xdg/pphq-agent-stop.desktop $PPHQAGENT_STAGING_DIR/scripts/xdg/hqagent-stop.desktop || _die "Failed to copy a menu pick (hqagent-stop.desktop)"

    # Copy the launch scripts
    cp $PPHQ_DIR/scripts/linux/launchagentctl.sh $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to copy the launchagentctl script (scripts/linux/launchagentctl.sh)"
    cp $PPHQ_DIR/scripts/linux/agentctl.sh $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to copy the agentctl script (scripts/linux/agentctl.sh)"
    cp $PPHQ_DIR/scripts/linux/runAgent.sh $PPHQAGENT_STAGING_DIR/scripts/ || _die "Failed to copy the agentctl script (scripts/linux/agentctl.sh)"
    chmod ugo+x $PPHQAGENT_STAGING_DIR/scripts/*.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    cd $WD

}


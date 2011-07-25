#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer_hpux() {

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ReplicationServer/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ReplicationServer/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ReplicationServer/staging/hpux)"
    mkdir -p $WD/ReplicationServer/staging/hpux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts || _die "Couldn't create the staging/hpux/instscripts directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts || _die "Couldn't set the permissions on the staging/hpux/instscripts directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Couldn't create the staging/hpux/instscripts/bin directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Couldn't set the permissions on the staging/hpux/instscripts/bin directory"
    mkdir -p $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Couldn't create the staging/hpux/instscripts/lib directory"
    chmod ugo+w $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Couldn't set the permissions on the staging/hpux/instscripts/lib directory"

    cp $WD/binaries/AS90-HPUX/instscripts/psql $WD/ReplicationServer/staging/hpux/instscripts/bin || _die "Failed to copy psql binary"
    cp $WD/binaries/AS90-HPUX/instscripts/lib*.* $WD/ReplicationServer/staging/hpux/instscripts/lib || _die "Failed to copy libs"
}

################################################################################
# PG Build
################################################################################

_build_ReplicationServer_hpux() {

    cd $WD
    cp -R $WD/binaries/AS90-HPUX/xdbReplicationServer/repconsole $WD/ReplicationServer/staging/hpux || _die "Failed to copy repconsole binary"
    cp -R $WD/binaries/AS90-HPUX/xdbReplicationServer/repserver $WD/ReplicationServer/staging/hpux  || _die "Failed to copy repserver binary"

    chmod +rx $WD/ReplicationServer/staging/hpux
    chmod +rx $WD/ReplicationServer/staging/hpux/repserver/bin/*
    chmod +r $WD/ReplicationServer/staging/hpux/repconsole/lib/*
    chmod +r $WD/ReplicationServer/staging/hpux/repconsole/lib/jdbc/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/jdbc/*
    chmod +r $WD/ReplicationServer/staging/hpux/repserver/lib/repl-mtk/*

}


################################################################################
# PG Build
################################################################################

_postprocess_ReplicationServer_hpux() {
 

    cd $WD/ReplicationServer

    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\.//g'`
    # Setup the installer scripts.
    mkdir -p staging/hpux/installer/xDBReplicationServer || _die "Failed to create a directory for the install scripts"

    cp scripts/hpux/createuser.sh staging/hpux/installer/xDBReplicationServer/createuser.sh || _die "Failed to copy the createuser.sh script (scripts/hpux/createuser.sh)"
    chmod ugo+x staging/hpux/installer/xDBReplicationServer/createuser.sh

    cp $WD/binaries/AS90-HPUX/xdbReplicationServer/edb-repencrypter.jar staging/hpux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility (staging/hpux/edb-repencrypter.jar)"
    cp -R $WD/binaries/AS90-HPUX/xdbReplicationServer/lib staging/hpux/installer/xDBReplicationServer/ || _die "Failed to copy the DESEncrypter utility's dependent libs (staging/hpux/lib)"
    # Setup Launch Scripts
    mkdir -p staging/hpux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/hpux/startupcfg_publication.sh staging/hpux/scripts/startupcfg_publication.sh || _die "Failed to copy the startupcfg_publication.sh script (scripts/hpux/startupcfg_publication.sh)"
    chmod ugo+x staging/hpux/scripts/startupcfg_publication.sh
    cp scripts/hpux/startupcfg_subscription.sh staging/hpux/scripts/startupcfg_subscription.sh || _die "Failed to copy the startupcfg_subscription.sh script (scripts/hpux/startupcfg_subscription.sh)"
    chmod ugo+x staging/hpux/scripts/startupcfg_subscription.sh

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml hpux || _die "Failed to build the installer"

    cd $WD
}


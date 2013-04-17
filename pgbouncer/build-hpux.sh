#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_hpux() {

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/hpux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/hpux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/hpux)"
    mkdir -p $WD/pgbouncer/staging/hpux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/hpux || _die "Couldn't set the permissions on the staging directory"

    cp -R $WD/binaries/AS90-HPUX/pgbouncer $WD/pgbouncer/staging/hpux || _die "Couldn't copy hpux distros to staging directory"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/hpux/pgbouncer/doc)"
    mkdir $WD/pgbouncer/staging/hpux/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/hpux/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/hpux/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    # Copy instscripts to staging directory
    cp -R $WD/binaries/AS90-HPUX/instscripts $WD/pgbouncer/staging/hpux/ || _die "Failed to copy libpq in instscripts"
}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_hpux() {

    cd $WD/pgbouncer
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_hpux() {
 

    cd $WD/pgbouncer

    mkdir -p staging/hpux/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/hpux/startupcfg.sh staging/hpux/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/hpux/installer/pgbouncer/startupcfg.sh


    rm -rf staging/hpux/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace "bardb = host=127.0.0.1 dbname=bazdb" ";bardb = host=127.0.0.1 dbname=bazdb" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" ";forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "nondefaultdb = pool_size=50 reserve_pool=10" ";nondefaultdb = pool_size=50 reserve_pool=10" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "foodb =" "@@CON@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = pgbouncer.log" "logfile = @@LOGFILE@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = etc/userlist.txt" "auth_file = @@AUTHFILE@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/hpux/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml hpux || _die "Failed to build the installer"

    cd $WD
}


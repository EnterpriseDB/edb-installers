#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.linux ];
    then
      echo "Removing existing pgbouncer.linux source directory"
      rm -rf pgbouncer.linux  || _die "Couldn't remove the existing pgbouncer.linux source directory (source/pgbouncer.linux)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.linux)"
    mkdir -p $WD/pgbouncer/source/libevent.linux || _die "Couldn't create the libevent.linux directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.linux)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.linux || _die "Couldn't create the pgbouncer.linux directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.linux || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/linux)"
    mkdir -p $WD/pgbouncer/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/linux || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/linux/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/linux/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/linux/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/linux/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
   

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_linux() {

    mkdir -p $WD/pgbouncer/staging/linux/instscripts || _die "Failed to create the instscripts directory"
    mkdir -p $WD/pgbouncer/staging/linux/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"
 
   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; LDFLAGS="-Wl,-rpath,$PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/lib" ./configure --prefix=$PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer --with-libevent=/opt/local/Current" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; make" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/source/pgbouncer.linux/; make install" || _die "Failed to install pgbouncer"

    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/share" || _die "Failed to copy pgbouncer ini to share directory"

    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 '.'`  
  
    ssh $PG_SSH_LINUX "cp -R /opt/local/Current/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"
    ssh $PG_SSH_LINUX "chmod o+rx $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/lib/*" || _die "Failed to change permission of libevent libs in pgbouncer lib folder"

    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy libpq in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy psql in instscripts"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libssl.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libcrypto.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libxml2.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; cp server/staging/linux/lib/libxslt.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy libxslt.so"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libedit.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libz.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libldap*.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/liblber*.so* $PG_PATH_LINUX/pgbouncer/staging/linux/instscripts/" || _die "Failed to copy the dependency library"

    echo "Changing the rpath for the pgbouncer"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"

    # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_LINUX/pgbouncer/staging/linux/pgbouncer" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/pgbouncer ];
    then
        echo "Removing existing $WD/output/symbols/linux/pgbouncer directory"
        rm -rf $WD/output/symbols/linux/pgbouncer  || _die "Couldn't remove the existing $WD/output/symbols/linux/pgbouncer directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/pgbouncer/staging/linux/pgbouncer/symbols $WD/output/symbols/linux/pgbouncer || _die "Failed to move $WD/pgbouncer/staging/linux/pgbouncer/symbols to $WD/output/symbols/linux/pgbouncer directory"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_linux() {
 

    cd $WD/pgbouncer

    mkdir -p staging/linux/installer/pgbouncer || _die "Failed to create directory for installer scripts"

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/linux -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/linux -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/linux -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/linux -name \*.sh -exec chmod 755 {} \;

    cp -R scripts/linux/startupcfg.sh staging/linux/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/linux/installer/pgbouncer/startupcfg.sh

    chmod -R 755 staging/linux/instscripts

    rm -rf staging/linux/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace "bardb = host=127.0.0.1 dbname=bazdb" ";bardb = host=127.0.0.1 dbname=bazdb" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" ";forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "nondefaultdb = pool_size=50 reserve_pool=10" ";nondefaultdb = pool_size=50 reserve_pool=10" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "foodb =" "@@CON@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = pgbouncer.log" "logfile = @@LOGFILE@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = etc/userlist.txt" "auth_file = @@AUTHFILE@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/linux/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    # Set 644 for all files and folders
    find staging/linux/ -type f | xargs -I{} chmod 644 {}

    # Set Permissions for links and folders
    find staging/linux/ -xtype l | xargs -I{} chmod 777 {}
    find staging/linux/ -type d | xargs -I{} chmod 755 {}

    # " executable" requires a ' ' prefix to ensure it is not a filename
    find staging/linux/ -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find staging/linux/ -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


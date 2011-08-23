#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_osx() {

    echo "**********************************"
    echo "*  Pre Process: pgBouncer (OSX)  *"
    echo "**********************************"

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.osx ];
    then
      echo "Removing existing pgbouncer.osx source directory"
      rm -rf pgbouncer.osx  || _die "Couldn't remove the existing pgbouncer.osx source directory (source/pgbouncer.osx)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.osx)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.osx || _die "Couldn't create the pgbouncer.osx directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.osx || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/osx)"
    mkdir -p $WD/pgbouncer/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/osx/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/osx/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod ugo+w $WD/pgbouncer/staging/osx/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/osx/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    

}

################################################################################
# Build
################################################################################

_build_pgbouncer_osx() {

    echo "****************************"
    echo "*  Build: pgBouncer (OSX)  *"
    echo "****************************"

    cd $PG_PATH_OSX/pgbouncer/source/pgbouncer.osx/; 
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" LDFLAGS="-arch ppc" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"
    mv include/config.h include/config_ppc.h || _die "Failed to rename config.h"
    
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-arch i386" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"
    mv include/config.h include/config_i386.h || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"
    mv include/config.h include/config_x86_64.h || _die "Failed to rename config.h"

    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc -arch x86_64" LDFLAGS="-arch i386 -arch ppc -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer --with-libevent=/usr/local || _die "Failed to configure pgbouncer"

    echo "#ifdef __BIG_ENDIAN__" > include/config.h
    echo "  #include \"config_ppc.h\"" >> include/config.h
    echo "#else" >> include/config.h
    echo "  #ifdef __LP64__" >> include/config.h
    echo "    #include \"config_x86_64.h\"" >> include/config.h
    echo "  #else" >> include/config.h
    echo "    #include \"config_i386.h\"" >> include/config.h
    echo "  #endif" >> include/config.h
    echo "#endif" >> include/config.h
    
    MACOSX_DEPLOYMENT_TARGET=10.5 make || _die "Failed to build pgbouncer"
    make install || _die "Failed to install pgbouncer"

    cp -R $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/share || _die "Failed to copy the ini file to share directory"

    mkdir -p $WD/pgbouncer/staging/osx/pgbouncer/lib || _die "Failed to create the pgbouncer lib directory"
    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 -d '.'`
 
    cp /usr/local/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION*dylib $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer/lib/ || _die "Failed to copy the libevent library(libevent-$PG_LIBEVENT_MAJOR_VERSION)"

    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer bin @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/pgbouncer/staging/osx/pgbouncer lib @loader_path/

 
    mkdir -p $WD/pgbouncer/staging/osx/instscripts || _die "Failed to create the instscripts directory"

    cp -R $PG_PATH_OSX/server/staging/osx/lib/libpq* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $PG_PATH_OSX/server/staging/osx/bin/psql $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy psql in instscripts"
    cp /usr/local/lib/libxml2* $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/ || _die "Failed to copy the latest libxml2"

    # Change the referenced libraries
    OLD_DLL_LIST=`otool -L $PG_PATH_OSX/pgbouncer/staging/osx/instscripts/psql | grep @loader_path/../lib |  grep -v ":" | awk '{ print $1 }' `
    for OLD_DLL in $OLD_DLL_LIST
    do 
        NEW_DLL=`echo $OLD_DLL | sed -e "s^@loader_path/../lib/^^g"`
        install_name_tool -change "$OLD_DLL" "$NEW_DLL" "$PG_PATH_OSX/pgbouncer/staging/osx/instscripts/psql"
    done

  
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_osx() {

    echo "***********************************"
    echo "*  Post Process: pgBouncer (OSX)  *"
    echo "***********************************"
 
    cd $WD/pgbouncer

    mkdir -p staging/osx/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/osx/startupcfg.sh staging/osx/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/osx/installer/pgbouncer/startupcfg.sh    

    rm -rf staging/osx/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace "bardb = host=127.0.0.1 dbname=bazdb" ";bardb = host=127.0.0.1 dbname=bazdb" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" ";forcedb = host=127.0.0.1 port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "nondefaultdb = pool_size=50 reserve_pool=10" ";nondefaultdb = pool_size=50 reserve_pool=10" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "foodb =" "@@CON@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = pgbouncer.log" "logfile = @@LOGFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = etc/userlist.txt" "auth_file = @@AUTHFILE@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type" 
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/osx/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/PgBouncer
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PgBouncer $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with PgBouncer ($WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.zip pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-osx.app/ || _die "Failed to remove the unpacked installer bundle"


    cd $WD
}


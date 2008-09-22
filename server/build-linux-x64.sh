#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.linux-x64 ];
    then
      echo "Removing existing postgres.linux-x64 source directory"
      rm -rf postgres.linux-x64  || _die "Couldn't remove the existing postgres.linux-x64 source directory (source/postgres.linux-x64)"
    fi
   
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.linux-x64 || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    chmod -R ugo+w postgres.linux-x64 || _die "Couldn't set the permissions on the source directory"
 
    if [ -e pgadmin.linux-x64 ];
    then
      echo "Removing existing pgadmin.linux-x64 source directory"
      rm -rf pgadmin.linux-x64  || _die "Couldn't remove the existing pgadmin.linux-x64 source directory (source/pgadmin.linux-x64)"
    fi

    # Grab a copy of the source tree
    cp -R pgadmin3-$PG_TARBALL_PGADMIN pgadmin.linux-x64 || _die "Failed to copy the source code (source/pgadmin-$PG_TARBALL_PGADMIN)"
    chmod -R ugo+w pgadmin.linux-x64 || _die "Couldn't set the permissions on the source directory"

    if [ -e pljava.linux-x64 ];
    then
      echo "Removing existing pljava.linux-x64 source directory"
      rm -rf pljava.linux-x64  || _die "Couldn't remove the existing pljava.linux-x64 source directory (source/pljava.linux-x64)"
    fi

    # Grab a copy of the source tree
    cp -R pljava-$PG_TARBALL_PLJAVA pljava.linux-x64 || _die "Failed to copy the source code (source/pljava-$PG_TARBALL_PLJAVA)"
    chmod -R ugo+w pljava.linux-x64 || _die "Couldn't set the permissions on the source directory"

    if [ -e stackbuilder.linux-x64 ];
    then
      echo "Removing existing stackbuilder.linux-x64 source directory"
      rm -rf stackbuilder.linux-x64  || _die "Couldn't remove the existing stackbuilder.linux-x64 source directory (source/stackbuilder.linux-x64)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -R stackbuilder stackbuilder.linux-x64 || _die "Failed to copy the source code (source/stackbuilder)"	
	chmod -R ugo+w stackbuilder.linux-x64 || _die "Couldn't set the permissions on the source directory"
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/linux-x64)"
    mkdir -p $WD/server/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/server/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

}

################################################################################
# Build
################################################################################

_build_server_linux_x64() {

    # First build PostgreSQL

    PG_STAGING=$PG_PATH_LINUX_X64/server/staging/linux-x64
    
    # Configure the source tree
    echo "Configuring the postgres source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/; sh ./configure --prefix=$PG_STAGING --with-openssl --with-perl --with-python --with-tcl --with-pam --with-krb5"  || _die "Failed to configure postgres"

    echo "Building postgres"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64; make" || _die "Failed to build postgres" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64; make install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib; make" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building debugger module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/pldebugger; make" || _die "Failed to build the debugger module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/pldebugger; make install" || _die "Failed to install the debugger module"
    cp "$WD/server/source/postgres.linux-x64/contrib/pldebugger/README.pldebugger" $WD/server/staging/linux-x64/doc || _die "Failed to copy the debugger README into the staging directory"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libreadline.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libtermcap.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
	
    # Now build pgAdmin

    # Bootstrap
    echo "Bootstrapping the build system"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; sh bootstrap"

    # Configure
    echo "Configuring the pgAdmin source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; sh ./configure --prefix=$PG_STAGING/pgAdmin3 --with-pgsql=$PG_PATH_LINUX_X64/server/staging/linux-x64 --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static" || _die "Failed to configure pgAdmin"

    # Build the app
    echo "Building & installing pgAdmin"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; make all" || _die "Failed to build pgAdmin"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; make install" || _die "Failed to install pgAdmin"

    # Copy in the various libraries
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_STAGING/pgAdmin3/lib" || _die "Failed to create the lib directory"

    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_adv-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_aui-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_core-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_html-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_ogl-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_qa-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_richtext-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_stc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_gtk2u_xrc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_baseu-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_baseu_net-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libwx_baseu_xml-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/lib/libpq.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libxslt.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
	ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libexpat.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
	ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libtiff.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    # Copy the Postgres utilities
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_dump $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_dumpall $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_restore $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/psql $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"

    # Move the utilties.ini file out of the way (Uncomment for Postgres Studio or 1.9+)
    # ssh $PG_SSH_LINUX_X64 "mv $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini.new" || _die "Failed to move the utilties.ini file"
     
    # And now, pl/java

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pljava.linux-x64/; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 PATH=$PATH:$PG_EXEC_PATH_LINUX_X64:$PG_PATH_LINUX_X64/server/staging/linux-x64/bin make" || _die "Failed to build pl/java"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pljava.linux-x64/; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 PATH=$PATH:$PG_EXEC_PATH_LINUX_X64:$PG_PATH_LINUX_X64/server/staging/linux-x64/bin make prefix=$PG_PATH_LINUX_X64/server/staging/linux-x64 install" || _die "Failed to install pl/java"

    mkdir -p "$WD/server/staging/linux-x64/share/pljava" || _die "Failed to create the pl/java share directory"
    cp "$WD/server/source/pljava.linux-x64/src/sql/install.sql" "$WD/server/staging/linux-x64/share/pljava/pljava.sql" || _die "Failed to install the pl/java installation SQL script"
    cp "$WD/server/source/pljava.linux-x64/src/sql/uninstall.sql" "$WD/server/staging/linux-x64/share/pljava/uninstall_pljava.sql" || _die "Failed to install the pl/java uninstallation SQL script"

    mkdir -p "$WD/server/staging/linux-x64/doc/pljava" || _die "Failed to create the pl/java doc directory"
    cp "$WD/server/source/pljava.linux-x64/docs/"* "$WD/server/staging/linux-x64/doc/pljava/" || _die "Failed to install the pl/java documentation"
 
 	# Stackbuilder
	
    # Configure
    echo "Configuring the StackBuilder source tree"
	ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_STAGING/stackbuilder ."

    # Build the app
    echo "Building & installing StackBuilder"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; make install" || _die "Failed to install StackBuilder"
	
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_linux_x64() {

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/linux-x64/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.gif" "$WD/server/staging/linux-x64/doc/" || _die "Failed to install the welcome logo"

    # Setup the installer scripts. 
    mkdir -p staging/linux-x64/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/getlocales.sh staging/linux-x64/installer/server/getlocales.sh || _die "Failed to copy the getlocales script (scripts/linux/getlocales.sh)"
    chmod ugo+x staging/linux-x64/installer/server/getlocales.sh
    cp scripts/linux/runpgcontroldata.sh staging/linux-x64/installer/server/runpgcontroldata.sh || _die "Failed to copy the runpgcontroldata script (scripts/linux/runpgcontroldata.sh)"
    chmod ugo+x staging/linux-x64/installer/server/runpgcontroldata.sh
    cp scripts/linux/createuser.sh staging/linux-x64/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/linux/createuser.sh)"
    chmod ugo+x staging/linux-x64/installer/server/createuser.sh
    cp scripts/linux/initcluster.sh staging/linux-x64/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/linux/initcluster.sh)"
    chmod ugo+x staging/linux-x64/installer/server/initcluster.sh
    cp scripts/linux/startupcfg.sh staging/linux-x64/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux-x64/installer/server/startupcfg.sh
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/server/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/server/createshortcuts.sh
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/server/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/server/removeshortcuts.sh
    cp scripts/linux/startserver.sh staging/linux-x64/installer/server/startserver.sh || _die "Failed to copy the startserver script (scripts/linux/startserver.sh)"
    chmod ugo+x staging/linux-x64/installer/server/startserver.sh
    cp scripts/linux/loadmodules.sh staging/linux-x64/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/linux/loadmodules.sh)"
    chmod ugo+x staging/linux-x64/installer/server/loadmodules.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*
    
    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"

    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_MAJOR_VERSION.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-documentation.directory staging/linux-x64/scripts/xdg/pg-documentation-$PG_MAJOR_VERSION.directory || _die "Failed to copy a menu pick directory"

    cp resources/xdg/pg-doc-installationnotes.desktop staging/linux-x64/scripts/xdg/pg-doc-installationnotes-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pgadmin.desktop staging/linux-x64/scripts/xdg/pg-doc-pgadmin-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pljava-readme.desktop staging/linux-x64/scripts/xdg/pg-doc-pljava-readme-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pljava.desktop staging/linux-x64/scripts/xdg/pg-doc-pljava-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql-releasenotes.desktop staging/linux-x64/scripts/xdg/pg-doc-postgresql-releasenotes-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql.desktop staging/linux-x64/scripts/xdg/pg-doc-postgresql-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-pgadmin.desktop staging/linux-x64/scripts/xdg/pg-pgadmin-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-psql.desktop staging/linux-x64/scripts/xdg/pg-psql-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-reload.desktop staging/linux-x64/scripts/xdg/pg-reload-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-restart.desktop staging/linux-x64/scripts/xdg/pg-restart-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
	cp resources/xdg/pg-stackbuilder.desktop staging/linux-x64/scripts/xdg/pg-stackbuilder-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-start.desktop staging/linux-x64/scripts/xdg/pg-start-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-stop.desktop staging/linux-x64/scripts/xdg/pg-stop-$PG_MAJOR_VERSION.desktop || _die "Failed to copy a menu pick"
    
    # Copy the launch scripts
    cp scripts/linux/launchpsql.sh staging/linux-x64/scripts/launchpsql.sh || _die "Failed to copy the launchpsql script (scripts/linux/launchpsql.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchpsql.sh
    cp scripts/linux/launchsvrctl.sh staging/linux-x64/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchsvrctl.sh
    cp scripts/linux/runpsql.sh staging/linux-x64/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/linux/runpsql.sh)"
    chmod ugo+x staging/linux-x64/scripts/runpsql.sh
    cp scripts/linux/serverctl.sh staging/linux-x64/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/serverctl.sh
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh
    cp scripts/linux/launchpgadmin.sh staging/linux-x64/scripts/launchpgadmin.sh || _die "Failed to copy the launchpgadmin script (scripts/linux/launchpgadmin.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchpgadmin.sh
    cp scripts/linux/launchstackbuilder.sh staging/linux-x64/scripts/launchstackbuilder.sh || _die "Failed to copy the launchstackbuilder script (scripts/linux/launchstackbuilder.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchstackbuilder.sh
    cp scripts/linux/runstackbuilder.sh staging/linux-x64/scripts/runstackbuilder.sh || _die "Failed to copy the runstackbuilder script (scripts/linux/runstackbuilder.sh)"
    chmod ugo+x staging/linux-x64/scripts/runstackbuilder.sh
		
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

	# Rename the installer
	mv $WD/output/postgresql-$PG_MAJOR_VERSION-linux-x64-installer.bin $WD/output/postgresql-$PG_PACKAGE_VERSION-linux-x64.bin || _die "Failed to rename the installer"

    cd $WD
}


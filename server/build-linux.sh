#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.linux ];
    then
      echo "Removing existing postgres.linux source directory"
      rm -rf postgres.linux  || _die "Couldn't remove the existing postgres.linux source directory (source/postgres.linux)"
    fi
   
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.linux || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    chmod -R ugo+w postgres.linux || _die "Couldn't set the permissions on the source directory"
 
    if [ -e pgadmin.linux ];
    then
      echo "Removing existing pgadmin.linux source directory"
      rm -rf pgadmin.linux  || _die "Couldn't remove the existing pgadmin.linux source directory (source/pgadmin.linux)"
    fi

    # Grab a copy of the source tree
    cp -R pgadmin3-$PG_TARBALL_PGADMIN pgadmin.linux || _die "Failed to copy the source code (source/pgadmin-$PG_TARBALL_PGADMIN)"
    chmod -R ugo+w pgadmin.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e pljava.linux ];
    then
      echo "Removing existing pljava.linux source directory"
      rm -rf pljava.linux  || _die "Couldn't remove the existing pljava.linux source directory (source/pljava.linux)"
    fi

    # Grab a copy of the source tree
    cp -R pljava-$PG_TARBALL_PLJAVA pljava.linux || _die "Failed to copy the source code (source/pljava-$PG_TARBALL_PLJAVA)"
    chmod -R ugo+w pljava.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e stackbuilder.linux ];
    then
      echo "Removing existing stackbuilder.linux source directory"
      rm -rf stackbuilder.linux  || _die "Couldn't remove the existing stackbuilder.linux source directory (source/stackbuilder.linux)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -R stackbuilder stackbuilder.linux || _die "Failed to copy the source code (source/stackbuilder)"	
	chmod -R ugo+w stackbuilder.linux || _die "Couldn't set the permissions on the source directory"
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/linux)"
    mkdir -p $WD/server/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/server/staging/linux || _die "Couldn't set the permissions on the staging directory"

}

_process_dependent_libs() {

   bin_dir=$1
   lib_dir=$2
   libname=$3

    cat <<EOT > "process_dependent_libs.sh"
   #!/bin/bash

   # Fatal error handler
    _die() {
       echo ""
       echo "FATAL ERROR: \$1"
       echo ""
       exit 1
   }


   # Create a temporary directory
   mkdir -p /tmp/templibs

   export LD_LIBRARY_PATH=$lib_dir

   # Get the exact version of $libname which are required by the binaries in $bin_dir
   cd $bin_dir
   cd ..
   dependent_libs=\`ldd \\\`find . -perm +111 -type f\\\` | grep $libname | cut -f1 -d "=" | uniq\`

   # Get all the library versions of $libname present in $lib_dir
   cd $lib_dir
   liblist=\`ls $libname*\`

   # Match the library versions, required by binaries, in the $lib_dir.
   # If the matched version is a symlink, we resolve the symlink and copy the file in a temp directory.
   # If the matched version is a regular file, we copy it to the temp directory.

   for deplib in \$dependent_libs
   do
       for lib in \$liblist
       do
           if [ "\$deplib" = "\$lib" ]
           then
                if [ -f \$lib ]
                then
                    if [ -L \$lib ]
                    then
                        # Resolve the symlink
                        ref_lib=\`stat -c %N \$lib | cut -f2 -d ">"  | cut -f1 -d "'" | sed -e 's:\\\`::g'\`
                        # Remove the symlink
                        rm -f \$lib   || _die "Failed to remove the symlink"
                        # Copy the original lib to the name of the symlink in a temp directory.
                        cp \$ref_lib /tmp/templibs/\$lib  || _die "Failed to copy the original lib"
                    else
                        # Copy the original lib in a temp directory.
                        cp \$lib /tmp/templibs/\$lib || _die "Failed to copy the original lib"
                    fi
                fi
           fi
        done
    done

    # Remove all the remaining \$libname versions (that are not symlinks) in the lib directory
    for lib in \$liblist
    do
         rm -f \$lib || _die "Failed to remove the library"
    done

    # Copy libs from the tmp/templibs directory
    cp /tmp/templibs/* $lib_dir/     || _die "Failed to move the library files from temp directory"

    # Remove the temporary directory
    rm -rf /tmp/templibs

EOT

   chmod ugo+x process_dependent_libs.sh  || _die "Failed to change permissions"
   scp process_dependent_libs.sh $PG_SSH_LINUX:$PG_PATH_LINUX

   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; sh process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}

################################################################################
# Build
################################################################################

_build_server_linux() {

    # First build PostgreSQL

    PG_STAGING=$PG_PATH_LINUX/server/staging/linux
    
    # Configure the source tree
    echo "Configuring the postgres source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/;export LD_LIBRARY_PATH=/usr/local/openssl/lib:/usr/local/lib:$LD_LIBRARY_PATH;sh ./configure --with-libs=/usr/local/openssl/lib:/usr/local/lib --with-includes=/usr/local/openssl/include:/usr/local/include --prefix=$PG_STAGING --with-openssl --with-perl --with-python --with-tcl --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred"  || _die "Failed to configure postgres"

    echo "Building postgres"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux; export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; make" || _die "Failed to build postgres" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux; export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; make install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib; make" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building debugger module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/pldebugger; make" || _die "Failed to build the debugger module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/pldebugger; make install" || _die "Failed to install the debugger module"
	if [ ! -e $WD/server/staging/linux/doc ];
	then
	    mkdir -p $WD/server/staging/linux/doc || _die "Failed to create the doc directory"
	fi
    cp "$WD/server/source/postgres.linux/contrib/pldebugger/README.pldebugger" $WD/server/staging/linux/doc || _die "Failed to copy the debugger README into the staging directory"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/uuid-ossp; make" || _die "Failed to build the uuid-ossp module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"
	
    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "cp -R /usr/local/openssl/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/openssl/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /lib/libtermcap.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libuuid.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libpng12.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libjpeg.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"

    # Process Dependent libs
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libssl.so"  
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libcrypto.so"  
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libedit.so"  
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libtermcap.so"  
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libxml2.so"  
    _process_dependent_libs "$PG_STAGING/bin" "$PG_STAGING/lib" "libxslt.so"  

	
    # Now build pgAdmin

    # Bootstrap
    echo "Bootstrapping the build system"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pgadmin.linux/; sh bootstrap"

    # Configure
    echo "Configuring the pgAdmin source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pgadmin.linux/; sh ./configure --prefix=$PG_STAGING/pgAdmin3 --with-pgsql=$PG_PATH_LINUX/server/staging/linux --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static" || _die "Failed to configure pgAdmin"

    # Build the app
    echo "Building & installing pgAdmin"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pgadmin.linux/; make all" || _die "Failed to build pgAdmin"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pgadmin.linux/; make install" || _die "Failed to install pgAdmin"

    # Copy in the various libraries
    ssh $PG_SSH_LINUX "mkdir -p $PG_STAGING/pgAdmin3/lib" || _die "Failed to create the lib directory"

    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_adv-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_aui-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_core-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_html-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_ogl-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_qa-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_richtext-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_stc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_gtk2u_xrc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_baseu-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_baseu_net-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libwx_baseu_xml-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/lib/libpq.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/local/lib/libxslt.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libexpat.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -R /usr/lib/libtiff.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    echo "Changing the rpath for the pgAdmin binaries"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/pgAdmin3/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
	
    # Copy the Postgres utilities
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/pg_dump $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/pg_dumpall $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/pg_restore $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX "cp -R $PG_PATH_LINUX/server/staging/linux/bin/psql $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"

    # Move the utilties.ini file out of the way (Uncomment for Postgres Studio or 1.9+)
    # ssh $PG_SSH_LINUX "mv $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini.new" || _die "Failed to move the utilties.ini file"

    # And now, pl/java

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pljava.linux/; JAVA_HOME=$PG_JAVA_HOME_LINUX PATH=$PATH:$PG_EXEC_PATH_LINUX:$PG_PATH_LINUX/server/staging/linux/bin make" || _die "Failed to build pl/java"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pljava.linux/; JAVA_HOME=$PG_JAVA_HOME_LINUX PATH=$PATH:$PG_EXEC_PATH_LINUX:$PG_PATH_LINUX/server/staging/linux/bin make prefix=$PG_PATH_LINUX/server/staging/linux install" || _die "Failed to install pl/java"

    mkdir -p "$WD/server/staging/linux/share/pljava" || _die "Failed to create the pl/java share directory"
    cp "$WD/server/source/pljava.linux/src/sql/install.sql" "$WD/server/staging/linux/share/pljava/pljava.sql" || _die "Failed to install the pl/java installation SQL script"
    cp "$WD/server/source/pljava.linux/src/sql/uninstall.sql"	 "$WD/server/staging/linux/share/pljava/uninstall_pljava.sql" || _die "Failed to install the pl/java uninstallation SQL script"

    mkdir -p "$WD/server/staging/linux/doc/pljava" || _die "Failed to create the pl/java doc directory"
    cp "$WD/server/source/pljava.linux/docs/"* "$WD/server/staging/linux/doc/pljava/" || _die "Failed to install the pl/java documentation"

    echo "Changing the rpath for the PostgreSQL executables and libraries"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/lib/postgresql; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/..\" \$f; done"
 
	# Stackbuilder
	
    # Configure
    echo "Configuring the StackBuilder source tree"
	ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_STAGING/stackbuilder ."

    # Build the app
    echo "Building & installing StackBuilder"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; make install" || _die "Failed to install StackBuilder"


    echo "Changing the rpath for the StackBuilder"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/stackbuilder/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../../lib:\\\\${ORIGIN}/../../pgAdmin3/lib\" \$f; done"
	
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_linux() {

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/linux/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.gif" "$WD/server/staging/linux/doc/" || _die "Failed to install the welcome logo"
    cp "$WD/scripts/runAsRoot.sh" "$WD/server/staging/linux" || _die "Failed to copy the runAsRoot script"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/linux/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/linux
    cp -R bin doc include lib pgAdmin3 share stackbuilder pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    tar -czf postgresql-$PG_PACKAGE_VERSION-linux-binaries.tar.gz pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-linux-binaries.tar.gz $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p staging/linux/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/getlocales.sh staging/linux/installer/server/getlocales.sh || _die "Failed to copy the getlocales script (scripts/linux/getlocales.sh)"
    chmod ugo+x staging/linux/installer/server/getlocales.sh
    cp scripts/linux/runpgcontroldata.sh staging/linux/installer/server/runpgcontroldata.sh || _die "Failed to copy the runpgcontroldata script (scripts/linux/runpgcontroldata.sh)"
    chmod ugo+x staging/linux/installer/server/runpgcontroldata.sh
    cp scripts/linux/createuser.sh staging/linux/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/linux/createuser.sh)"
    chmod ugo+x staging/linux/installer/server/createuser.sh
    cp scripts/linux/initcluster.sh staging/linux/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/linux/initcluster.sh)"
    chmod ugo+x staging/linux/installer/server/initcluster.sh
    cp scripts/linux/startupcfg.sh staging/linux/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux/installer/server/startupcfg.sh
    cp scripts/linux/createshortcuts.sh staging/linux/installer/server/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/server/createshortcuts.sh
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/server/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/server/removeshortcuts.sh
    cp scripts/linux/startserver.sh staging/linux/installer/server/startserver.sh || _die "Failed to copy the startserver script (scripts/linux/startserver.sh)"
    chmod ugo+x staging/linux/installer/server/startserver.sh
    cp scripts/linux/loadmodules.sh staging/linux/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/linux/loadmodules.sh)"
    chmod ugo+x staging/linux/installer/server/loadmodules.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*
    
    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-help.png staging/linux/scripts/images/pg-help-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-pgadmin.png staging/linux/scripts/images/pg-pgadmin-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-postgresql.png staging/linux/scripts/images/pg-postgresql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-psql.png staging/linux/scripts/images/pg-psql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-reload.png staging/linux/scripts/images/pg-reload-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-restart.png staging/linux/scripts/images/pg-restart-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-stackbuilder.png staging/linux/scripts/images/pg-stackbuilder-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-start.png staging/linux/scripts/images/pg-start-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-stop.png staging/linux/scripts/images/pg-stop-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"

    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-documentation.directory staging/linux/scripts/xdg/pg-documentation-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"

    cp resources/xdg/pg-doc-installationnotes.desktop staging/linux/scripts/xdg/pg-doc-installationnotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pgadmin.desktop staging/linux/scripts/xdg/pg-doc-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pljava-readme.desktop staging/linux/scripts/xdg/pg-doc-pljava-readme-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pljava.desktop staging/linux/scripts/xdg/pg-doc-pljava-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql-releasenotes.desktop staging/linux/scripts/xdg/pg-doc-postgresql-releasenotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql.desktop staging/linux/scripts/xdg/pg-doc-postgresql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-pgadmin.desktop staging/linux/scripts/xdg/pg-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-psql.desktop staging/linux/scripts/xdg/pg-psql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-reload.desktop staging/linux/scripts/xdg/pg-reload-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-restart.desktop staging/linux/scripts/xdg/pg-restart-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-stackbuilder.desktop staging/linux/scripts/xdg/pg-stackbuilder-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-start.desktop staging/linux/scripts/xdg/pg-start-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-stop.desktop staging/linux/scripts/xdg/pg-stop-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    # Copy the launch scripts
    cp scripts/linux/launchpsql.sh staging/linux/scripts/launchpsql.sh || _die "Failed to copy the launchpsql script (scripts/linux/launchpsql.sh)"
    chmod ugo+x staging/linux/scripts/launchpsql.sh
    cp scripts/linux/launchsvrctl.sh staging/linux/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x staging/linux/scripts/launchsvrctl.sh
    cp scripts/linux/runpsql.sh staging/linux/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/linux/runpsql.sh)"
    chmod ugo+x staging/linux/scripts/runpsql.sh
    cp scripts/linux/serverctl.sh staging/linux/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x staging/linux/scripts/serverctl.sh
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh
    cp scripts/linux/launchpgadmin.sh staging/linux/scripts/launchpgadmin.sh || _die "Failed to copy the launchpgadmin script (scripts/linux/launchpgadmin.sh)"
    chmod ugo+x staging/linux/scripts/launchpgadmin.sh
    cp scripts/linux/launchstackbuilder.sh staging/linux/scripts/launchstackbuilder.sh || _die "Failed to copy the launchstackbuilder script (scripts/linux/launchstackbuilder.sh)"
    chmod ugo+x staging/linux/scripts/launchstackbuilder.sh
    cp scripts/linux/runstackbuilder.sh staging/linux/scripts/runstackbuilder.sh || _die "Failed to copy the runstackbuilder script (scripts/linux/runstackbuilder.sh)"
    chmod ugo+x staging/linux/scripts/runstackbuilder.sh
			
    PG_DATETIME_SETTING_LINUX=`cat staging/linux/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_LINUX" = "x" ]
    then
          PG_DATETIME_SETTING_LINUX="floating-point numbers"
    else
          PG_DATETIME_SETTING_LINUX="64-bit integers"
    fi  

    _replace @@PG_DATETIME_SETTING_LINUX@@ "$PG_DATETIME_SETTING_LINUX" installer.xml || _die "Failed to replace the date-time setting in the installer.xml"     


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
	
	# Rename the installer
	mv $WD/output/postgresql-$PG_MAJOR_VERSION-linux-installer.run $WD/output/postgresql-$PG_PACKAGE_VERSION-linux.run || _die "Failed to rename the installer"

    cd $WD
}


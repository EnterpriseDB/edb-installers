#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.osx ];
    then
      echo "Removing existing postgres.osx source directory"
      rm -rf postgres.osx  || _die "Couldn't remove the existing postgres.osx source directory (source/postgres.osx)"
    fi
    
    # Grab a copy of the postgres source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.osx || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"

    if [ -e pgadmin.osx ];
    then
      echo "Removing existing pgadmin.osx source directory"
      rm -rf pgadmin.osx  || _die "Couldn't remove the existing pgadmin.osx source directory (source/pgadmin.osx)"
    fi

    # Grab a copy of the pgadmin source tree
    cp -R pgadmin3-$PG_TARBALL_PGADMIN pgadmin.osx || _die "Failed to copy the source code (source/pgadmin3-$PG_TARBALL_PGADMIN)"

    if [ -e pljava.osx ];
    then
      echo "Removing existing pljava.osx source directory"
      rm -rf pljava.osx  || _die "Couldn't remove the existing pljava.osx source directory (source/pljava.osx)"
    fi

    # Grab a copy of the pljava source tree
    cp -R pljava-$PG_TARBALL_PLJAVA pljava.osx || _die "Failed to copy the source code (source/pljava-$PG_TARBALL_PLJAVA)"
    
    if [ -e stackbuilder.osx ];
    then
      echo "Removing existing stackbuilder.osx source directory"
      rm -rf stackbuilder.osx  || _die "Couldn't remove the existing stackbuilder.osx source directory (source/stackbuilder.osx)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -R stackbuilder stackbuilder.osx || _die "Failed to copy the source code (source/stackbuilder)"	
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"

}

################################################################################
# Build
################################################################################

_build_server_osx() {

    # First, build the server

    cd $WD/server/source/postgres.osx
    
    # Hack up gen_bki.sh so the bki files are generated correctly from our hacked pg_config.h.
    echo "Updating genbki.sh (WARNING: Not 64 bit safe!)..."
    echo ""
    _replace "pg_config.h" "pg_config_i386.h" src/backend/catalog/genbki.sh
    sleep 2
    
    # Configure the source tree
    echo "Configuring the postgres source tree for Intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-L/usr/local/lib" ./configure --host=i386-apple-darwin --prefix=$WD/server/staging/osx --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-includes=/usr/local/include/libxml2 --docdir=$WD/server/staging/osx/doc/postgresql || _die "Failed to configure postgres for i386"
    mv src/include/pg_config.h src/include/pg_config_i386.h

    echo "Configuring the postgres source tree for PPC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" LDFLAGS="-L/usr/local/lib" ./configure --host=powerpc-apple-darwin --prefix=$WD/server/staging/osx --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-includes=/usr/local/include/libxml2 --docdir=$WD/server/staging/osx/doc/postgresql || _die "Failed to configure postgres for PPC"
    mv src/include/pg_config.h src/include/pg_config_ppc.h

    echo "Configuring the postgres source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" LDFLAGS="-L/usr/local/lib" ./configure --prefix=$WD/server/staging/osx --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-includes=/usr/local/include/libxml2 --docdir=$WD/server/staging/osx/doc/postgresql || _die "Failed to configure postgres for Universal"

    # Create a replacement pg_config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > src/include/pg_config.h
    echo "#include \"pg_config_ppc.h\"" >> src/include/pg_config.h
    echo "#else" >> src/include/pg_config.h
    echo "#include \"pg_config_i386.h\"" >> src/include/pg_config.h
    echo "#endif" >> src/include/pg_config.h

    # Fixup the makefiles
    echo "Post-processing Makefiles for Universal Binary build"
    find . -name Makefile -print -exec perl -p -i.backup -e 's/\Q$(LD) $(LDREL) $(LDOUT)\E (\S+) (.+)/\$(LD) -arch ppc \$(LDREL) \$(LDOUT) $1.ppc $2; \$(LD) -arch i386 \$(LDREL) \$(LDOUT) $1.i386 $2; lipo -create -output $1 $1.ppc $1.i386/' {} \; || _die "Failed to post-process the postgres Makefiles for Universal build"

    echo "Building postgres"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" make || _die "Failed to build postgres" 
    make install || _die "Failed to install postgres"
    cp src/include/pg_config_i386.h $WD/server/staging/osx/include/
    cp src/include/pg_config_ppc.h $WD/server/staging/osx/include/

    echo "Building contrib modules"
    cd contrib
    make || _die "Failed to build the postgres contrib modules"
    make install || _die "Failed to install the postgres contrib modules"

    echo "Building contrib modules"
    cd pldebugger
    make || _die "Failed to build the debugger module"
    make install || _die "Failed to install the debugger module"
	if [ ! -e $WD/server/staging/osx/doc ];
	then
	    mkdir -p $WD/server/staging/osx/doc || _die "Failed to create the doc directory"
	fi
    cp README.pldebugger $WD/server/staging/osx/doc || _die "Failed to copy the debugger README into the staging directory"

    # Now, build pgAdmin

    cd $WD/server/source/pgadmin.osx

    # Bootstrap
    sh bootstrap

    # Configure
    ./configure --enable-appbundle --disable-dependency-tracking --with-pgsql=$WD/server/staging/osx --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug || _die "Failed to configure pgAdmin"

    # Build the app bundle
    make all || _die "Failed to build pgAdmin"
    make install || _die "Failed to install pgAdmin"

    # Move the utilties.ini file out of the way (Uncomment for Postgres Studio or pgAdmin 1.9+)
    # mv pgAdmin3.app/Contents/SharedSupport/plugins/utilities.ini pgAdmin3.app/Contents/SharedSupport/plugins/utilities.ini.new || _die "Failed to move the utilties.ini file"

    # Copy the app bundle into place
    cp -R pgAdmin3.app $WD/server/staging/osx || _die "Failed to copy pgAdmin into the staging directory"

    # And now, pl/java

    cd $WD/server/source/pljava.osx

    PATH=$PATH:$WD/server/staging/osx/bin make || _die "Failed to build pl/java" 
    PATH=$PATH:$WD/server/staging/osx/bin make prefix=$STAGING install || _die "Failed to install pl/java"

    mkdir -p "$WD/server/staging/osx/share/pljava" || _die "Failed to create the pl/java share directory"
    cp src/sql/install.sql "$WD/server/staging/osx/share/pljava/pljava.sql" || _die "Failed to install the pl/java installation SQL script"
    cp src/sql/uninstall.sql "$WD/server/staging/osx/share/pljava/uninstall_pljava.sql" || _die "Failed to install the pl/java uninstallation SQL script"

    mkdir -p "$WD/server/staging/osx/doc/pljava" || _die "Failed to create the pl/java doc directory"
    cp docs/* "$WD/server/staging/osx/doc/pljava/" || _die "Failed to install the pl/java documentation"
     
	# Stackbuilder
	
	cd $WD/server/source/stackbuilder.osx
	
	cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON .  || _die "Failed to configure StackBuilder"
	make all || _die "Failed to build StackBuilder"
	
	# Copy the StackBuilder app bundle into place
    cp -R stackbuilder.app $WD/server/staging/osx || _die "Failed to copy StackBuilder into the staging directory"	

    # Copy libxml2 as System's libxml can be old. 	
    cp /usr/local/lib/libxml2* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libxml2"	
	 
    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/server/staging/osx bin @loader_path/..
    _rewrite_so_refs $WD/server/staging/osx lib @loader_path/..
    _rewrite_so_refs $WD/server/staging/osx lib/postgresql @loader_path/../..
    _rewrite_so_refs $WD/server/staging/osx lib/postgresql/plugins @loader_path/../../..
	
    cd $WD 
}


################################################################################
# Post process
################################################################################

_postprocess_server_osx() {

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.gif" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/osx/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/osx
    cp -R bin doc include lib pgAdmin3.app share stackbuilder.app pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    zip -rq postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p staging/osx/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/preinstall.sh staging/osx/installer/server/preinstall.sh || _die "Failed to copy the preinstall script (scripts/osx/preinstall.sh)"
    chmod ugo+x staging/osx/installer/server/preinstall.sh
    cp scripts/osx/getlocales.sh staging/osx/installer/server/getlocales.sh || _die "Failed to copy the getlocales script (scripts/osx/getlocales.sh)"
    chmod ugo+x staging/osx/installer/server/getlocales.sh
    cp scripts/osx/createuser.sh staging/osx/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/osx/createuser.sh)"
    chmod ugo+x staging/osx/installer/server/createuser.sh
    cp scripts/osx/initcluster.sh staging/osx/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/osx/initcluster.sh)"
    chmod ugo+x staging/osx/installer/server/initcluster.sh
    cp scripts/osx/createshortcuts.sh staging/osx/installer/server/createshortcuts.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/server/createshortcuts.sh
    cp scripts/osx/startupcfg.sh staging/osx/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/server/startupcfg.sh
    cp scripts/osx/loadmodules.sh staging/osx/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/osx/loadmodules.sh)"
    chmod ugo+x staging/osx/installer/server/loadmodules.sh
    
    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/*.icns)"
    
    # Copy the launch scripts    
    cp scripts/osx/runpsql.sh staging/osx/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/osx/runpsql.sh)"
    chmod ugo+x staging/osx/scripts/runpsql.sh
    
    # Hack up the scripts, and compile them into the staging directory
    cp scripts/osx/doc-installationnotes.applescript.in staging/osx/scripts/doc-installationnotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-installationnotes.applescript.in)"
    cp scripts/osx/doc-postgresql.applescript.in staging/osx/scripts/doc-postgresql.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql.applescript.in)"
    cp scripts/osx/doc-postgresql-releasenotes.applescript.in staging/osx/scripts/doc-postgresql-releasenotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql-releasenotes.applescript.in)"
    cp scripts/osx/doc-pgadmin.applescript.in staging/osx/scripts/doc-pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pgadmin.applescript.in)"
    cp scripts/osx/doc-pljava.applescript.in staging/osx/scripts/doc-pljava.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava.applescript.in)"
    cp scripts/osx/doc-pljava-readme.applescript.in staging/osx/scripts/doc-pljava-readme.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava-readme.applescript.in)"

    cp scripts/osx/psql.applescript.in staging/osx/scripts/psql.applescript || _die "Failed to to the menu pick script (scripts/osx/psql.applescript.in)"
    cp scripts/osx/reload.applescript.in staging/osx/scripts/reload.applescript || _die "Failed to to the menu pick script (scripts/osx/reload.applescript.in)"
    cp scripts/osx/restart.applescript.in staging/osx/scripts/restart.applescript || _die "Failed to to the menu pick script (scripts/osx/restart.applescript.in)"
    cp scripts/osx/start.applescript.in staging/osx/scripts/start.applescript || _die "Failed to to the menu pick script (scripts/osx/start.applescript.in)"
    cp scripts/osx/stop.applescript.in staging/osx/scripts/stop.applescript || _die "Failed to to the menu pick script (scripts/osx/stop.applescript.in)"
    cp scripts/osx/pgadmin.applescript.in staging/osx/scripts/pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/pgadmin.applescript.in)"
    cp scripts/osx/stackbuilder.applescript.in staging/osx/scripts/stackbuilder.applescript || _die "Failed to to the menu pick script (scripts/osx/stackbuilder.applescript.in)"
	
    PG_DATETIME_SETTING_OSX=`cat staging/osx/include/pg_config_ppc.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_OSX" = "x" ]
    then
          PG_DATETIME_SETTING_OSX="floating-point numbers"
    else
          PG_DATETIME_SETTING_OSX="64-bit integers"
    fi

    _replace @@PG_DATETIME_SETTING_OSX@@ "$PG_DATETIME_SETTING_OSX" installer.xml || _die "Failed to replace the date-time setting in the installer.xml"

	
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app $WD/output/postgresql-$PG_PACKAGE_VERSION-osx.app || _die "Failed to rename the installer"
	
    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    if [ -d server.img ];
    then
        rm -rf server.img
    fi
    mkdir server.img || _die "Failed to create DMG staging directory"
    mv postgresql-$PG_PACKAGE_VERSION-osx.app server.img || _die "Failed to copy the installer bundle into the DMG staging directory"
    cp $WD/server/resources/README.osx server.img/README || _die "Failed to copy the installer README file into the DMG staging directory"
    hdiutil create -quiet -srcfolder server.img -format UDZO -volname "PostgreSQL $PG_PACKAGE_VERSION" -ov "postgresql-$PG_PACKAGE_VERSION-osx.dmg" || _die "Failed to create the disk image (output/postgresql-$PG_PACKAGE_VERSION-osx.dmg)"
    rm -rf server.img
    
    cd $WD
}


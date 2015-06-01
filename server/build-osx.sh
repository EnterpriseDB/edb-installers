#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_server_osx() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP Server OSX"

    echo "*******************************************************"
    echo " Pre Process : Server (OSX)"
    echo "*******************************************************"

    # Enter the source directory and cleanup if required
    cd $WD/server/source

    if [ -e postgres.osx ];
    then
      echo "Removing existing postgres.osx source directory"
      rm -rf postgres.osx  || _die "Couldn't remove the existing postgres.osx source directory (source/postgres.osx)"
    fi
    
    if [ -e postgres.tar.bz2 ];
    then
      echo "Removing existing postgres archive"
      rm -f postgres.tar.bz2  || _die "Couldn't remove the existing postgres archive (source/postgres.tar.bz2)"
    fi

    # Grab a copy of the postgres source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.osx || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"

    if [ -e pgadmin.osx ];
    then
      echo "Removing existing pgadmin.osx source directory"
      rm -rf pgadmin.osx  || _die "Couldn't remove the existing pgadmin.osx source directory (source/pgadmin.osx)"
    fi
    
    if [ -e pgadmin.tar.bz2 ];
    then
      echo "Removing existing pgadmin archive"
      rm -f pgadmin.tar.bz2  || _die "Couldn't remove the existing pgadmin archive (source/pgadmin.tar.bz2)"
    fi

    # Grab a copy of the pgadmin source tree
    cp -pR pgadmin3-$PG_TARBALL_PGADMIN pgadmin.osx || _die "Failed to copy the source code (source/pgadmin3-$PG_TARBALL_PGADMIN)"
    tar -jcvf pgadmin.tar.bz2 pgadmin.osx || _die "Failed to create the archive (source/pgadmin.tar.bz2)"

    if [ -e stackbuilder.osx ];
    then
      echo "Removing existing stackbuilder.osx source directory"
      rm -rf stackbuilder.osx  || _die "Couldn't remove the existing stackbuilder.osx source directory (source/stackbuilder.osx)"
    fi

    if [ -e stackbuilder.tar.bz2 ];
    then
      echo "Removing existing stackbuilder archive"
      rm -f stackbuilder.tar.bz2  || _die "Couldn't remove the existing stackbuilder archive (source/stackbuilder.tar.bz2)"
    fi
    # Grab a copy of the stackbuilder source tree
    cp -pR stackbuilder stackbuilder.osx || _die "Failed to copy the source code (source/stackbuilder)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    
    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"

    if [ -f $WD/server/scripts/osx/getlocales/getlocales.osx ]; then
      rm -f $WD/server/scripts/osx/getlocales/getlocales.osx
    fi

    echo "END PREP Server OSX"
}

################################################################################
# Build
################################################################################

_build_server_osx() {

    echo "BEGIN BUILD Server OSX"

    echo "*******************************************************"
    echo " Build : Server (OSX) "
    echo "*******************************************************"

    # First, build the server

    PG_STAGING=$PG_PATH_OSX/server/staging/osx

    cd $WD/server/source/postgres.osx

    if [ -f src/backend/catalog/genbki.sh ];
	then
      echo "Updating genbki.sh (WARNING: Not 64 bit safe!)..."
      echo ""
      _replace "pg_config.h" "pg_config_i386.h" src/backend/catalog/genbki.sh
    fi

    # Configure the source tree
    echo "Configuring the postgres source tree for Intel"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=i386-apple-darwin --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for i386"
    mv src/include/pg_config.h src/include/pg_config_i386.h

    echo "Configuring the postgres source tree for x86_64"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=x86_64-apple-darwin --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for x86_64"
    mv src/include/pg_config.h src/include/pg_config_x86_64.h

    echo "Configuring the postgres source tree for Universal"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for Universal"

    # Create a replacement pg_config.h that will pull in the appropriate architecture-specific one:
    rm -f src/include/pg_config.h
cat <<EOT > "src/include/pg_config.h"
#ifdef __BIG_ENDIAN__
 #error "Dont support ppc architecture"
#else
 #ifdef __LP64__
  #include "pg_config_x86_64.h"
 #else
  #include "pg_config_i386.h"
 #endif
#endif

EOT

    echo "Building postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; make install" || _die "Failed to install postgres"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; cp src/include/pg_config_i386.h $PG_STAGING/include/"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; cp src/include/pg_config_x86_64.h $PG_STAGING/include/"

    echo "Building contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building pldebugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the debugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; make install" || _die "Failed to install the debugger module"
    if [ ! -e $WD/server/staging/osx/doc ];
    then
        mkdir -p $WD/server/staging/osx/doc || _die "Failed to create the doc directory"
    fi
    cp $WD/server/source/postgres.osx/contrib/pldebugger/README.pldebugger $WD/server/staging/osx/doc || _die "Failed to copy the debugger README into the staging directory"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the uuid-ossp module" 
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/osx/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/osx/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $WD/server/staging/osx/share/man || _die "Failed to create the man directory"
    cd $WD/server/staging/osx/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (osx)"

    # Now, build pgAdmin

    cd $WD/server/source/pgadmin.osx

    # Configure
    echo "Configuring the pgAdmin source tree"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/pgadmin.osx; PATH=/opt/local/Current/bin:/opt/local/bin:$PATH CPPFLAGS='$PG_ARCH_OSX_CPPFLAGS' LDFLAGS='$PG_ARCH_OSX_LDFLAGS' ./configure --enable-appbundle --disable-dependency-tracking --with-pgsql=$PG_STAGING --with-wx=/opt/local/Current --with-libxml2=/opt/local/Current --with-libxslt=/opt/local/Current --disable-debug --disable-static  --with-sphinx-build=$PG_PYTHON_OSX/bin/sphinx-build" || _die "Failed to configure pgAdmin"

    # Build the app bundle
    echo "Building & installing pgAdmin"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/pgadmin.osx; PATH=/opt/local/Current/bin:$PATH make -j4 all" || _die "Failed to build pgAdmin"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/pgadmin.osx; PATH=/opt/local/Current/bin:$PATH make doc" || _die "Failed to build documentation for pgAdmin"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/pgadmin.osx; make install" || _die "Failed to install pgAdmin"

    # Copy the app bundle into place
    cp -pR pgAdmin3.app $WD/server/staging/osx || _die "Failed to copy pgAdmin into the staging directory"

    #Fix permission in the staging/osx/share
    chmod -R a+r $WD/server/staging/osx/share/postgresql/timezone/*

    # Stackbuilder
    cd $WD/server/source/stackbuilder.osx

    echo "Configuring the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; PATH=/opt/local/Current/bin:$PATH cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.6 -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=i386 ."  || _die "Failed to configure StackBuilder"
    echo "Building the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; make all" || _die "Failed to build StackBuilder"

    # Copy the StackBuilder app bundle into place
    cp -pR stackbuilder.app $WD/server/staging/osx || _die "Failed to copy StackBuilder into the staging directory"

    # Copy the third party headers
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/openssl $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/libxml2 $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/libxslt $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp /opt/local/Current/include/iconv.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp /opt/local/Current/include/zlib.h $PG_STAGING/include" || _die "Failed to copy the required header"
    # Removing third party GPL license headres
    ssh $PG_SSH_OSX "find $PG_STAGING/include -name '*.h' | xargs grep -rwl 'GNU General Public License\|GNU Library General Public' | grep -v 'gram.h' | xargs rm " || _die "Failed to remove GPL license headers."

    #cd $WD/server/staging/osx
    # Copy libxml2 as System's libxml can be old.
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libxml2*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libxml2"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libxslt*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libxslt"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libuuid*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libedit*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libedit"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libz*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libz"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libssl*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libssl"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libcrypto*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libcrypto"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libjpeg*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libjpeg"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libpng16*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libpng15"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libiconv*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libiconv"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libexpat*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libexpat"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libintl.*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libintl"

    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libwx_macu_adv-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libwx_macu_core-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libwx_base_carbonu-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libwx_base_carbonu_net-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libwx_base_carbonu_xml-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libuuid"

    # Copying plperl to staging/osx directory as we would not like to update the _rewrite_so_refs for it.
    cp -f $WD/server/staging/osx/lib/postgresql/plperl.so $WD/server/staging/osx/

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; source settings.sh; source common.sh; cd $PG_STAGING; _rewrite_so_refs $PG_STAGING bin @loader_path/..;\
        _rewrite_so_refs $PG_STAGING lib @loader_path/..; _rewrite_so_refs $PG_STAGING lib/postgresql @loader_path/../..;\
        _rewrite_so_refs $PG_STAGING lib/postgresql/plugins @loader_path/../../..;\
        _rewrite_so_refs $PG_STAGING stackbuilder.app/Contents/MacOS @loader_path/../../.."

    # Copying back plperl to staging/osx/lib/postgresql directory as we would not like to update the _rewrite_so_refs for it.
    mv -f $WD/server/staging/osx/plperl.so $WD/server/staging/osx/lib/postgresql/plperl.so

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/scripts/osx/getlocales; gcc -no-cpp-precomp $PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -o getlocales.osx -O0 getlocales.c"  || _die "Failed to build getlocales utility"

    # Delete the old regress dir from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/src/test/; rm -rf regress" || _die "Failed to remove the regression regress directory"

    # Copy the regress source to the regression setup 
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/src/test/; cp -pR regress /buildfarm/src/test/" || _die "Failed to Copy regress to the regression directory"

    cd $WD
    echo "END BUILD Server OSX"
}


################################################################################
# Post process
################################################################################

_postprocess_server_osx() {

    echo "BEGIN POST Server OSX"

    echo "*******************************************************"
    echo " Post Process : Server (OSX)"
    echo "*******************************************************"

    cd $WD/server

    pushd staging/osx
    generate_3rd_party_license "server"
    popd
    mv $WD/server/staging/osx/server_3rd_party_licenses.txt $WD/server/staging/osx/3rd_party_licenses.txt

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/osx/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/osx
    cp -pR bin doc include lib pgAdmin3.app share stackbuilder.app pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    zip -rq postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory"

    cd $WD/server

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/server || _die "Failed to create a directory for the install scripts"
    cp $WD/server/scripts/osx/getlocales/getlocales.osx $WD/server/staging/osx/installer/server/getlocales || _die "Failed to copy getlocales utility in the staging directory"
    chmod ugo+x staging/osx/installer/server/getlocales
    cp $WD/server/scripts/osx/prerun_checks.sh $WD/server/staging/osx/installer/server/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
    chmod ugo+x $WD/server/staging/osx/installer/server/prerun_checks.sh

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
#    cp scripts/osx/doc-pljava.applescript.in staging/osx/scripts/doc-pljava.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava.applescript.in)"
#    cp scripts/osx/doc-pljava-readme.applescript.in staging/osx/scripts/doc-pljava-readme.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pljava-readme.applescript.in)"

    cp scripts/osx/psql.applescript.in staging/osx/scripts/psql.applescript || _die "Failed to to the menu pick script (scripts/osx/psql.applescript.in)"
    cp scripts/osx/reload.applescript.in staging/osx/scripts/reload.applescript || _die "Failed to to the menu pick script (scripts/osx/reload.applescript.in)"
    cp scripts/osx/pgadmin.applescript.in staging/osx/scripts/pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/pgadmin.applescript.in)"
    cp scripts/osx/stackbuilder.applescript.in staging/osx/scripts/stackbuilder.applescript || _die "Failed to to the menu pick script (scripts/osx/stackbuilder.applescript.in)"

    PG_DATETIME_SETTING_OSX=`cat staging/osx/include/pg_config_i386.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_OSX" = "x" ]
    then
          PG_DATETIME_SETTING_OSX="floating-point numbers"
    else
          PG_DATETIME_SETTING_OSX="64-bit integers"
    fi
    
    # Set permissions to all files and folders in staging
    _set_permissions osx

    if [ -f installer-osx.xml ]; then
        rm -f installer-osx.xml
    fi
    cp installer.xml installer-osx.xml

    _replace @@PG_DATETIME_SETTING_OSX@@ "$PG_DATETIME_SETTING_OSX" installer-osx.xml || _die "Failed to replace the date-time setting in the installer.xml"
    _replace @@WIN64MODE@@ "0" installer-osx.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "" installer-osx.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"

    if [ -f installer_1.xml ]; then
      rm -f installer_1.xml
    fi
    cp installer-osx.xml installer_1.xml
    _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

    # Build the installer (for the root privileges required)
    echo Building the installer with the root privileges required
    "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"

    cp $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

    echo "Removing the installer previously generated installer"
    rm -rf $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app || _die "Failed to remove the installer ($WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app)"

    # Build the installer (for the root privileges not required)
    echo "Building the installer with the root privileges not required"
    "$PG_INSTALLBUILDER_BIN" build installer-osx.xml osx || _die "Failed to build the installer"

    # Use the risePrivileges utility created in the first installer
    cp $WD/scripts/risePrivileges $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL
    chmod a+x $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/PostgreSQL

    # Using own scripts for extract-only mode
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PostgreSQL $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app/Contents/MacOS/installbuilder.sh

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

    # sign the .app, create the DMG
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' --output ./server.img server.img/postgresql-$PG_PACKAGE_VERSION-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX/output/server.img; rm -rf postgresql-$PG_PACKAGE_VERSION-osx.app; mv postgresql-$PG_PACKAGE_VERSION-osx-signed.app postgresql-$PG_PACKAGE_VERSION-osx.app;" || _die "could not move the signed app"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; hdiutil create -quiet -anyowners -srcfolder server.img -format UDZO -volname 'PostgreSQL $PG_PACKAGE_VERSION' -ov 'postgresql-$PG_PACKAGE_VERSION-osx.dmg'" || _die "Failed to create the disk image (postgresql-$PG_PACKAGE_VERSION-osx.dmg)"

    echo "Attach the  disk image, create zip and then detach the image"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; hdid postgresql-$PG_PACKAGE_VERSION-osx.dmg" || _die "Failed to open the disk image (postgresql-$PG_PACKAGE_VERSION-osx.dmg in remote host.)"

    ssh $PG_SSH_OSX "cd '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'; zip -r $PG_PATH_OSX/output/postgresql-$PG_PACKAGE_VERSION-osx.zip postgresql-$PG_PACKAGE_VERSION-osx.app" || _die "Failed to create the installer zip file (postgresql-$PG_PACKAGE_VERSION-osx.zip) in remote host."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; sleep 2; echo 'Detaching /Volumes/PostgreSQL $PG_PACKAGE_VERSION...' ; hdiutil detach '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'" || _die "Failed to detach the /Volumes/PostgreSQL $PG_PACKAGE_VERSION in remote host."

     # Delete the old installer from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/installers; rm -rf postgresql-*.dmg" || _die "Failed to remove the installer from regression installer directory"

    # Copy the installer to regression setup
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output cp -p postgresql-*.dmg /buildfarm/installers/" || _die "Failed to Copy installer to the regression directory"

    cd $WD
    echo "END POST Server OSX"
}


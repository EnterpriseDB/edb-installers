#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_server_osx() {

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

    # Grab a copy of the postgres source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.osx || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"

    if [ -e pgadmin.osx ];
    then
      echo "Removing existing pgadmin.osx source directory"
      rm -rf pgadmin.osx  || _die "Couldn't remove the existing pgadmin.osx source directory (source/pgadmin.osx)"
    fi

    # Grab a copy of the pgadmin source tree
    cp -pR pgadmin3-$PG_TARBALL_PGADMIN pgadmin.osx || _die "Failed to copy the source code (source/pgadmin3-$PG_TARBALL_PGADMIN)"

    if [ -e stackbuilder.osx ];
    then
      echo "Removing existing stackbuilder.osx source directory"
      rm -rf stackbuilder.osx  || _die "Couldn't remove the existing stackbuilder.osx source directory (source/stackbuilder.osx)"
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

}

################################################################################
# Build
################################################################################

_build_server_osx() {

    echo "*******************************************************"
    echo " Build : Server (OSX) "
    echo "*******************************************************"

    # First, build the server

    cd $WD/server/source/postgres.osx

    if [ -f src/backend/catalog/genbki.sh ];
	then
      echo "Updating genbki.sh (WARNING: Not 64 bit safe!)..."
      echo ""
      _replace "pg_config.h" "pg_config_i386.h" src/backend/catalog/genbki.sh
    fi

    # Configure the source tree
    echo "Configuring the postgres source tree for Intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=i386-apple-darwin --prefix=$WD/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$WD/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for i386"
    mv src/include/pg_config.h src/include/pg_config_i386.h

    echo "Configuring the postgres source tree for x86_64"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=x86_64-apple-darwin --prefix=$WD/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$WD/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for PPC"
    mv src/include/pg_config.h src/include/pg_config_x86_64.h

    echo "Configuring the postgres source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" LDFLAGS="-L/usr/local/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --prefix=$WD/server/staging/osx --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --with-includes=/usr/local/include/libxml2:/usr/local/include:/usr/local/include/security --docdir=$WD/server/staging/osx/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi || _die "Failed to configure postgres for Universal"

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
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build postgres"
    make install || _die "Failed to install postgres"

    cp src/include/pg_config_i386.h $WD/server/staging/osx/include/
    cp src/include/pg_config_x86_64.h $WD/server/staging/osx/include/

    cd $WD/server/source/postgres.osx

    echo "Building contrib modules"
    cd contrib
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the postgres contrib modules"
    make install || _die "Failed to install the postgres contrib modules"

    echo "Building pldebugger module"
    cd pldebugger
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the debugger module"
    make install || _die "Failed to install the debugger module"
    if [ ! -e $WD/server/staging/osx/doc ];
    then
        mkdir -p $WD/server/staging/osx/doc || _die "Failed to create the doc directory"
    fi
    cp README.pldebugger $WD/server/staging/osx/doc || _die "Failed to copy the debugger README into the staging directory"

    cd ../uuid-ossp
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64" make -j4 || _die "Failed to build the uuid-ossp module"
    make install || _die "Failed to install the uuid-ossp module"

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

    # Bootstrap
    PATH=/opt/local/bin:$PATH sh bootstrap

    # Configure
    CPPFLAGS="$PG_ARCH_OSX_CPPFLAGS" LDFLAGS="$PG_ARCH_OSX_LDFLAGS" ./configure --enable-appbundle --disable-dependency-tracking --with-pgsql=$WD/server/staging/osx --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static  --with-sphinx-build=$PG_PYTHON_OSX/bin/sphinx-build || _die "Failed to configure pgAdmin"

    # Build the app bundle
    make -j4 all || _die "Failed to build pgAdmin"
    make doc || _die "Failed to build documentation for pgAdmin"
    make install || _die "Failed to install pgAdmin"

    # Copy the app bundle into place
    cp -pR pgAdmin3.app $WD/server/staging/osx || _die "Failed to copy pgAdmin into the staging directory"

    #Fix permission in the staging/osx/share
    chmod -R a+r $WD/server/staging/osx/share/postgresql/timezone/*

    # Stackbuilder

    cd $WD/server/source/stackbuilder.osx

    cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.6 -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=i386 .  || _die "Failed to configure StackBuilder"
    make all || _die "Failed to build StackBuilder"

    # Copy the StackBuilder app bundle into place
    cp -pR stackbuilder.app $WD/server/staging/osx || _die "Failed to copy StackBuilder into the staging directory"

    cd $WD/server/staging/osx
    # Copy libxml2 as System's libxml can be old.
    cp -pR /usr/local/lib/libxml2* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libxml2"
    cp -pR /usr/local/lib/libxslt.* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libxslt"
    cp -pR /usr/local/lib/libuuid* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libedit* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libedit"
    cp -pR /usr/local/lib/libz* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libz"
    cp -pR /usr/local/lib/libssl* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libssl"
    cp -pR /usr/local/lib/libcrypto* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libcrypto"
    cp -pR /usr/local/lib/libjpeg* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libjpeg"
    cp -pR /usr/local/lib/libpng15* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libpng15"
    cp -pR /usr/local/lib/libiconv* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libiconv"
    cp -pR /usr/local/lib/libexpat* $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libexpat"

    cp -pR /usr/local/lib/libwx_macu_adv-*.dylib $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_macu_core-*.dylib $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu-*.dylib $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu_net-*.dylib $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"
    cp -pR /usr/local/lib/libwx_base_carbonu_xml-*.dylib $WD/server/staging/osx/lib/ || _die "Failed to copy the latest libuuid"

    # Copying plperl to staging/osx directory as we would not like to update the _rewrite_so_refs for it.
    cp -f $WD/server/staging/osx/lib/postgresql/plperl.so $WD/server/staging/osx/

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/server/staging/osx bin @loader_path/..
    _rewrite_so_refs $WD/server/staging/osx lib @loader_path/..
    _rewrite_so_refs $WD/server/staging/osx lib/postgresql @loader_path/../..
    _rewrite_so_refs $WD/server/staging/osx lib/postgresql/plugins @loader_path/../../..
    _rewrite_so_refs $WD/server/staging/osx stackbuilder.app/Contents/MacOS @loader_path/../../..

    # Copying back plperl to staging/osx/lib/postgresql directory as we would not like to update the _rewrite_so_refs for it.
    mv -f $WD/server/staging/osx/plperl.so $WD/server/staging/osx/lib/postgresql/plperl.so

    cd $WD/server/scripts/osx/getlocales/; gcc -no-cpp-precomp $PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -o getlocales.osx -O0 getlocales.c  || _die "Failed to build getlocales utility"

    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_osx() {

    echo "*******************************************************"
    echo " Post Process : Server (OSX)"
    echo "*******************************************************"

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.gif" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome logo"

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
    cp scripts/osx/preinstall.sh staging/osx/installer/server/preinstall.sh || _die "Failed to copy the preinstall script (scripts/osx/preinstall.sh)"
    chmod ugo+x staging/osx/installer/server/preinstall.sh
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
    hdiutil create -quiet -srcfolder server.img -format UDZO -volname "PostgreSQL $PG_PACKAGE_VERSION" -ov "postgresql-$PG_PACKAGE_VERSION-osx.dmg" || _die "Failed to create the disk image (output/postgresql-$PG_PACKAGE_VERSION-osx.dmg)"
    rm -rf server.img

    cd $WD
}


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
    tar -jcvf postgres.tar.bz2 postgres.osx || _die "Failed to create the archive (source/postgres.tar.bz2)"

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
    cp -pR pgadmin4-$PG_TARBALL_PGADMIN pgadmin.osx || _die "Failed to copy the source code (source/pgadmin4-$PG_TARBALL_PGADMIN)"
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
    tar -jcvf stackbuilder.tar.bz2 stackbuilder.osx || _die "Failed to create the archive (source/stackbuilder.tar.bz2)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    
    echo "Cleaning the directories/files in remote server directory"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/source" || _die "Falied to clean the server/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/scripts" || _die "Falied to clean the server/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/resources" || _die "Falied to clean the server/resources directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/*.bz2" || _die "Falied to clean the server/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/*.sh" || _die "Falied to clean the server/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/staging/osx.build" || _die "Falied to clean the server directory on Mac OS X VM"

    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"

    if [ -f $WD/server/scripts/osx/getlocales/getlocales.osx ]; then
      rm -f $WD/server/scripts/osx/getlocales/getlocales.osx
    fi

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source" || _die "Failed to create the source dircetory on the build VM"
    scp postgres.tar.bz2 pgadmin.tar.bz2 stackbuilder.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/server
    tar -jcvf scripts.tar.bz2 scripts/osx resources/complete-bundle.sh
    scp $WD/server/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"
    rm -f scripts.tar.bz2 || _die "Couldn't remove the scipts archive (source/scripts.tar.bz2)"    

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf postgres.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf pgadmin.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source; tar -jxvf stackbuilder.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server; tar -jxvf scripts.tar.bz2"

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
    PG_STAGING=$PG_PATH_OSX/server/staging/osx.build

    cd $WD/server/source/postgres.osx

    if [ -f src/backend/catalog/genbki.sh ];
	then
      echo "Updating genbki.sh (WARNING: Not 64 bit safe!)..."
      echo ""
      ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx; source $PG_PATH_OSX/common.sh; _replace 'pg_config.h' 'pg_config_i386.h' src/backend/catalog/genbki.sh"
    fi

    # Configure the source tree
    echo "Configuring the postgres source tree for Intel"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -O2' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=i386-apple-darwin --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for i386"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx; mv src/include/pg_config.h src/include/pg_config_i386.h"

    echo "Configuring the postgres source tree for x86_64"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64 -O2' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --host=x86_64-apple-darwin --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for x86_64"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx; mv src/include/pg_config.h src/include/pg_config_x86_64.h"

    echo "Configuring the postgres source tree for Universal"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -O2' LDFLAGS="-L/opt/local/Current/lib" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl ./configure --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for Universal"

    # Create a replacement pg_config.h that will pull in the appropriate architecture-specific one:
cat <<EOT > "/tmp/pg_config.h"
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
   
    ssh $PG_SSH_OSX "rm -f $PG_PATH_OSX/server/source/postgres.osx/src/include/pg_config.h" || _die "Failed to remove pg_config.h"
    scp /tmp/pg_config.h $PG_SSH_OSX:$PG_PATH_OSX/server/source/postgres.osx/src/include/
    rm -f /tmp/pg_config.h

    echo "Building postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -O2' make -j4" || _die "Failed to build postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; make install" || _die "Failed to install postgres"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; cp src/include/pg_config_i386.h $PG_STAGING/include/"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; cp src/include/pg_config_x86_64.h $PG_STAGING/include/"

    echo "Building contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building pldebugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the debugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; make install" || _die "Failed to install the debugger module"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64' make -j4" || _die "Failed to build the uuid-ossp module" 
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"

    # Now, build pgAdmin

    #cd $WD/server/source/pgadmin.osx

    # Configure
    echo "Configuring the pgAdmin source tree"
cat <<EOT-PGADMIN > $WD/server/build-pgadmin.sh
    source ../versions.sh
    source ../common.sh
    PATH=$PG_STAGING/bin:/usr/local/bin:\$PATH
    LD_LIBRARY_PATH=$PG_STAGING/lib:\$LD_LIBRARY_PATH
    # Set PYTHON_VERSION variable required for pgadmin build
    export PGADMIN_PYTHON_DIR=$PGADMIN_PYTHON_OSX
    export LD_LIBRARY_PATH=\$PGADMIN_PYTHON_DIR/lib:\$LD_LIBRARY_PATH
    # Check if Python is working and calculate PYTHON_VERSION
    if \$PGADMIN_PYTHON_DIR/bin/python3 -V > /dev/null 2>&1; then
        export PYTHON_VERSION=\`\$PGADMIN_PYTHON_DIR/bin/python3 -V 2>&1 | awk '{print \$2}' | cut -d"." -f1-2\`
    else
        echo "Error: Python installation missing!"
        exit 1
    fi
    export PYTHON=\$PGADMIN_PYTHON_DIR/bin/python3
    export PIP=pip3
    SOURCEDIR=$PG_PATH_OSX/server/source/pgadmin.osx
    BUILDROOT=$PG_PATH_OSX/server/source/pgadmin.osx/mac-build
    test -d \$BUILDROOT || mkdir \$BUILDROOT
    cd \$BUILDROOT
    mkdir -p venv/lib
    cp -pR \$PGADMIN_PYTHON_DIR/lib/lib*.dylib* venv/lib/

    #Install virtualenv if not present in python installation to create venv
    if [ ! -f \$PGADMIN_PYTHON_DIR/bin/virtualenv ]; then
        echo "Installing virtualenv..."
        \$PGADMIN_PYTHON_DIR/bin/\$PIP install virtualenv
        export UNINSTALL_VIRTUALENV=1
    fi
    \$PGADMIN_PYTHON_DIR/bin/virtualenv --always-copy -p \$PYTHON venv || _die "Failed to create venv"
    mkdir -p venv/lib/python\$PYTHON_VERSION/lib-dynload/
    cp -f \$PGADMIN_PYTHON_DIR/lib/python\$PYTHON_VERSION/lib-dynload/*.so venv/lib/python\$PYTHON_VERSION/lib-dynload/
    source venv/bin/activate
    #cryptography needs to be compiled against the custom OpenSSL 1.1.1
    LDFLAGS="-L/opt/local/Current/lib" CFLAGS="-I/opt/local/Current/include" \$PIP --no-cache-dir install cryptography || _die "PIP install cryptography failed"
     # To resolve the PyNacl (Required by sshtunnel) installation issue. 
     # This issues occurred due to the older version of /usr/bin/clang which is 4.1. 
     # So we have to export /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang version 5.1
     export CC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
    \$PIP --no-cache-dir install -r \$SOURCEDIR/\requirements.txt || _die "PIP install failed"
    rsync -zrva --exclude site-packages --exclude lib2to3 --include="*.py" --include="*/" --exclude="*" \$PGADMIN_PYTHON_DIR/lib/python\$PYTHON_VERSION/* venv/lib/python\$PYTHON_VERSION/

    # Move the python<version> directory to python so that the private environment path is found by the application.
    export PYMODULES_PATH=\`python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"\`
    export DIR_PYMODULES_PATH=\`dirname \$PYMODULES_PATH\`
    if test -d \$DIR_PYMODULES_PATH; then
        cd \$DIR_PYMODULES_PATH/..
        ln -s python\$PYTHON_VERSION python
    fi

    # Build runtime
    cd \$BUILDROOT/../runtime
    #python3.8-config --libs output doesn't include -lpython3.8. Hence, add that in the ldflags
    # Also set PYTHON_CONFIG to python3 as the default python-config is python2
    PYTHON_CONFIG="\$PGADMIN_PYTHON_DIR/bin/python\$PYTHON_VERSION-config" PGADMIN_LDFLAGS="-L\$PGADMIN_PYTHON_DIR/lib -lpython\$PYTHON_VERSION" $PG_QMAKE_OSX || _die "qmake failed"
    make || _die "pgadmin runtime build failed"

    # Copy the generated app bundle to buildroot and rename the bundle as required
    cp -r pgAdmin4.app "\$BUILDROOT/$APP_BUNDLE_NAME"

    # Build docs
    \$PIP install Sphinx || _die "PIP Sphinx failed"
    cd $PG_PATH_OSX/server/source/pgadmin.osx/docs/en_US
    LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 make -f Makefile.sphinx html || exit 1
    
    # Uninstall as it is not required to bundle Sphinx
    \$PIP uninstall --yes Sphinx
    
    # Copy docs
    test -d "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources" || "mkdir -p \$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources"
    test -d "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/docs/en_US" || mkdir -p "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/docs/en_US"
    cp -r _build/html "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/docs/en_US/" || exit 1
   
    cd $PG_PATH_OSX/server/source/pgadmin.osx/pkg/mac
   
    # Replace the place holders with the current version
    sed -e "s/PGADMIN_LONG_VERSION/$APP_LONG_VERSION/g" -e "s/PGADMIN_SHORT_VERSION/$APP_SHORT_VERSION/g" pgadmin.Info.plist.in > pgadmin.Info.plist

    # copy Python private environment to app bundle
    cp -pR \$BUILDROOT/venv "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/" || exit 1

    # remove the unwanted files from the virtual environment
    rm -rf "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv/.Python" "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv/include"
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv/bin"
    find . \( -name "*.py" \) -delete
    rm -rf __pycache__
    cd $PG_PATH_OSX/server/resources/
    # run complete-bundle to copy the dependent libraries and frameworks and fix the rpaths
    PGDIR=$PG_PATH_OSX/server/staging/osx.build QTDIR="`dirname $PG_QMAKE_OSX`/.." sh ./complete-bundle.sh "\$BUILDROOT/$APP_BUNDLE_NAME" || _die "complete-bundle.sh failed"

    # copy the web directory to the bundle as it is required by runtime
    cp -r $PG_PATH_OSX/server/source/pgadmin.osx/web "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/"
    mkdir -p "\$BUILDROOT/pgAdmin 4.app/Contents/Resources/venv/bin"
    cp "\$BUILDROOT/venv/bin/python" "\$BUILDROOT/pgAdmin 4.app/Contents/Resources/venv/bin"

    # Removing the unwanted files and directories from the pgAdmin4 staging
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv"
    find . \( -name test -o -name tests \) -type d | xargs rm -rf
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/web"
    find . \( -name tests -o -name feature_tests \) -type d | xargs rm -rf
    rm -rf regression
    rm -f pgadmin4.db config_local.*
     # Create config_distro
    echo "SERVER_MODE = False" > config_distro.py
    echo "HELP_PATH = '../../../docs/en_US/html/'" >> config_distro.py
    echo "UPGRADE_CHECK_KEY = 'edb-pgadmin4'" >> config_distro.py

    # Remove the .pyc files if any
    cd "\$BUILDROOT/$APP_BUNDLE_NAME"
    find . \( -name "*.pyc" -o -name "*.pyo" \) -delete
    
    # Copy the app bundle into place
    cp -pR "\$BUILDROOT/$APP_BUNDLE_NAME" $PG_PATH_OSX/server/staging/osx.build || _die "Failed to copy pgAdmin into the staging directory"
EOT-PGADMIN

    cd $WD
    chmod 755 $WD/server/build-pgadmin.sh
    scp server/build-pgadmin.sh $PG_SSH_OSX:$PG_PATH_OSX/server
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server; sh -x ./build-pgadmin.sh" || _die "Failed to build pgadmin on OSX"

    #Fix permission in the staging/osx/share
    ssh $PG_SSH_OSX "chmod -R a+r $PG_PATH_OSX/server/staging/osx.build/share/postgresql/timezone/*"

    # Stackbuilder
    #cd $WD/server/source/stackbuilder.osx

    echo "Configuring the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; PATH=/opt/local/Current/bin:$PATH cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.6 -D CURL_ROOT:PATH=/opt/local/Current -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/wxWidgets-30/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D WX_VERSION=3.0 -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=x86_64 ."  || _die "Failed to configure StackBuilder"
    echo "Building the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source/stackbuilder.osx/stackbuilder.app/Contents/Resources/certs" || _die "Failed to create certs directory"
    ssh $PG_SSH_OSX "cp /opt/local/Current/certs/ca-bundle.crt $PG_PATH_OSX/server/source/stackbuilder.osx/stackbuilder.app/Contents/Resources/certs/ " || _die "Failed to copy certs bundle"

    # Copy the StackBuilder app bundle into place
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; cp -pR stackbuilder.app $PG_PATH_OSX/server/staging/osx.build" || _die "Failed to copy StackBuilder into the staging directory"

    # Copy the third party headers
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/openssl $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/libxml2 $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp -r /opt/local/Current/include/libxslt $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp /opt/local/Current/include/iconv.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_OSX "cp /opt/local/Current/include/zlib.h $PG_STAGING/include" || _die "Failed to copy the required header"

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
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libcurl*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libcurl"

    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_xrc-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_webview-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_html-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_qa-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_adv-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_core-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu_xml-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu_net-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu-*.dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libwx"

    # Copying plperl to staging/osx directory as we would not like to update the _rewrite_so_refs for it.
    ssh $PG_SSH_OSX "cp -f $PG_PATH_OSX/server/staging/osx.build/lib/postgresql/plperl.so $PG_PATH_OSX/server/staging/osx.build/"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    echo "Rewrite shared library references"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; source settings.sh; source common.sh; cd $PG_STAGING; _rewrite_so_refs $PG_STAGING bin @loader_path/..;\
        _rewrite_so_refs $PG_STAGING lib @loader_path/..; _rewrite_so_refs $PG_STAGING lib/postgresql @loader_path/../..;\
        _rewrite_so_refs $PG_STAGING lib/postgresql/plugins @loader_path/../../..;\
        _rewrite_so_refs $PG_STAGING stackbuilder.app/Contents/MacOS @loader_path/../../.."

    echo "Some specific rewriting of shared library references"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change $PG_STAGING/lib/libpq.5.dylib @loader_path/../../../../../../Frameworks/libpq.5.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libpq"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20200101/lib/libssl.1.1.dylib @loader_path/../../../../../../Frameworks/libssl.1.1.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libssl"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20200101/lib/libcrypto.1.1.dylib @loader_path/../../../../../../Frameworks/libcrypto.1.1.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libcrypto"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20200101/lib/libssl.1.1.dylib @loader_path/../../../../../../../../Frameworks/libssl.1.1.dylib Contents/Resources/venv/lib/python/site-packages/cryptography/hazmat/bindings/_openssl.abi3.so" || _die "install_name_tool change failed for libssl"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20200101/lib/libcrypto.1.1.dylib @loader_path/../../../../../../../../Frameworks/libcrypto.1.1.dylib Contents/Resources/venv/lib/python/site-packages/cryptography/hazmat/bindings/_openssl.abi3.so" || _die "install_name_tool change failed for libcrypto"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -id libpq.5.dylib Contents/Frameworks/libpq.5.dylib" || _die "install_name_tool id failed for libpq"

    # Copying back plperl to staging/osx/lib/postgresql directory as we would not like to update the _rewrite_so_refs for it.
     ssh $PG_SSH_OSX "mv -f $PG_PATH_OSX/server/staging/osx.build/plperl.so $PG_PATH_OSX/server/staging/osx.build/lib/postgresql/plperl.so"

    # Changing loader path of plpython3.so
     ssh $PG_SSH_OSX "install_name_tool -change libpython$PG_VERSION_PYTHON\m.dylib $PG_PYTHON_OSX/lib/libpython$PG_VERSION_PYTHON\m.dylib $PG_PATH_OSX/server/staging/osx.build/lib/postgresql/plpython3.so"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/scripts/osx/getlocales; gcc -no-cpp-precomp $PG_ARCH_OSX_CFLAGS -arch i386 -arch x86_64 -o getlocales.osx -O0 getlocales.c"  || _die "Failed to build getlocales utility"

    # Delete the old regress dir from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/src/test/; rm -rf regress" || _die "Failed to remove the regression regress directory"

    # Copy the regress source to the regression setup 
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/src/test/; cp -pR regress /buildfarm/src/test/" || _die "Failed to Copy regress to the regression directory"

    echo "Removing last successful staging directory ($PG_PATH_OSX/server/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR server/staging/osx.build/* server/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_MAJOR_VERSION=$PG_MAJOR_VERSION > $PG_PATH_OSX/server/staging/osx/versions-osx.sh" || _die "Failed to write server version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_MINOR_VERSION=$PG_MINOR_VERSION >> $PG_PATH_OSX/server/staging/osx/versions-osx.sh" || _die "Failed to write server build number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_PACKAGE_VERSION=$PG_PACKAGE_VERSION >> $PG_PATH_OSX/server/staging/osx/versions-osx.sh" || _die "Failed to write server build number into versions-osx.sh"

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

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"
    mkdir -p $WD/server/staging/osx/doc/postgresql/html || _die "Failed to create the doc directory"
    mkdir -p $WD/server/staging/osx/share/man || _die "Failed to create the man directory"
    mkdir -p $WD/server/scripts/osx/getlocales || _die "Failed to create the getlocales directory"

    cp $WD/server/source/postgres.osx/contrib/pldebugger/README.pldebugger $WD/server/staging/osx/doc || _die "Failed to copy the debugger README into the staging directory"

    # Install the PostgreSQL docs
    cd $WD/server/staging/osx/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    cd $WD/server/staging/osx/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (osx)"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/staging/osx; rm -f server-staging.tar.bz2" || _die "Failed to remove archive of the server staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/staging/osx; tar -jcvf server-staging.tar.bz2 *" || _die "Failed to create archive of the server staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/server/staging/osx/server-staging.tar.bz2 $WD/server/staging/osx || _die "Failed to scp server staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/server/scripts/osx/getlocales/getlocales.osx $WD/server/scripts/osx/getlocales/ || _die "Failed to scp getlocales.osx"

    # sign the getlocales binary
    scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
    scp $WD/server/scripts/osx/getlocales/getlocales.osx $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy getlocales binary to  signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --deep -f -i 'com.edb.postgresql' -s 'Developer ID Application' --options runtime getlocales.osx" || _die "Failed to sign the getlocales binary"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/getlocales.osx $WD/server/scripts/osx/getlocales/ || _die "Failed to copy getlocales binary to controller"

    # sign the binaries and libraries
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf server-staging.tar.bz2" || _die "Failed to remove server-staging.tar from signing server"
    scp $WD/server/staging/osx/server-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy server-staging.tar.bz2 on signing server"
    rm -rf $WD/server/staging/osx/server-staging.tar.bz2 || _die "Failed to remove server-staging.tar from controller"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../server-staging.tar.bz2; mv pgAdmin\ 4.app pgAdmin4.app"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging" || _die "Failed to do libraries signing"
    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging/lib entitlements-server.xml" || _die "Failed to do libraries signing with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_bundles staging" || _die "Failed to sign bundle"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_bundles staging/lib/postgresql entitlements-server.xml" || _die "Failed to sign bundle with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging" || _die "Failed to do binaries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging/bin entitlements-server.xml" || _die "Failed to do binaries signing with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging; mv pgAdmin4.app pgAdmin\ 4.app; tar -jcvf server-staging.tar.bz2 *" || _die "Failed to create server-staging tar on signing server"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/server-staging.tar.bz2 $WD/server/staging/osx || _die "Failed to copy server-staging to controller vm"

    # Extract the staging archive
    cd $WD/server/staging/osx
    tar -jxvf server-staging.tar.bz2 || _die "Failed to extract the server staging archive"
    rm -f server-staging.tar.bz2

    source $WD/server/staging/osx/versions-osx.sh
    PG_BUILD_SERVER=$(expr $PG_BUILD_SERVER + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SERVER -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Copy the required Python executables
    scp $PG_SSH_OSX:$PGADMIN_PYTHON_OSX/Python $WD/server/staging/osx/pgAdmin\ 4.app/Contents/Resources/venv/.Python

    cd $WD/server

    pushd staging/osx
    generate_3rd_party_license "server"
    popd

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/osx/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/osx/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/osx
    cp -pR bin doc include lib pgAdmin*.app share stackbuilder.app pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    zip -yrq postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

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
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app

    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    # Clean existing source image directory if any
    rm -rf server.img*
    mkdir server.img || _die "Failed to create DMG staging directory"
    mv postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app server.img || _die "Failed to copy the installer bundle into the DMG staging directory"
   
    tar -jcvf server.img.tar.bz2 server.img || _die "Failed to create the archive."
    # Clean up the output directory on signing server before copying the image
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf server.img*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp server.img.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output || _die "Failed to copy the archive to sign server."

    # Copy the versions file to signing server 
    scp ../versions.sh ../resources/entitlements-server.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # sign the .app, create the DMG
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh;  tar -jxvf server.img.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain;codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements-server.xml server.img/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"

    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output/server.img; rm -rf postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app; mv postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx-signed.app postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv server.img/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; tar -jcvf server.img.tar.bz2 server.img;" || _die "faled to create server.img.tar.bz2 on $PG_SSH_OSX_SIGN"
    # Remove the existing source image archive before copying the signed image
    rm server.img.tar.bz2 || _die "Failed to remove the server.img"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/server.img.tar.bz2 $WD/output || _die "faled to copy server.img.tar.bz2 to $WD/output"

    # Cleanup the output directory on build machine before copying the image archive
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; rm -rf postgresql* server* " || _die "Failed to clean the remote output directory"
    scp server.img.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/output || _die "faled to copy server.img.tar.bz2 to $PG_PATH_OSX/output"
    rm -rf server.img* || _die "Failed to remove server.img from output directory."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; tar -jxvf server.img.tar.bz2; touch server.img/.Trash; hdiutil create -quiet -anyowners -srcfolder server.img -format UDZO -volname 'PostgreSQL $PG_PACKAGE_VERSION' -ov 'postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg'" || _die "Failed to create the disk image (postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg)"

    echo "Attach the  disk image, create zip and then detach the image"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; hdiutil detach '/Volumes/PostgreSQL $PG_PACKAGE_VERSION* -force'; hdid postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg" || _die "Failed to open the disk image (postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg in remote host.)"

    ssh $PG_SSH_OSX "cd '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'; zip -r $PG_PATH_OSX/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app" || _die "Failed to create the installer zip file (postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip) in remote host."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; sleep 2; echo 'Detaching /Volumes/PostgreSQL $PG_PACKAGE_VERSION...' ; hdiutil detach '/Volumes/PostgreSQL $PG_PACKAGE_VERSION'" || _die "Failed to detach the /Volumes/PostgreSQL $PG_PACKAGE_VERSION in remote host."

    scp $PG_SSH_OSX:$PG_PATH_OSX/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.* $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf postgresql-*.dmg postgresql-*.zip" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg postgresql" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip postgresql" || _die "Failed to notarize the app"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg $WD/output || _die "Failed to copy notarized installer to $WD/output."
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

     # Delete the old installer from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/installers; rm -rf postgresql-*.dmg" || _die "Failed to remove the installer from regression installer directory"

    # Copy the installer to regression setup
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; cp -p postgresql-*.dmg /buildfarm/installers/" || _die "Failed to Copy installer to the regression directory"

    cd $WD
    echo "END POST Server OSX"
}


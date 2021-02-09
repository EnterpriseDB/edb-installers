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

    # Remove any existing staging_cache directory that might exist, and create a clean one
    if [ -e $WD/server/staging_cache/osx ];
    then
      echo "Removing existing staging_cache directory"
      rm -rf $WD/server/staging_cache/osx || _die "Couldn't remove the existing staging_cache directory"
    fi

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    
    echo "Cleaning the files in remote server directory"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/source" || _die "Falied to clean the server/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/scripts" || _die "Falied to clean the server/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/resources" || _die "Falied to clean the server/resources directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/*.bz2" || _die "Falied to clean the server/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/*.sh" || _die "Falied to clean the server/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/staging_cache/osx.build" || _die "Falied to clean the server directory on Mac OS X VM"

    echo "Creating staging_cache directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging_cache/osx || _die "Couldn't create the staging_cache directory"

    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $PGSERVER_STAGING_OSX || _die "Couldn't create the staging directory $PGSERVER_STAGING_OSX"
    mkdir -p $PGADMIN_STAGING_OSX || _die "Couldn't create the staging directory $PGADMIN_STAGING_OSX"
    mkdir -p $SB_STAGING_OSX || _die "Couldn't create the staging directory $SB_STAGING_OSX"
    mkdir -p $CLT_STAGING_OSX || _die "Couldn't create the staging directory $CLT_STAGING_OSX"

    if [ -f $WD/server/scripts/osx/getlocales/getlocales.osx ]; then
      rm -f $WD/server/scripts/osx/getlocales/getlocales.osx
    fi

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source" || _die "Failed to create the source dircetory on the build VM"
    scp postgres.tar.bz2 pgadmin.tar.bz2 stackbuilder.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/server
    tar -jcvf scripts.tar.bz2 scripts/osx resources/complete-bundle.sh resources/framework-config.sh resources/Info.plist-template_Qt5
    scp $WD/server/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/server || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $WD/resources/create_debug_symbols.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"
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
    PG_STAGING=$PG_PATH_OSX/server/staging_cache/osx.build

    cd $WD/server/source/postgres.osx

    # Configure the source tree
    echo "Configuring the postgres source tree for x86_64"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64 -O2' LDFLAGS=\"-L/opt/local/Current/lib -L/opt/local/libexec/llvm-6.0/lib\" PYTHON=$PG_PYTHON_OSX/bin/python3 TCL_CONFIG_SH=$PG_TCL_OSX/lib/tclConfig.sh PERL=$PG_PERL_OSX/bin/perl XML2_CONFIG=/opt/local/Current/bin/xml2-config ICU_LIBS=\"-L/opt/local/Current/lib -licuuc -licudata -licui18n\" ICU_CFLAGS=\"-I/opt/local/Current/include\" LLVM_CONFIG=/opt/local/bin/llvm-config-mp-6.0 CLANG=/opt/local/bin/clang-mp-6.0 ./configure --with-llvm --with-icu --enable-debug --host=x86_64-apple-darwin --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-bonjour --with-pam --enable-thread-safety --with-libxml --with-uuid=e2fs --with-includes=/opt/local/Current/include/libxml2:/opt/local/Current/include:/opt/local/Current/include/security --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi" || _die "Failed to configure postgres for x86_64"

    echo "Building postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; PATH=/opt/local/Current/bin:$PATH CFLAGS='$PG_ARCH_OSX_CFLAGS  -arch x86_64 -O2' make -j4" || _die "Failed to build postgres"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/; make install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64' make" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building pldebugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64' make -j4" || _die "Failed to build the debugger module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/pldebugger; make install" || _die "Failed to install the debugger module"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; CFLAGS='$PG_ARCH_OSX_CFLAGS -arch x86_64' make -j4" || _die "Failed to build the uuid-ossp module"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"

    # Now, build pgAdmin

    #cd $WD/server/source/pgadmin.osx

    # Configure
    echo "Configuring the pgAdmin source tree"
cat <<EOT-PGADMIN > $WD/server/build-pgadmin.sh
    source ../versions.sh
    source ../common.sh
    PATH=$PG_STAGING/bin:\$PATH
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
    mkdir -p venv/lib/python\$PYTHON_VERSION/lib-dynload
    cp -pR \$PGADMIN_PYTHON_DIR/lib/lib*.dylib* venv/lib/

    #Install virtualenv if not present in python installation to create venv
    if [ ! -f \$PGADMIN_PYTHON_DIR/bin/virtualenv ]; then
        echo "Installing virtualenv..."
        \$PGADMIN_PYTHON_DIR/bin/\$PIP install virtualenv
        export UNINSTALL_VIRTUALENV=1
    fi
    \$PGADMIN_PYTHON_DIR/bin/virtualenv --always-copy -p \$PYTHON venv || _die "Failed to create venv"
    cp -f \$PGADMIN_PYTHON_DIR/lib/python\$PYTHON_VERSION/lib-dynload/*.so venv/lib/python\$PYTHON_VERSION/lib-dynload/
    source venv/bin/activate

    ### Added to resolve cryptography installation issue.
    if [ -f \$SOURCEDIR/\requirements.txt.macos ]; then
        rm -rf \$SOURCEDIR/\requirements.txt.macos
    fi
 
    LDFLAGS="-L/opt/local/Current/lib" CFLAGS="-I/opt/local/Current/include" \$PIP install --no-cache-dir --no-binary psycopg2 -r \$SOURCEDIR/requirements.txt || _die "pip install failed"
    # Move the python<version> directory to python so that the private environment path is found by the application.
    export PYMODULES_PATH=\`python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"\`
    export DIR_PYMODULES_PATH=\`dirname \$PYMODULES_PATH\`
    if test -d \$DIR_PYMODULES_PATH; then
        cd \$DIR_PYMODULES_PATH/..
        ln -s python\$PYTHON_VERSION python
    fi

    #Uninstall virtualenv if installed above
    if [ ! -z "\$UNINSTALL_VIRTUALENV"  ]
    then
        \$PGADMIN_PYTHON_DIR/bin/pip uninstall --yes virtualenv
    fi

    # Build runtime
    cd \$BUILDROOT/../runtime
    # python3.8-config --libs output doesn't include -lpython3.8. Hence, add that in the ldflags
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
    rm -rf "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv/include"

    cd $PG_PATH_OSX/server/resources/
    # run complete-bundle to copy the dependent libraries and frameworks and fix the rpaths
    PGDIR=$PG_PATH_OSX/server/staging_cache/osx.build QTDIR="`dirname $PG_QMAKE_OSX`/.." sh ./complete-bundle.sh "\$BUILDROOT/$APP_BUNDLE_NAME" || _die "complete-bundle.sh failed"

    # copy the web directory to the bundle as it is required by runtime
    cp -r $PG_PATH_OSX/server/source/pgadmin.osx/web "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/"
    cp /opt/local/Current/certs/cacert.pem "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/web/"

    # Removing the unwanted files and directories from the pgAdmin4 staging
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv/bin"
    find . \( -name "*.py" \) -delete
    rm -rf __pycache__
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/venv"
    find . \( -name test -o -name tests \) -type d | xargs rm -rf
    cd "\$BUILDROOT/$APP_BUNDLE_NAME/Contents/Resources/web"
    find . \( -name tests -o -name feature_tests \) -type d | xargs rm -rf
    rm -rf regressioni
    rm -f pgadmin4.db config_local.*
    # Create config_distro
    echo "SERVER_MODE = False" > config_distro.py
    echo "MINIFY_HTML = False" >> config_distro.py
    echo "HELP_PATH = '../../../docs/en_US/html/'" >> config_distro.py
    echo "UPGRADE_CHECK_KEY = 'edb-pgadmin4'" >> config_distro.py

    # Remove the .pyc files if any
    cd "\$BUILDROOT/$APP_BUNDLE_NAME"
    find . \( -name "*.pyc" -o -name "*.pyo" \) -delete

    #fix the Qt framework else codesign may fail
    cd $PG_PATH_OSX/server/resources/
    sh ./framework-config.sh "\$BUILDROOT/$APP_BUNDLE_NAME" || _die "framework-config.sh failed"

    # Copy the app bundle into place
    cp -pR "\$BUILDROOT/$APP_BUNDLE_NAME" $PG_PATH_OSX/server/staging_cache/osx.build || _die "Failed to copy pgAdmin into the staging_cache directory"
EOT-PGADMIN

    cd $WD
    chmod 755 $WD/server/build-pgadmin.sh
    scp server/build-pgadmin.sh $PG_SSH_OSX:$PG_PATH_OSX/server
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server; sh -x ./build-pgadmin.sh" || _die "Failed to build pgadmin on OSX"

    #Fix permission in the staging/osx/share
    ssh $PG_SSH_OSX "chmod -R a+r $PG_PATH_OSX/server/staging_cache/osx.build/share/postgresql/timezone/*"

    # Stackbuilder
    #cd $WD/server/source/stackbuilder.osx

    echo "Configuring the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; PATH=/opt/local/Current/bin:$PATH cmake -D CMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.9 -D CURL_ROOT:PATH=/opt/local/Current -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/wxWidgets-30/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D WX_VERSION=3.0 -D CMAKE_OSX_SYSROOT:FILEPATH=$SDK_PATH -D CMAKE_OSX_ARCHITECTURES:STRING=x86_64 ."  || _die "Failed to configure StackBuilder"
    echo "Building the StackBuilder"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/source/stackbuilder.osx/stackbuilder.app/Contents/Resources/certs" || _die "Failed to create certs directory"
    ssh $PG_SSH_OSX "cp /opt/local/Current/certs/ca-bundle.crt $PG_PATH_OSX/server/source/stackbuilder.osx/stackbuilder.app/Contents/Resources/certs/ " || _die "Failed to copy certs bundle"

    # Copy the StackBuilder app bundle into place
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/stackbuilder.osx; cp -pR stackbuilder.app $PG_PATH_OSX/server/staging_cache/osx.build" || _die "Failed to copy StackBuilder into the staging_cache directory"

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
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libintl.*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libintl"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libicui18n*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libicui18n"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libicudata*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libicudata"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libicuuc*dylib $PG_STAGING/lib/" || _die "Failed to copy the latest libicuuc"

    ssh $PG_SSH_OSX "mkdir -p $PG_STAGING/stackbuilder.app/Contents/Frameworks" || _die "Failed to create $PG_STAGING/stackbuilder/Frameworks"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_xrc-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_webview-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_html-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_qa-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_adv-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_osx_cocoau_core-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu_xml-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu_net-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/wxWidgets-30/lib/libwx_baseu-*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libwx"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libcurl*dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libcurl"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libz*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libz"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libssl*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libssl"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libcrypto*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libcrypto"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libjpeg*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libjpeg"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libpng16*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libpng16"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libiconv*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libiconv"
    ssh $PG_SSH_OSX "cp -pR /opt/local/Current/lib/libexpat*.dylib $PG_STAGING/stackbuilder.app/Contents/Frameworks/" || _die "Failed to copy the latest libexpat"

    # Copying plperl to staging/osx directory as we would not like to update the _rewrite_so_refs for it.
    ssh $PG_SSH_OSX "cp -f $PG_PATH_OSX/server/staging_cache/osx.build/lib/postgresql/plperl.so $PG_PATH_OSX/server/staging_cache/osx.build/"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    echo "Rewrite shared library references for stackbuilder.app"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; source settings.sh; source common.sh; cd $PG_STAGING; _rewrite_so_refs_for_framework $PG_STAGING/stackbuilder.app/Contents/MacOS"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; source settings.sh; source common.sh; cd $PG_STAGING; _rewrite_so_refs_for_framework $PG_STAGING/stackbuilder.app/Contents/Frameworks"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    echo "Rewrite shared library references"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; source settings.sh; source common.sh; cd $PG_STAGING; _rewrite_so_refs $PG_STAGING bin @loader_path/..;\
        _rewrite_so_refs $PG_STAGING lib @loader_path/..; _rewrite_so_refs $PG_STAGING lib/postgresql @loader_path/../..;\
        _rewrite_so_refs $PG_STAGING lib/postgresql/plugins @loader_path/../../.."

    echo "Some specific rewriting of shared library references"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change $PG_STAGING/lib/libpq.5.dylib @loader_path/../../../../../../Frameworks/libpq.5.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libpq"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20180529/lib/libssl.1.1.dylib @loader_path/../../../../../../Frameworks/libssl.1.1.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libssl"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20180529/lib/libcrypto.1.1.dylib @loader_path/../../../../../../Frameworks/libcrypto.1.1.dylib Contents/Resources/venv/lib/python/site-packages/psycopg2/_psycopg*.so" || _die "install_name_tool change failed for libcrypto"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20180529/lib/libssl.1.1.dylib @loader_path/../../../../../../../../Frameworks/libssl.1.1.dylib Contents/Resources/venv/lib/python/site-packages/cryptography/hazmat/bindings/_openssl.abi3.so" || _die "install_name_tool change failed for libssl"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -change /opt/local/20180529/lib/libcrypto.1.1.dylib @loader_path/../../../../../../../../Frameworks/libcrypto.1.1.dylib Contents/Resources/venv/lib/python/site-packages/cryptography/hazmat/bindings/_openssl.abi3.so" || _die "install_name_tool change failed for libcrypto"
    ssh $PG_SSH_OSX "cd \"$PG_STAGING/$APP_BUNDLE_NAME\"; install_name_tool -id libpq.5.dylib Contents/Frameworks/libpq.5.dylib" || _die "install_name_tool id failed for libpq"

    # Copying back plperl to staging/osx/lib/postgresql directory as we would not like to update the _rewrite_so_refs for it.
     ssh $PG_SSH_OSX "mv -f $PG_PATH_OSX/server/staging_cache/osx.build/plperl.so $PG_PATH_OSX/server/staging_cache/osx.build/lib/postgresql/plperl.so"

    # Changing loader path of plpython3.so
     ssh $PG_SSH_OSX "install_name_tool -change libpython$PG_VERSION_PYTHON\m.dylib $PG_PYTHON_OSX/lib/libpython$PG_VERSION_PYTHON\m.dylib $PG_PATH_OSX/server/staging_cache/osx.build/lib/postgresql/plpython3.so"

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/scripts/osx/getlocales; gcc -no-cpp-precomp $PG_ARCH_OSX_CFLAGS -arch x86_64 -o getlocales.osx -O0 getlocales.c"  || _die "Failed to build getlocales utility"

    # Generate debug symbols
    ssh $PG_SSH_OSX "cd $PG_STAGING; mv pgAdmin\ 4.app/ pgAdmin4.app"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    ssh $PG_SSH_OSX "cd $PG_STAGING; mv pgAdmin4.app/ pgAdmin\ 4.app"

    # Delete the old regress dir from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/src/test/; rm -rf regress" || _die "Failed to remove the regression regress directory"

    # Copy the regress source to the regression setup 
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/server/source/postgres.osx/src/test/; cp -pR regress /buildfarm/src/test/" || _die "Failed to Copy regress to the regression directory"

    echo "Removing last successful staging directory ($PG_PATH_OSX/server/staging_cache/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/server/staging_cache/osx" || _die "Couldn't remove the last successful staging_cache directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/server/staging_cache/osx" || _die "Couldn't create the last successful staging_cache directory"

    echo "Copying the complete build to the successful staging_cache directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR server/staging_cache/osx.build/* server/staging_cache/osx" || _die "Couldn't copy the existing staging_cache directory"

    ssh $PG_SSH_OSX "echo PG_MAJOR_VERSION=$PG_MAJOR_VERSION > $PG_PATH_OSX/server/staging_cache/osx/versions-osx.sh" || _die "Failed to write server version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_MINOR_VERSION=$PG_MINOR_VERSION >> $PG_PATH_OSX/server/staging_cache/osx/versions-osx.sh" || _die "Failed to write server build number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_PACKAGE_VERSION=$PG_PACKAGE_VERSION >> $PG_PATH_OSX/server/staging_cache/osx/versions-osx.sh" || _die "Failed to write server build number into versions-osx.sh"

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

    PG_STAGING=$PG_PATH_OSX/server/staging_cache/osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/server/staging/osx)"
    mkdir -p $WD/server/staging/osx || _die "Couldn't create the staging directory"
    mkdir -p $PGSERVER_STAGING_OSX || _die "Couldn't create the staging directory $PGSERVER_STAGING_OSX"
    mkdir -p $PGADMIN_STAGING_OSX || _die "Couldn't create the staging directory $PGADMIN_STAGING_OSX"
    mkdir -p $SB_STAGING_OSX || _die "Couldn't create the staging directory $SB_STAGING_OSX"
    mkdir -p $CLT_STAGING_OSX || _die "Couldn't create the staging directory $CLT_STAGING_OSX"

    echo "Creating staging directory for debug symbols"
    mkdir -p $PGSERVER_STAGING_OSX/debug_symbols || _die "Couldn't create the staging directory $PGSERVER_STAGING_OSX/debug_symbols"
    mkdir -p $PGADMIN_STAGING_OSX/debug_symbols || _die "Couldn't create the staging directory $PGADMIN_STAGING_OSX/debug_symbols"
    mkdir -p $SB_STAGING_OSX/debug_symbols || _die "Couldn't create the staging directory $SB_STAGING_OSX/debug_symbols"


    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_STAGING; tar -jcvf server-staging.tar.bz2 *" || _die "Failed to create archive of the server staging_cache"
    scp $PG_SSH_OSX:$PG_STAGING/server-staging.tar.bz2 $WD/server/staging_cache/osx || _die "Failed to scp server staging_cache"

    scp $PG_SSH_OSX:$PG_PATH_OSX/server/scripts/osx/getlocales/getlocales.osx $WD/server/scripts/osx/getlocales/ || _die "Failed to scp getlocales.osx"

    # Copy the required files to signing server
    scp $WD/common.sh $WD/settings.sh $WD/versions.sh $WD/resources/entitlements-server.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
    # sign the getlocales binary
    scp $WD/server/scripts/osx/getlocales/getlocales.osx $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy getlocales binary to  signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --deep -f -i 'com.edb.postgresql' -s 'Developer ID Application: EnterpriseDB Corporation' --options runtime getlocales.osx" || _die "Failed to sign the getlocales binary"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/getlocales.osx $WD/server/scripts/osx/getlocales/ || _die "Failed to copy getlocales binary to controller"

    # sign the binaries and libraries
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf server-staging.tar.bz2" || _die "Failed to remove server-staging.tar from signing server"
    scp $WD/server/staging_cache/osx/server-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy server-staging.tar.bz2 on signing server"
    rm -rf $WD/server/staging_cache/osx/server-staging.tar.bz2 || _die "Failed to remove server-staging.tar from controller"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../server-staging.tar.bz2; mv pgAdmin\ 4.app pgAdmin4.app"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging" || _die "Failed to do libraries signing"
    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging/lib entitlements-server.xml" || _die "Failed to do libraries signing with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_bundles staging" || _die "Failed to sign bundle"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_bundles staging/lib/postgresql entitlements-server.xml" || _die "Failed to sign bundle with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging" || _die "Failed to do binaries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging/bin entitlements-server.xml" || _die "Failed to do binaries signing with entitlements"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging; mv pgAdmin4.app pgAdmin\ 4.app; tar -jcvf server-staging.tar.bz2 *" || _die "Failed to create server-staging tar on signing server"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/server-staging.tar.bz2 $WD/server/staging_cache/osx || _die "Failed to copy server-staging to controller vm"

    # Extract the staging archive
    cd $WD/server/staging_cache/osx
    tar -jxvf server-staging.tar.bz2 || _die "Failed to extract the server staging archive"
    rm -f server-staging.tar.bz2

    mkdir -p $WD/server/staging_cache/osx/doc || _die "Failed to create the doc directory"
    cp $WD/server/source/postgres.osx/contrib/pldebugger/README.pldebugger $WD/server/staging_cache/osx/doc || _die "Failed to copy the debugger README into the staging_cache directory"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging_cache/osx/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging_cache/osx/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $WD/server/staging_cache/osx/share/man || _die "Failed to create the man directory"
    cd $WD/server/staging_cache/osx/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (osx)"
    cp -pR $WD/server/source/postgres.osx/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (osx)"

    source $WD/server/staging_cache/osx/versions-osx.sh
    PG_BUILD_SERVER=$(expr $PG_BUILD_SERVER + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SERVER -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    echo "Preparing restructured staging for server"
    cp -r $WD/server/staging_cache/osx/bin $PGSERVER_STAGING_OSX  || _die "Failed to copy $WD/server/staging_cache/osx/bin"
    cp -r $WD/server/staging_cache/osx/lib $PGSERVER_STAGING_OSX  || _die "Failed to copy $WD/server/staging_cache/osx/lib"
    cp -r $WD/server/staging_cache/osx/include $PGSERVER_STAGING_OSX || _die "Failed to copy $WD/server/staging_cache/osx/include"
    cp -r $WD/server/staging_cache/osx/doc $PGSERVER_STAGING_OSX || _die "Failed to copy $WD/server/staging_cache/osx/doc"
    cp -r $WD/server/staging_cache/osx/share $PGSERVER_STAGING_OSX || _die "Failed to copy $WD/server/staging_cache/osx/share"
    cp -r $WD/server/staging_cache/osx/debug_symbols/bin $WD/server/staging_cache/osx/debug_symbols/lib $PGSERVER_STAGING_OSX/debug_symbols/ || _die "Failed to copy $WD/server/staging_cache/osx/share"

    echo "Preparing restructured staging for Command Line Tools"
    mkdir -p $CLT_STAGING_OSX/bin || _die "Failed to create the $CLT_STAGING_OSX/bin directory"
    mkdir -p $CLT_STAGING_OSX/lib || _die "Failed to create the $CLT_STAGING_OSX/lib directory"
    mkdir -p $CLT_STAGING_OSX/share/man/man1 || _die "Failed to create the $CLT_STAGING_OSX/share/man/man1 directory"

    mv $PGSERVER_STAGING_OSX/lib  $CLT_STAGING_OSX || _die "Failed to move $PGSERVER_STAGING_OSX/lib"
    mv $PGSERVER_STAGING_OSX/bin/psql*  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/bin/psql"
    mv $PGSERVER_STAGING_OSX/bin/pg_basebackup  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/bin/pg_basebackup"
    mv $PGSERVER_STAGING_OSX/bin/pg_dump  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/bin/pg_dump"
    mv $PGSERVER_STAGING_OSX/bin/pg_dumpall  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/bin/pg_dumpall"
    mv $PGSERVER_STAGING_OSX/bin/pg_restore  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/pg_restore"
    mv $PGSERVER_STAGING_OSX/bin/createdb  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/createdb"
    mv $PGSERVER_STAGING_OSX/bin/clusterdb $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/clusterdb"
    mv $PGSERVER_STAGING_OSX/bin/createuser  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/createuser"
    mv $PGSERVER_STAGING_OSX/bin/dropuser  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/dropuser"
    mv $PGSERVER_STAGING_OSX/bin/dropdb  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/dropdb"
    mv $PGSERVER_STAGING_OSX/bin/pg_isready  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/pg_isready"
    mv $PGSERVER_STAGING_OSX/bin/vacuumdb  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/vacuumdb"
    mv $PGSERVER_STAGING_OSX/bin/reindexdb  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/reindexdb"
    mv $PGSERVER_STAGING_OSX/bin/pgbench  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/pgbench"
    mv $PGSERVER_STAGING_OSX/bin/vacuumlo  $CLT_STAGING_OSX/bin/ || _die "Failed to move $PGSERVER_STAGING_OSX/server/bin/vacuumlo"

    mv $PGSERVER_STAGING_OSX/share/man/man1/pg_basebackup.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/pg_dump.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/pg_restore.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/createdb.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/clusterdb.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/createuser.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/dropdb.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/dropuser.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/pg_isready.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/vacuumdb.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/reindexdb.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/pgbench.1 $CLT_STAGING_OSX/share/man/man1
    mv $PGSERVER_STAGING_OSX/share/man/man1/vacuumlo.1 $CLT_STAGING_OSX/share/man/man1

    echo "Preparing restructured staging for pgAdmin"
    cp -pR $WD/server/staging_cache/osx/pgAdmin\ 4.app/  $PGADMIN_STAGING_OSX
    cp -pR $WD/server/staging_cache/osx/debug_symbols/pgAdmin4.app $PGADMIN_STAGING_OSX/debug_symbols

    echo "Preparing restructured staging for stackbuilder"
    mkdir -p $WD/server/staging_cache/osx/stackbuilder
    rm -rf $WD/server/staging_cache/osx/stackbuilder/stackbuilder.app
    mv $WD/server/staging_cache/osx/stackbuilder.app $WD/server/staging_cache/osx/stackbuilder/ || _die "Failed to move stackbuilder.app"
    cp -pR $WD/server/staging_cache/osx/stackbuilder/stackbuilder.app $SB_STAGING_OSX || _die "Failed to copy stackbuilder.app"
    cp -pR $WD/server/staging_cache/osx/debug_symbols/stackbuilder.app $SB_STAGING_OSX/debug_symbols

    cd $WD/server

    #generate commandlinetools license file
    pushd $CLT_STAGING_OSX
        generate_3rd_party_license "commandlinetools"
    popd

    #generate pgAdmin4 license file
    pushd $PGADMIN_STAGING_OSX
        generate_3rd_party_license "pgAdmin"
    popd

    #generate StackBuilder license file
    pushd $SB_STAGING_OSX
        generate_3rd_party_license "StackBuilder"
    popd

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$PGSERVER_STAGING_OSX/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/edblogo.png" "$PGSERVER_STAGING_OSX/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging_cache/osx/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging_cache/osx
    cp -pR bin doc include lib pgAdmin* share stackbuilder pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    zip -yrq postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-osx-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/osx/server ];
    then
        echo "Removing existing $WD/output/symbols/osx/server directory"
        rm -rf $WD/output/symbols/osx/server  || _die "Couldn't remove the existing $WD/output/symbols/osx/server directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/osx || _die "Failed to create $WD/output/symbols/osx directory"
    mv $WD/server/staging_cache/osx/debug_symbols $WD/output/symbols/osx/server || _die "Failed to move $WD/server/staging_cache/osx/debug_symbols to $WD/output/symbols/osx/server directory"

    # Complete the staging and prepare the installer
    #cp $WD/server/staging_cache/osx/server_3rd_party_licenses.txt $PGSERVER_STAGING_OSX/../
    cp $WD/resources/license.txt $PGSERVER_STAGING_OSX/server_license.txt
    cp $WD/server/source/pgadmin.osx/LICENSE $PGADMIN_STAGING_OSX/pgAdmin_license.txt

    cd $WD/server

    # Setup the installer scripts.
    mkdir -p $PGSERVER_STAGING_OSX/installer/server || _die "Failed to create a directory for the install scripts"
    cp $WD/server/scripts/osx/getlocales/getlocales.osx $PGSERVER_STAGING_OSX/installer/server/getlocales || _die "Failed to copy getlocales utility in the staging directory"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/getlocales
    cp $WD/server/scripts/osx/prerun_checks.sh $PGSERVER_STAGING_OSX/installer/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/prerun_checks.sh

    cp scripts/osx/createuser.sh $PGSERVER_STAGING_OSX/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/osx/createuser.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/createuser.sh
    cp scripts/osx/initcluster.sh $PGSERVER_STAGING_OSX/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/osx/initcluster.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/initcluster.sh
    cp scripts/osx/createshortcuts.sh $PGSERVER_STAGING_OSX/installer/server/createshortcuts.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts.sh)"
    cp scripts/osx/createshortcuts_server.sh $PGSERVER_STAGING_OSX/installer/server/createshortcuts_server.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts_server.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/createshortcuts*.sh
    cp scripts/osx/startupcfg.sh $PGSERVER_STAGING_OSX/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/startupcfg.sh
    cp scripts/osx/loadmodules.sh $PGSERVER_STAGING_OSX/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/osx/loadmodules.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/loadmodules.sh

    cp scripts/osx/createshortcuts_server.sh $PGSERVER_STAGING_OSX/installer/server/createshortcuts_server.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts_server.sh)"
    chmod ugo+x $PGSERVER_STAGING_OSX/installer/server/createshortcuts*.sh

    mkdir -p $SB_STAGING_OSX/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts_sb.sh $SB_STAGING_OSX/installer/server/createshortcuts_sb.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts_sb.sh)"
    chmod ugo+x $SB_STAGING_OSX/installer/server/createshortcuts_sb.sh

    mkdir -p $PGADMIN_STAGING_OSX/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts_pgadmin.sh $PGADMIN_STAGING_OSX/installer/server/createshortcuts_pgadmin.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts_pgadmin.sh)"
    chmod ugo+x $PGADMIN_STAGING_OSX/installer/server/createshortcuts_pgadmin.sh

    mkdir -p $CLT_STAGING_OSX/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts_clt.sh $CLT_STAGING_OSX/installer/server/createshortcuts_clt.sh || _die "Failed to copy the createuser script (scripts/osx/createshortcuts_clt.sh)"
    chmod ugo+x $CLT_STAGING_OSX/installer/server/createshortcuts_clt.sh

    # Copy in the menu pick images
    mkdir -p $PGSERVER_STAGING_OSX/scripts/images || _die "Failed to create a directory $PGSERVER_STAGING_OSX/scripts/images for the menu pick images"
    mkdir -p $SB_STAGING_OSX/scripts/images || _die "Failed to create a directory $SB_STAGING_OSX/scripts/images for the menu pick images"
    mkdir -p $CLT_STAGING_OSX/scripts/images || _die "Failed to create a directory $CLT_STAGING_OSX/scripts/images for the menu pick images"

    cp resources/pg-help.icns $PGSERVER_STAGING_OSX/scripts/images/ || _die "Failed to copy a menu pick image"
    cp resources/pg-reload.icns $PGSERVER_STAGING_OSX/scripts/images/|| _die "Failed to copy a menu pick image"
    cp resources/pg-stackbuilder.icns $SB_STAGING_OSX/scripts/images/|| _die "Failed to copy a menu pick image"
    cp resources/pg-psql.icns $CLT_STAGING_OSX/scripts/images/|| _die "Failed to copy a menu pick image"

    # Copy the launch scripts
    cp scripts/osx/runpsql.sh $CLT_STAGING_OSX/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/osx/runpsql.sh)"
    chmod ugo+x $CLT_STAGING_OSX/scripts/runpsql.sh

    # Hack up the scripts, and compile them into the staging directory
    cp scripts/osx/doc-installationnotes.applescript.in $PGSERVER_STAGING_OSX/scripts/doc-installationnotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-installationnotes.applescript.in)"
    cp scripts/osx/doc-postgresql.applescript.in $PGSERVER_STAGING_OSX/scripts/doc-postgresql.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql.applescript.in)"
    cp scripts/osx/doc-postgresql-releasenotes.applescript.in $PGSERVER_STAGING_OSX/scripts/doc-postgresql-releasenotes.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-postgresql-releasenotes.applescript.in)"
    cp scripts/osx/doc-pgadmin.applescript.in $PGSERVER_STAGING_OSX/scripts/doc-pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/doc-pgadmin.applescript.in)"

    cp scripts/osx/psql.applescript.in $PGSERVER_STAGING_OSX/scripts/psql.applescript || _die "Failed to to the menu pick script (scripts/osx/psql.applescript.in)"
    cp scripts/osx/reload.applescript.in $PGSERVER_STAGING_OSX/scripts/reload.applescript || _die "Failed to to the menu pick script (scripts/osx/reload.applescript.in)"
    cp scripts/osx/pgadmin.applescript.in $PGSERVER_STAGING_OSX/scripts/pgadmin.applescript || _die "Failed to to the menu pick script (scripts/osx/pgadmin.applescript.in)"
    cp scripts/osx/stackbuilder.applescript.in $PGSERVER_STAGING_OSX/scripts/stackbuilder.applescript || _die "Failed to to the menu pick script (scripts/osx/stackbuilder.applescript.in)"

    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Prepare the installer XML file
    _prepare_server_xml "osx"

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
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-osx-installer.app $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app || _die "Failed to rename the installer"
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
    echo "Signing the installer"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh;  tar -jxvf server.img.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain;codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s 'Developer ID Application: EnterpriseDB Corporation' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements-server.xml server.img/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"


    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output/server.img; rm -rf postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app; mv postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx-signed.app postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv server.img/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output;rm -rf server.img.tar.bz2; tar -jcvf server.img.tar.bz2 server.img;" || _die "faled to create server.img.tar.bz2 on $PG_SSH_OSX_SIGN"
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
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf postgresql-*.dmg; rm -rf postgresql-*.zip" || _die "Failed to remove the installer and zip from notarization installer directory"
    scp $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg $WD/output/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installer and zip to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg postgresql" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip postgresql" || _die "Failed to notarize the zip"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.dmg $WD/output || _die "Failed to copy notarized installer to $WD/output."
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/postgresql-$PG_PACKAGE_VERSION-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized zip to $WD/output."

    # Delete the old installer from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/installers; rm -rf postgresql-*.dmg" || _die "Failed to remove the installer from regression installer directory"

    # Copy the installer to regression setup
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; cp -p postgresql-*.dmg /buildfarm/installers/" || _die "Failed to Copy installer to the regression directory"

    cd $WD
    echo "END POST Server OSX"
}


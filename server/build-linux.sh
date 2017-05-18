#!/bin/bash
################################################################################
# Build preparation
################################################################################

_prep_server_linux() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP Server Linux"

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.linux ];
    then
      echo "Removing existing postgres.linux source directory"
      rm -rf postgres.linux  || _die "Couldn't remove the existing postgres.linux source directory (source/postgres.linux)"
    fi
   
    # Grab a copy of the source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.linux || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
 
    if [ -e pgadmin.linux ];
    then
      echo "Removing existing pgadmin.linux source directory"
      rm -rf pgadmin.linux  || _die "Couldn't remove the existing pgadmin.linux source directory (source/pgadmin.linux)"
    fi

    # Grab a copy of the source tree
    cp -pR pgadmin4-$PG_TARBALL_PGADMIN pgadmin.linux || _die "Failed to copy the source code (source/pgadmin-$PG_TARBALL_PGADMIN)"

    if [ -e stackbuilder.linux ];
    then
      echo "Removing existing stackbuilder.linux source directory"
      rm -rf stackbuilder.linux  || _die "Couldn't remove the existing stackbuilder.linux source directory (source/stackbuilder.linux)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -pR stackbuilder stackbuilder.linux || _die "Failed to copy the source code (source/stackbuilder)"	
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/linux)"
    mkdir -p $WD/server/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/server/staging/linux || _die "Couldn't set the permissions on the staging directory"

    mkdir -p $PGSERVER_STAGING || _die "Couldn't create the staging directory $PGSERVER_STAGING"
    mkdir -p $PGADMIN_STAGING || _die "Couldn't create the staging directory $PGADMIN_STAGING"
    mkdir -p $SB_STAGING || _die "Couldn't create the staging directory $SB_STAGING"
    mkdir -p $CLT_STAGING || _die "Couldn't create the staging directory $CLT_STAGING"
    chmod ugo+w $PGSERVER_STAGING $PGADMIN_STAGING $SB_STAGING $CLT_STAGING || _die "Couldn't set the permissions on the staging directory"
    
    if [ -f $WD/server/scripts/linux/getlocales/getlocales.linux ]; then
      rm -f $WD/server/scripts/linux/getlocales/getlocales.linux
    fi

    echo "END PREP Server Linux"
}

_process_dependent_libs_linux() {

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
 

   if [ -e /tmp/templibs ];
   then
	rm -rf /tmp/templibs
   fi

   # Create a temporary directory
   mkdir /tmp/templibs  

   export LD_LIBRARY_PATH=$libdir

   # Get the exact version of $libname which are required by the binaries in $bin_dir
   cd $bin_dir
   dependent_libs=\`ldd \\\`ls\\\` | grep $libname | cut -f1 -d "=" | uniq\`

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
        done
    done

    # Remove all the remaining \$libname versions (that are not symlinks) in the lib directory
    for lib in \$liblist
    do 
         rm -f \$lib || _die "Failed to remove the library"
    done            

    if [ "\$(ls -A /tmp/templibs)" ];
    then
        # Copy libs from the tmp/templibs directory
        cp -pR /tmp/templibs/* $lib_dir/     || _die "Failed to move the library files from temp directory"
    fi

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
    echo "BEGIN BUILD Server Linux"

    # First build PostgreSQL

    #PG_STAGING=$PG_PATH_LINUX/server/staging/linux
    
    # Configure the source tree
    echo "Configuring the postgres source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/; PYTHON=$PG_PYTHON_LINUX/bin/python3 TCLSH=$PG_TCL_LINUX/bin/tclsh TCL_CONFIG_SH=$PG_TCL_LINUX/lib/tclConfig.sh PERL=$PG_PERL_LINUX/bin/perl CFLAGS='-O2 -DMAP_HUGETLB=0x40000' ./configure --enable-debug --with-libs=/opt/local/Current/lib --with-includes=/opt/local/Current/include:/opt/local/Current/include/libxml2 --prefix=$REMOTE_PGSERVER_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-tclconfig=$PG_TCL_LINUX/lib --with-pam --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=$REMOTE_PGSERVER_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi LD_LIBRARY_PATH=/opt/local/Current/lib"  || _die "Failed to configure postgres"

    echo "Building postgres"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux; LD_LIBRARY_PATH=/opt/local/Current/lib  make -j4 shared_libpython=yes" || _die "Failed to build postgres" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux; LD_LIBRARY_PATH=/opt/local/Current/lib make shared_libpython=yes install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib; LD_LIBRARY_PATH=/opt/local/Current/lib make -j4" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib; make install" || _die "Failed to install the postgres contrib modules"

    echo "Building debugger module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/pldebugger; export LD_LIBRARY_PATH=/opt/local/Current/lib:\$LD_LIBRARY_PATH; make" || _die "Failed to build the debugger module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/pldebugger; make install" || _die "Failed to install the debugger module"
	if [ ! -e $PGSERVER_STAGING/doc ];
	then
	    mkdir -p $PGSERVER_STAGING/doc || _die "Failed to create the doc directory"
	fi
    cp "$WD/server/source/postgres.linux/contrib/pldebugger/README.pldebugger" $PGSERVER_STAGING/doc || _die "Failed to copy the debugger README into the staging directory"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/uuid-ossp; export LD_LIBRARY_PATH=/opt/local/Current/lib:\$LD_LIBRARY_PATH; make" || _die "Failed to build the uuid-ossp module"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"

 
    # Install the PostgreSQL docs
    mkdir -p $PGSERVER_STAGING/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $PGSERVER_STAGING/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.linux/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $PGSERVER_STAGING/share/man || _die "Failed to create the man directory"
    cd $PGSERVER_STAGING/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.linux/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (linux)"
    cp -pR $WD/server/source/postgres.linux/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (linux)"
    cp -pR $WD/server/source/postgres.linux/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (linux)"

    # Copy the third party headers
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/openssl $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/libxml2 $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/libxslt $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/sasl $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/krb5 $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/gssapi $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/include/iconv.h $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/include/zlib.h $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/include/krb5.h $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp -r /opt/local/Current/include/ncurses $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/include/gssapi.h $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/include/ldap*.h $REMOTE_PGSERVER_STAGING/include" || _die "Failed to copy the required header"

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libssl.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libcrypto.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libedit.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libz.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libkrb5.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libkrb5support* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libk5crypto* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libcom* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libgssapi* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libncurses.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libuuid.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libxml2.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libxslt.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libiconv.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/liblber-2.4.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library(lber)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libsasl2.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library(sasl)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libldap-2.4.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library(ldap)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libldap_r-2.4.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library(ldap_r)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libcurl.so* $REMOTE_PGSERVER_STAGING/lib" || _die "Failed to copy the dependency library(libcurl)"

    # Process Dependent libs
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libssl"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libcrypto"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libedit"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libz"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libkrb5.so"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libkrb5support"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libk5crypto"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libcom"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libgssapi"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libncurses"  
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libxml2"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/lib/postgresql" "$REMOTE_PGSERVER_STAGING/lib" "libxslt.so"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/lib/postgresql" "$REMOTE_PGSERVER_STAGING/lib" "libuuid.so"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libiconv"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "liblber-2.4"
    #_process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libsasl2"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libldap-2.4"
    _process_dependent_libs_linux "$REMOTE_PGSERVER_STAGING/bin" "$REMOTE_PGSERVER_STAGING/lib" "libldap_r-2.4"

    # Copying psql to psql.bin and the creating a caller script psql
    # which will set the LD_PRELOAD to libreadline if found on the system.
    cd $PGSERVER_STAGING/bin
    mv psql psql.bin
    cat <<EOT > psql
#!/bin/bash

# If there's an OS supplied version of libreadline, try to make use of it,
# as it's more reliable than libedit, which we link with.
PLL=""
if [ -f /lib/libreadline.so.6 ];
then
    PLL=/lib/libreadline.so.6
elif [ -f /lib/libreadline.so.5 ];
then
    PLL=\$PLL:/lib/libreadline.so.5
fi

# Get the PG bin directory path relative to psql caller script.
PG_BIN_PATH=\`dirname "\$0"\`

if [ -z "\$PLL" ];
then
	LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$PG_BIN_PATH/../lib  "\$PG_BIN_PATH/psql.bin" "\$@"
else
	LD_PRELOAD=\$PLL LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$PG_BIN_PATH/../lib "\$PG_BIN_PATH/psql.bin" "\$@"
fi

EOT
    chmod +x psql.bin || _die "Failed to grant execute permission to psql script"
    chmod +x psql || _die "Failed to grant execute permission to psql script"

    # Now build pgAdmin
    echo "Building pgAdmin"
cat <<EOT-PGADMIN > $WD/server/build-pgadmin.sh
    source ../versions.sh
    source ../common.sh
    # In PG10, the version numbering scheme got changed and adopted a single digit major version (10) instead of two which is not supported by psycopg2
    # and requires a two digit version. Hence, use 9.6 installation to build pgAdmin
    PATH=/opt/local/pg96-linux:\$PATH
    LD_LIBRARY_PATH=$REMOTE_PGSERVER_STAGING/lib:\$LD_LIBRARY_PATH
    # Set PYTHON_VERSION variable required for pgadmin build
    PYTHON_HOME=$PGADMIN_PYTHON_LINUX
    export LD_LIBRARY_PATH=\$PYTHON_HOME/lib:\$LD_LIBRARY_PATH
    # Check if Python is working and calculate PYTHON_VERSION
    if \$PYTHON_HOME/bin/python2 -V > /dev/null 2>&1; then
        export PYTHON_VERSION=\`\$PYTHON_HOME/bin/python2 -V 2>&1 | awk '{print \$2}' | cut -d"." -f1-2\`
    elif \$PYTHON_HOME/bin/python3 -V > /dev/null 2>&1; then
        export PYTHON_VERSION=\`\$PYTHON_HOME/bin/python3 -V 2>&1 | awk '{print \$2}' | cut -d"." -f1-2\`
    else
        echo "Error: Python installation missing!"
        exit 1
    fi
    if echo \$PYTHON_VERSION | grep ^3 > /dev/null 2>&1 ; then
        export PYTHON=\$PYTHON_HOME/bin/python3
        export PIP=pip3
    else
        export PYTHON=\$PYTHON_HOME/bin/python2
        export PIP=pip
    fi
    SOURCEDIR=$PG_PATH_LINUX/server/source/pgadmin.linux
    BUILDROOT=$PG_PATH_LINUX/server/source/pgadmin.linux/linux-build
    test -d \$BUILDROOT || mkdir \$BUILDROOT
    cd \$BUILDROOT
    mkdir -p venv/lib
    cp -pR \$PYTHON_HOME/lib/lib*.so* venv/lib/
    virtualenv --always-copy -p \$PYTHON_HOME/bin/python venv || _die "Failed to create venv"
    cp -f \$PYTHON_HOME/lib/python\$PYTHON_VERSION/lib-dynload/*.so venv/lib/python\$PYTHON_VERSION/lib-dynload/
    source venv/bin/activate
    \$PIP --cache-dir "~/.cache/\$PIP-pgadmin" install -r \$SOURCEDIR/\requirements.txt || _die "PIP install failed"
    rsync -zrva --exclude site-packages --exclude lib2to3 --include="*.py" --include="*/" --exclude="*" \$PYTHON_HOME/lib/python\$PYTHON_VERSION/* venv/lib/python\$PYTHON_VERSION/

    # Move the python<version> directory to python so that the private environment path is found by the application.
    export PYMODULES_PATH=\`python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"\`
    export DIR_PYMODULES_PATH=\`dirname \$PYMODULES_PATH\`
    if test -d \$DIR_PYMODULES_PATH; then
	cd \$DIR_PYMODULES_PATH/..
	ln -s python\$PYTHON_VERSION python
    fi
    # Build runtime
    cd \$BUILDROOT/../runtime
    PGADMIN_LDFLAGS="-L\$PYTHON_HOME/lib" $PG_QMAKE_LINUX || _die "qmake failed"
    make || _die "pgadmin runtime build failed"

    # Create qt.conf
    cat >> "qt.conf" << EOF
    [Paths]
    Plugins = ../plugins
    Translations = ../translations
EOF
    # Build docs
    \$PIP install Sphinx || _die "PIP Sphinx failed"
    cd \$SOURCEDIR/docs/en_US
    LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 make -f Makefile.sphinx html || exit 1
    
    # Uninstall as it is not required to bundle Sphinx
    \$PIP uninstall --yes Sphinx

    # copy the web directory to the bundle as it is required by runtime
    cp -r \$SOURCEDIR/web "\$BUILDROOT"

    # Removing the unwanted files and directories from the pgAdmin4 staging
    cd "\$BUILDROOT/venv"
    find . \( -name test -o -name tests \) -type d | xargs rm -rf
    cd "\$BUILDROOT/web/pgadmin"
    rm -rf feature_tests
    cd ..
    rm -rf regression
    rm -f pgadmin4.db config_local.* config_distro.py
    find . -name "tests" -type d | xargs rm -rf
    # Create config_distro
    echo "SERVER_MODE = False" > config_distro.py
    echo "HELP_PATH = '../../../docs/en_US/html/'" >> config_distro.py

EOT-PGADMIN

    cd $WD
    chmod 755 $WD/server/build-pgadmin.sh
    scp server/build-pgadmin.sh $PG_SSH_LINUX:$PG_PATH_LINUX/server
    # Build
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server; sh -x ./build-pgadmin.sh" || _die "Failed to build pgadmin on Linux"

    # Prepare Staging
    ssh $PG_SSH_LINUX "cd $REMOTE_PGADMIN_STAGING; mkdir \"pgAdmin 4\"; cd \"pgAdmin 4\"; mkdir -p bin lib docs/en_US translations" || _die "Failed to create pgadmin staging directories"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/pgadmin.linux/runtime; cp pgAdmin4 qt.conf \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/bin\"" || _die "Failed to copy pgAdmin4 binary to staging"
    ssh $PG_SSH_LINUX "cp -r $PG_PATH_LINUX/server/source/pgadmin.linux/linux-build/venv \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/\"" || _die "Failed to copy venv to staging"
    ssh $PG_SSH_LINUX "cp -r $PG_PATH_LINUX/server/source/pgadmin.linux/docs/en_US/_build/html \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/docs/en_US\"" || _die "Failed to copy pgAdmin4 docs to staging"
    ssh $PG_SSH_LINUX "cp -r $PG_PATH_LINUX/server/source/pgadmin.linux/linux-build/web \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/\"" || _die "Failed to copy pgAdmin4 web to staging"
    ssh $PG_SSH_LINUX "mkdir -p \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/plugins/platforms\"" || _die "Failed to create plugins directory"

    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/plugins/platforms/libqxcb.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/plugins/platforms\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/plugins/xcbglintegrations \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/plugins/\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/plugins/bearer \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/plugins/\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/plugins/qtwebengine \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/plugins/\"" || _die "Failed to copy qt dependent libs to staging"

    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5XcbQpa.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5DBus.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Widgets.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5WebEngine.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5WebEngineWidgets.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Gui.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Network.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Core.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5PrintSupport.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5OpenGL.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Sql.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libicui18n.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libicuuc.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libicudata.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5WebEngineCore.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Quick.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5WebChannel.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Qml.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Positioning.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/lib/libQt5Core.so* \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/lib\"" || _die "Failed to copy qt dependent libs to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/translations/qtwebengine_locales \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/translations/\""|| _die "Failed to copy qt dependent translations to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/icu*.dat \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/bin/\""|| _die "Failed to copy qt dependent resources to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/qtwebengine*.pak \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/bin/\""|| _die "Failed to copy qt dependent resources to staging"
    ssh $PG_SSH_LINUX "cp -pR $PG_QT_LINUX/libexec/QtWebEngineProcess \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/bin/\""|| _die "Failed to copy qt dependent resources to staging"

    # Remove the unwanted stuff from staging
    ssh $PG_SSH_LINUX "cd \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/venv\"; find . \( -name \"*.pyc\" -o -name \"*.pyo\" \) -delete" || _die "Failed to remove unwanted files from pgadmin staging"
    ssh $PG_SSH_LINUX "cd \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/web\"; find . \( -name \"*.pyc\" -o -name \"*.pyo\" \) -delete" || _die "Failed to remove unwanted files from pgadmin staging"
    ssh $PG_SSH_LINUX "cd \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/venv/bin\"; find . ! -name python -delete" || _die "Failed to remove unwanted files from pgadmin staging"
    ssh $PG_SSH_LINUX "cd \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/venv/bin\"; rm -rf .Python include"

    echo "Changing the rpath for the pgAdmin"
    ssh $PG_SSH_LINUX "cd \"$REMOTE_PGADMIN_STAGING/pgAdmin 4/bin\"; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib:\\\${ORIGIN}/../venv/lib\" \$f; done"

    echo "Changing the rpath for the PostgreSQL executables and libraries"
    ssh $PG_SSH_LINUX "cd $REMOTE_PGSERVER_STAGING/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX "cd $REMOTE_PGSERVER_STAGING/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"
    ssh $PG_SSH_LINUX "cd $REMOTE_PGSERVER_STAGING/lib/postgresql; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/..\" \$f; done"

    #Fix permission in the staging/linux/lib
    ssh $PG_SSH_LINUX "cd $REMOTE_PGSERVER_STAGING/lib; chmod a+r *"
    
    #Fix permission in the staging/linux/share
    ssh $PG_SSH_LINUX "cd $REMOTE_PGSERVER_STAGING/share/postgresql/timezone; chmod -R a+r *"
 
    # Stackbuilder
    # Configure
    echo "Configuring the StackBuilder source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D CURL_ROOT:PATH=/opt/local/Current -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_INSTALL_PREFIX:PATH=$REMOTE_SB_STAGING ."

    # Build the app
    echo "Building & installing StackBuilder"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/stackbuilder.linux/; make install" || _die "Failed to install StackBuilder"

    # Copy in the various libraries
    ssh $PG_SSH_LINUX "mkdir -p $REMOTE_SB_STAGING/share/certs" || _die "Failed to create the certs directory"
    ssh $PG_SSH_LINUX "cp /opt/local/Current/certs/ca-bundle.crt $REMOTE_SB_STAGING/share/certs" || _die "Failed to copy the certs directory"
    ssh $PG_SSH_LINUX "mkdir -p $REMOTE_SB_STAGING/lib" || _die "Failed to create the lib directory"

    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_adv-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_aui-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_core-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_html-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_ogl-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_qa-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_richtext-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_stc-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_gtk2u_xrc-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_baseu-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_baseu_net-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libwx_baseu_xml-2.8.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libexpat.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libpng12.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libtiff.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libjpeg.so* $REMOTE_SB_STAGING/lib" || _die "Failed to copy the dependency library"

    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_adv-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_aui-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_core-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_html-2.8"
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_ogl-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_qa-2.8.so"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_richtext-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_stc-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_gtk2u_xrc-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_baseu-2.8"  
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_baseu_net-2.8"
    _process_dependent_libs_linux "$REMOTE_SB_STAGING/bin" "$REMOTE_SB_STAGING/lib" "libwx_baseu_xml-2.8"  

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/scripts/linux/getlocales/; gcc -o getlocales.linux -O0 getlocales.c" || _die "Failed to build getlocales utility"

    # Generate debug symbols
    mv $PGADMIN_STAGING/pgAdmin\ 4/ $PGADMIN_STAGING/pgAdmin4
    cd $PGSERVER_STAGING

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $REMOTE_PGSERVER_STAGING" || _die "Failed to execute $REMOTE_PGSERVER_STAGING create_debug_symbols.sh"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $REMOTE_PGADMIN_STAGING" || _die "Failed to execute $REMOTE_PGADMIN_STAGING create_debug_symbols.sh"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $REMOTE_SB_STAGING" || _die "Failed to execute $REMOTE_SB_STAGING create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/server ];
    then
        echo "Removing existing $WD/output/symbols/linux/server directory"
        rm -rf $WD/output/symbols/linux/server  || _die "Couldn't remove the existing $WD/output/symbols/linux/server directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $PGSERVER_STAGING/symbols $WD/output/symbols/linux/server || _die "Failed to move $PGSERVER_STAGING/symbols to $WD/output/symbols/linux/server"
    mv $PGADMIN_STAGING/pgAdmin4 $PGADMIN_STAGING/pgAdmin\ 4/

    #create Commandlinetools
    echo "Creating Commandlinetools"
    mkdir -p $CLT_STAGING/bin || _die "Failed to create the $CLT_STAGING/bin directory"
    mkdir -p $CLT_STAGING/lib || _die "Failed to create the $CLT_STAGING/lib directory"
    mkdir -p $CLT_STAGING/share/man/man1 || _die "Failed to create the $CLT_STAGING/share/man/man1 directory"

    mv $PGSERVER_STAGING/bin/psql*  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/bin/psql"
    mv $PGSERVER_STAGING/lib  $CLT_STAGING || _die "Failed to move $PGSERVER_STAGING/lib"
    mv $PGSERVER_STAGING/bin/pg_basebackup  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/bin/pg_basebackup"
    mv $PGSERVER_STAGING/bin/pg_dump  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/bin/pg_dump"
    mv $PGSERVER_STAGING/bin/pg_dumpall  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/bin/pg_dumpall"
    mv $PGSERVER_STAGING/bin/pg_restore  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/pg_restore"
    mv $PGSERVER_STAGING/bin/createdb  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/createdb"
    mv $PGSERVER_STAGING/bin/clusterdb $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/clusterdb"
    mv $PGSERVER_STAGING/bin/createuser  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/createuser"
    mv $PGSERVER_STAGING/bin/dropuser  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/dropuser"
    mv $PGSERVER_STAGING/bin/dropdb  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/dropdb"
    mv $PGSERVER_STAGING/bin/pg_isready  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/pg_isready"
    mv $PGSERVER_STAGING/bin/vacuumdb  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/vacuumdb"
    mv $PGSERVER_STAGING/bin/reindexdb  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/reindexdb"
    mv $PGSERVER_STAGING/bin/pgbench  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/pgbench"
    mv $PGSERVER_STAGING/bin/vacuumlo  $CLT_STAGING/bin/ || _die "Failed to move $PGSERVER_STAGING/server/bin/vacuumlo"
    mv $PGSERVER_STAGING/share/man/man1/pg_basebackup.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/pg_dump.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/pg_restore.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/createdb.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/clusterdb.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/createuser.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/dropdb.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/dropuser.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/pg_isready.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/vacuumdb.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/reindexdb.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/pgbench.1 $CLT_STAGING/share/man/man1
    mv $PGSERVER_STAGING/share/man/man1/vacuumlo.1 $CLT_STAGING/share/man/man1

    #Restructure stackbuilder lib
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libiconv.so*  $REMOTE_SB_STAGING/lib/"  ||  _die "Failed to copy /opt/local/Current/lib/libiconv.so*"

    touch $PGADMIN_STAGING/pgAdmin\ 4/venv/lib/python2.7/site-packages/backports/__init__.py || _die "Failed to tocuh the __init__.py"
    cd $WD
    echo "END BUILD Server Linux"
}


################################################################################
# Post process
################################################################################

_postprocess_server_linux() {
    echo "BEGIN POST Server Linux"

    cd $WD/server

    pushd staging/linux
    generate_3rd_party_license "server"
    popd

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$PGSERVER_STAGING/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/edblogo.png" "$PGSERVER_STAGING/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $PGSERVER_STAGING/pgsql || _die "Failed to create the directory for binaries "
    cd $PGSERVER_STAGING
    cp -pR $PGSERVER_STAGING/bin $PGSERVER_STAGING/doc $PGSERVER_STAGING/include $CLT_STAGING/lib $PGADMIN_STAGING/pgAdmin* $PGSERVER_STAGING/share $SB_STAGING/ pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    tar -czf postgresql-$PG_PACKAGE_VERSION-linux-binaries.tar.gz pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-linux-binaries.tar.gz $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p $PGSERVER_STAGING/installer/server || _die "Failed to create a directory for the install scripts"
    cp $WD/server/scripts/linux/getlocales/getlocales.linux $PGSERVER_STAGING/installer/server/getlocales || _die "Failed to copy getlocales utility in the staging directory"
    chmod ugo+x $PGSERVER_STAGING/installer/server/getlocales
    cp $WD/server/scripts/linux/prerun_checks.sh $PGSERVER_STAGING/installer/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
    chmod ugo+x $PGSERVER_STAGING/installer/server/prerun_checks.sh
    cp scripts/linux/runpgcontroldata.sh $PGSERVER_STAGING/installer/server/runpgcontroldata.sh || _die "Failed to copy the runpgcontroldata script (scripts/linux/runpgcontroldata.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/runpgcontroldata.sh
    cp scripts/linux/createuser.sh $PGSERVER_STAGING/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/linux/createuser.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/createuser.sh
    cp scripts/linux/initcluster.sh $PGSERVER_STAGING/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/linux/initcluster.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/initcluster.sh
    cp scripts/linux/startupcfg.sh $PGSERVER_STAGING/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/startupcfg.sh
    cp scripts/linux/createshortcuts.sh $PGSERVER_STAGING/installer/server/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/createshortcuts.sh
    cp scripts/linux/createshortcuts_server.sh $PGSERVER_STAGING/installer/server/createshortcuts_server.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/createshortcuts_server.sh
    cp scripts/linux/removeshortcuts.sh $PGSERVER_STAGING/installer/server/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/removeshortcuts.sh
    cp scripts/linux/startserver.sh $PGSERVER_STAGING/installer/server/startserver.sh || _die "Failed to copy the startserver script (scripts/linux/startserver.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/startserver.sh
    cp scripts/linux/loadmodules.sh $PGSERVER_STAGING/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/linux/loadmodules.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/loadmodules.sh
    cp scripts/linux/config_libs.sh $PGSERVER_STAGING/installer/server/config_libs.sh || _die "Failed to copy the cleanlib script (scripts/linux/test.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/config_libs.sh


    mkdir -p $SB_STAGING/installer/server || _die "Failed to create a directory for the install scripts"
    mkdir -p $PGADMIN_STAGING/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/createshortcuts_sb.sh $SB_STAGING/installer/server/createshortcuts_sb.sh || _die "Failed to copy the createshortcuts script createshortcuts_sb.sh)"
    chmod ugo+x $SB_STAGING/installer/server/createshortcuts_sb.sh

    cp scripts/linux/createshortcuts_pgadmin.sh $PGADMIN_STAGING/installer/server/createshortcuts_pgadmin.sh || _die "Failed to copy the createshortcuts createshortcuts_pgadmin.sh)"
    chmod ugo+x $PGADMIN_STAGING/installer/server/createshortcuts_pgadmin.sh

    cp scripts/linux/createshortcuts.sh $PGSERVER_STAGING/installer/server/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x $PGSERVER_STAGING/installer/server/createshortcuts.sh

    # Copy the XDG scripts
    mkdir -p $PGSERVER_STAGING/installer/xdg || _die "Failed to create a directory for the $PGSERVER_STAGING/installer/xdg scripts"
    mkdir -p $PGADMIN_STAGING/installer/xdg || _die "Failed to create a directory for the $PGADMIN_STAGING/installer/xdg scripts"
    mkdir -p $SB_STAGING/installer/xdg || _die "Failed to create a directory for the $SB_STAGING/installer/xdg scripts"
    mkdir -p $CLT_STAGING/installer/xdg || _die "Failed to create a directory for the $CLT_STAGING/installer/xdg scripts"

    cp -pR $WD/scripts/xdg/xdg* $PGSERVER_STAGING/installer/xdg || _die "Failed to copy the xdg scripts ($PGSERVER_STAGING/scripts/xdg/xdg*)"
    cp -pR $WD/scripts/xdg/xdg* $PGADMIN_STAGING/installer/xdg || _die "Failed to copy the xdg scripts ($PGADMIN_STAGING/scripts/xdg/xdg*)"
    cp -pR $WD/scripts/xdg/xdg* $SB_STAGING/installer/xdg || _die "Failed to copy the xdg scripts ($SB_STAGING/scripts/xdg/xdg*)"
    cp -pR $WD/scripts/xdg/xdg* $CLT_STAGING/installer/xdg || _die "Failed to copy the xdg scripts ($CLT_STAGING/scripts/xdg/xdg*)"

    find . -name "xdg*" -exec chmod ugo+x {} \;
    
    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`

    # Copy in the menu pick images and XDG items
    mkdir -p $PGSERVER_STAGING/scripts/images || _die "Failed to create a directory $PGSERVER_STAGING/scripts/images for the menu pick images"
    mkdir -p $PGADMIN_STAGING/scripts/images || _die "Failed to create a directory $PGADMIN_STAGING/scripts/images for the menu pick images"
    mkdir -p $SB_STAGING/scripts/images || _die "Failed to create a directory $SB_STAGING/scripts/images for the menu pick images"
    mkdir -p $CLT_STAGING/scripts/images || _die "Failed to create a directory $CLT_STAGING/scripts/images for the menu pick images"

    cp resources/pg-help.png $PGSERVER_STAGING/scripts/images/pg-help-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-postgresql.png $PGSERVER_STAGING/scripts/images/pg-postgresql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-psql.png $PGSERVER_STAGING/scripts/images/pg-psql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-psql.png $CLT_STAGING/scripts/images/pg-psql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-reload.png $PGSERVER_STAGING/scripts/images/pg-reload-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"

    cp resources/pg-pgadmin.png $PGADMIN_STAGING/scripts/images/pg-pgadmin-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"
    cp resources/pg-stackbuilder.png $SB_STAGING/scripts/images/pg-stackbuilder-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p $PGSERVER_STAGING/scripts/xdg || _die "Failed to create a directory $PGSERVER_STAGING/scripts/xdg for the menu pick images"
    mkdir -p $PGADMIN_STAGING/scripts/xdg || _die "Failed to create a directory $PGADMIN_STAGING/scripts/xdg for the menu pick images"
    mkdir -p $SB_STAGING/scripts/xdg || _die "Failed to create a directory $SB_STAGING/scripts/xdg for the menu pick images"
    mkdir -p $CLT_STAGING/scripts/xdg || _die "Failed to create a directory $CLT_STAGING/scripts/xdg for the menu pick images"

    cp resources/xdg/pg-postgresql.directory $PGSERVER_STAGING/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgresql.directory $CLT_STAGING/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-documentation.directory $PGSERVER_STAGING/scripts/xdg/pg-documentation-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-documentation.directory $CLT_STAGING/scripts/xdg/pg-documentation-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"

    cp resources/xdg/pg-doc-installationnotes.desktop $PGSERVER_STAGING/scripts/xdg/pg-doc-installationnotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql-releasenotes.desktop $PGSERVER_STAGING/scripts/xdg/pg-doc-postgresql-releasenotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql.desktop $PGSERVER_STAGING/scripts/xdg/pg-doc-postgresql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-pgadmin.desktop $PGADMIN_STAGING/scripts/xdg/pg-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-psql.desktop $PGSERVER_STAGING/scripts/xdg/pg-psql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-psql.desktop $CLT_STAGING/scripts/xdg/pg-psql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-reload.desktop $PGSERVER_STAGING/scripts/xdg/pg-reload-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    cp resources/xdg/pg-doc-pgadmin.desktop $PGADMIN_STAGING/scripts/xdg/pg-doc-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-stackbuilder.desktop $SB_STAGING/scripts/xdg/pg-stackbuilder-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"

    # Copy the launch scripts
    cp scripts/linux/launchpsql.sh $PGSERVER_STAGING/scripts/launchpsql.sh || _die "Failed to copy the launchpsql script (scripts/linux/launchpsql.sh)"
    chmod ugo+x $PGSERVER_STAGING/scripts/launchpsql.sh
    cp scripts/linux/launchsvrctl.sh $PGSERVER_STAGING/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x $PGSERVER_STAGING/scripts/launchsvrctl.sh
    cp scripts/linux/serverctl.sh $PGSERVER_STAGING/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x $PGSERVER_STAGING/scripts/serverctl.sh
    cp scripts/linux/runpsql.sh $PGSERVER_STAGING/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/linux/runpsql.sh)"
    chmod ugo+x $PGSERVER_STAGING/scripts/runpsql.sh
    cp scripts/linux/launchbrowser.sh $PGADMIN_STAGING/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x $PGSERVER_STAGING/scripts/launchbrowser.sh
    cp scripts/linux/launchpgadmin.sh $PGADMIN_STAGING/scripts/launchpgadmin.sh || _die "Failed to copy the launchpgadmin script (scripts/linux/launchpgadmin.sh)"
    chmod ugo+x $PGADMIN_STAGING/scripts/launchpgadmin.sh
    cp scripts/linux/launchstackbuilder.sh $SB_STAGING/scripts/launchstackbuilder.sh || _die "Failed to copy the launchstackbuilder script (scripts/linux/launchstackbuilder.sh)"
    chmod ugo+x $SB_STAGING/scripts/launchstackbuilder.sh
    cp scripts/linux/runstackbuilder.sh $SB_STAGING/scripts/runstackbuilder.sh || _die "Failed to copy the runstackbuilder script (scripts/linux/runstackbuilder.sh)"
    chmod ugo+x $SB_STAGING/scripts/runstackbuilder.sh
			
    PG_DATETIME_SETTING_LINUX="64-bit integers"

    if [ -f installer-linux.xml ]; then
        rm -f installer-linux.xml
    fi
    cp installer.xml installer-linux.xml

    _replace @@PG_DATETIME_SETTING_LINUX@@ "$PG_DATETIME_SETTING_LINUX" installer-linux.xml || _die "Failed to replace the date-time setting in the installer.xml"     
    _replace @@WIN64MODE@@ "0" installer-linux.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "" installer-linux.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"

    # Copy plLanguages.config
    mkdir -p $PGSERVER_STAGING/etc/sysconfig || _die "Failed to create etc/sysconfig directory"
    cp $WD/server/scripts/common/plLanguages.config $PGSERVER_STAGING/etc/sysconfig || _die "Failed to copy plLanguages.config in etc/sysconfig directory"
    cp $WD/server/scripts/common/loadplLanguages.sh $PGSERVER_STAGING/etc/sysconfig || _die "Failed to copy loadplLanguages.sh in etc/sysconfig directory"

    _replace PERL_PACKAGE_VERSION $PG_VERSION_PERL $PGSERVER_STAGING/etc/sysconfig/plLanguages.config || _die "Failed to set the PERL version in config file."
    _replace PYTHON_PACKAGE_VERSION $PG_VERSION_PYTHON $PGSERVER_STAGING/etc/sysconfig/plLanguages.config || _die "Failed to set the PYTHON version in config file."
    _replace TCL_PACKAGE_VERSION $PG_VERSION_TCL $PGSERVER_STAGING/etc/sysconfig/plLanguages.config || _die "Failed to set the TCL version in config file."
    # Set permissions to all files and folders in staging
    _set_permissions linux

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-linux.xml linux || _die "Failed to build the installer"
	
	# Rename the installer
	mv $WD/output/postgresql-$PG_MAJOR_VERSION-linux-installer.run $WD/output/postgresql-$PG_PACKAGE_VERSION-linux.run || _die "Failed to rename the installer"

    cd $WD
    echo "END POST Server Linux"
}


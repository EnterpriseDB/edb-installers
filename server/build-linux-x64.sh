#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_server_linux_x64() {
    
    echo "BEGIN PREP Server Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.linux-x64 ];
    then
      echo "Removing existing postgres.linux-x64 source directory"
      rm -rf postgres.linux-x64  || _die "Couldn't remove the existing postgres.linux-x64 source directory (source/postgres.linux-x64)"
    fi
   
    # Grab a copy of the source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.linux-x64 || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
 
    if [ -e pgadmin.linux-x64 ];
    then
      echo "Removing existing pgadmin.linux-x64 source directory"
      rm -rf pgadmin.linux-x64  || _die "Couldn't remove the existing pgadmin.linux-x64 source directory (source/pgadmin.linux-x64)"
    fi

    # Grab a copy of the source tree
    cp -pR pgadmin3-$PG_TARBALL_PGADMIN pgadmin.linux-x64 || _die "Failed to copy the source code (source/pgadmin-$PG_TARBALL_PGADMIN)"

    if [ -e stackbuilder.linux-x64 ];
    then
      echo "Removing existing stackbuilder.linux-x64 source directory"
      rm -rf stackbuilder.linux-x64  || _die "Couldn't remove the existing stackbuilder.linux-x64 source directory (source/stackbuilder.linux-x64)"
    fi

    # Grab a copy of the stackbuilder source tree
    cp -pR stackbuilder stackbuilder.linux-x64 || _die "Failed to copy the source code (source/stackbuilder)"	
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/linux-x64)"
    mkdir -p $WD/server/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/server/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

    if [ -f $WD/server/scripts/linux/getlocales/getlocales.linux-x64 ]; then
      rm -f $WD/server/scripts/linux/getlocales/getlocales.linux-x64
    fi
    
    echo "END PREP Server Linux-x64"
}


_process_dependent_libs_linux_x64() {

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

   export LD_LIBRARY_PATH=$lib_dir

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
        cp /tmp/templibs/* $lib_dir/     || _die "Failed to move the library files from temp directory"
    fi

    # Remove the temporary directory 
    rm -rf /tmp/templibs  

EOT

   chmod ugo+x process_dependent_libs.sh  || _die "Failed to change permissions"
   scp process_dependent_libs.sh $PG_SSH_LINUX_X64:$PG_PATH_LINUX_X64

   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; sh process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}

################################################################################
# Build
################################################################################

_build_server_linux_x64() {
    
    echo "BEGIN BUILD Server Linux-x64"

    # First build PostgreSQL

    PG_STAGING=$PG_PATH_LINUX_X64/server/staging/linux-x64
    
    # Configure the source tree
    echo "Configuring the postgres source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/;export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; PYTHON=$PG_PYTHON_LINUX_X64/bin/python3.2 TCLSH=$PG_TCL_LINUX_X64/bin/tclsh TCL_CONFIG_SH=$PG_TCL_LINUX_X64/lib/tclConfig.sh PERL=$PG_PERL_LINUX_X64/bin/perl ./configure --with-libs=/usr/local/lib --with-includes=/usr/local/include/libxml2:/usr/local/include --prefix=$PG_STAGING --with-ldap --with-openssl --with-perl --with-python --with-tcl --with-tclconfig=$PG_TCL_LINUX_X64/lib --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-gssapi LD_LIBRARY_PATH=/usr/local/lib"  || _die "Failed to configure postgres"

    echo "Building postgres"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64; export LD_LIBRARY_PATH=/usr/local/lib; make -j4" || _die "Failed to build postgres" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64; export LD_LIBRARY_PATH=/usr/local/lib; make install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib; export LD_LIBRARY_PATH=/usr/local/lib; make" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib; LD_LIBRARY_PATH=/usr/local/lib make install" || _die "Failed to install the postgres contrib modules"

    echo "Building debugger module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/pldebugger; export LD_LIBRARY_PATH=/usr/local/lib; make" || _die "Failed to build the debugger module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/pldebugger; LD_LIBRARY_PATH=/usr/local/lib make install" || _die "Failed to install the debugger module"
	if [ ! -e $WD/server/staging/linux-x64/doc ];
	then
	    mkdir -p $WD/server/staging/linux-x64/doc || _die "Failed to create the doc directory"
	fi
    cp "$WD/server/source/postgres.linux-x64/contrib/pldebugger/README.pldebugger" $WD/server/staging/linux-x64/doc || _die "Failed to copy the debugger README into the staging directory"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/uuid-ossp; export LD_LIBRARY_PATH=/usr/local/lib; make" || _die "Failed to build the uuid-ossp module"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/uuid-ossp; make install" || _die "Failed to install the uuid-ossp module"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/linux-x64/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/linux-x64/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.linux-x64/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $WD/server/staging/linux-x64/share/man || _die "Failed to create the man directory"
    cd $WD/server/staging/linux-x64/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.linux-x64/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (linux-x64)"
    cp -pR $WD/server/source/postgres.linux-x64/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (linux-x64)"
    cp -pR $WD/server/source/postgres.linux-x64/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (linux-x64)"

    # Copy the third party headers
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/openssl $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/libxml2 $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/libxslt $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/sasl $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/krb5 $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp -r /usr/local/include/gssapi $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/iconv.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/uuid.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/zlib.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/krb5.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/ncurses*.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/gssapi.h $PG_STAGING/include" || _die "Failed to copy the required header"
    ssh $PG_SSH_LINUX_X64 "cp /usr/local/include/ldap*.h $PG_STAGING/include" || _die "Failed to copy the required header"
    # Removing third party GPL license headres
    ssh $PG_SSH_LINUX_X64 "find $PG_STAGING/include -name '*.h' | xargs grep -rwl 'GNU General Public License\|GNU Library General Public' | grep -v 'gram.h' | xargs rm " || _die "Failed to remove GPL license headers."

    # Copy in the dependency libraries
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libz.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libkrb5support* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libk5crypto* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libcom* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libgssapi* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libncurses.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libuuid.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libiconv.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/liblber-2.4.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library(lber)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libsasl2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library(sasl)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libldap-2.4.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library(ldap)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libldap_r-2.4.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library(ldap_r)"

    # Process Dependent libs
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libssl"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libcrypto"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libedit"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libz"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5.so"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5support"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libk5crypto"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libcom"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libgssapi"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libncurses"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libxml2"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/lib/postgresql" "$PG_STAGING/lib" "libxslt.so"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/lib/postgresql" "$PG_STAGING/lib" "libuuid.so"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libiconv"  
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "liblber-2.4"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libsasl2"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libldap-2.4"
    _process_dependent_libs_linux_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libldap_r-2.4"

    # Hack for bypassing dependency on the deprecated libtermcap
    # As libnucurses is API compatible with the termcap so we copy libtermcap and then just
    # create a symlink libtermcap.so pointing to libncurses.
    cd $WD/server/staging/linux-x64/lib

    ln -s libncurses.so libtermcap.so

    # Copying psql to psql.bin and the creating a caller script psql
    # which will set the LD_PRELOAD to libreadline if found on the system.
    cd $WD/server/staging/linux-x64/bin
    mv psql psql.bin
    cat <<EOT > psql
#!/bin/bash

# If there's an OS supplied version of libreadline, try to make use of it,
# as it's more reliable than libedit, which we link with.
PLL=""
if [ -f /lib64/libreadline.so.6 ];
then
    PLL=/lib64/libreadline.so.6
elif [ -f /lib64/libreadline.so.5 ];
then
    PLL=\$PLL:/lib64/libreadline.so.5
elif [ -f /lib/libreadline.so.6 ];
then
    PLL=\$PLL:/lib/libreadline.so.6
elif [ -f /lib/libreadline.so.5 ];
then
    PLL=\$PLL:/lib/libreadline.so.5
fi
# Get the PG bin directory path relative to psql caller script.
PG_BIN_PATH=\`dirname "\$0"\`

if [ -z "\$PLL" ];
then
	LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$PG_BIN_PATH/../lib "\$PG_BIN_PATH/psql.bin" "\$@"
else
	LD_PRELOAD=\$PLL LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$PG_BIN_PATH/../lib "\$PG_BIN_PATH/psql.bin" "\$@"
fi

EOT
    chmod a+x psql || _die "Failed to grant execute permission to psql script"

    # Now build pgAdmin

    # Bootstrap
    echo "Bootstrapping the build system"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; sh bootstrap"

    # Configure
    echo "Configuring the pgAdmin source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; LD_LIBRARY_PATH="/usr/local/lib" CPPFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" ./configure --prefix=$PG_STAGING/pgAdmin3 --with-pgsql=$PG_PATH_LINUX_X64/server/staging/linux-x64 --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static --with-sphinx-build=$PG_PYTHON_LINUX_X64/bin/sphinx-build" || _die "Failed to configure pgAdmin"

    # Build the app
    echo "Building & installing pgAdmin"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; LD_LIBRARY_PATH="/usr/local/lib" make all" || _die "Failed to build pgAdmin"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; make doc" || _die "Failed to build documentation for pgAdmin"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/pgadmin.linux-x64/; make install" || _die "Failed to install pgAdmin"

    # Copy in the various libraries
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_STAGING/pgAdmin3/lib" || _die "Failed to create the lib directory"

    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_adv-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_aui-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_core-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_html-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_ogl-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_qa-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_richtext-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_stc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_gtk2u_xrc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_baseu-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_baseu_net-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libwx_baseu_xml-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libexpat.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/lib64/libpng12.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libtiff.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libjpeg.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libfreetype.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_LINUX_X64 "cp -pR /usr/local/lib/libfontconfig.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"

    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PATH_LINUX_X64/server/staging/linux-x64/lib/libpq.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"


    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_adv-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_aui-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_core-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_html-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_ogl-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_qa-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_richtext-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_stc-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_gtk2u_xrc-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_baseu-2.8.so"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_baseu_net-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libwx_baseu_xml-2.8"
    _process_dependent_libs_linux_x64 "$PG_STAGING/pgAdmin3/bin" "$PG_STAGING/pgAdmin3/lib" "libpq"

    echo "Changing the rpath for the pgAdmin binaries"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/pgAdmin3/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"

    #Fix permission in the staging/linux-x64/pgAdmin3/lib
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/pgAdmin3/lib; chmod a+r *"

    # Copy the Postgres utilities
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_dump $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_dumpall $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/pg_restore $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PATH_LINUX_X64/server/staging/linux-x64/bin/psql* $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"

    echo "Changing the rpath for the PostgreSQL executables and libraries"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/lib/postgresql; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/..\" \$f; done"

    #Fix permission in the staging/linux-x64/lib
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/lib; chmod a+r *"

    #Fix permission in the staging/linux/share
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/share/postgresql/timezone; chmod -R a+r *"

    # Stackbuilder
	
    # Configure
    echo "Configuring the StackBuilder source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_STAGING/stackbuilder ."

    # Build the app
    echo "Building & installing StackBuilder"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; make all" || _die "Failed to build StackBuilder"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/stackbuilder.linux-x64/; make install" || _die "Failed to install StackBuilder"

    echo "Changing the rpath for the StackBuilder"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/stackbuilder/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../../lib:\\\\${ORIGIN}/../../pgAdmin3/lib\" \$f; done"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/scripts/linux/getlocales; gcc -o getlocales.linux-x64 -O0 getlocales.c" || _die "Failed to build getlocale utility"

    cd $WD

    echo "END BUILD Server Linux-x64"
}


################################################################################
# Post process
################################################################################

_postprocess_server_linux_x64() {

    echo "BEGIN POST Server Linux-x64"

    cd $WD/server

    pushd staging/linux-x64
    generate_3rd_party_license "server"
    popd
    mv $WD/server/staging/linux-x64/server_3rd_party_licenses.txt $WD/server/staging/linux-x64/3rd_party_licenses.txt

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/linux-x64/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/linux-x64/doc/" || _die "Failed to install the welcome logo"
    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/linux-x64/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/linux-x64
    cp -pR bin doc include lib pgAdmin3 share stackbuilder pgsql/ || _die "Failed to copy the binaries to the pgsql directory"

    tar -czf postgresql-$PG_PACKAGE_VERSION-linux-x64-binaries.tar.gz pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-linux-x64-binaries.tar.gz $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p staging/linux-x64/installer/server || _die "Failed to create a directory for the install scripts"
    cp $WD/server/scripts/linux/getlocales/getlocales.linux-x64 $WD/server/staging/linux-x64/installer/server/getlocales || _die "Failed ot copy getlocales utility to staging directory"
    chmod ugo+x $WD/server/staging/linux-x64/installer/server/getlocales
    cp $WD/server/scripts/linux/prerun_checks.sh $WD/server/staging/linux-x64/installer/server/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
    chmod ugo+x $WD/server/staging/linux-x64/installer/server/prerun_checks.sh

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
    cp -pR $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*
    
    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    
    cp resources/pg-help.png staging/linux-x64/scripts/images/pg-help-$PG_VERSION_STR.png || _die "Failed to copy a menu pick im
age"
    cp resources/pg-pgadmin.png staging/linux-x64/scripts/images/pg-pgadmin-$PG_VERSION_STR.png || _die "Failed to copy a menu p
ick image"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images/pg-postgresql-$PG_VERSION_STR.png || _die "Failed to copy a
menu pick image"
    cp resources/pg-psql.png staging/linux-x64/scripts/images/pg-psql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick im
age"
    cp resources/pg-reload.png staging/linux-x64/scripts/images/pg-reload-$PG_VERSION_STR.png || _die "Failed to copy a menu pic
k image"
    cp resources/pg-stackbuilder.png staging/linux-x64/scripts/images/pg-stackbuilder-$PG_VERSION_STR.png || _die "Failed to cop
y a menu pick image"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"


    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-documentation.directory staging/linux-x64/scripts/xdg/pg-documentation-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"

    cp resources/xdg/pg-doc-installationnotes.desktop staging/linux-x64/scripts/xdg/pg-doc-installationnotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-pgadmin.desktop staging/linux-x64/scripts/xdg/pg-doc-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-pljava-readme.desktop staging/linux-x64/scripts/xdg/pg-doc-pljava-readme-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-pljava.desktop staging/linux-x64/scripts/xdg/pg-doc-pljava-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql-releasenotes.desktop staging/linux-x64/scripts/xdg/pg-doc-postgresql-releasenotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-doc-postgresql.desktop staging/linux-x64/scripts/xdg/pg-doc-postgresql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-pgadmin.desktop staging/linux-x64/scripts/xdg/pg-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-psql.desktop staging/linux-x64/scripts/xdg/pg-psql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    cp resources/xdg/pg-reload.desktop staging/linux-x64/scripts/xdg/pg-reload-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
	cp resources/xdg/pg-stackbuilder.desktop staging/linux-x64/scripts/xdg/pg-stackbuilder-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
    
    # Copy the launch scripts
    cp scripts/linux/launchpsql.sh staging/linux-x64/scripts/launchpsql.sh || _die "Failed to copy the launchpsql script (scripts/linux/launchpsql.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchpsql.sh
    cp scripts/linux/launchsvrctl.sh staging/linux-x64/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/linux/launchsvrctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchsvrctl.sh
    cp scripts/linux/serverctl.sh staging/linux-x64/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/linux/serverctl.sh)"
    chmod ugo+x staging/linux-x64/scripts/serverctl.sh
    cp scripts/linux/runpsql.sh staging/linux-x64/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/linux/runpsql.sh)"
    chmod ugo+x staging/linux-x64/scripts/runpsql.sh
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh
    cp scripts/linux/launchpgadmin.sh staging/linux-x64/scripts/launchpgadmin.sh || _die "Failed to copy the launchpgadmin script (scripts/linux/launchpgadmin.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchpgadmin.sh
    cp scripts/linux/launchstackbuilder.sh staging/linux-x64/scripts/launchstackbuilder.sh || _die "Failed to copy the launchstackbuilder script (scripts/linux/launchstackbuilder.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchstackbuilder.sh
    cp scripts/linux/runstackbuilder.sh staging/linux-x64/scripts/runstackbuilder.sh || _die "Failed to copy the runstackbuilder script (scripts/linux/runstackbuilder.sh)"
    chmod ugo+x staging/linux-x64/scripts/runstackbuilder.sh
		
    PG_DATETIME_SETTING_LINUX_X64=`cat staging/linux-x64/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_LINUX_X64" = "x" ]
    then
          PG_DATETIME_SETTING_LINUX_X64="floating-point numbers"
    else
          PG_DATETIME_SETTING_LINUX_X64="64-bit integers"
    fi
    if [ -f installer-lin64.xml ]; then
        rm -f installer-lin64.xml
    fi
    cp installer.xml installer-lin64.xml

    _replace @@PG_DATETIME_SETTING_LINUX_X64@@ "$PG_DATETIME_SETTING_LINUX_X64" installer-lin64.xml || _die "Failed to replace the date-time setting in the installer.xml"
    _replace @@WIN64MODE@@ "0" installer-lin64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "" installer-lin64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-lin64.xml linux-x64 || _die "Failed to build the installer"

	# Rename the installer
	mv $WD/output/postgresql-$PG_MAJOR_VERSION-linux-x64-installer.run $WD/output/postgresql-$PG_PACKAGE_VERSION-linux-x64.run || _die "Failed to rename the installer"

    cd $WD
    
    echo "END POST Server Linux-x64"
}


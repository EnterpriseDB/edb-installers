#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_solaris_sparc() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.solaris-sparc ];
    then
      echo "Removing existing postgres.solaris-sparc source directory"
      rm -rf postgres.solaris-sparc  || _die "Couldn't remove the existing postgres.solaris-sparc source directory (source/postgres.solaris-sparc)"
    fi
 
    if [ -e postgres.solaris-sparc.zip ];
    then
      echo "Removing existing postgres.solaris-sparc zip file"
      rm -rf postgres.solaris-sparc.zip  || _die "Couldn't remove the existing postgres.solaris-sparc zip file (source/postgres.solaris-sparc.zip)"
    fi
   
    # Grab a copy of the source tree
    cp -pR postgresql-$PG_TARBALL_POSTGRESQL postgres.solaris-sparc || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL)"
    chmod -R ugo+w postgres.solaris-sparc || _die "Couldn't set the permissions on the source directory"
    zip -r postgres.solaris-sparc.zip postgres.solaris-sparc 
 
#    if [ -e pgadmin.solaris-sparc ];
#    then
#      echo "Removing existing pgadmin.solaris-sparc source directory"
#      rm -rf pgadmin.solaris-sparc  || _die "Couldn't remove the existing pgadmin.solaris-sparc source directory (source/pgadmin.solaris-sparc)"
#    fi
#
#    if [ -e pgadmin.solaris-sparc.zip ];
#    then
#      echo "Removing existing pgadmin.solaris-sparc zip file"
#      rm -rf pgadmin.solaris-sparc.zip  || _die "Couldn't remove the existing pgadmin.solaris-sparc zip file (source/pgadmin.solaris-sparc.zip)"
#    fi
#    # Grab a copy of the source tree
#    cp -pR pgadmin3-$PG_TARBALL_PGADMIN pgadmin.solaris-sparc || _die "Failed to copy the source code (source/pgadmin-$PG_TARBALL_PGADMIN)"
#    cd pgadmin.solaris-sparc/
#    patch -c -p0 < $WD/tarballs/pgadmin_solaris_acinclude.patch
#    cd ../
#    chmod -R ugo+w pgadmin.solaris-sparc || _die "Couldn't set the permissions on the source directory"
#    zip -r pgadmin.solaris-sparc.zip pgadmin.solaris-sparc
#
#    if [ -e pljava.solaris-sparc ];
#    then
#      echo "Removing existing pljava.solaris-sparc source directory"
#      rm -rf pljava.solaris-sparc  || _die "Couldn't remove the existing pljava.solaris-sparc source directory (source/pljava.solaris-sparc)"
#    fi
#
##    if [ -e pljava.solaris-sparc.zip ];
##    then
##      echo "Removing existing pljava.solaris-sparc zip file"
##      rm -rf pljava.solaris-sparc.zip  || _die "Couldn't remove the existing pljava.solaris-sparc zip file (source/pljava.solaris-sparc.zip)"
##    fi
##    # Grab a copy of the source tree
##    cp -pR pljava-$PG_TARBALL_PLJAVA pljava.solaris-sparc || _die "Failed to copy the source code (source/pljava-$PG_TARBALL_PLJAVA)"
##    chmod -R ugo+w pljava.solaris-sparc || _die "Couldn't set the permissions on the source directory"
##    zip -r pljava.solaris-sparc.zip pljava.solaris-sparc
#
#    if [ -e stackbuilder.solaris-sparc ];
#    then
#      echo "Removing existing stackbuilder.solaris-sparc source directory"
#      rm -rf stackbuilder.solaris-sparc  || _die "Couldn't remove the existing stackbuilder.solaris-sparc source directory (source/stackbuilder.solaris-sparc)"
#    fi
#
#    if [ -e stackbuilder.solaris-sparc.zip ];
#    then
#      echo "Removing existing stackbuilder.solaris-sparc zip file"
#      rm -rf stackbuilder.solaris-sparc.zip  || _die "Couldn't remove the existing stackbuilder.solaris-sparc zip file (source/stackbuilder.solaris-sparc.zip)"
#    fi
#    # Grab a copy of the stackbuilder source tree
#    cp -pR stackbuilder stackbuilder.solaris-sparc || _die "Failed to copy the source code (source/stackbuilder)"	
#    chmod -R ugo+w stackbuilder.solaris-sparc || _die "Couldn't set the permissions on the source directory"
#    cd stackbuilder.solaris-sparc
#    patch -p0 < $WD/tarballs/stackbuilder.patch
#    cd ..
#    zip -r stackbuilder.solaris-sparc.zip stackbuilder.solaris-sparc
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/server/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc" || _die "Falied to remove the staging directory on the Solaris VM"
    fi

    echo "Creating staging directory ($WD/server/staging/solaris-sparc)"
    mkdir -p $WD/server/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/server/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"

    # Send all the source to Solaris VM
    ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/server/source" || _die "Falied to remove the source directory on the Solaris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/server/source" || _die "Falied to create the source directory on the Solaris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc" || _die "Falied to create the staging directory on the Solaris VM"
    scp -r postgres.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/ || _die "Failed to scp the postgres source"
#    scp -r pgadmin.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/ || _die "Failed to scp the postgres source"
#    scp -r pljava.solaris-sparc.zip  $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/ || _die "Failed to scp the postgres source"
#    scp -r stackbuilder.solaris-sparc.zip  $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/ || _die "Failed to scp the postgres source"
#
#    if [ -f $WD/server/scripts/solaris/getlocales/getlocales.solaris-sparc ]; then
#      rm -f $WD/server/scripts/solaris/getlocales/getlocales.solaris-sparc
#      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/server/source/getlocales" || _die "Falied to remove the source directory on the Solaris VM"
#    fi
#    scp -r $WD/server/scripts/solaris/getlocales $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/ || _die "Failed to scp the getlocales source"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/server/source; unzip postgres.solaris-sparc.zip" || _die "Falied to remove the source directory on the Solaris VM"
#    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/server/source; unzip pgadmin.solaris-sparc.zip" || _die "Falied to remove the source directory on the Solaris VM"
#    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/server/source; unzip pljava.solaris-sparc.zip" || _die "Falied to remove the source directory on the Solaris VM"
#    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/server/source; unzip stackbuilder.solaris-sparc.zip" || _die "Falied to remove the source directory on the Solaris VM"

}


_process_dependent_libs_solaris_sparc() {

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

    # Copy libs from the tmp/templibs directory
    cp /tmp/templibs/* $lib_dir/     || _die "Failed to move the library files from temp directory"

    # Remove the temporary directory 
    rm -rf /tmp/templibs  

EOT

   chmod ugo+x process_dependent_libs.sh  || _die "Failed to change permissions"
   scp process_dependent_libs.sh $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC

   ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; ./process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}

################################################################################
# Build
################################################################################

_build_server_solaris_sparc() {

    # First build PostgreSQL

    cd $WD/server/source

    PG_STAGING=$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc

    cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64"
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local.sun/lib
export PATH=/usr/local.sun/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"
    
    # Configure the source tree
    echo "Configuring the postgres source tree"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/;./configure --prefix=$PG_STAGING --with-openssl --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred --with-libs=/usr/local.sun/lib --with-includes=/usr/local.sun/include/libxml2:/usr/local.sun/include"  || _die "Failed to configure postgres"

    echo "Building postgres"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc; gmake -j4" || _die "Failed to build postgres" 
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc; gmake install" || _die "Failed to install postgres"

    echo "Building contrib modules"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib; gmake" || _die "Failed to build the postgres contrib modules"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib; gmake install" || _die "Failed to install the postgres contrib modules"

    echo "Building debugger module"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib/pldebugger; gmake" || _die "Failed to build the debugger module"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib/pldebugger; gmake install" || _die "Failed to install the debugger module"
	if [ ! -e $WD/server/staging/solaris-sparc/doc ];
	then
	    mkdir -p $WD/server/staging/solaris-sparc/doc || _die "Failed to create the doc directory"
	fi
    cp "$WD/server/source/postgres.solaris-sparc/contrib/pldebugger/README.pldebugger" $WD/server/staging/solaris-sparc/doc || _die "Failed to copy the debugger README into the staging directory"

    echo "Building uuid-ossp module"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib/uuid-ossp; gmake" || _die "Failed to build the uuid-ossp module"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/postgres.solaris-sparc/contrib/uuid-ossp; gmake install" || _die "Failed to install the uuid-ossp module"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/solaris-sparc/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/solaris-sparc/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -pR $WD/server/source/postgres.solaris-sparc/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"

    # Install the PostgreSQL man pages
    mkdir -p $WD/server/staging/solaris-sparc/share/man || _die "Failed to create the man directory"
    cd $WD/server/staging/solaris-sparc/share/man || _die "Failed to change to the man directory"
    cp -pR $WD/server/source/postgres.solaris-sparc/doc/src/sgml/man1 man1 || _die "Failed to copy the PostgreSQL man pages (solaris-sparc)"
    cp -pR $WD/server/source/postgres.solaris-sparc/doc/src/sgml/man3 man3 || _die "Failed to copy the PostgreSQL man pages (solaris-sparc)"
    cp -pR $WD/server/source/postgres.solaris-sparc/doc/src/sgml/man7 man7 || _die "Failed to copy the PostgreSQL man pages (solaris-sparc)"

    # Copy in the dependency libraries
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libuuid.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libkrb5support.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local.sun/lib/libz.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"

    # Process Dependent libs
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libssl.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libcrypto.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libedit.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libxml2.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libxslt.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5support.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libk5crypto.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libcom_err.so"  
    _process_dependent_libs_solaris_sparc "$PG_STAGING/bin" "$PG_STAGING/lib" "libz.so"  

	
    # Now build pgAdmin

    # Bootstrap
#    echo "Bootstrapping the build system"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pgadmin.solaris-sparc/; sh bootstrap"
#
#    # Configure
#    echo "Configuring the pgAdmin source tree"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pgadmin.solaris-sparc/; ./configure --prefix=$PG_STAGING/pgAdmin3 --with-pgsql=$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc --with-wx=/usr/local --with-libxml2=/usr/local --with-libxslt=/usr/local --disable-debug --disable-static" || _die "Failed to configure pgAdmin"
#
#    # Build the app
#    echo "Building & installing pgAdmin"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pgadmin.solaris-sparc/xtra/png2c; sed -e 's/-lpq//g' Makefile > /tmp/Makefile.tmp; mv /tmp/Makefile.tmp Makefile" || _die "Failed to modify png2c makefile"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pgadmin.solaris-sparc/; gmake all" || _die "Failed to build pgAdmin"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pgadmin.solaris-sparc/; gmake install" || _die "Failed to install pgAdmin"
#
#    # Copy in the various libraries
#    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_STAGING/pgAdmin3/lib" || _die "Failed to create the lib directory"
#
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_adv-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_aui-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_core-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_html-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_ogl-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_qa-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_richtext-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_stc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_gtk2u_xrc-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_baseu-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_baseu_net-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libwx_baseu_xml-2.8.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/lib/libpq.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libxml2.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/local/lib/libxslt.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/sfw/lib/64/libexpat.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR /usr/lib/64/libtiff.so* $PG_STAGING/pgAdmin3/lib" || _die "Failed to copy the dependency library"
#
#    echo "Changing the rpath for the pgAdmin binaries"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_STAGING/pgAdmin3/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/../lib:/usr/sfw/lib/64\" \$f; done"
#
#    #Fix permission in the staging/solaris-sparc/pgAdmin3/lib
#    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_STAGING/pgAdmin3/lib; chmod a+r *"
#
#    # Copy the Postgres utilities
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin/pg_dump $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin/pg_dumpall $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin/pg_restore $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"
#    ssh $PG_SSH_SOLARIS_SPARC "cp -pR $PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin/psql $PG_STAGING/pgAdmin3/bin" || _die "Failed to copy the utility program"

    # Move the utilties.ini file out of the way (Uncomment for Postgres Studio or 1.9+)
    # ssh $PG_SSH_SOLARIS_SPARC "mv $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini $PG_STAGING/pgAdmin3/share/pgadmin3/plugins/utilities.ini.new" || _die "Failed to move the utilties.ini file"
     
    # And now, pl/java

#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pljava.solaris-sparc/; JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC PATH=$PG_EXEC_PATH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin:\$PATH LD_LIBRARY_PATH=$PG_JAVA_HOME_SOLARIS_SPARC/jre/lib/sparcv9/server:$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/lib:\$LD_LIBRARY_PATH gmake USE_JDK6=1 all" || _die "Failed to build pl/java"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/pljava.solaris-sparc/; JAVA_HOME=$PG_JAVA_HOME_SOLARIS_SPARC PATH=$PG_EXEC_PATH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/bin:\$PATH LD_LIBRARY_PATH=$PG_JAVA_HOME_SOLARIS_SPARC/jre/lib/sparcv9/server:$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/lib:\$LD_LIBRARY_PATH gmake prefix=$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc install" || _die "Failed to install pl/java" 
#
#    mkdir -p "$WD/server/staging/solaris-sparc/share/pljava" || _die "Failed to create the pl/java share directory"
#    cp "$WD/server/source/pljava.solaris-sparc/src/sql/install.sql" "$WD/server/staging/solaris-sparc/share/pljava/pljava.sql" || _die "Failed to install the pl/java installation SQL script"
#    cp "$WD/server/source/pljava.solaris-sparc/src/sql/uninstall.sql" "$WD/server/staging/solaris-sparc/share/pljava/uninstall_pljava.sql" || _die "Failed to install the pl/java uninstallation SQL script"
#
#    mkdir -p "$WD/server/staging/solaris-sparc/doc/pljava" || _die "Failed to create the pl/java doc directory"
#    cp "$WD/server/source/pljava.solaris-sparc/docs/"* "$WD/server/staging/solaris-sparc/doc/pljava/" || _die "Failed to install the pl/java documentation"
 
    echo "Changing the rpath for the PostgreSQL executables and libraries"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_STAGING/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/../lib:/usr/sfw/lib/64\" \$f; done"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_STAGING/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN:/usr/sfw/lib/64\" \$f; done"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_STAGING/lib/postgresql; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/..:/usr/sfw/lib/64\" \$f; done"

    #Fix permission in the staging/solaris-sparc/lib
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_STAGING/lib; chmod a+r *"

    #Fix permission in the staging/solaris-sparc/share
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_STAGING/share/postgresql/timezone; chmod -R a+r *"

    # Stackbuilder
	
    # Configure
#    echo "Configuring the StackBuilder source tree"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/stackbuilder.solaris-sparc/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_INSTALL_PREFIX:PATH=$PG_STAGING/stackbuilder -D CMAKE_CXX_FLAGS:STRING=\"-m64\" ."
#
#    # Build the app
#    echo "Building & installing StackBuilder"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/stackbuilder.solaris-sparc/; gmake all" || _die "Failed to build StackBuilder"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/stackbuilder.solaris-sparc/; gmake install" || _die "Failed to install StackBuilder"
#
#    echo "Changing the rpath for the StackBuilder"
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_STAGING/stackbuilder/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/../../lib:\\\$ORIGIN/../../pgAdmin3/lib:/usr/sfw/lib/64\" \$f; done"
#
#
#    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/server/source/getlocales; gcc -m64 -o getlocales.solaris-sparc -O0 getlocales.c" || _die "Failed to build getlocale utility"

    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/staging/solaris-sparc/* $WD/server/staging/solaris-sparc/ || _die "Failed to get the staging directory"
#    scp $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/server/source/getlocales/getlocales.solaris-sparc $WD/server/scripts/solaris/getlocales/ || _die "Failed to build the getlocales utility"
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_solaris_sparc() {

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/solaris-sparc/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/solaris-sparc/doc/" || _die "Failed to install the welcome logo"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/solaris-sparc/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/solaris-sparc
#    cp -pR bin doc include lib pgAdmin3 share stackbuilder pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
    cp -pR bin doc include lib share pgsql/ || _die "Failed to copy the binaries to the pgsql directory"
#
    tar -czf postgresql-$PG_PACKAGE_VERSION-solaris-sparc-binaries.tar.gz pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-solaris-sparc-binaries.tar.gz $WD/output/ || _die "Failed to move the archive to output folder"
#
    rm -rf pgsql || _die "Failed to remove the binaries directory" 

#    cd $WD/server
#
#    # Setup the installer scripts. 
#    mkdir -p staging/solaris-sparc/installer/server || _die "Failed to create a directory for the install scripts"
#    cp $WD/server/scripts/solaris/getlocales/getlocales.solaris-sparc $WD/server/staging/solaris-sparc/installer/server/getlocales || _die "Failed ot copy getlocales utility to staging directory"
#    chmod ugo+x $WD/server/staging/solaris-sparc/installer/server/getlocales
#
#    cp $WD/server/scripts/linux/prerun_checks.sh $WD/server/staging/solaris-sparc/installer/server/prerun_checks.sh || _die "Failed to copy the prerun_checks.sh script"
#    chmod ugo+x $WD/server/staging/solaris-sparc/installer/server/prerun_checks.sh
#
#    cp scripts/solaris/runpgcontroldata.sh staging/solaris-sparc/installer/server/runpgcontroldata.sh || _die "Failed to copy the runpgcontroldata script (scripts/solaris/runpgcontroldata.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/runpgcontroldata.sh
#
#    cp scripts/solaris/createuser.sh staging/solaris-sparc/installer/server/createuser.sh || _die "Failed to copy the createuser script (scripts/solaris/createuser.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/createuser.sh
#    cp scripts/solaris/initcluster.sh staging/solaris-sparc/installer/server/initcluster.sh || _die "Failed to copy the initcluster script (scripts/solaris/initcluster.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/initcluster.sh
#    cp scripts/solaris/startupcfg.sh staging/solaris-sparc/installer/server/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/solaris/startupcfg.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/startupcfg.sh
#    cp scripts/solaris/createshortcuts.sh staging/solaris-sparc/installer/server/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/solaris/createshortcuts.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/createshortcuts.sh
#    cp scripts/solaris/removeshortcuts.sh staging/solaris-sparc/installer/server/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/removeshortcuts.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/removeshortcuts.sh
#    cp scripts/solaris/startserver.sh staging/solaris-sparc/installer/server/startserver.sh || _die "Failed to copy the startserver script (scripts/solaris/startserver.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/startserver.sh
#    cp scripts/solaris/loadmodules.sh staging/solaris-sparc/installer/server/loadmodules.sh || _die "Failed to copy the loadmodules script (scripts/solaris/loadmodules.sh)"
#    chmod ugo+x staging/solaris-sparc/installer/server/loadmodules.sh
#
#    # Copy the XDG scripts
#    mkdir -p staging/solaris-sparc/installer/xdg || _die "Failed to create a directory for the xdg scripts"
#    cp -pR $WD/scripts/xdg/xdg* staging/solaris-sparc/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
#    chmod ugo+x staging/solaris-sparc/installer/xdg/xdg*
#    
#    # Version string, for the xdg filenames
#    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
#
#    # Copy in the menu pick images and XDG items
#    mkdir -p staging/solaris-sparc/scripts/images || _die "Failed to create a directory for the menu pick images"
#    
#    cp resources/pg-help.png staging/solaris-sparc/scripts/images/pg-help-$PG_VERSION_STR.png || _die "Failed to copy a menu pick im
#age"
#    cp resources/pg-pgadmin.png staging/solaris-sparc/scripts/images/pg-pgadmin-$PG_VERSION_STR.png || _die "Failed to copy a menu p
#ick image"
#    cp resources/pg-postgresql.png staging/solaris-sparc/scripts/images/pg-postgresql-$PG_VERSION_STR.png || _die "Failed to copy a
#menu pick image"
#    cp resources/pg-psql.png staging/solaris-sparc/scripts/images/pg-psql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick im
#age"
#    cp resources/pg-reload.png staging/solaris-sparc/scripts/images/pg-reload-$PG_VERSION_STR.png || _die "Failed to copy a menu pic
#k image"
#    cp resources/pg-stackbuilder.png staging/solaris-sparc/scripts/images/pg-stackbuilder-$PG_VERSION_STR.png || _die "Failed to cop
#y a menu pick image"
#
#    mkdir -p staging/solaris-sparc/scripts/xdg || _die "Failed to create a directory for the menu pick items"
#
#
#    cp resources/xdg/pg-postgresql.directory staging/solaris-sparc/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
#    cp resources/xdg/pg-documentation.directory staging/solaris-sparc/scripts/xdg/pg-documentation-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
#
#    cp resources/xdg/pg-doc-installationnotes.desktop staging/solaris-sparc/scripts/xdg/pg-doc-installationnotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-pgadmin.desktop staging/solaris-sparc/scripts/xdg/pg-doc-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-pljava-readme.desktop staging/solaris-sparc/scripts/xdg/pg-doc-pljava-readme-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-pljava.desktop staging/solaris-sparc/scripts/xdg/pg-doc-pljava-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-postgresql-releasenotes.desktop staging/solaris-sparc/scripts/xdg/pg-doc-postgresql-releasenotes-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-doc-postgresql.desktop staging/solaris-sparc/scripts/xdg/pg-doc-postgresql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-pgadmin.desktop staging/solaris-sparc/scripts/xdg/pg-pgadmin-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-psql.desktop staging/solaris-sparc/scripts/xdg/pg-psql-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    cp resources/xdg/pg-reload.desktop staging/solaris-sparc/scripts/xdg/pg-reload-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#	cp resources/xdg/pg-stackbuilder.desktop staging/solaris-sparc/scripts/xdg/pg-stackbuilder-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick"
#    
#    # Copy the launch scripts
#    cp scripts/solaris/launchpsql.sh staging/solaris-sparc/scripts/launchpsql.sh || _die "Failed to copy the launchpsql script (scripts/solaris/launchpsql.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/launchpsql.sh
#    cp scripts/solaris/launchsvrctl.sh staging/solaris-sparc/scripts/launchsvrctl.sh || _die "Failed to copy the launchsvrctl script (scripts/solaris/launchsvrctl.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/launchsvrctl.sh
#    cp scripts/solaris/serverctl.sh staging/solaris-sparc/scripts/serverctl.sh || _die "Failed to copy the serverctl script (scripts/solaris/serverctl.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/serverctl.sh
#    cp scripts/solaris/runpsql.sh staging/solaris-sparc/scripts/runpsql.sh || _die "Failed to copy the runpsql script (scripts/solaris/runpsql.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/runpsql.sh
#    cp scripts/solaris/launchbrowser.sh staging/solaris-sparc/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/solaris/launchbrowser.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/launchbrowser.sh
#    cp scripts/solaris/launchpgadmin.sh staging/solaris-sparc/scripts/launchpgadmin.sh || _die "Failed to copy the launchpgadmin script (scripts/solaris/launchpgadmin.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/launchpgadmin.sh
#    cp scripts/solaris/launchstackbuilder.sh staging/solaris-sparc/scripts/launchstackbuilder.sh || _die "Failed to copy the launchstackbuilder script (scripts/solaris/launchstackbuilder.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/launchstackbuilder.sh
#    cp scripts/solaris/runstackbuilder.sh staging/solaris-sparc/scripts/runstackbuilder.sh || _die "Failed to copy the runstackbuilder script (scripts/solaris/runstackbuilder.sh)"
#    chmod ugo+x staging/solaris-sparc/scripts/runstackbuilder.sh
#		
#    PG_DATETIME_SETTING_SOLARIS_SPARC=`cat staging/solaris-sparc/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`
#
#    if [ "x$PG_DATETIME_SETTING_SOLARIS_SPARC" = "x" ]
#    then
#          PG_DATETIME_SETTING_SOLARIS_SPARC="floating-point numbers"
#    else
#          PG_DATETIME_SETTING_SOLARIS_SPARC="64-bit integers"
#    fi
#    if [ -f installer-solaris-sparc.xml ]; then
#        rm -f installer-solaris-sparc.xml
#    fi
#    cp installer.xml installer-solaris-sparc.xml
#
#    _replace @@PG_DATETIME_SETTING_SOLARIS_SPARC@@ "$PG_DATETIME_SETTING_SOLARIS_SPARC" installer-solaris-sparc.xml || _die "Failed to replace the date-time setting in the installer.xml"
#    _replace @@WIN64MODE@@ "0" installer-solaris-sparc.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
#    _replace @@SERVICE_SUFFIX@@ "" installer-solaris-sparc.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
#
#		
#    # Build the installer
#    "$PG_INSTALLBUILDER_BIN" build installer-solaris-sparc.xml solaris-sparc || _die "Failed to build the installer"
#
#    # Rename the installer
#    mv $WD/output/postgresql-$PG_MAJOR_VERSION-solaris-sparc-installer.bin $WD/output/postgresql-$PG_PACKAGE_VERSION-solaris-sparc.bin || _die "Failed to rename the installer"

    cd $WD
}


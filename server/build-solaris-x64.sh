#!/bin/bash


################################################################################
# Build preparation
################################################################################
BUILD_PG_CACHE_SOLARIS_X64=1

_prep_server_solaris_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source

    if [ -e postgres.solaris-x64 ];
    then
      echo "Removing existing postgres.solaris-x64 source directory"
      rm -rf postgres.solaris-x64  || _die "Couldn't remove the existing postgres.solaris-x64 source directory (source/postgres.solaris-x64)"
    fi

    if [ -e postgres.solaris-x64.zip ];
    then
      echo "Removing existing postgres.solaris-x64 zip file"
      rm -rf postgres.solaris-x64.zip  || _die "Couldn't remove the existing postgres.solaris-x64 zip file (source/postgres.solaris-x64.zip)"
    fi

    if [ -d postgres.solaris-x64.cache ]; then
        rm -rf postgres.solaris-x64.cache
    fi

    if [ -e postgres.solaris-x64-$PG_TARBALL_POSTGRESQL.zip ]; then
        BUILD_PG_CACHE_SOLARIS_X64=0
    fi

    # We will build the PostgreSQL cache only if does not exists
    if [ $BUILD_PG_CACHE_SOLARIS_X64 -eq 1 ]; then

        # Grab a copy of the source tree
        cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.solaris-x64 || _die "Failed to copy the source code (source/postgresql-$PG_TARBALL_POSTGRESQL) for Solaris(x64)"
        chmod -R ugo+w postgres.solaris-x64 || _die "Couldn't set the permissions on the source directory"
        zip -r postgres.solaris-x64.zip postgres.solaris-x64

        ssh $PG_SSH_SOLARIS_X64 "rm -rf $PG_PATH_SOLARIS_X64/server" || _die "Falied to create the server directory on the Solaris (x64) VM"
        ssh $PG_SSH_SOLARIS_X64 "mkdir -p $PG_PATH_SOLARIS_X64/server/source" || _die "Falied to create the source directory on the Solaris (x64) VM"
        scp -r postgres.solaris-x64.zip $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/server/source/ || _die "Failed to scp the postgres source"
        ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64/server/source; unzip postgres.solaris-x64.zip" || _die "Falied to remove the source directory on the Solaris(X64) VM"
    fi

}


_process_dependent_libs_solaris_x64() {

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
   scp process_dependent_libs.sh $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64

   ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; ./process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_SOLARIS_X64 "cd $PG_PATH_SOLARIS_X64; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}

################################################################################
# Build
################################################################################

_build_server_solaris_x64() {

    # First build PostgreSQL

    cd $WD/server/source

    if [ $BUILD_PG_CACHE_SOLARIS_X64 -eq 1 ]; then

        PG_STAGING=$PG_PATH_SOLARIS_X64/server/postgres.solaris-x64.cache
    
        cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64"
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:\$PATH
export GTK_MODULES=""

EOT
        scp setenv.sh $PG_SSH_SOLARIS_X64: || _die "Failed to scp the setenv.sh file"
    
        # Configure the source tree
        echo "Configuring the postgres source tree"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server/source/postgres.solaris-x64/;./configure --prefix=$PG_STAGING --with-openssl --with-pam --with-krb5 --enable-thread-safety --with-libxml --with-ossp-uuid --docdir=$PG_STAGING/doc/postgresql --with-libxslt --with-libedit-preferred"  || _die "Failed to configure postgres"
    
        echo "Building postgres"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server/source/postgres.solaris-x64; gmake -j4" || _die "Failed to build postgres"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server/source/postgres.solaris-x64; gmake install" || _die "Failed to install postgres"
    
        echo "Building contrib modules"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server/source/postgres.solaris-x64/contrib; gmake" || _die "Failed to build the postgres contrib modules"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server/source/postgres.solaris-x64/contrib; gmake install" || _die "Failed to install the postgres contrib modules"

        # Copy in the dependency libraries
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libssl.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libcrypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libedit.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libuuid.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libxslt.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libkrb5.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libkrb5support.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libk5crypto.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"
        ssh $PG_SSH_SOLARIS_X64 "cp -R /usr/local/lib/libcom_err.so* $PG_STAGING/lib" || _die "Failed to copy the dependency library"

        # Process Dependent libs
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libssl.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libcrypto.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libedit.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libxml2.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libxslt.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libkrb5support.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libk5crypto.so"
        _process_dependent_libs_solaris_x64 "$PG_STAGING/bin" "$PG_STAGING/lib" "libcom_err.so"

        echo "Changing the rpath for the PostgreSQL executables and libraries"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_STAGING/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/../lib:/usr/sfw/lib/64\" \$f; done"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_STAGING/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN:/usr/sfw/lib/64\" \$f; done"
        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_STAGING/lib/postgresql; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/..:/usr/sfw/lib/64\" \$f; done"
    
        #Fix permission in the staging/solaris-x64/lib
        ssh $PG_SSH_SOLARIS_X64 "cd $PG_STAGING/lib; chmod a+r *"

        ssh $PG_SSH_SOLARIS_X64 "source setenv.sh; cd $PG_PATH_SOLARIS_X64/server; zip -r postgres.solaris-x64-$PG_TARBALL_POSTGRESQL.zip postgres.solaris-x64.cache" || _die "Failed to make archieve of the PostgreSQL binaries for caching on Solaris(x64) VM"

        scp -r $PG_SSH_SOLARIS_X64:$PG_PATH_SOLARIS_X64/server/postgres.solaris-x64-$PG_TARBALL_POSTGRESQL.zip $WD/server/source/ || _die "Failed to get the staging archieve (Solaris-x64)"
    fi

    cd $WD/server/source
    unzip postgres.solaris-x64-$PG_TARBALL_POSTGRESQL.zip -d $PWD || _die "Failed to unpack binaries"

    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_solaris_x64() {

    cd $WD
}


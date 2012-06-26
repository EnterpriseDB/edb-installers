#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.linux ];
    then
      echo "Removing existing psqlODBC.linux source directory"
      rm -rf psqlODBC.linux  || _die "Couldn't remove the existing psqlODBC.linux source directory (source/psqlODBC.linux)"
    fi

    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.linux)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.linux || _die "Couldn't create the psqlODBC.linux directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.linux || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    chmod -R ugo+w psqlODBC.linux || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/linux)"
    mkdir -p $WD/psqlODBC/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/linux || _die "Couldn't set the permissions on the staging directory"

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
   mkdir /tmp/templibs

   export LD_LIBRARY_PATH=$lib_dir

   # Get the exact version of $libname which are required by the binaries in $bin_dir
   cd $bin_dir
   dependent_libs=\`ldd psqlodbcw.so | grep $libname | cut -f1 -d "=" | uniq\`

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
                    cp \$ref_lib /tmp/templibs/\$lib  || _die "Failed to copy the original \$lib"
                else
                    # Copy the original lib in a temp directory.
                    cp \$lib /tmp/templibs/\$lib || _die "Failed to copy the original \$lib"
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
   scp process_dependent_libs.sh $PG_SSH_LINUX:$PG_PATH_LINUX/

   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; sh process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_linux() {

    cd $WD/psqlODBC

    PG_STAGING=$PG_PATH_LINUX/psqlODBC/staging/linux
    SOURCE_DIR=$PG_PATH_LINUX/psqlODBC/source/psqlODBC.linux

    echo "Configuring psqlODBC sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; export LD_LIBRARY_PATH=/usr/local/lib:$PG_PGHOME_LINUX/lib:\$LD_LIBRARY_PATH; export PATH=/usr/local/bin:$PG_PGHOME_LINUX/bin:\$PATH; CFLAGS=\"-I/usr/local/include\" LDFLAGS=\"-L/usr/local/lib\"  ./configure --prefix=$PG_STAGING " || _die "Couldn't configure the psqlODBC sources"
    echo "Compiling psqlODBC"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; CFLAGS=\"-I/usr/local/include\" LDFLAGS=\"-L/usr/local/lib\"  make" || _die "Couldn't compile the psqlODBC sources"
    echo "Installing psqlODBC into the sources"
    ssh $PG_SSH_LINUX "cd $SOURCE_DIR; make install" || _die "Couldn't install the psqlODBC into statging directory"

    cd $WD/psqlODBC/staging/linux/lib

    # Copy in the dependency libraries
    cp -pR $WD/server/staging/linux/lib/libpq.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $WD/server/staging/linux/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $WD/server/staging/linux/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $WD/server/staging/linux/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $WD/server/staging/linux/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $WD/server/staging/linux/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $WD/server/staging/linux/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $WD/server/staging/linux/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $WD/server/staging/linux/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $WD/server/staging/linux/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $WD/server/staging/linux/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libodbcinst.so* $PG_STAGING/lib" || _die "Failed to copy libodbcinst.so"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libodbc.so* $PG_STAGING/lib" || _die "Failed to copy libodbc.so"

    # Process Dependent libs
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libcom_err.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libgssapi_krb5.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libkrb5.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libk5crypto.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libkrb5support.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libssl.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libcrypto.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libedit.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libncurses.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libldap.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "liblber.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libodbcinst.so"
    _process_dependent_libs "$PG_STAGING/lib" "$PG_STAGING/lib" "libpq.so"

}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_linux() {

    cd $WD/psqlODBC

    # Setup the installer scripts.
    mkdir -p staging/linux/installer/psqlODBC || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux/installer/psqlODBC/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/removeshortcuts.sh

    cp scripts/linux/createshortcuts.sh staging/linux/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/createshortcuts.sh

    cp scripts/linux/getodbcinstpath.sh staging/linux/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/linux/getodbcinstpath.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/getodbcinstpath.sh

    cp scripts/linux/configpsqlodbc.sh staging/linux/installer/psqlODBC/configpsqlodbc.sh || _die "Failed to copy the configpsqlodbc.sh script (scripts/linux/configpsqlodbc.sh)"
    chmod ugo+x staging/linux/installer/psqlODBC/configpsqlodbc.sh

    #Setup the launch scripts
    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/scripts/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg files (resources/)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Setup the psqlODBC xdg Files
    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the xdg entries"
    cp resources/xdg/pg-launchOdbcDocs.desktop staging/linux/scripts/xdg/pg-launchOdbcDocs.desktop || _die "Failed to copy the launch files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


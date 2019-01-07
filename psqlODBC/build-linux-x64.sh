#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_linux_x64() {
    
    echo "BEGIN PREP psqlODBC Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.linux-x64 ];
    then
      echo "Removing existing psqlODBC.linux-x64 source directory"
      rm -rf psqlODBC.linux-x64  || _die "Couldn't remove the existing psqlODBC.linux-x64 source directory (source/psqlODBC.linux-x64)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.linux-x64)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.linux-x64 || _die "Couldn't create the psqlODBC.linux-x64 directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.linux-x64 || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/linux-x64.build)"
    mkdir -p $WD/psqlODBC/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"
    
    echo "END PREP psqlODBC Linux-x64"
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
   scp process_dependent_libs.sh $PG_SSH_LINUX_X64:$PG_PATH_LINUX_X64/

   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; sh process_dependent_libs.sh" || _die "Failed to process dependent libs for $libname"
   ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; rm -f process_dependent_libs.sh" || _die "Failed to remove the process_dependent_libs.sh file from the Linux VM"

   rm -f process_dependent_libs.sh || _die "Failed to remove the process_dependent_libs.sh file"

}


################################################################################
# PG Build
################################################################################

_build_psqlODBC_linux_x64() {
    
    echo "BEGIN BUILD psqlODBC Linux-x64"

    cd $WD/psqlODBC

    PG_STAGING=$PG_PATH_LINUX_X64/psqlODBC/staging/linux-x64.build
    SOURCE_DIR=$PG_PATH_LINUX_X64/psqlODBC/source/psqlODBC.linux-x64

    PG_STAGING_CACHE=$WD/server/staging_cache/linux-x64

    echo "Configuring psqlODBC sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; export LD_LIBRARY_PATH=/opt/local/Current/lib:$PG_PGHOME_LINUX_X64/lib:\$LD_LIBRARY_PATH; export PATH=/opt/local/Current/bin:$PG_PGHOME_LINUX_X64/bin:\$PATH; CFLAGS=\"-I/opt/local/Current/include\" LDFLAGS=\"-L/opt/local/Current/lib\" ./configure --prefix=$PG_STAGING " || _die "Couldn't configure the psqlODBC sources"
    echo "Compiling psqlODBC"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; CFLAGS=\"-I/opt/local/Current/include\" LDFLAGS=\"-L/opt/local/Current/lib\" make" || _die "Couldn't compile the psqlODBC sources"
    echo "Installing psqlODBC into the sources"
    ssh $PG_SSH_LINUX_X64 "cd $SOURCE_DIR; make install" || _die "Couldn't install the psqlODBC into statging directory" 

    cd $WD/psqlODBC/staging/linux-x64.build/lib

    # Copy in the dependency libraries
    cp -pR $PG_STAGING_CACHE/lib/libpq.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $PG_STAGING_CACHE/lib/libcrypto.so* . || _die "Failed to copy libcrypto.so"
    cp -pR $PG_STAGING_CACHE/lib/libssl.so* . || _die "Failed to copy libssl.so"
    cp -pR $PG_STAGING_CACHE/lib/libedit.so* . || _die "Failed to copy libedit.so"
    cp -pR $PG_STAGING_CACHE/lib/libldap*.so* . || _die "Failed to copy libldap.so"
    cp -pR $PG_STAGING_CACHE/lib/liblber*.so* . || _die "Failed to copy liblber.so"
    cp -pR $PG_STAGING_CACHE/lib/libgssapi_krb5*.so* . || _die "Failed to copy libgssapi_krb5.so"
    cp -pR $PG_STAGING_CACHE/lib/libkrb5.so* . || _die "Failed to copy libkrb5.so"
    cp -pR $PG_STAGING_CACHE/lib/libkrb5support*.so* . || _die "Failed to copy libkrb5support.so"
    cp -pR $PG_STAGING_CACHE/lib/libk5crypto*.so* . || _die "Failed to copy libk5crypto.so"
    cp -pR $PG_STAGING_CACHE/lib/libcom_err*.so* . || _die "Failed to copy libcom_err.so"
    cp -pR $PG_STAGING_CACHE/lib/libncurses*.so* . || _die "Failed to copy libncurses.so"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libodbcinst.so* $PG_STAGING/lib" || _die "Failed to copy libodbcinst.so"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libodbc.so* $PG_STAGING/lib" || _die "Failed to copy libodbc.so"

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
    
    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/psqlODBC ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/psqlODBC directory"
        rm -rf $WD/output/symbols/linux-x64/psqlODBC  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/psqlODBC directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/psqlODBC/staging/linux-x64.build/symbols $WD/output/symbols/linux-x64/psqlODBC || _die "Failed to move $WD/psqlODBC/staging/linux-x64.build/symbols to $WD/output/symbols/linux-x64/psqlODBC directory"

    echo "Removing last successful staging directory ($WD/psqlODBC/staging/linux-x64)"
    rm -rf $WD/psqlODBC/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/psqlODBC/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/psqlODBC/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/psqlODBC/staging/linux-x64.build/* $WD/psqlODBC/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_PSQLODBC=$PG_VERSION_PSQLODBC" > $WD/psqlODBC/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_PSQLODBC=$PG_BUILDNUM_PSQLODBC" >> $WD/psqlODBC/staging/linux-x64/versions-linux-x64.sh

    echo "END BUILD psqlODBC Linux-x64"
}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_linux_x64() {
    
    echo "BEGIN POST psqlODBC Linux-x64"    

    source $WD/psqlODBC/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_PSQLODBC=$(expr $PG_BUILD_PSQLODBC + $SKIPBUILD)

    cd $WD/psqlODBC
 
    pushd staging/linux-x64
    generate_3rd_party_license "psqlODBC"
    popd

    # Setup the installer scripts.
    mkdir -p staging/linux-x64/installer/psqlODBC || _die "Failed to create a directory for the install scripts"
    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/psqlODBC/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/removeshortcuts.sh
    
    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/createshortcuts.sh

    cp scripts/linux/getodbcinstpath.sh staging/linux-x64/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/linux/getodbcinstpath.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/getodbcinstpath.sh

    cp scripts/linux/configpsqlodbc.sh staging/linux-x64/installer/psqlODBC/configpsqlodbc.sh || _die "Failed to copy the configpsqlodbc.sh script (scripts/linux/configpsqlodbc.sh)"
    chmod ugo+x staging/linux-x64/installer/psqlODBC/configpsqlodbc.sh

    #Setup the launch scripts
    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/scripts/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the menu pick xdg files"

    # Copy in installation xdg Files
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg files (resources/)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Setup the psqlODBC xdg Files
    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the xdg entries"
    cp resources/xdg/pg-launchOdbcDocs.desktop staging/linux-x64/scripts/xdg/pg-launchOdbcDocs.desktop || _die "Failed to copy the launch files (resources)"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy the xdg files (resources)"
    
    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PSQLODBC -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-linux-x64.run $WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-${BUILD_FAILED}linux-x64.run

    cd $WD

    echo "END POST psqlODBC Linux-x64"
}



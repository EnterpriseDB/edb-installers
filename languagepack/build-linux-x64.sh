#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_languagepack_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source

    if [ -e languagepack.linux-x64 ];
    then
      echo "Removing existing languagepack.linux-x64 source directory"
      rm -rf languagepack.linux-x64  || _die "Couldn't remove the existing languagepack.linux-x64 source directory (source/languagepack.linux-x64)"
    fi
   
    echo "Creating staging directory ($WD/languagepack/source/languagepack.linux-x64)"
    mkdir -p $WD/languagepack/source/languagepack.linux-x64 || _die "Couldn't create the languagepack.linux-x64 directory"
    chmod -R ugo+w languagepack.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Copy languagepack build script languagepack.sh 
    cp $WD/languagepack/scripts/linux/languagepack.sh languagepack.linux-x64 || _die "Failed to copy the languagepack build script (languagepack.sh)"

    # Copy Python_MAXREPEAT.patch to build Python
    cp $WD/languagepack/scripts/linux/Python_MAXREPEAT.patch languagepack.linux-x64 || _die "Failed to copy (Python_MAXREPEAT.patch) to build Python"

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    ssh $PG_SSH_LINUX_X64 "rm -rf $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't remove the existing install directory"
    
    if [ -e $WD/languagepack/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging/install directory ($PG_LANGUAGEPACK_INSTALL_DIR_LINUX)"
    mkdir -p $WD/languagepack/staging/linux-x64 || _die "Couldn't create the staging directory"
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't create the install directory"
    chmod ugo+w $WD/languagepack/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    ssh $PG_SSH_LINUX_X64 "chmod ugo+w $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't set the permissions on the install directory"
}

################################################################################
# Build LanguagePack
################################################################################

_build_languagepack_linux_x64() {

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/languagepack/source/languagepack.linux-x64; export SSL_INST=/opt/local/Current; ./languagepack.sh -n 5.9 -p 3.3.4 -d 0.6.49 -t 8.5.15 -P 5.20.3 -v $PG_VERSION_LANGUAGEPACK -b /opt/local/pg-languagepack -i $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Failed to build languagepack"
}


################################################################################
# Build Postprocess
################################################################################

_postprocess_languagepack_linux_x64() {
 
    cd $WD/languagepack
    
    echo "Copying files to staging directory from install directory"
    ssh $PG_SSH_LINUX_X64 "mv $PG_LANGUAGEPACK_INSTALL_DIR_LINUX/$PG_VERSION_LANGUAGEPACK/* $PG_PATH_LINUX_X64/languagepack/staging/linux-x64 && rm -rf $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Failed to copy the languagepack Source into the staging directory"
 
    pushd staging/linux-x64
    generate_3rd_party_license "languagepack"
    popd
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_languagepack_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source

    if [ -e languagepack.linux ];
    then
      echo "Removing existing languagepack.linux source directory"
      rm -rf languagepack.linux  || _die "Couldn't remove the existing languagepack.linux source directory (source/languagepack.linux)"
    fi
   
    echo "Creating staging directory ($WD/languagepack/source/languagepack.linux)"
    mkdir -p $WD/languagepack/source/languagepack.linux || _die "Couldn't create the languagepack.linux directory"
    chmod -R ugo+w languagepack.linux || _die "Couldn't set the permissions on the source directory"
   
    # Copy languagepack build script languagepack.sh 
    cp $WD/languagepack/scripts/linux/languagepack.sh languagepack.linux || _die "Failed to copy the languagepack build script (languagepack.sh)"

    # Copy Python_MAXREPEAT.patch to build Python
    cp $WD/languagepack/scripts/linux/Python_MAXREPEAT.patch languagepack.linux || _die "Failed to copy (Python_MAXREPEAT.patch) to build Python"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/linux)"
    mkdir -p $WD/languagepack/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/linux || _die "Couldn't set the permissions on the staging directory"
}

################################################################################
# Build LanguagePack
################################################################################

_build_languagepack_linux() {

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/languagepack/source/languagepack.linux; export SSL_INST=/opt/local/Current; ./languagepack.sh -n 5.9 -p 3.3.4 -d 0.6.49 -t 8.5.15 -P 5.16.3 -v $EDB_VERSION_LANGUAGEPACK -i $PG_PATH_LINUX/languagepack/staging/linux" || _die "Failed to build languagepack"
}


################################################################################
# Build Postprocess
################################################################################

_postprocess_languagepack_linux() {
 
    cd $WD/languagepack
    pushd staging/linux
    generate_3rd_party_license "languagepack"
    popd
  
    mv staging/linux/$EDB_VERSION_LANGUAGEPACK/* staging/linux && rm -rf staging/linux/$EDB_VERSION_LANGUAGEPACK || _die "Failed to copy the languagepack Source into the staging directory"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}


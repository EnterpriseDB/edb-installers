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
   
    echo "Creating source directory ($WD/languagepack/source/languagepack.linux)"
    mkdir -p $WD/languagepack/source/languagepack.linux || _die "Couldn't create the languagepack.linux directory"
    chmod -R ugo+w languagepack.linux || _die "Couldn't set the permissions on the source directory"
   
    # Copy languagepack build script languagepack.sh 
    cp $WD/languagepack/scripts/linux/languagepack.sh languagepack.linux || _die "Failed to copy the languagepack build script (languagepack.sh)"

    # Copy the tarballs
    cp $WD/tarballs/ncurses-${PG_VERSION_NCURSES}.tar.gz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy ncurses"
    cp $WD/tarballs/tcl${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src.tar.gz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy tcl"
    cp $WD/tarballs/tk${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src.tar.gz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy tk"
    cp $WD/tarballs/perl-${PG_VERSION_PERL}.${PG_MINOR_VERSION_PERL}.tar.gz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy perl"
    cp $WD/tarballs/Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}.tgz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy python"
    cp $WD/tarballs/setuptools-${PG_VERSION_PYTHON_SETUPTOOLS}.tar.gz $WD/languagepack/source/languagepack.linux/ || _die  "failed to copy setuptools"

    # Copy Python_MAXREPEAT.patch to build Python
    cp $WD/languagepack/scripts/linux/Python_MAXREPEAT.patch languagepack.linux || _die "Failed to copy (Python_MAXREPEAT.patch) to build Python"

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    ssh $PG_SSH_LINUX "rm -rf $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't remove the existing install directory"

    if [ -e "$WD/languagepack/staging/linux" ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/linux || _die "Couldn't remove the existing staging directory"
    fi


    echo "Creating staging/install directory ($PG_LANGUAGEPACK_INSTALL_DIR_LINUX)"
    mkdir -p $WD/languagepack/staging/linux || _die "Couldn't create the staging directory"
    ssh $PG_SSH_LINUX "mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't create the install directory"
    chmod ugo+w $WD/languagepack/staging/linux || _die "Couldn't set the permissions on the staging directory"
    ssh $PG_SSH_LINUX "chmod ugo+w $PG_LANGUAGEPACK_INSTALL_DIR_LINUX" || _die "Couldn't set the permissions on the install directory"
}

################################################################################
# Build LanguagePack
################################################################################

_build_languagepack_linux() {

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/languagepack/source/languagepack.linux; export SSL_INST=/opt/local/Current; ./languagepack.sh -n ${PG_VERSION_NCURSES} -p ${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON} -d ${PG_VERSION_PYTHON_SETUPTOOLS} -t ${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL} -P ${PG_VERSION_PERL}.${PG_MINOR_VERSION_PERL} -v $PG_VERSION_LANGUAGEPACK -b $PG_BINARY_PATH_LINUX -i $PG_LANGUAGEPACK_INSTALL_DIR_LINUX -e" || _die "Failed to build languagepack"

    echo "Removing last successful staging directory ($PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging)"
    ssh $PG_SSH_LINUX "rm -rf $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_LINUX "mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging" || _die "Couldn't create the last successful staging directory"
    ssh $PG_SSH_LINUX "chmod ugo+w $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging" || _die "Couldn't set the permission on the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_LINUX "cp -rp $PG_LANGUAGEPACK_INSTALL_DIR_LINUX/* $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_LINUX "echo PG_VERSION_LANGUAGEPACK=$PG_VERSION_LANGUAGEPACK > $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging/versions-linux.sh" || _die "Failed to write languagepack version number into versions-linux.sh"
    ssh $PG_SSH_LINUX "echo PG_BUILDNUM_LANGUAGEPACK=$PG_BUILDNUM_LANGUAGEPACK >> $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging/versions-linux.sh" || _die "Failed to write languagepack build number into versions-linux.sh"

}


################################################################################
# Build Postprocess
################################################################################

_postprocess_languagepack_linux() {

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e "$WD/languagepack/staging/linux" ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/linux || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/languagepack/staging/linux)"
    mkdir -p $WD/languagepack/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/linux || _die "Couldn't set the permissions on the staging directory"

    cd $WD/languagepack

    echo "Copying files to staging directory from install directory"
    ssh $PG_SSH_LINUX "cp -rp $PG_LANGUAGEPACK_INSTALL_DIR_LINUX.staging/* $PG_PATH_LINUX/languagepack/staging/linux" || _die "Failed to copy the built tree into the staging directory"

    source $WD/languagepack/staging/linux/versions-linux.sh
    PG_BUILD_LANGUAGEPACK=$(expr $PG_BUILD_LANGUAGEPACK + $SKIPBUILD)

    mv $WD/languagepack/staging/linux/Python-3.4/pip_packages_list.txt $WD/languagepack/staging/linux || _die "Failed to move pip_packages_list.txt to $WD/languagepack/staging/linux"

    pushd $WD/languagepack/staging/linux
    generate_3rd_party_license "languagepack"
    popd
  
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_LANGUAGEPACK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-linux.run $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}linux.run

    cd $WD
}


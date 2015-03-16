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

    # Grab a copy of the binaries
    ##cp -R $EDB_LINUX64_BLD/LanguagePack/* languagepack.linux-x64 || _die "Failed to copy the source code (source/languagepack)"
    chmod -R ugo+w languagepack.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Copy languagepack build script languagepack.sh 
    cp $WD/languagepack/scripts/linux/languagepack.sh languagepack.linux-x64 || _die "Failed to copy the languagepack build script (languagepack.sh)"

    # Copy Python_MAXREPEAT.patch to build Python
    cp $WD/languagepack/scripts/linux/Python_MAXREPEAT.patch languagepack.linux-x64 || _die "Failed to copy (Python_MAXREPEAT.patch) to build Python"

#    # Remove any existing installation directory that might exist, and create a clean one
#    if [ -e /opt/EnterpriseDB/LanguagePack ];
#    then
#      echo "Removing existing installation directory"
#      rm -rf /opt/EnterpriseDB/LanguagePack || _die "Couldn't remove the existing installation directory (/opt/EnterpriseDB/LanguagePack)"
#    fi
#    
#    echo "Creating installation directory (/opt/EnterpriseDB/LanguagePack)"
#    mkdir -p /opt/EnterpriseDB/LanguagePack || _die "Couldn't create the installation directory (/opt/EnterpriseDB/LanguagePack)"
#    chmod ugo+w /opt/EnterpriseDB/LanguagePack || _die "Couldn't set the permissions on the installation directory (/opt/EnterpriseDB/LanguagePack)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/linux-x64)"
    mkdir -p $WD/languagepack/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_languagepack_linux_x64() {

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/languagepack/source/languagepack.linux-x64; export SSL_INST=/opt/local/Current; ./languagepack.sh -n 5.9 -p 3.3.4 -d 0.6.49 -t 8.5.15 -P 5.16.3 -v 9.4 -i $PG_PATH_LINUX_X64/languagepack/staging/linux-x64" || _die "Failed to build languagepack"
}


################################################################################
# PG Build
################################################################################

_postprocess_languagepack_linux_x64() {
 
    ##cp -R $EDB_LINUX64_BLD/LanguagePack/* $WD/languagepack/staging/linux-x64  || _die "Failed to copy the languagepack Source into the staging directory"
    cd $WD/languagepack
    pushd staging/linux-x64
    generate_3rd_party_license "languagepack"
    popd
    
    mv staging/linux-x64/$EDB_VERSION_LANGUAGEPACK/* staging/linux-x64 && rm -rf staging/linux-x64/$EDB_VERSION_LANGUAGEPACK || _die "Failed to copy the languagepack Source into the staging directory"
    # mv staging/linux-x64/languagepack.config staging/linux-x64/languagepack-$EDB_VERSION_LANGUAGEPACK.config || _die "Failed to rename the config file"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


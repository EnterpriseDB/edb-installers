#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_languagepack_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source

    if [ -e languagepack.osx ];
    then
      echo "Removing existing languagepack.osx source directory"
      rm -rf languagepack.osx  || _die "Couldn't remove the existing languagepack.osx source directory (source/languagepack.osx)"
    fi
   
    echo "Creating staging directory ($WD/languagepack/source/languagepack.osx)"
    mkdir -p $WD/languagepack/source/languagepack.osx || _die "Couldn't create the languagepack.osx directory"

    # Grab a copy of the binaries
    cp -R $EDB_OSX_BLD/LanguagePack/* languagepack.osx || _die "Failed to copy the source code (source/languagepack)"
    chmod -R ugo+w languagepack.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/osx)"
    mkdir -p $WD/languagepack/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/osx || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_languagepack_osx() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_languagepack_osx() {
 
    cp -R $EDB_OSX_BLD/LanguagePack/* $WD/languagepack/staging/osx  || _die "Failed to copy the languagepack Source into the staging directory"
    
    cd $WD/languagepack
    # mv staging/osx/languagepack.config staging/osx/languagepack-$EDB_VERSION_LANGUAGEPACK.config || _die "Failed to rename the config file"

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$EDB_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/Language\ Pack $WD/risePrivileges || _die "Failed to copy the privileges escalation applet"
        echo "Removing the installer previously generated installer"
        rm -rf $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app
    fi

    # Build the installer
    echo "Building the installer with the root privileges not required"
    "$EDB_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/risePrivileges $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/Language\ Pack
    chmod a+x $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/Language\ Pack
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Language\ Pack $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with Language\ Pack ($WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.zip edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf edb_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
}


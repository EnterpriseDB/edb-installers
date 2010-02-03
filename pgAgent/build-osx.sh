#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgAgent_osx() {

    echo "#####################################"
    echo "# pgAgent : OSX : Build preparation #"
    echo "#####################################"

    # Enter the source directory and cleanup if required
    cd $WD/pgAgent/source
	
    if [ -e pgAgent.osx ];
    then
      echo "Removing existing pgAgent.osx source directory"
      rm -rf pgAgent.osx  || _die "Couldn't remove the existing pgAgent.osx source directory (source/pgAgent.osx)"
    fi

    echo "Creating staging directory ($WD/pgAgent/source/pgAgent.osx)"
    mkdir -p $WD/pgAgent/source/pgAgent.osx || _die "Couldn't create the pgAgent.osx directory"
	
    # Grab a copy of the source tree
    cp -R pgAgent-$PG_VERSION_PGAGENT-Source/* pgAgent.osx || _die "Failed to copy the source code (source/pgAgent-$PG_VERSION_PGAGENT)"
    chmod -R ugo+w pgAgent.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgAgent/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgAgent/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgAgent/staging/osx)"
    mkdir -p $WD/pgAgent/staging/osx || _die "Couldn't create the staging directory"


}

################################################################################
# pgAgent Build
################################################################################

_build_pgAgent_osx() {

    echo "#####################################"
    echo "# pgAgent : OSX : Build             #"
    echo "#####################################"

    cd $WD/pgAgent

    PG_STAGING=$WD/pgAgent/staging/osx
    SOURCE_DIR=$WD/pgAgent/source/pgAgent.osx

    echo "Building pgAgent sources"
    cd $SOURCE_DIR
    WXWIN=/usr/local PGDIR=$PG_PGHOME_OSX cmake -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.5 -DCMAKE_INSTALL_PREFIX=$PG_STAGING CMakeLists.txt || _die "Couldn't configure the pgAgent sources"
    echo "Compiling pgAgent"
    cd $SOURCE_DIR
    make || _die "Couldn't compile the pgAgent sources"
    make install || _die "Couldn't install pgAgent"

    mkdir -p $PG_STAGING/lib

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -R $PG_PGHOME_OSX/bin/psql $PG_STAGING/bin || _die "Failed to copy psql"
    cp -R $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library (libpq.5.dylib)"

    # Copy libxml2 as System's libxml can be old.
    cp /usr/local/lib/libxml2* $PG_STAGING/lib || _die "Failed to copy the latest libxml2"

    _rewrite_so_refs $WD/pgAgent/staging/osx lib @loader_path/..
    install_name_tool -change "libpq.5.dylib" "@loader_path/libpq.5.dylib" "$PG_STAGING/bin/psql"

}


################################################################################
# PG Build
################################################################################

_postprocess_pgAgent_osx() {

    echo "#####################################"
    echo "# pgAgent : OSX : Post Process      #"
    echo "#####################################"

    # Setup the installer scripts.
    cd $PG_PATH_OSX/pgAgent/staging
    mkdir -p $PG_PATH_OSX/pgAgent/staging/osx/installer/pgAgent || _die "Failed to create a directory for the install scripts"

    cp -f $PG_PATH_OSX/pgAgent/scripts/osx/*.sh   $PG_PATH_OSX/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the installer scripts"
    cp -f $PG_PATH_OSX/pgAgent/scripts/osx/pgpass $PG_PATH_OSX/pgAgent/staging/osx/installer/pgAgent/ || _die "Failed to copy the pgpass script (scripts/osx/pgpass)"
    chmod ugo+x $PG_PATH_OSX/pgAgent/staging/osx/installer/pgAgent/*

    cd $WD/pgAgent

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>"
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent
    chmod a+x $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/pgAgent
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ pgAgent $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with pgAgent ($WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/Contents/MacOS/installbuilder.sh
    # Zip up the output
    cd $WD/output
    zip -r pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.zip pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD

}


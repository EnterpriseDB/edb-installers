#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_stackbuilderplus_solaris_sparc() {

    echo "********************************************"
    echo "* Preparing - StackBuilderPlus (solaris-sparc) *"
    echo "********************************************"

    # Enter the source directory and cleanup if required
    cd $WD/StackBuilderPlus/source

    if [ -e StackBuilderPlus.solaris-sparc ];
    then
      echo "Removing existing StackBuilderPlus.solaris-sparc source directory"
      rm -rf StackBuilderPlus.solaris-sparc  || _die "Couldn't remove the existing StackBuilderPlus.solaris-sparc source directory (source/StackBuilderPlus.solaris-sparc)"
    fi
   
    if [ -e StackBuilderPlus.solaris-sparc.zip ];
    then
      echo "Removing existing StackBuilderPlus.solaris-sparc zip file"
      rm -rf StackBuilderPlus.solaris-sparc.zip  || _die "Couldn't remove the existing StackBuilderPlus.solaris-sparc zip file (source/StackBuilderPlus.solaris-sparc.zip)"
    fi
 
    if [ -e updatemanager.solaris-sparc ];
    then
      echo "Removing existing updatemanager.solaris-sparc source directory"
      rm -rf updatemanager.solaris-sparc  || _die "Couldn't remove the existing updatemanager.solaris-sparc source directory (source/updatemanager.solaris-sparc)"
    fi
   
    if [ -e updatemanager.solaris-sparc.zip ];
    then
      echo "Removing existing updatemanager.solaris-sparc zip file"
      rm -rf updatemanager.solaris-sparc.zip  || _die "Couldn't remove the existing updatemanager.solaris-sparc zip file (source/updatemanager.solaris-sparc.zip)"
    fi
   
    echo "Creating source directory ($WD/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc)"
    mkdir -p $WD/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc || _die "Couldn't create the StackBuilderPlus.solaris-sparc directory"

    echo "Creating source directory ($WD/StackBuilderPlus/source/updatemanager.solaris-sparc)"
    mkdir -p $WD/StackBuilderPlus/source/updatemanager.solaris-sparc || _die "Couldn't create the updatemanager.solaris-sparc directory"

    # Grab a copy of the source tree
    cp -R STACKBUILDER-PLUS/* StackBuilderPlus.solaris-sparc || _die "Failed to copy the source code (source/STACKBUILDER-PLUS)"
    chmod -R ugo+w StackBuilderPlus.solaris-sparc || _die "Couldn't set the permissions on the source directory (STACKBUILDER-PLUS)"
    cd StackBuilderPlus.solaris-sparc
    patch -p0 < $WD/tarballs/StackBuilderPlus_solaris.patch
    cd ..
    zip -r StackBuilderPlus.solaris-sparc.zip StackBuilderPlus.solaris-sparc || _die "Failed to zip the StackBuilderPlus source directory"

    cp -R SS-UPDATEMANAGER/* updatemanager.solaris-sparc || _die "Failed to copy the source code (source/SS-UPDATEMANAGER)"
    chmod -R ugo+w updatemanager.solaris-sparc || _die "Couldn't set the permissions on the source directory (SS-UPDATEMANAGER)"
    zip -r updatemanager.solaris-sparc.zip updatemanager.solaris-sparc || _die "Failed to zip the updatemanager source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/StackBuilderPlus/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/StackBuilderPlus/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc" || _die "Failed to remove the StackBuilderPlus staging directory from Soalris VM"
    fi
    
    ssh $PG_SSH_SOLARIS_SPARC "rm -rf $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source" || _die "Failed to remove the StackBuilderPlus source directory from Soalris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source" || _die "Failed to create the StackBuilderPlus source directory on Soalris VM"
    scp StackBuilderPlus.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/ 
    scp updatemanager.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/ 
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source; unzip StackBuilderPlus.solaris-sparc.zip" || _die "Failed to unzip the StackBuilderPlus source directory on Soalris VM"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source; unzip updatemanager.solaris-sparc.zip" || _die "Failed to unzip the updatemanager source directory on Soalris VM"

    echo "Creating staging directory ($WD/StackBuilderPlus/staging/solaris-sparc)"
    mkdir -p $WD/StackBuilderPlus/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/StackBuilderPlus/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"
    
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/bin" || _die "Couldn't create the staging/bin directory"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Couldn't create the staging/lib directory"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/share" || _die "Couldn't create the staging/share directory"

}

################################################################################
# StackBuilderPlus Build
################################################################################

_build_stackbuilderplus_solaris_sparc() {

    echo "*******************************************"
    echo "* Building - StackBuilderPlus (solaris-sparc) *"
    echo "*******************************************"

    cd $WD/StackBuilderPlus/source

    cat <<EOT > "setenv.sh"
export CC=gcc
export CXX=g++
export CFLAGS="-m64" 
export CXXFLAGS="-m64"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/usr/local/lib
export PATH=/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/local/bin:/usr/ucb:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"

    cd $WD/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc

    # Configure
    echo "Configuring the StackBuilder Plus source tree"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/usr/local/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=OFF -D CMAKE_INSTALL_PREFIX:PATH=$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc -D CMAKE_CXX_FLAGS:STRING=\"-m64\" ."

    # Build the app
    echo "Building & installing StackBuilderPlus"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; gmake all" || _die "Failed to build StackBuilderPlus"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; gmake install" || _die "Failed to install StackBuilderPlus"

    echo "Building & installing UpdateManager"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc; $PG_QMAKE_SOLARIS_SPARC UpdateManager.pro" || _die "Failed to configure UpdateManager on solaris-sparc"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc; gmake" || _die "Failed to build UpdateManger on solaris-sparc"
      
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/bin" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to create the bin directory" 

    echo "Copying UpdateManager binary to staging directory"
    ssh $PG_SSH_SOLARIS_SPARC "cp $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc/UpdateManager $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/bin" || _die "Failed to copy the UpdateManager binary"

    echo "Copying dependent libraries to staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtXml.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtNetwork.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtCore.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libQtGui.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libpng12.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libssl.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libssl.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libcrypto.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libcrypto.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/sfw/lib/64/libexpat.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libexpat.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libgssapi_krb5.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libgssapi_krb5.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libkrb5.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libkrb5.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libcom_err.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libcom_err.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/local/lib/libk5crypto.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libk5crypto.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libjpeg.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libjpeg.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libtiff.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libtiff.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libz.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libz.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/sfw/lib/64/libfreetype.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libfreetype.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libfontconfig.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libfontconfig.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libpango* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (solaris-sparc)"

    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/* $WD/StackBuilderPlus/staging/solaris-sparc/ || _die "Failed to copy back the staging directory from Solaris VM"

    cd $WD
}


################################################################################
# Post Processing StackBuilderPlus
################################################################################

_postprocess_stackbuilderplus_solaris_sparc() {

    echo "**************************************************"
    echo "* Post-processing - StackBuilderPlus (solaris-sparc) *"
    echo "**************************************************"
 
    cd $WD/StackBuilderPlus

    mkdir -p staging/solaris-sparc/installer/StackBuilderPlus || _die "Failed to create a directory for the installer scripts"
    mkdir -p staging/solaris-sparc/UpdateManager/scripts || _die "Failed to create a directory for the installer scripts"
    
    cp scripts/solaris/createshortcuts.sh staging/solaris-sparc/installer/StackBuilderPlus/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/solaris/createshortcuts.sh)"
    cp scripts/solaris/removeshortcuts.sh staging/solaris-sparc/installer/StackBuilderPlus/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/removeshortcuts.sh)"
    cp scripts/solaris/configlibs.sh staging/solaris-sparc/installer/StackBuilderPlus/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/configlibs.sh)"
    chmod ugo+x staging/solaris-sparc/installer/StackBuilderPlus/*.sh

    mkdir -p staging/solaris-sparc/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/solaris/launchSBPUpdateMonitor.sh staging/solaris-sparc/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchSBPUpdateMonitor.sh)"
    cp scripts/solaris/launchStackBuilderPlus.sh staging/solaris-sparc/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchStackBuilderPlus.sh)"
    cp scripts/solaris/runStackBuilderPlus.sh staging/solaris-sparc/scripts/runStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/solaris/runStackBuilderPlus.sh)"

    # Copy the XDG scripts
    mkdir -p staging/solaris-sparc/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp $WD/scripts/xdg/xdg* staging/solaris-sparc/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/solaris-sparc/installer/xdg/xdg*

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`

    mkdir -p staging/solaris-sparc/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/edb-stackbuilderplus.png staging/solaris-sparc/scripts/images/edb-stackbuilderplus-$PG_VERSION_STR.png  || _die "Failed to copy the menu pick images (resources/edb-stackbuilderplus.png)"
    cp resources/pg-postgresql.png staging/solaris-sparc/scripts/images/pg-postgresql-$PG_VERSION_STR.png  || _die "Failed to copy the menu pick images (pg-postgresql.png)"

    mkdir -p staging/solaris-sparc/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    mkdir -p staging/solaris-sparc/UpdateManager/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/solaris-sparc/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/edb-stackbuilderplus.desktop staging/solaris-sparc/scripts/xdg/edb-stackbuilderplus-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/edb-sbp-update-monitor.desktop staging/solaris-sparc/UpdateManager/scripts/xdg/edb-sbp-update-monitor.desktop || _die "Failed to copy the startup pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer for solaris-sparc"
   
    cd $WD
}


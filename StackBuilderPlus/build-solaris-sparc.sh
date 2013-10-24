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
    patch -p0 < $WD/../tarballs/StackBuilderPlus_solaris.patch
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

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; rm -f create_debug_symbols.sh"

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
export CC="cc"
export CXX="CC -library=stlport4"
export CFLAGS="-m64 -library=stlport4" 
export CXXFLAGS="-m64 -library=stlport4"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/opt/local/Current/lib:/opt/qt-4.4.3-gnu/lib:/usr/sfw/lib/64
export PATH=/opt/qt-4.4.3-gnu/bin:/opt/gettext-0.18.1.1/inst/bin:$PG_SOLARIS_STUDIO_SOLARIS_SPARC/bin:/opt/cmake-2.8.8/bin:/opt/local/Current/bin:/usr/local/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/ucb:\$PATH
EOT
    scp setenv.sh $PG_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"

    cd $WD/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc

    # Configure
    echo "Configuring the StackBuilder Plus source tree"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; cmake -D CMAKE_BUILD_TYPE:STRING=Release -D WX_CONFIG_PATH:FILEPATH=/opt/local/Current/bin/wx-config -D WX_DEBUG:BOOL=OFF -D WX_STATIC:BOOL=ON -D CMAKE_INSTALL_PREFIX:PATH=$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc -D CMAKE_CXX_FLAGS:STRING=\"-m64\" ."

    # Build the app
    echo "Building & installing StackBuilderPlus"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; gmake all" || _die "Failed to build StackBuilderPlus"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/StackBuilderPlus.solaris-sparc/; gmake install" || _die "Failed to install StackBuilderPlus"

    echo "Building & installing UpdateManager"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc; $PG_QMAKE_SOLARIS_SPARC UpdateManager.pro" || _die "Failed to configure UpdateManager on solaris-sparc"
    #ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc; $PG_QMAKE_SOLARIS_SPARC QMAKESPEC=/usr/local/mkspecs/solaris-cc-64 QMAKE_CFLAGS=-m64 QMAKE_LFLAGS=-m64 QMAKE_CXX=\"CC -m64\" QMAKE_LIBS=\"-L /usr/sfw/lib/64 -L$PG_SOLARIS_STUDIO_SOLARIS_X64/lib/v9\" UpdateManager.pro" || _die "Failed to configure UpdateManager on solaris-sparc"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc; gmake" || _die "Failed to build UpdateManger on solaris-sparc"
      
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/bin" || _die "Failed to create the bin directory" 
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to create the bin directory" 
   
    echo "Copying UpdateManager binary to staging directory"
    ssh $PG_SSH_SOLARIS_SPARC "cp $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/source/updatemanager.solaris-sparc/UpdateManager $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/bin" || _die "Failed to copy the UpdateManager binary"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN/../lib' $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/bin/UpdateManager" || _die "Failed to change the rpath of UpdateManager binary"

    echo "Copying dependent libraries to staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp -Pr /opt/qt-4.4.3-gnu/lib/libQtXml.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtXml.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN' $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib/libQtXml.so.*" || _die "Failed to change the rpath of libQtXml.so"
    ssh $PG_SSH_SOLARIS_SPARC "cp -Pr /opt/qt-4.4.3-gnu/lib/libQtNetwork.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtNetwork.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN' $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib/libQtNetwork.so.*" || _die "Failed to change the rpath of libQtNetwork.so"
    ssh $PG_SSH_SOLARIS_SPARC "cp -Pr /opt/qt-4.4.3-gnu/lib/libQtCore.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtCore.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN' $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib/libQtCore.so.*" || _die "Failed to change the rpath of libQtCore.so"
    ssh $PG_SSH_SOLARIS_SPARC "cp -Pr /opt/qt-4.4.3-gnu/lib/libQtGui.so.* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib" || _die "Failed to copy dependent library (libQtGui.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN' $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/UpdateManager/lib/libQtGui.so.*" || _die "Failed to change the rpath of libQtGui.so"
    #ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libpng12.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpng12.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libpng15.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpng15.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libssl.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libssl.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libcrypto.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libcrypto.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libiconv.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libiconv.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libexpat.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libexpat.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libgssapi_krb5.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libgssapi_krb5.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libkrb5.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libkrb5.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libkrb5support.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libkrb5.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libcom_err.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libcom_err.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libk5crypto.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libk5crypto.so) in staging directory (solaris-sparc)"
    #ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libjpeg.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libjpeg.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libjpeg.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libjpeg.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libtiff.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libtiff.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libz.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libz.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/sfw/lib/64/libfreetype.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libfreetype.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libfontconfig.so* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libfontconfig.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libpango-* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /usr/lib/64/libpangoft2* $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libpangoft2-1.0.so) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp /opt/local/Current/lib/libuuid.so.16 $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libuuid.so.16) in staging directory (solaris-sparc)"
    ssh $PG_SSH_SOLARIS_SPARC "cp -r $PG_SOLARIS_STUDIO_SOLARIS_SPARC/lib/stlport4/v9/libstlport.so.1 $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/lib" || _die "Failed to copy dependent library (libstlport.so.1) in staging directory (solaris-sparc)"
    #scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc/* $WD/StackBuilderPlus/staging/solaris-sparc/ || _die "Failed to copy back the staging directory from Solaris VM"

    # Generate debug symbols
    scp $WD/create_debug_symbols.sh $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC || _die "Failed to copy create_debug_symbols.sh on solaris-sparc build machine"

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc" || _die "Failed to execute create_debug_symbols.sh"

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging; /usr/sfw/bin/gtar cpvzf solaris-sparc.tar.gz solaris-sparc" || _die "Failed to create tar file"
    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/StackBuilderPlus/staging/solaris-sparc.tar.gz $WD/StackBuilderPlus/staging/ || _die "Failed to copy back the staging directory from Solaris VM"

    cd $WD/StackBuilderPlus/staging

    tar zxvfp solaris-sparc.tar.gz || _die "Failed to extract tar file"
    rm -f solaris-sparc.tar.gz || _die "Failed to delete tar file"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/solaris-sparc/StackBuilderPlus ];
    then
        echo "Removing existing $WD/output/symbols/solaris-sparc/StackBuilderPlus directory"
        rm -rf $WD/output/symbols/solaris-sparc/StackBuilderPlus  || _die "Couldn't remove the existing $WD/output/symbols/solaris-sparc/StackBuilderPlus directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/solaris-sparc || _die "Failed to create $WD/output/symbols/solaris-sparc directory"
    mv $WD/StackBuilderPlus/staging/solaris-sparc/symbols $WD/output/symbols/solaris-sparc/StackBuilderPlus || _die "Failed to move $WD/StackBuilderPlus/staging/solaris-sparc/StackBuilderPlus/symbols to $WD/output/symbols/solaris-sparc/StackBuilderPlus directory"

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

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/solaris-sparc -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/solaris-sparc -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/solaris-sparc -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/solaris-sparc -name \*.sh -exec chmod 755 {} \;
    
    cp scripts/solaris/createshortcuts.sh staging/solaris-sparc/installer/StackBuilderPlus/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/solaris/createshortcuts.sh)"
    cp scripts/solaris/removeshortcuts.sh staging/solaris-sparc/installer/StackBuilderPlus/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/removeshortcuts.sh)"
    cp scripts/solaris/configlibs.sh staging/solaris-sparc/installer/StackBuilderPlus/configlibs.sh || _die "Failed to copy the removeshortcuts script (scripts/solaris/configlibs.sh)"
    chmod ugo+x staging/solaris-sparc/installer/StackBuilderPlus/*.sh

    mkdir -p staging/solaris-sparc/scripts || _die "Failed to create a directory for the launch scripts"
    chmod 755 staging/solaris-sparc/scripts
    cp scripts/solaris/launchSBPUpdateMonitor.sh staging/solaris-sparc/UpdateManager/scripts/launchSBPUpdateMonitor.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchSBPUpdateMonitor.sh)"
    cp scripts/solaris/launchStackBuilderPlus.sh staging/solaris-sparc/scripts/launchStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/solaris/launchStackBuilderPlus.sh)"
    cp scripts/solaris/runStackBuilderPlus.sh staging/solaris-sparc/scripts/runStackBuilderPlus.sh || _die "Failed to copy the launch scripts (scripts/solaris/runStackBuilderPlus.sh)"

    # Copy the XDG scripts
    mkdir -p staging/solaris-sparc/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    chmod 755 staging/solaris-sparc/installer/xdg
    cp $WD/scripts/xdg/xdg* staging/solaris-sparc/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/solaris-sparc/installer/xdg/xdg*

    mkdir -p staging/solaris-sparc/scripts/images || _die "Failed to create a directory for the menu pick images"
    chmod 755 staging/solaris-sparc/scripts/images
    cp resources/edb-stackbuilderplus.png staging/solaris-sparc/scripts/images/ || _die "Failed to copy the menu pick images (resources/edb-stackbuilderplus.png)"
    cp resources/pg-postgresql.png staging/solaris-sparc/scripts/images/ || _die "Failed to copy the menu pick images (pg-postgresql.png)"

    mkdir -p staging/solaris-sparc/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    chmod 755 staging/solaris-sparc/scripts/xdg
    mkdir -p staging/solaris-sparc/UpdateManager/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    chmod 755 staging/solaris-sparc/UpdateManager/scripts/xdg
    cp resources/xdg/pg-postgresql.directory staging/solaris-sparc/scripts/xdg/ || _die "Failed to copy a menu pick directory"
    cp resources/xdg/edb-stackbuilderplus.desktop staging/solaris-sparc/scripts/xdg/ || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/edb-sbp-update-monitor.desktop staging/solaris-sparc/UpdateManager/scripts/xdg/ || _die "Failed to copy the startup pick desktop"

    # Set 644 for all files and folders
    find staging/solaris-sparc/ -type f | xargs -I{} chmod 644 {}
    
    # Set Permissions for links and folders
    find staging/solaris-sparc/ -xtype l | xargs -I{} chmod 777 {}
    find staging/solaris-sparc/ -type d | xargs -I{} chmod 755 {}

    # " executable" requires a ' ' prefix to ensure it is not a filename
    find staging/solaris-sparc/ -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find staging/solaris-sparc/ -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer for solaris-sparc"

    #Copy staging directory
    copy_binaries StackBuilderPlus solaris-sparc
   
    cd $WD
}


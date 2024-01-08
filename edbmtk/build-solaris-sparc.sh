#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_solaris_sparc() {

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.solaris-sparc ];
    then
      echo "Removing existing edbmtk.solaris-sparc source directory"
      rm -rf edbmtk.solaris-sparc  || _die "Couldn't remove the existing edbmtk.solaris-sparc source directory (source/edbmtk.solaris-sparc)"
    fi
   
    echo "Creating staging directory ($WD/edbmtk/source/edbmtk.solaris-sparc)"
    mkdir -p $WD/edbmtk/source/edbmtk.solaris-sparc || _die "Couldn't create the edbmtk.solaris-sparc directory"
    chmod 755 edbmtk.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the binaries
    cp -R EDB-MTK/* edbmtk.solaris-sparc || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_EDBMTK)"

    # Copy edb-jdbc16.jar from connectors
    cp $WD/connectors/staging/solaris-sparc/jdbc/edb-jdbc16.jar edbmtk.solaris-sparc/lib || _die "Failed to copy edb-jdbc16.jar from connectors staging directory to source."

    chmod -R 755 edbmtk.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    cp pgJDBC-$EDB_VERSION_PGJDBC/postgresql-$EDB_VERSION_PGJDBC.jdbc4.jar edbmtk.solaris-sparc/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Cleanup build machine
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; rm -f edbmtk.solaris-sparc.zip"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; rm -f edbmtk-output.zip"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; rm -rf edbmtk.solaris-sparc"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; rm -rf edbmtk-output"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/solaris-sparc)"
    mkdir -p $WD/edbmtk/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"
    
}

################################################################################
# PG Build
################################################################################

_build_edbmtk_solaris_sparc() {

    # build migrationtoolkit    
    EDB_STAGING=$EDB_PATH_SOLARIS_SPARC/edbmtk-output

    cat <<EOT > "setenvas.sh"
export CC="cc -m64"
export CXX="CC -m64 -library=stlport4"
export CPP="cc -E -m64"
export CXXPP="CC -E -m64 -library=stlport4"
export CFLAGS="-m64 -fPIC"
export CXXFLAGS="-m64 -KPIC"
export CPPFLAGS="-m64 -KPIC"
export LDFLAGS="-m64 -KPIC"
export LD_LIBRARY_PATH=/opt/local/Current/lib
export PATH=$EDB_SOLARIS_STUDIO_SOLARIS_SPARC/bin:/opt/local/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:\$PATH

EOT
    scp setenvas.sh $EDB_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"

    # Copy source code to build machine
    cd $WD/edbmtk/source

    # Copy PPAS source
    zip -r edbmtk.solaris-sparc.zip edbmtk.solaris-sparc || _die "Failed to pack the source tree (edbmtk.solaris-sparc)"
    scp edbmtk.solaris-sparc.zip $EDB_SSH_SOLARIS_SPARC:$EDB_PATH_SOLARIS_SPARC || _die "Failed to copy the source tree to the solaris-sparc build host (edbmtk.solaris-sparc.zip)"
    rm -f edbmtk.solaris-sparc.zip || _die "Failed to remove edbmtk.solaris-sparc.zip from local machine"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; unzip -o edbmtk.solaris-sparc.zip" || _die "Failed to unpack edbmtk.solaris-sparc.zip"

    echo "Building migrationtoolkit"
    ssh $EDB_SSH_SOLARIS_SPARC "mkdir $EDB_STAGING" || _die "Failed to create staging output directory"
    ssh $EDB_SSH_SOLARIS_SPARC "source setenvas.sh; cd $EDB_PATH_SOLARIS_SPARC/edbmtk.solaris-sparc; JAVA_HOME=$EDB_JAVA_HOME_SOLARIS_SPARC $EDB_ANT_HOME_SOLARIS_SPARC/bin/ant clean" || _die "Couldn't build the migrationtoolkit"
    ssh $EDB_SSH_SOLARIS_SPARC "source setenvas.sh; cd $EDB_PATH_SOLARIS_SPARC/edbmtk.solaris-sparc; JAVA_HOME=$EDB_JAVA_HOME_SOLARIS_SPARC $EDB_ANT_HOME_SOLARIS_SPARC/bin/ant -f build.xml install-as" || _die "Couldn't build the migrationtoolkit"

    # Copying the MigrationToolKit binary to staging directory
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC/edbmtk.solaris-sparc; cp -R install/* $EDB_STAGING" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (edbmtk/staging/solaris-sparc)"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_STAGING; mkdir doc" || _die "Failed to create doc directory"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC; mv $EDB_STAGING/README-mtk.txt $EDB_STAGING/doc" || _die "Failed to copy the README-mtk.txt into the staging directory"
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_STAGING/bin; rm -f *.bat" || _die "Failed to remove .bat files from bin staging directory"

    # Zip edbmtk output directory
    ssh $EDB_SSH_SOLARIS_SPARC "cd $EDB_PATH_SOLARIS_SPARC/edbmtk-output; zip -r edbmtk-output.zip *" || _die "Failed to zip edbmtk-output directory"

    cd $WD/edbmtk/staging/solaris-sparc
    scp $EDB_SSH_SOLARIS_SPARC:$EDB_PATH_SOLARIS_SPARC/edbmtk-output/edbmtk-output.zip . || _die "Failed to copy edbmtk-output.zip"

    unzip -o edbmtk-output.zip || _die "Failed to unzip edbmtk-output.zip"
    rm -f edbmtk-output.zip || _die "Failed to remove edbmtk-output.zip"

}


################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_solaris_sparc() {
 
    cd $WD/edbmtk

    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f3 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/solaris-sparc/bin/runMTK.sh || _die "Failed to put $CORE_EDBMTK_VERSION in runMTK.sh"

    mkdir -p staging/solaris-sparc/etc/sysconfig || _die "Failed to create etc/sysconfig directory"

    cp scripts/common/edbmtk.config staging/solaris-sparc/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to create file edbmtk-$CORE_EDBMTK_VERSION.config"
    cp $WD/scripts/common_scripts/runJavaApplication.sh staging/solaris-sparc/etc/sysconfig/ || _die "Failed to copy runJavaApplication.sh"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/solaris-sparc/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to put CORE_EDBMTK_VERSION in edbmtk-$CORE_EDBMTK_VERSION.config"

    chmod ugo+x staging/solaris-sparc/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/solaris-sparc -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/solaris-sparc -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/solaris-sparc -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/solaris-sparc -name \*.sh -exec chmod 755 {} \;

    # Build the installer
    "$EDB_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer"

    #Copy staging directory
    copy_binaries edbmtk solaris-sparc

    cd $WD
}


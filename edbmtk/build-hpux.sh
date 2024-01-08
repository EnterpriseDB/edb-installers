#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_hpux() {

    ARCH="hpux"
    EDB_BLD=$EDB_HPUX_BLD

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.$ARCH ];
    then
      echo "Removing existing edbmtk.$ARCH source directory"
      rm -rf edbmtk.$ARCH  || _die "Couldn't remove the existing edbmtk.$ARCH source directory (source/edbmtk.$ARCH)"
    fi
   
    echo "Creating staging directory ($WD/edbmtk/source/edbmtk.$ARCH)"
    mkdir -p $WD/edbmtk/source/edbmtk.$ARCH || _die "Couldn't create the edbmtk.$ARCH directory"

    # Grab a copy of the binaries
    cp -R $EDB_BLD/edb-mtk/* edbmtk.$ARCH || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_EDBMTK)"
    chmod -R 755 edbmtk.$ARCH || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/$ARCH)"
    mkdir -p $WD/edbmtk/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/edbmtk/staging/$ARCH/doc || _die "Couldn't create the staging directory"
    chmod 755 $WD/edbmtk/staging/$ARCH/doc || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_edbmtk_hpux() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_hpux() {

    ARCH="hpux"
    EDB_BLD=$EDB_HPUX_BLD
    ARCH_TAG=$ARCH
 
    cp -R $WD/edbmtk/source/edbmtk.$ARCH/* $WD/edbmtk/staging/$ARCH || _die "Failed to copy the edbmtk Source into the staging directory"
    mv $WD/edbmtk/staging/$ARCH/*.txt $WD/edbmtk/staging/$ARCH/doc || _die "Failed to copy the edbmtk Source into the staging directory"

    cd $WD/edbmtk

    # Build the installer
    "$EDB_INSTALLBUILDER_BIN" build installer.xml $ARCH || _die "Failed to build the installer"
    
    if [ "$ARCH" != "$ARCH_TAG" ];
    then
       mv $WD/output/edb_edbmtk-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-$ARCH.run $WD/output/edb_edbmtk-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-$ARCH_TAG.run || _die "Failed to rename the installer"
    fi

    cd $WD
}


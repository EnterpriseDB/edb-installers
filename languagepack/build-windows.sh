#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_languagepack_windows() {

    ARCH=$1
    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       EDB_BLD=$EDB_WINDOWS_BLD
    else
       ARCH="windows-x64"
       EDB_BLD=$EDB_WINDOWS_X64_BLD
    fi

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source

    if [ -e languagepack.$ARCH ];
    then
      echo "Removing existing languagepack.$ARCH source directory"
      rm -rf languagepack.$ARCH  || _die "Couldn't remove the existing languagepack.$ARCH source directory (source/languagepack.$ARCH)"
    fi
   
    echo "Creating staging directory ($WD/languagepack/source/languagepack.$ARCH)"
    mkdir -p $WD/languagepack/source/languagepack.$ARCH || _die "Couldn't create the languagepack.$ARCH directory"

    # Grab a copy of the binaries
    cp -R $EDB_BLD/LanguagePack/* languagepack.$ARCH || _die "Failed to copy the source code (source/languagepack)"
    chmod -R ugo+w languagepack.$ARCH || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/$ARCH)"
    mkdir -p $WD/languagepack/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_languagepack_windows() {

    cd $WD
}


################################################################################
# PG Build
################################################################################

_postprocess_languagepack_windows() {

    ARCH=$1

    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       OS="windows"
       EDB_BLD=$EDB_WINDOWS_BLD
    else
       ARCH="windows-x64"
       OS=$ARCH
       EDB_BLD=$EDB_WINDOWS_X64_BLD
    fi
 
    cp -R $EDB_BLD/LanguagePack/* $WD/languagepack/staging/$ARCH  || _die "Failed to copy the languagepack Source into the staging directory"

    mkdir -p $WD/languagepack/staging/$ARCH/installer/languagepack || _die "Failed to create a directory for the install scripts"
    cp $WD/languagepack/scripts/windows/installruntimes.vbs $WD/languagepack/staging/$ARCH/installer/languagepack/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"

    if [ "$ARCH" = "windows-x64" ];
    then
	cp $WD/binaries/vcredist_x64.exe $WD/languagepack/staging/$ARCH/installer/languagepack
    else
	cp $WD/binaries/vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack
    fi   
 
    cd $WD/languagepack
    ##mv staging/$ARCH/languagepack.config staging/$ARCH/languagepack-$EDB_VERSION_LANGUAGEPACK.config || _die "Failed to rename the config file"
    
    rm -rf $WD/languagepack/staging/windows
    mv $WD/languagepack/staging/$ARCH $WD/languagepack/staging/windows || _die "Failed to rename $ARCH staging directory to windows"

    if [ "$ARCH" = "windows-x64" ];
    then
        # Build the installer
        "$EDB_INSTALLBUILDER_BIN" build installer.xml windows --setvars windowsArchitecture=x64 || _die "Failed to build the installer"
    else
        # Build the installer
        "$EDB_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    fi

    if [ $SIGNING -eq 1 ]; then
        win32_sign "*_languagepack-$EDB_VERSION_LANGUAGEPACK-$EDB_BUILDNUM_LANGUAGEPACK-$OS.exe"
    fi

    mv $WD/languagepack/staging/windows $WD/languagepack/staging/$ARCH || _die "Failed to rename windows staging directory to $ARCH"
    cd $WD
}


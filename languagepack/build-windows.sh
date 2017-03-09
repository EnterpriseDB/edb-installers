#!/bin/bash

    
################################################################################
# Build Preparation
################################################################################

_prep_languagepack_windows() {

    ARCH=$1
    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\i386"
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\x64"
    fi

    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source
    echo "Removing existing languagepack.$ARCH source directory and languagepack.zip"
    rm -rf languagepack.$ARCH*  || _die "Couldn't remove the existing languagepack.$ARCH source directory (source/languagepack.$ARCH)"
   
    echo "Creating source directory ($WD/languagepack/source/languagepack.$ARCH)"
    mkdir -p $WD/languagepack/source/languagepack.$ARCH || _die "Couldn't create the languagepack.$ARCH directory"

    # Copy languagepack build scripts
    cp $WD/languagepack/scripts/$ARCH/Tcl_Tk_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Tcl_Tk_Build.bat)"
    cp $WD/languagepack/scripts/$ARCH/Perl_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Perl_Build.bat)"
    cp $WD/languagepack/scripts/$ARCH/Python_Build.bat languagepack.$ARCH || _die "Failed to copy the languagepack build script (Python_Build.bat)"

    cd $WD/languagepack/source/languagepack.$ARCH
    extract_file $WD/../tarballs/tcl8.6.6-src || _die "Failed to extract tcl/tk source (tcl8.6.6-src.tar.gz)"
    extract_file $WD/../tarballs/tk8.6.6-src || _die "Failed to extract tcl/tk source (tk8.6.6-src.tar.gz)"
    extract_file $WD/../tarballs/perl-5.24.0 || _die "Failed to extract perl source (perl-5.24.0.tar.gz)"
    extract_file $WD/../tarballs/Python-3.5.2 || _die "Failed to extract python source (Python-3.5.2.tgz)"
    extract_file $WD/../tarballs/distribute-0.6.49 || _die "Failed to extract python source (distribute-0.6.49)"

    if [ "$ARCH" = "windows-x32" ];
    then
        # Perl related changes - x32
        cd perl-5.24.0/win32
        sed -i "s/^INST_DRV\t\*= c:/INST_DRV\t\*= $PG_LANGUAGEPACK_INSTALL_DIR_WIN/g" makefile.mk
        sed -i 's/^INST_TOP\t\*= $(INST_DRV)\\perl/INST_TOP\t\*= $(INST_DRV)\\Perl-5.24/g' makefile.mk
        sed -i 's/^CCHOME\t\t\*= C:\\MinGW/C:\\MinGW\\mingw-w64\\mingw32/g' makefile.mk
        sed -i 's/^#WIN64/WIN64/g' makefile.mk

        # Python related changes - x32
        echo "extraction Pillow binaries into languagepack.$ARCH source folder."
        cd $WD/languagepack/source/languagepack.$ARCH 
        extract_file $WD/../tarballs/Pillow-3.4.2.win32 || _die "Failed to extract Pillow binaries."
    else
        # Perl related changes - x64
        cd perl-5.24.0/win32
        sed -i "s/^INST_DRV\t\*= c:/INST_DRV\t\*= $PG_LANGUAGEPACK_INSTALL_DIR_WIN/g" makefile.mk
        sed -i 's/^INST_TOP\t\*= $(INST_DRV)\\perl/INST_TOP\t\*= $(INST_DRV)\\Perl-5.24/g' makefile.mk
        sed -i 's/^CCHOME\t\t\*= C:\\MinGW/CCHOME\t\t\*= C:\\MinGW_X64\\mingw64/g' makefile.mk

        # Python related changes - x64
        echo "extraction Pillow binaries into languagepack.$ARCH source folder."
        cd $WD/languagepack/source/languagepack.$ARCH
        extract_file $WD/../tarballs/Pillow-3.4.2.win-amd64 || _die "Failed to extract Pillow binaries."
    fi

    cd $WD/languagepack/source
    echo "Archiving languagepack sources"
    zip -r languagepack.$ARCH.zip languagepack.$ARCH || _die "Failed to zip the languagepack source"
    chmod -R ugo+w languagepack.$ARCH || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q $PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS"

    if [ -e $WD/languagepack/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/$ARCH)"
    mkdir -p $WD/languagepack/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c del /S /Q languagepack.$ARCH.zip"
    
    echo "Copying languagepack sources to Windows VM"
    rsync -av languagepack.$ARCH.zip $PG_SSH_WIN:$PG_CYGWIN_PATH_WINDOWS || _die "Couldn't copy the languagepack archive to windows VM (languagepack.$ARCH.zip)"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q languagepack.$ARCH; unzip languagepack.$ARCH.zip" || _die "Couldn't extract languagepack archive on windows VM (languagepack.$ARCH.zip)"

    echo "END PREP languagepack Windows"
}

################################################################################
# Build LanguagePack
################################################################################

_build_languagepack_windows() {

    ARCH=$1
    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\i386"
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}\\\\x64"
    fi

  # Tcl/Tk Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-8.6; cmd /c Tcl_Tk_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tcl8.6.6 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-8.6 $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tk8.6.6"

    # Perl Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.24.0 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24 PERL"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.24.0 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24 DBI"
##    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.24.0 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24 DBD"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-5.24.0 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-5.24 IPC"

    # Python Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.5; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.5.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.5 $PG_PATH_WIN\\\\languagepack.$ARCH BUILD"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.5; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-3.5.2 $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-3.5 $PG_PATH_WIN\\\\languagepack.$ARCH INSTALL"
}


################################################################################
# Build Postprocess
################################################################################

_postprocess_languagepack_windows() {

    ARCH=$1

    if [ "$ARCH" = "x32" ];
    then
       ARCH="windows-x32"
       OS="windows"
       PG_SSH_WIN=$PG_SSH_WINDOWS
       PG_PATH_WIN=$PG_PATH_WINDOWS
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}/i386"
    else
       ARCH="windows-x64"
       OS=$ARCH
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}/x64"
    fi
    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN; zip -r Tcl-8.6.zip Tcl-8.6; zip -r Perl-5.24.zip Perl-5.24; zip -r Python-3.5.zip Python-3.5" || _die "Failed to create Tcl-8.6.zip;Perl-5.24.zip;Python-3.5.zip on  windows buildhost"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN/Tcl-8.6.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Tcl-8.6.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN/Perl-5.24.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Perl-5.24.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN/Python-3.5.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Python-3.5.zip"

    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN; rm -f Tcl-8.6.zip Perl-5.24.zip Python-3.5.zip " || _die "Failed to remove  Tcl-8.6.zip;Perl-5.24.zip; Python-3.5.zip on  windows buildhost"
    cd $WD/languagepack/staging/$ARCH/
    unzip Tcl-8.6.zip ||_die " ailed to unzip Tcl-8.6.zip"
    unzip Perl-5.24.zip || _die "Failed to unzip Perl-5.24.zip"
    unzip Python-3.5.zip || _die "Failed to unzip Python-3.5.zip"
    rm -f Tcl-8.6.zip Perl-5.24.zip Python-3.5.zip || _die "Failed to remove the Tcl-8.6.zip;Perl-5.24.zip;Python-3.5.zip"

    mv $WD/languagepack/staging/$ARCH/Python-3.5/pip_packages_list.txt $WD/languagepack/staging/$ARCH || _die "Failed to move pip_packages_list.txt to $WD/languagepack/staging/$ARCH"
    
    # Using __inline (MSCV) instead of __inline__ (gcc -ansi) as Perl-5.24.0 was build with mingw64
    sed -i "s/^#define PERL_STATIC_INLINE static __inline__/#define PERL_STATIC_INLINE static __inline/g" $WD/languagepack/staging/$ARCH/Perl-5.24/lib/CORE/config.h

    cd $WD/languagepack
    pushd staging/$ARCH
    generate_3rd_party_license "languagepack"
    popd

    mkdir -p $WD/languagepack/staging/$ARCH/installer/languagepack || _die "Failed to create a directory for the install scripts"
    cp $WD/languagepack/scripts/$ARCH/installruntimes.vbs $WD/languagepack/staging/$ARCH/installer/languagepack/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"

    if [ "$ARCH" = "windows-x64" ];
    then
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x64.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x64.exe || _die "Failed to get vcredist_x64.exe from windows build host"
    else
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x86.exe || _die "Failed to get vcredist_x86.exe from windows build host"
    fi   
 
    cd $WD/languagepack
    rm -rf $WD/languagepack/staging/windows
    mv $WD/languagepack/staging/$ARCH $WD/languagepack/staging/windows || _die "Failed to rename $ARCH staging directory to windows"

    if [ "$ARCH" = "windows-x64" ];
    then
        # Build the installer
        "$PG_INSTALLBUILDER_BIN" build installer.xml windows --setvars windowsArchitecture=x64 || _die "Failed to build the installer"
    else
        # Build the installer
        "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    fi

    if [ $SIGNING -eq 1 ]; then
        win32_sign "*-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-$OS.exe"
    fi

    mv $WD/languagepack/staging/windows $WD/languagepack/staging/$ARCH || _die "Failed to rename windows staging directory to $ARCH"
    cd $WD
}

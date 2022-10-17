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
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}"
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}"
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
    extract_file $WD/../tarballs/tcl${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src || _die "Failed to extract tcl/tk source (tcl-${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src.tar.gz)"
    extract_file $WD/../tarballs/tk${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src || _die "Failed to extract tcl/tk source (tk-${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL}-src.tar.gz)"
    extract_file $WD/../tarballs/perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} || _die "Failed to extract perl source (perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64}.tar.gz)"
    extract_file $WD/../tarballs/Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON} || _die "Failed to extract python source (Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}.tgz)"
    extract_file $WD/../tarballs/setuptools-${PG_VERSION_PYTHON_SETUPTOOLS} || _die "Failed to extract python source (setuptools-${PG_VERSION_PYTHON_SETUPTOOLS})"

    pushd perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64}/win32
        if [ "$ARCH" = "windows-x32" ];
        then
            # Perl related changes - x32
            sed -i 's/^#WIN64\t\t= undef/WIN64\t\t= undef/g' Makefile
        fi
	sed -i "s|^INST_DRV\t=.*|INST_DRV\t= ${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}|" Makefile
	sed -i "s|INST_TOP\t=.*$|INST_TOP\t= \$(INST_DRV)\\\Perl-${PG_VERSION_PERL_WINDOWS64}|" Makefile
        sed -i 's/^#CCTYPE\t\t= MSVC141/CCTYPE\t\t= MSVC141/g' Makefile
    popd

    # Changes to build Python with openssl-3.0.5 external binaries
    sed -i '0,/rmdir/s//rem rmdir/' Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}/PCbuild/get_externals.bat
    sed -i 's/-1_1/-3-x64/' Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}/PCbuild/openssl.props
    mkdir -p Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}/externals/openssl-bin-1.1.1q/amd64/include

    # Python 3.9 vesion has issue with not finding tcl.h for _tkinter.c 
    # Fixing in _tkinter.vcxproj
    sed -i "s|\$(tcltkDir)include|\$(tcltkDir)\\\include|" Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}/PCbuild/_tkinter.vcxproj
    cd $WD/languagepack/source
    echo "Archiving languagepack sources"
    zip -qr languagepack.$ARCH.zip languagepack.$ARCH || _die "Failed to zip the languagepack source"
    chmod -R ugo+w languagepack.$ARCH || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c rd /S /Q $PG_LANGUAGEPACK_INSTALL_DIR_WIN"

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
    rsync -av languagepack.$ARCH.zip $PG_SSH_WIN:$PG_CYGWIN_PATH_WINDOWS_X64 || _die "Couldn't copy the languagepack archive to windows VM (languagepack.$ARCH.zip)"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN; cmd /c unzip -qq -o languagepack.$ARCH.zip" || _die "Couldn't extract languagepack archive on windows VM (languagepack.$ARCH.zip)"


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
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}"
       CYGWIN_HOME="C:\\\\cygwin32"
       PG_PATH_PSYCOPG=$PG_BINARY_PATH
    else
       ARCH="windows-x64"
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_INSTALL_DIR_WINDOWS}"
       CYGWIN_HOME="C:\\\\cygwin64"
       PG_PATH_PSYCOPG=$PG_BINARY_PATH_X64
    fi

    # Tcl/Tk Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-${PG_VERSION_TCL}; cmd /c Tcl_Tk_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tcl${PG_VERSION_TCL}.${PG_MINOR_VERSION_TCL} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Tcl-${PG_VERSION_TCL} $PG_PATH_WIN\\\\languagepack.$ARCH\\\\tk${PG_VERSION_TK}.${PG_MINOR_VERSION_TK}"

    # Perl Build
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output PERL"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output DBI"
    # Install cpanm to exclude running test cases when installing IPC and DBD as one of test cases stucks
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output CPANMINUS"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output IPC"
   ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output WIN32PROCESS"
    # install.pm gets installed as part of IPC installation. Uninstall it as postgres installation fails because of it.
  ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64}; cmd /c Perl_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\perl-${PG_VERSION_PERL_WINDOWS64}.${PG_MINOR_VERSION_PERL_WINDOWS64} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Perl-${PG_VERSION_PERL_WINDOWS64} $PG_PATH_WIN\\\\output INSTALL"

    # Python Build

    # Copying Openssl 3.x files to openssl-bin-1.1.1q directory structure.
    ssh $PG_SSH_WIN "cmd /c copy $PG_PGBUILD_WIN\\\\lib\\\\libssl* $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64" || _die "Failed to copy libssl from lib folder to external openssl folder"
    ssh $PG_SSH_WIN "cmd /c copy $PG_PGBUILD_WIN\\\\lib\\\\libcrypto* $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64" || _die "Failed to copy libcrypto from lib folder to external openssl folder"
    ssh $PG_SSH_WIN "cmd /c copy $PG_PGBUILD_WIN\\\\bin\\\\libssl* $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64" || _die "Failed to copy libssl from bin folder to external openssl folder"
    ssh $PG_SSH_WIN "cmd /c copy $PG_PGBUILD_WIN\\\\bin\\\\libcrypto* $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64" || _die "Failed to copy libcrypto from bin folder to external openssl folder"
    ssh $PG_SSH_WIN "cmd /c copy $PG_PGBUILD_WIN\\\\include\\\\openssl\\\\applink.c $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64\\\\include" || _die "Failed to copy applink.c from include folder to external openssl folder"
    ssh $PG_SSH_WIN "cp -R $PG_PGBUILD_WIN\\\\include\\\\openssl $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON}\\\\externals\\\\openssl-bin-1.1.1q\\\\amd64\\\\include" || _die "Failed to copy openssl from include folder to external openssl folder"

    cd $WD/languagepack/scripts/$ARCH

    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-${PG_VERSION_PYTHON}; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-${PG_VERSION_PYTHON} $PG_PATH_WIN\\\\languagepack.$ARCH $PG_PGBUILD_WIN BUILD"
    ssh $PG_SSH_WIN "cd $PG_PATH_WIN\\\\languagepack.$ARCH; mkdir -p $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-${PG_VERSION_PYTHON}; cmd /c Python_Build.bat $PG_PATH_WIN\\\\languagepack.$ARCH\\\\Python-${PG_VERSION_PYTHON}.${PG_MINOR_VERSION_PYTHON} $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\Python-${PG_VERSION_PYTHON} $PG_PATH_WIN\\\\languagepack.$ARCH $PG_PGBUILD_WIN INSTALL"

    echo "Removing last successful staging directory ($PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging)"
    ssh $PG_SSH_WIN "cmd /c if EXIST $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging rd /S /Q $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WIN "cmd /c mkdir $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WIN "cmd /c xcopy /E /Q /Y $PG_LANGUAGEPACK_INSTALL_DIR_WIN\\\\* $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WIN "cmd /c echo PG_VERSION_LANGUAGEPACK=$PG_VERSION_LANGUAGEPACK >  $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh" || _die "Failed to write languagepack version number into versions-windows.sh"
    ssh $PG_SSH_WIN "cmd /c echo PG_BUILDNUM_LANGUAGEPACK=$PG_BUILDNUM_LANGUAGEPACK >> $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh" || _die "Failed to write languagepack build number into versions-windows.sh"

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
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}"
    else
       ARCH="windows-x64"
       OS=$ARCH
       PG_SSH_WIN=$PG_SSH_WINDOWS_X64
       PG_PATH_WIN=$PG_PATH_WINDOWS_X64
       PG_PGBUILD_WIN=$PG_PGBUILD_WINDOWS_X64
       PG_LANGUAGEPACK_INSTALL_DIR_WIN="${PG_LANGUAGEPACK_CYG_PATH}"
    fi

    # Remove any existing staging/install directory that might exist, and create a clean one
    echo "Removing existing install directory"
    if [ -e $WD/languagepack/staging/$ARCH ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/$ARCH || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/languagepack/staging/$ARCH)"
    mkdir -p $WD/languagepack/staging/$ARCH || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/$ARCH || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging; zip -r Tcl-${PG_VERSION_TCL}.zip Tcl-${PG_VERSION_TCL}; zip -r Perl-${PG_VERSION_PERL_WINDOWS64}.zip Perl-${PG_VERSION_PERL_WINDOWS64}; zip -r Python-${PG_VERSION_PYTHON}.zip Python-${PG_VERSION_PYTHON}" || _die "Failed to create Tcl-${PG_VERSION_TCL}.zip;Perl-${PG_VERSION_PERL_WINDOWS64}.zip;Python-${PG_VERSION_PYTHON}.zip on  windows buildhost"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Tcl-${PG_VERSION_TCL}.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Tcl-${PG_VERSION_TCL}.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Perl-${PG_VERSION_PERL_WINDOWS64}.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Perl-${PG_VERSION_PERL_WINDOWS64}.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/Python-${PG_VERSION_PYTHON}.zip  $WD/languagepack/staging/$ARCH || _die "Failed to copy Python-${PG_VERSION_PYTHON}.zip"
    rsync -av $PG_SSH_WIN:$PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging/versions-${ARCH}.sh  $WD/languagepack/staging/$ARCH || _die "Failed to copy versions-${ARCH}.sh"

    ssh $PG_SSH_WIN "cd $PG_LANGUAGEPACK_INSTALL_DIR_WIN.staging; rm -f Tcl-${PG_VERSION_TCL}.zip Perl-${PG_VERSION_PERL_WINDOWS64}.zip Python-${PG_VERSION_PYTHON}.zip " || _die "Failed to remove  Tcl-${PG_VERSION_TCL}.zip;Perl-${PG_VERSION_PERL_WINDOWS64}.zip; Python-${PG_VERSION_PYTHON}.zip on  windows buildhost"

    cd $WD/languagepack/staging/$ARCH/
    unzip -qq -o Tcl-${PG_VERSION_TCL}.zip ||_die "Failed to unzip Tcl-${PG_VERSION_TCL}.zip"
    unzip -qq -o Perl-${PG_VERSION_PERL_WINDOWS64}.zip || _die "Failed to unzip Perl-${PG_VERSION_PERL_WINDOWS64}.zip"
    unzip -qq -o Python-${PG_VERSION_PYTHON}.zip || _die "Failed to unzip Python-${PG_VERSION_PYTHON}.zip"
    rm -f Tcl-${PG_VERSION_TCL}.zip Perl-${PG_VERSION_PERL_WINDOWS64}.zip Python-${PG_VERSION_PYTHON}.zip || _die "Failed to remove the Tcl-${PG_VERSION_TCL}.zip;Perl-${PG_VERSION_PERL_WINDOWS64}.zip;Python-${PG_VERSION_PYTHON}.zip"

    dos2unix $WD/languagepack/staging/$ARCH/versions-${ARCH}.sh || _die "Failed to convert format of versions-${ARCH}.sh from dos to unix"
    source $WD/languagepack/staging/$ARCH/versions-${ARCH}.sh
    PG_BUILD_LANGUAGEPACK=$(expr $PG_BUILD_LANGUAGEPACK + $SKIPBUILD)

    cd $WD/languagepack
    pushd staging/$ARCH

    # DBSCM-385, Remove pyw.exe from staging as it's detected Trojan Virus.
    find . -name "pyw.exe" | xargs rm -f {} \; || _die "Failed to clear pyw.exe from staging/$ARCHD"

    generate_3rd_party_license "languagepack"
    popd

    mkdir -p $WD/languagepack/staging/$ARCH/installer/languagepack || _die "Failed to create a directory for the install scripts"

    if [ "$ARCH" = "windows-x64" ];
    then
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x64.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x64.exe || _die "Failed to get vcredist_x64.exe from windows build host"
    else
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x86.exe || _die "Failed to get vcredist_x86.exe from windows build host"
        scp -r $PG_SSH_WIN:$PG_PGBUILD_WIN\\\\vcredist\\\\vc2010\\\\vcredist_x86.exe $WD/languagepack/staging/$ARCH/installer/languagepack/vcredist_x86_2010.exe || _die "Failed to get vcredist_x86.exe of version 2010 from windows build host"
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

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_LANGUAGEPACK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-$OS.exe $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}${OS}.exe

    # Signing the installer
    win32_sign "*-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}${OS}.exe"

    mv $WD/languagepack/staging/windows $WD/languagepack/staging/$ARCH || _die "Failed to rename windows staging directory to $ARCH"
    cd $WD
}

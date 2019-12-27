#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_languagepack_osx() {

    echo "BEGIN PREP LanguagePack OSX"

    # Cleanup existing sources on the build machine
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/languagepack"
 
    # Enter the source directory and cleanup if required
    cd $WD/languagepack/source

    if [ -e Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON ];
    then
      echo "Removing existing Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON source directory"
      rm -rf Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON  || _die "Couldn't remove the existing source directory (source/Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON)"
    fi

    echo "Unpacking python source..."
    extract_file  ../../tarballs/Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON || exit 1

    if [ -e python.osx ];
    then
      echo "Removing existing python.osx source directory"
      rm -rf python.osx  || _die "Couldn't remove the existing python.osx source directory (source/python.osx)"
    fi

    # Grab a copy of the python source tree
    cp -pR Python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON python.osx || _die "Failed to copy the source code (source/python-$PG_VERSION_PYTHON.$PG_MINOR_VERSION_PYTHON)" 
    tar -jcvf python.tar.bz2 python.osx || _die "Failed to create the archive (source/python.tar.bz2)"

    if [ -e perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL ];
    then
      echo "Removing existing perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL source directory"
      rm -rf perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL  || _die "Couldn't remove the existing source directory (source/perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL)"
    fi
    
    echo "Unpacking perl source..."
    extract_file  ../../tarballs/perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL || exit 1

    if [ -e perl.osx ];
    then
      echo "Removing existing perl.osx source directory"
      rm -rf perl.osx  || _die "Couldn't remove the existing perl.osx source directory (source/perl.osx)"
    fi
    
    # Grab a copy of the perl source tree
    cp -pR perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL perl.osx || _die "Failed to copy the source code (source/perl-$PG_VERSION_PERL.$PG_MINOR_VERSION_PERL)"
    tar -jcvf perl.tar.bz2 perl.osx || _die "Failed to create the archive (source/perl.tar.bz2)"

    if [ -e tcl-$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL ];
    then
      echo "Removing existing tcl-$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL source directory"
      rm -rf tcl-$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL  || _die "Couldn't remove the existing source directory (source/tcl-$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL)"
    fi
    
    echo "Unpacking tcl source..."
    extract_file  ../../tarballs/tcl$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL-src || exit 1

    if [ -e tcl.osx ];
    then
      echo "Removing existing tcl.osx source directory"
      rm -rf tcl.osx  || _die "Couldn't remove the existing tcl.osx source directory (source/tcl.osx)"
    fi
    # Grab a copy of the tcl source tree
    cp -pR tcl$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL tcl.osx || _die "Failed to copy the source code (source/tcl-$PG_VERSION_TCL.$PG_MINOR_VERSION_TCL)"
    tar -jcvf tcl.tar.bz2 tcl.osx || _die "Failed to create the archive (source/tcl.tar.bz2)"

    if [ -e setuptools-$PG_VERSION_PYTHON_SETUPTOOLS ];
    then
      echo "Removing existing setuptools-$PG_VERSION_PYTHON_SETUPTOOLS source directory"
      rm -rf setuptools-$PG_VERSION_PYTHON_SETUPTOOLS  || _die "Couldn't remove the existing setuptools-$PG_VERSION_PYTHON_SETUPTOOLS source directory (source/setuptools-$PG_VERSION_PYTHON_SETUPTOOLS)"
    fi

    echo "Unpacking setuptools python source..."
    extract_file  ../../tarballs/setuptools-$PG_VERSION_PYTHON_SETUPTOOLS || exit 1

    if [ -e setuptools-python.osx ];
    then
      echo "Removing existing python.osx source directory"
      rm -rf setuptools-python.osx  || _die "Couldn't remove the existing setuptools-python.osx source directory (source/setuptools-python.osx)"
    fi
    cp -pR setuptools-$PG_VERSION_PYTHON_SETUPTOOLS setuptools-python.osx || _die "Failed to copy the source code (source/python-$PG_VERSION_PYTHON)"
    tar -jcvf setuptools-python.tar.bz2 setuptools-python.osx || _die "Failed to create the archive (source/setuptools-python.tar.bz2)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/languagepack/staging/osx)"
    mkdir -p $WD/languagepack/staging/osx || _die "Couldn't create the staging directory"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/languagepack/source" || _die "Failed to create the source dircetory on the build VM"
    scp python.tar.bz2 perl.tar.bz2 tcl.tar.bz2 setuptools-python.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/languagepack/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/languagepack
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/languagepack/source; tar -jxvf python.tar.bz2" || _die "Failed to extract python archive on build VM"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/languagepack/source; tar -jxpvf perl.tar.bz2" || _die "Failed to extract perl archive on build VM"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/languagepack/source; tar -jxvf tcl.tar.bz2" || _die "Failed to extract tcl archive on build VM"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/languagepack/source; tar -jxvf setuptools-python.tar.bz2" || _die "Failed to extract setuptools-python archive on build VM"

    echo "END PREP LanguagePack OSX"
}

################################################################################
# PG Build
################################################################################

_build_languagepack_osx() {
    
   echo "BEGIN BUILD LanguagePack OSX" 

   cd $WD
   cat <<EOT-LANGUAGEPACK > $WD/languagepack/build-languagepack.sh
   source ../settings.sh
   source ../versions.sh
   source ../common.sh
    
   install_path="$PG_LANGUAGEPACK_OSX"
     
   PERL_INSTALL_PATH="\$install_path/Perl-\$PG_VERSION_PERL" #$(echo $PG_VERSION_PERL | cut -d'.' -f1,2)"
   PYTHON_INSTALL_PATH="\$install_path/Python-\$PG_VERSION_PYTHON" #$(echo $PG_VERSION_PYTHON | cut -d'.' -f1,2)"
   TCL_TK_INSTALL_PATH="\$install_path/Tcl-\$PG_VERSION_TCL" #$(echo $PG_VERSION_TCL_TK | cut -d'.' -f1,2)"
    
   rm -rf \$PERL_INSTALL_PATH
   rm -rf \$PYTHON_INSTALL_PATH
   rm -rf \$TCL_TK_INSTALL_PATH
   rm -f $PG_LANGUAGEPACK_OSX/LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2

   cd $PG_PATH_OSX/languagepack/source/tcl.osx/unix

   export LD_RUN_PATH=\$TCL_TK_INSTALL_PATH/lib

   echo "Building TCL..."
   
   CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L\$TCL_TK_INSTALL_PATH/lib -arch x86_64" ./configure --prefix=\$TCL_TK_INSTALL_PATH --enable-threads --enable-shared || _die "Failed to configure tcl"
   CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L\$TCL_TK_INSTALL_PATH/lib -arch x86_64" make || _die "Failed to make tcl"
   make install || _die "Failed to make install tcl"

     echo "Setting RPATHs..."

     cd \$TCL_TK_INSTALL_PATH/bin
     find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib" {}

     cd \$TCL_TK_INSTALL_PATH/lib
     find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
     echo "Building Python..."
    
     cd $PG_PATH_OSX/languagepack/source/python.osx
 
     export LDFLAGS="-L/opt/local/Current/lib -L\$TCL_TK_INSTALL_PATH/lib"
     export CFLAGS="-I/opt/local/Current/include -I\$TCL_TK_INSTALL_PATH/include"
     export CPPFLAGS=\$CFLAGS
     export LD_LIBRARY_PATH="\$TCL_TK_INSTALL_PATH/lib:\$LD_LIBRARY_PATH"
     export LD_RUN_PATH="\$PYTHON_INSTALL_PATH/lib"
     export MACOSX_DEPLOYMENT_TARGET=\$MACOSX_MIN_VERSION
     export PYTHONHOME="\$PYTHON_INSTALL_PATH"

     CC='clang' CFLAGS="\$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L/opt/local/Current/lib \$PG_ARCH_OSX_LDFLAGS -arch x86_64" ./configure --prefix=\$PYTHON_INSTALL_PATH --enable-shared --with-openssl=/opt/local/Current || _die "Failed to configure Python"
     echo "-----------------------------------------------------"
     echo "out put of Python Make started"
     echo "-----------------------------------------------------"

     PYTHONHOME=\$PYTHON_INSTALL_PATH CFLAGS="\$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="\$PG_ARCH_OSX_LDFLAGS -arch x86_64" make || _die "Failed to make Python"
     echo "-----------------------------------------------------"
     echo "out put of Python Make end"
     echo "-----------------------------------------------------"
     make install || _die "Failed to make install Python"
    
     echo "Setting RPATHs..."

     cd \$PYTHON_INSTALL_PATH/bin
     find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib" {}
     ln -sv python3 python

     cd \$PYTHON_INSTALL_PATH/lib
     find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
     echo "=============creating soft link for libpython3.3m.dylib==================="
     cd \$PYTHON_INSTALL_PATH/lib/python\$PG_VERSION_PYTHON/config-\$PG_VERSION_PYTHON\m
     ln -s ../../libpython\$PG_VERSION_PYTHON\m.dylib libpython\$PG_VERSION_PYTHON\m.dylib
     echo "================end========================"
     chmod 755 \$PYTHON_INSTALL_PATH/lib/libpython*dylib
     cp -pR /opt/local/Current/lib/libiconv* \$PYTHON_INSTALL_PATH/lib/
     cp -pR /opt/local/Current/lib/libintl* \$PYTHON_INSTALL_PATH/lib/
     cp -pR /opt/local/Current/lib/libssl* \$PYTHON_INSTALL_PATH/lib/
     cp -pR /opt/local/Current/lib/libcrypto* \$PYTHON_INSTALL_PATH/lib/
     cp -pR /opt/local/Current/lib/libz* \$PYTHON_INSTALL_PATH/lib/

     _rewrite_so_refs \$PYTHON_INSTALL_PATH bin @loader_path/..
     _rewrite_so_refs \$PYTHON_INSTALL_PATH lib @loader_path/..
     _rewrite_so_refs \$PYTHON_INSTALL_PATH lib/python\$PG_VERSION_PYTHON/lib-dynload @loader_path/../../..
     
     cd \$PYTHON_INSTALL_PATH/lib
     echo "====================install name tool change=================="
     install_name_tool -change libpython\$PG_VERSION_PYTHON\m.dylib \$PYTHON_INSTALL_PATH/lib/libpython\$PG_VERSION_PYTHON\m.dylib
     echo "=========================end==============="
     echo "Building Python Distribute..."
     cd $PG_PATH_OSX/languagepack/source/setuptools-python.osx
     echo "============PATH Varaibles=========="
     export PYTHONHOME="\$PYTHON_INSTALL_PATH"
     export PATH="\$PYTHON_INSTALL_PATH/bin:\$PATH"
     export LD_LIBRARY_PATH="/opt/local/Current/lib:\$LD_LIBRARY_PATH"

     python setup.py install --prefix=\$PYTHON_INSTALL_PATH 
     easy_install pip
     pip3 install sphinx
     pip3 install virtualvenv

     cd \$PYTHON_INSTALL_PATH/bin
     pip3 list > \$install_path/pip_packages_list.txt

    echo "Building Perl..."
    cd $PG_PATH_OSX/languagepack/source/perl.osx
    export LD_RUN_PATH=\$PERL_INSTALL_PATH/lib

    LDFLAGS='-L\$PERL_INSTALL_PATH/lib' ./Configure -ders -Dcc=llvm-gcc-4.2 -Dusethreads -Duseithreads -Uinstallusrbinperl -Ulocincpth= -Uloclibpth= -A ccflags=-DUSE_SITECUSTOMIZE -A ccflags=-DPERL_RELOCATABLE_INCPUSH -A ccflags=-Duselargefiles -Accflags='\$PG_ARCH_OSX_CFLAGS -arch x86_64 -fno-merge-constants' -Aldflags='-arch x86_64' -Duseshrplib -Dprefix=\$PERL_INSTALL_PATH -Dprivlib=\$PERL_INSTALL_PATH/lib -Darchlib=\$PERL_INSTALL_PATH/lib -Dsiteprefix=\$PERL_INSTALL_PATH/site -Dsitelib=\$PERL_INSTALL_PATH/site/lib -Dsitearch=\$PERL_INSTALL_PATH/site/lib || _die "Failed to configure Perl"
    make || _die "Failed to Make Perl"
    make install || _die "Failed to make install Perl"
    echo "Setting RPATHs..."
    cd \$PERL_INSTALL_PATH/bin
    find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib/CORE" {}
    cd \$PERL_INSTALL_PATH/lib
    find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
    echo "copying Tcl,Python,Perl instalation directories into Staging...."
    
    #cp -pR \$PYTHON_INSTALL_PATH \$PG_PATH_OSX/languagepack/staging/osx
    #cp -pR \$PERL_INSTALL_PATH \$PG_PATH_OSX/languagepack/staging/osx
    #cp -pR \$TCL_TK_INSTALL_PATH \$PG_PATH_OSX/languagepack/staging/osx

    #cd \$install_path
    #tar -jcvf LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 *

EOT-LANGUAGEPACK

    cd $WD
    scp languagepack/build-languagepack.sh $PG_SSH_OSX:$PG_PATH_OSX/languagepack
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/languagepack; sh ./build-languagepack.sh" || _die "Failed to build the languagepack on OSX VM"

    echo "Removing last successful staging directory ($PG_LANGUAGEPACK_OSX.staging)"
    ssh $PG_SSH_OSX "rm -rf $PG_LANGUAGEPACK_OSX.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_LANGUAGEPACK_OSX.staging" || _die "Couldn't create the last successful staging directory"
    ssh $PG_SSH_OSX "chmod ugo+w $PG_LANGUAGEPACK_OSX.staging" || _die "Couldn't set the permission on the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cp -rp $PG_LANGUAGEPACK_OSX/* $PG_LANGUAGEPACK_OSX.staging" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_LANGUAGEPACK=$PG_VERSION_LANGUAGEPACK > $PG_LANGUAGEPACK_OSX.staging/versions-osx.sh" || _die "Failed to write languagepack version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_LANGUAGEPACK=$PG_BUILDNUM_LANGUAGEPACK >> $PG_LANGUAGEPACK_OSX.staging/versions-osx.sh" || _die "Failed to write languagepack build number into versions-osx.sh"

    echo "END BUILD LanguagePack OSX" 

}


################################################################################
# PG Build
################################################################################

_postprocess_languagepack_osx() {

    echo "BEGIN POST LanguagePack OSX"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/languagepack/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/languagepack/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/languagepack/staging/osx)"
    mkdir -p $WD/languagepack/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/languagepack/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_LANGUAGEPACK_OSX.staging; rm -f LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_LANGUAGEPACK_OSX.staging; tar -jcvf LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 *" || _die "Failed to create an archive of languagepack build"
    scp $PG_SSH_OSX:$PG_LANGUAGEPACK_OSX.staging/LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 $WD/languagepack/staging/osx || _die "Failed to copy the binaries to controller"

    # sign the binaries and libraries
    scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2" || _die "Failed to remove lp staging tar from signing server"
    scp $WD/languagepack/staging/osx/LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy lp tar file on signing server"
    rm -rf $WD/languagepack/staging/osx/LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 || _die "Failed to remove lp tar from controller"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries staging" || _die "Failed to do binaries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries staging" || _die "Failed to do libraries signing"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging;tar -jcvf LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 *" || _die "Failed to create lp tar on signing server"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 $WD/languagepack/staging/osx || _die "Failed to copy lp to controller vm"


    cd $WD/languagepack/staging/osx
    tar -jxvf LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2 || _die "Failed to extract the staging binary archive on controller"
    rm -f LanguagePack-$PG_VERSION_LANGUAGEPACK.tar.bz2

    source $WD/languagepack/staging/osx/versions-osx.sh
    PG_BUILD_LANGUAGEPACK=$(expr $PG_BUILD_LANGUAGEPACK + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_LANGUAGEPACK -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    cd $WD/languagepack

    pushd $WD/languagepack/staging/osx
    generate_3rd_party_license "languagepack"
    popd
 
    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml
        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-osx.app/Contents/MacOS/Language\ Pack $WD/risePrivileges || _die "Failed to copy the privileges escalation applet"
        echo "Removing the installer previously generated installer"
        rm -rf $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-osx.app
    fi

    # Build the installer
    echo "Building the installer with the root privileges not required"
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-osx.app $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/risePrivileges $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/Language\ Pack
    chmod a+x $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/Language\ Pack
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ Language\ Pack $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace @@PROJECTNAME@@ with Language\ Pack ($WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh)"
    chmod a+x $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh

    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    if [ -d lp.img ];
    then
        rm -rf lp.img
    fi
    mkdir lp.img || _die "Failed to create DMG staging directory"
    mv edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app lp.img || _die "Failed to copy the installer bundle into the DMG staging directory"

    # Scp the app bundle to the signing machine for signing
    tar -jcvf lp.img.tar.bz2 lp.img || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf lp.img*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp lp.img.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output || _die "Failed to copy the archive to sign server."
    rm lp.img.tar.bz2 || _die "Failed to remove the lp.img archive"

    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Sign the .app, create the DMG
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output/; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf lp.img.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain;codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml lp.img/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"

    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output/lp.img; rm -rf edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app; mv edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx-signed.app  edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv lp.img/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; tar -jcvf lp.img.tar.bz2 lp.img" || _die "Failed to create lp.img on $PG_SSH_OSX_SIGN"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/lp.img.tar.bz2 $WD/output || _die "Failed to copy lp.img.tar.bz2 to $WD/output."
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/output" || _die "Failed to create output directory in $PG_PATH_OSX"
    scp lp.img.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/output ||  _die "Failed to copy lp.img.tar.bz2 to $PG_PATH_OSX/output."
    rm -rf lp.img* || _die "Failed to remove lp.img.tar.bz2 from output directory."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; source $PG_PATH_OSX/versions.sh; tar -jxvf lp.img.tar.bz2; hdiutil create -quiet -anyowners -srcfolder lp.img -format UDZO -volname 'EDB-LanguagePack $PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK' -ov 'edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg'" || _die "Failed to create the disk image (edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg)"

    echo "Attach the  disk image, create zip and then detach the image"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; hdiutil detach '/Volumes/EDB_LanguagePack $PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK* -force'; hdid edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg" || _die "Failed to open the disk image (edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg in remote host)"

    ssh $PG_SSH_OSX "cd '/Volumes/EDB-LanguagePack $PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK'; zip -r $PG_PATH_OSX/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.zip edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.app" || _die "Failed to create the installer zip file (edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.zip) in remote host."

    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; sleep 2; echo 'Detaching /Volumes/edb-LanguagePack $PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK...' ; hdiutil detach '/Volumes/edb-LanguagePack $PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK'" || _die "Failed to detach the /Volumes/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK in remote host."

    scp $PG_SSH_OSX:$PG_PATH_OSX/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.* $WD/output || _die "Failed to copy installers to $WD/output."

    # Notarize the OS X installer
    ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf edb-languagepack-*.dmg edb-languagepack-*.zip" || _die "Failed to remove the installer from notarization installer directory"
    scp $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg $WD/output/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.zip  $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
    scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg edb-languagepack" || _die "Failed to notarize the app"
    ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.zip edb-languagepack" || _die "Failed to notarize the zip"
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.dmg $WD/output || _die "Failed to copy notarized installer to $WD/output."
    scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/edb-languagepack-$PG_VERSION_LANGUAGEPACK-$PG_BUILDNUM_LANGUAGEPACK-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    # Delete the old installer from regression setup
    ssh $PG_SSH_OSX "cd /buildfarm/installers;rm -rf edb-languagepack-*.dmg" || _die "Failed to remove the installer from the regression intaller directory"

    # Copy the installer to regression setup
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output;cp -p edb-languagepack-*.dmg /buildfarm/installers/" || _die "Failed to copy installers to the regression direcory"

    # Delete the installer from remote output directory
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/output; rm -rf edb-languagepack* lp*" || _die "Failed to clean the remote output directory"

    cd $WD
    echo "END POST LanguagePack OSX"
}

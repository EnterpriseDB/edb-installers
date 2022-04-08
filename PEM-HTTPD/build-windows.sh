#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_PEM-HTTPD_windows() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP PEM-HTTPD Windows"

    # Enter the source directory and cleanup if required
    cd $WD/PEM-HTTPD/source

    # Grab a copy of the openssl & zlib source tree
    chmod -R ugo+w apache.windows || _die "Couldn't set the permissions on the source directory"
    mv openssl-$PG_TARBALL_OPENSSL apache.windows/srclib/openssl
    mv zlib-$PG_TARBALL_ZLIB apache.windows/srclib/zlib

    cd $WD/PEM-HTTPD/source/apache.windows
    if [ -f $WD/tarballs/apache_win_$PG_VERSION_APACHE.patch ];
    then
      patch -p1 < $WD/tarballs/apache_win_$PG_VERSION_APACHE.patch
    fi
    cd ..

    if [ -f $WD/tarballs/apr-${PG_VERSION_APACHE_APR}.patch ];
    then
      echo "Applying apr patch..."
      cd $WD/PEM-HTTPD/source/apache.windows/srclib/apr
      patch -p1 < "$WD/tarballs/apr-${PG_VERSION_APACHE_APR}.patch"
      cd ../../../
    fi

    cd $WD/PEM-HTTPD/source

    mkdir -p apache.windows/mod_wsgi || _die "Couldn't create the mod_wsgi directory"
    cp -pR mod_wsgi-$PG_VERSION_WSGI/* apache.windows/mod_wsgi || _die "Failed to copy the source code (source/mod_wsgi-$PG_VERSION_WSGI)"

    # Patches to build the correct version
    cd apache.windows/mod_wsgi/win32
    echo "Applying mod_wsgi patch..."
    cp ap24py34-win32-VC10.mk ap24py37-win32-VC10.mk
    sed -i 's/Python34/Python37/g' ap24py37-win32-VC10.mk
    sed -i 's/34/37/g' ap24py37-win32-VC10.mk
    sed -i 's/ap24py34-win32-VC10.mk/ap24py37-win32-VC10.mk/g' build-win32-VC10.bat
    patch -p0 < $WD/tarballs/mod_wsgi_psapi.patch

    # For PEM7, apachehttpd needs to be built with python3.4 (LP10)
    PEM_PYTHON_WINDOWS=$PEM_PYTHON_WINDOWS
    patch -p0 < $WD/tarballs/apache-build-win32.patch
    MOD_WSGI_MAKEFILE=ap24py37-win32-VC10.mk

    sed -i "s/^APACHE_ROOTDIR =\(.*\)$/APACHE_ROOTDIR=$PG_PATH_WINDOWS\\\\apache.staging.build/g" ${MOD_WSGI_MAKEFILE}
    sed -i "s/^PYTHON_ROOTDIR =\(.*\)$/PYTHON_ROOTDIR=$PEM_PYTHON_WINDOWS/g" ${MOD_WSGI_MAKEFILE}

    cd $WD/PEM-HTTPD/source

    if [ -e apache.zip ]; then
        echo "Removing old zip of apache source"
        rm -f apache.zip || _die "Couldn't remove the zip of apache source"
    fi
    echo "Change older ssl reference"
    find apache.windows -type f -name "*" -exec sed -i 's/libeay32.lib/libssl.lib/g' {} \;
    find apache.windows -type f -name "*" -exec sed -i 's/ssleay32.lib/libcrypto.lib/g' {} \;

    echo "Archieving apache sources"
    zip -r apache.zip apache.windows/ || _die "Couldn't create zip of the apache sources (apache.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PEM-HTTPD/staging/windows ]; then 
        echo "Removing existing staging directory"
        rm -rf $WD/PEM-HTTPD/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PEM-HTTPD/staging/windows)"
    mkdir -p $WD/PEM-HTTPD/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PEM-HTTPD/staging/windows || _die "Couldn't set the permissions on the staging directory"
    
    #Remove existing staging directory on Windows VM
    echo "Removing existing directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.zip del /S /Q apache.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache-staging.zip del /S /Q apache-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-apache.bat del /S /Q build-apache.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache-build.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.windows rd /S /Q apache.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.staging.build rd /S /Q apache.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.staging.build directory on Windows VM"

    # Copy sources on windows VM
    echo "Copying apache sources to Windows VM"
    scp apache.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the apache archieve to windows VM (apache.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip apache.zip" || _die "Couldn't extract apache archieve on windows VM (apache.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir apache.staging.build; chmod -R a+wrx apache.staging.build" || _die "Couldn't give full rights to apache windows directory on windows VM (apache.windows)"

    echo "END PREP PEM-HTTPD Windows"
}


################################################################################
# PEM-HTTPD Build
################################################################################

_build_PEM-HTTPD_windows() {
    echo "BEGIN BUILD PEM-HTTPD Windows"

    cd $WD/PEM-HTTPD/staging/windows

    # Building Apache

    cat <<EOT > "build-apache.bat"

REM Setting Visual Studio Environment
CALL "$PG_VS14INSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

@SET PGBUILD=$PG_PGBUILD_WINDOWS
echo ON
@echo Building zlib first
cd $PG_PATH_WINDOWS\apache.windows\srclib\zlib
nmake -f win32\Makefile.msc
nmake -f win32\Makefile.msc test
if EXIST "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib.lib" copy "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib.lib" "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib1.lib"

@echo Building openssl
cd $PG_PATH_WINDOWS\apache.windows\srclib\openssl
SET LIB=$PEM_PYTHON_WINDOWS\Lib;$PG_PATH_WINDOWS\apache.windows\srclib\zlib;$PG_PGBUILD_WINDOWS\lib;%LIB%
SET INCLUDE=$PEM_PYTHON_WINDOWS\include;$PG_PATH_WINDOWS\apache.windows\srclib\zlib;%INCLUDE%;$PG_PGBUILD_WINDOWS\include
SET PATH=$PG_PATH_WINDOWS;$PG_PGBUILD_WINDOWS\bin;$PG_PERL_WINDOWS\bin;$PEM_PYTHON_WINDOWS;$PG_TCL_WINDOWS\bin;%PATH%;C:\cygwin\bin
perl Configure VC-WIN32 no-asm --prefix=%CD% --openssldir=%CD%\openssl.build
nmake
SET INCLUDE=$PG_PATH_WINDOWS\apache.windows\srclib\openssl\include;%INCLUDE%

REM Building apache
cd $PG_PATH_WINDOWS
SET STAGING_DIR=%CD%
cd $PG_PATH_WINDOWS\apache.windows
perl srclib\apr\build\lineends.pl
perl srclib\apr\build\fixwin32mak.pl

cd $PG_PATH_WINDOWS\apache.windows\srclib\apr-util\xml\expat
cmake -G "NMake Makefiles" -D BUILD_shared=OFF -DCMAKE_BUILD_TYPE=Release .
nmake

SET XML_OPTIONS="/D XML_STATIC"
SET XML_PARSER=libexpat
SET LIB=$PG_PATH_WINDOWS\apache.windows\srclib\apr-util\xml\expat;%LIB%

cd $PG_PATH_WINDOWS\apache.windows
devenv /Upgrade Apache.dsw
devenv Apache.sln /useenv /build Release /project libhttpd

cd "$PG_PATH_WINDOWS\apache.windows"

@echo Compiling Apache with Standard configuration
REM apr-iconv fails to build as apr.h does not exists in first round, as apr build runs later. Hence - run the build twrice to resolve that issue.
nmake -f Makefile.win PORT=8080 NO_EXTERNAL_DEPS=1 INSTDIR="%STAGING_DIR%\apache.staging.build" NO_EXTERNAL_DEPS=1 _buildr installr || exit 1

SET INCLUDE=$PEM_PYTHON_WINDOWS\include;$PG_PATH_WINDOWS\apache.staging.build\include;$PG_PATH_WINDOWS\apache.windows\srclib\zlib;$PG_PGBUILD_WINDOWS\include\openssl;%INCLUDE%

REM Building mod_wsgi
cd $PG_PATH_WINDOWS\apache.windows\mod_wsgi\win32
build-win32-VC10.bat

EOT

    scp build-apache.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-apache.bat" ||  _die "Failed to build apache server"
    echo "Removing last successful staging directory ($PG_PATH_WINDOWS\\\\apache.staging)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.staging rd /S /Q apache.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\apache.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y apache.staging.build\\\\* apache.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS "cmd /c echo PG_VERSION_APACHE=$PG_VERSION_APACHE > $PG_PATH_WINDOWS\\\\apache.staging/versions-windows.sh" || _die "Failed to write server version number into versions-windows.sh"
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_BUILDNUM_PEMHTTPD=$PG_BUILDNUM_PEMHTTPD >> $PG_PATH_WINDOWS\\\\apache.staging/versions-windows.sh" || _die "Failed to write server build number into versions-windows.sh"

    echo "END BUILD PEM-HTTPD Windows"
}



################################################################################
# PEM-HTTPD Postprocess
################################################################################

_postprocess_PEM-HTTPD_windows() {

    echo "BEGIN POST PEM-HTTPD Windows"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PEM-HTTPD/staging/windows ]; then
        echo "Removing existing staging directory"
        rm -rf $WD/PEM-HTTPD/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/PEM-HTTPD/staging/windows)"
    mkdir -p $WD/PEM-HTTPD/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PEM-HTTPD/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Zip up the installed code, copy it back here, and unpack.
    mkdir $WD/PEM-HTTPD/staging/windows/apache || _die "Failed to create directory for apache"
    echo "Copying apache built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe $PG_PATH_WINDOWS\\\\apache.staging" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vc_redist.x86_2015.exe  $PG_PATH_WINDOWS\\\\apache.staging" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache-staging.zip del /S /Q apache-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\apache.staging; cmd /c zip -r ..\\\\apache-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache-staging.zip $WD/PEM-HTTPD/staging/windows/apache || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache-staging.zip)"
    unzip $WD/PEM-HTTPD/staging/windows/apache/apache-staging.zip -d $WD/PEM-HTTPD/staging/windows/apache || _die "Failed to unpack the built source tree ($WD/staging/windows/apache-staging.zip)"
    mv $WD/PEM-HTTPD/staging/windows/apache/versions-windows.sh $WD/PEM-HTTPD/staging/windows || _die "Failed to move versions-windows.sh"
    rm $WD/PEM-HTTPD/staging/windows/apache/apache-staging.zip

    TEMP_PATH=`echo $PG_PATH_WINDOWS | sed -e 's:\\\\\\\\:/:g'`

    # Configure the httpd.conf file
    _replace "$TEMP_PATH/apache.staging" "@@INSTALL_DIR@@" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    _replace "@@INSTALL_DIR@@.build" "@@INSTALL_DIR@@" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    _replace "Listen 8080" "Listen 0.0.0.0:@@PORT@@" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    _replace "#ServerName www.example.com:8080" "ServerName localhost:@@PORT@@" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    _replace "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"

    echo "ServerTokens Prod" >> "$WD/PEM-HTTPD/staging/windows/apache/conf/httpd.conf"
    # disable SSL v3 because of POODLE vulnerability
    echo "SSLProtocol All -SSLv2 -SSLv3" >> "$WD/PEM-HTTPD/staging/windows/apache/conf/extra/httpd-ssl.conf"

    dos2unix $WD/PEM-HTTPD/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/PEM-HTTPD/staging/windows/versions-windows.sh
    PG_BUILD_PEMHTTPD=$(expr $PG_BUILD_PEMHTTPD + $SKIPBUILD)

    TEMP_PATH=`echo $PG_PATH_WINDOWS | sed -e 's:\\\\\\\\:/:g'`

    #Configure the files in apache and httpd
    filelist=`grep -rslI "$TEMP_PATH" "$WD/PEM-HTTPD/staging/windows/apache/conf" | grep -v Binary`
    cd $WD/PEM-HTTPD/staging/windows

    pushd $WD/PEM-HTTPD/staging/windows
    generate_3rd_party_license "pem_httpd"
    popd

    for file in $filelist
    do
        _replace "$TEMP_PATH/apache.staging" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done

    cd $WD/PEM-HTTPD
    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/windows/apache/htdocs staging/windows/apache/www || _die "Failed to change Server Root"

    mkdir -p staging/windows/installer/PEM-HTTPD || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/windows/apache/www/images || _die "Failed to create a directory for the images"

    cp staging/windows/apache/vcredist_x86.exe staging/windows/installer/PEM-HTTPD 
    cp staging/windows/apache/vc_redist.x86_2015.exe staging/windows/installer/PEM-HTTPD/vcredist_x86_2015.exe

    if [ -f staging/windows/apache/vcredist_x86.exe ]; then
      rm -f staging/windows/apache/vcredist_x86.exe
    fi

    if [ -f staging/windows/apache/vc_redist.x86_2015.exe ]; then
      rm -f staging/windows/apache/vc_redist.x86_2015.exe
    fi

    cp scripts/windows/start-apache.bat staging/windows/installer/PEM-HTTPD/start-apache.bat || _die "Failed to copy the start-apache script (scripts/windows/start-apache.bat)"
    cp scripts/windows/install-apache.bat staging/windows/installer/PEM-HTTPD/install-apache.bat || _die "Failed to copy the install-apache script (scripts/windows/install-apache.bat)"
    cp scripts/windows/uninstall-apache.bat staging/windows/installer/PEM-HTTPD/uninstall-apache.bat || _die "Failed to copy the uninstall-apache script (scripts/windows/uninstall-apache.bat)"
    cp scripts/windows/stopApacheService.bat staging/windows/installer/PEM-HTTPD/stopApacheService.bat || _die "Failed to copy the stopApacheService script (scripts/windows/stopApacheService.bat)"
    cp scripts/windows/startApache.vbs staging/windows/installer/PEM-HTTPD/startApache.vbs || _die "Failed to copy the startApache vbs script (scripts/windows/startApache.vbs)"
    cp scripts/windows/stopApache.vbs staging/windows/installer/PEM-HTTPD/stopApache.vbs || _die "Failed to copy the stopApache vbs script (scripts/windows/stopApache.vbs)"

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/windows/launchApacheHTTPD.vbs staging/windows/scripts/launchApacheHTTPD.vbs || _die "Failed to copy the launchApacheHTTPD script (scripts/windows/launchApacheHTTPD.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/logo.ico)" 

    cp resources/index.html staging/windows/apache/www || _die "Failed to copy index.html"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PEMHTTPD -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pem-httpd-$PG_VERSION_APACHE-$PG_BUILDNUM_PEMHTTPD-windows.exe $WD/output/pem-httpd-$PG_VERSION_APACHE-$PG_BUILDNUM_PEMHTTPD-${BUILD_FAILED}windows.exe

	# Sign the installer
	win32_sign "pem-httpd-$PG_VERSION_APACHE-$PG_BUILDNUM_PEMHTTPD-windows.exe"
	
     cd $WD
    echo "END POST PEM-HTTPD Windows"
}


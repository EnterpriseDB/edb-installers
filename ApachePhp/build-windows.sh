#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_windows() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP ApachePhp Windows"
      
    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    # Grab a copy of the openssl & zlib source tree
    chmod -R ugo+w apache.windows || _die "Couldn't set the permissions on the source directory"
    mv openssl-$PG_TARBALL_OPENSSL apache.windows/srclib/openssl
    mv zlib-$PG_TARBALL_ZLIB apache.windows/srclib/zlib

    # Apply the patch
    cd apache.windows
    if [ -f $WD/tarballs/apache_win_$PG_VERSION_APACHE.patch ];
    then
      patch -p1 < $WD/tarballs/apache_win_$PG_VERSION_APACHE.patch
    fi
    cd ..

    cd $WD/ApachePhp/source
    if [ -e php.windows ]; then 
        echo "Removing old php sources"
        rm -rf php.windows || _die "Couldn't remove the php sources"
    fi

    # Grab a copy of PHP
    echo "Grab copy of the clean php sources"
    cp -pR php-$PG_VERSION_PHP php.windows || _die "Couldn't copy sources for php (php-$PG_VERSION_PHP to php.windows)"
    if [ x"$PG_VERSION_PHP" = x"5.3.3" -o x"$PG_VERSION_PHP" = x"5.3.5" ]; then
        if [ -f "$WD/tarballs/php-$PG_VERSION_PHP-win32.patch" ]; then
            cp $WD/ApachePhp/source/php.windows/win32/readdir.c $WD/ApachePhp/source/php.windows/ext/mcrypt/readdir.c
            cd php.windows
            patch -p1 < $WD/tarballs/php-$PG_VERSION_PHP-win32.patch
        fi
    fi

    cd $WD/ApachePhp/source

    if [ -e apache.zip ]; then
        echo "Removing old zip of apache source"
        rm -f apache.zip || _die "Couldn't remove the zip of apache source"
    fi

    echo "Archieving apache sources"
    zip -r apache.zip apache.windows/ || _die "Couldn't create zip of the apache sources (apache.zip)"

    if [ -e php.zip ]; then
        echo "Removing old zip of php source"
        rm -f php.zip || _die "Couldn't remove the zip of php source"
    fi

    echo "Archieving php sources"
    zip -r php.zip php.windows/ || _die "Couldn't create archieve of the php sources (php.zip)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/windows ]; then 
        echo "Removing existing staging directory"
        rm -rf $WD/ApachePhp/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/windows)"
    mkdir -p $WD/ApachePhp/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApachePhp/staging/windows || _die "Couldn't set the permissions on the staging directory"
    
    #Remove existing staging directory on Windows VM
    echo "Removing existing directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.zip del /S /Q apache.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache-staging.zip del /S /Q apache-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-apache.bat del /S /Q build-apache.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache-build.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.windows rd /S /Q apache.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST apache.staging rd /S /Q apache.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\apache.staging directory on Windows VM"

    # Remove existing staging directory on Windows VM
    echo "Removing existing source & staging directories on Winodws VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST php.zip del /S /Q php.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\\\php.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST php-staging.zip del /S /Q php-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\\\php-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST php.windows rd /S /Q php.windows" || _die "Couldn't remove the source directory on Windows VM (php.windows)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST php.staging rd /S /Q php.staging" || _die "Couldn't remove the source directory on Windows VM (php.staging)"

    # Copy sources on windows VM
    echo "Copying apache sources to Windows VM"
    scp apache.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the apache archieve to windows VM (apache.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip apache.zip" || _die "Couldn't extract apache archieve on windows VM (apache.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir apache.staging; chmod -R a+wrx apache.staging" || _die "Couldn't give full rights to apache windows directory on windows VM (apache.windows)"

    echo "Copying php sources to Windows VM"
    scp php.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the php archieve to windows VM (php.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip php.zip" || _die "Couldn't extract php archieve on windows VM (php.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; chmod -R a+wrx php.windows" || _die "Couldn't give full rights to php windows directory on windows VM (php.windows)"

    echo "END PREP ApachePhp Windows"
}


################################################################################
# ApachePhp Build
################################################################################

_build_ApachePhp_windows() {
    echo "BEGIN BUILD ApachePhp Windows"


    cd $WD/ApachePhp/staging/windows

    # Building Apache

    cat <<EOT > "build-apache.bat"

REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

REM Building zlib first
cd $PG_PATH_WINDOWS\apache.windows\srclib\zlib
nmake -f win32\Makefile.msc
nmake -f win32\Makefile.msc test
if EXIST "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib.lib" copy "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib.lib" "$PG_PATH_WINDOWS\apache.windows\srclib\zlib\zlib1.lib"

REM Building openssl
cd $PG_PATH_WINDOWS\apache.windows\srclib\openssl
SET LIB=$PG_PATH_WINDOWS\apache.windows\srclib\zlib;C:\pgBuild\lib;%LIB%
SET INCLUDE=$PG_PATH_WINDOWS\apache.windows\srclib\zlib;C:\pgBuild\OpenSSL\include;%INCLUDE%
SET PATH=$PG_PATH_WINDOWS;$PG_PGBUILD_WINDOWS\bin;$PG_PERL_WINDOWS\bin;$PG_PYTHON_WINDOWS;$PG_TCL_WINDOWS\bin;%PATH%;C:\cygwin\bin
perl Configure no-mdc2 no-rc5 no-idea enable-zlib VC-WIN32
CALL ms\do_ms.bat
nmake -f ms\ntdll.mak

REM Building apache
cd $PG_PATH_WINDOWS
SET STAGING_DIR=%CD%
cd $PG_PATH_WINDOWS\apache.windows
perl srclib\apr\build\lineends.pl
perl srclib\apr\build\fixwin32mak.pl

REM Compiling Apache with Standard configuration
nmake -f Makefile.win PORT=8080 NO_EXTERNAL_DEPS=1 _buildr || exit 1
nmake -f Makefile.win PORT=8080 INSTDIR="%STAGING_DIR%\apache.staging" NO_EXTERNAL_DEPS=1 installr || exit 1

EOT

    scp build-apache.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    APACHE_BUILT=0
    APACHE_WIN_BUILT_COUNT=0
    while [ $APACHE_BUILT == 0 ]; do
        # We will stop trying, if the count is more than 3
        if [ $APACHE_WIN_BUILT_COUNT -gt 9 ];
        then
            _die "Failed to build Apache on Windows VM"
        fi
        APACHE_BUILT=1
        ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-apache.bat" || APACHE_BUILT=0
        APACHE_WIN_BUILT_COUNT=`expr $APACHE_WIN_BUILT_COUNT + 1`
    done

    #Building php
    cat <<EOT > "build-php.bat"

@ECHO OFF
@ECHO Setting Proper Environment Variable to build PHP
@SET BUILD_DIR=%~dp0
@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET PG_HOME_PATH=$PG_PATH_WINDOWS\output
@CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"
IF EXIST "$PG_PSDK_WINDOWS\SetEnv.Bat" @CALL "$PG_PSDK_WINDOWS\SetEnv.Bat"
IF EXIST "$PG_PSDK_WINDOWS\SetEnv.cmd" @CALL "$PG_PSDK_WINDOWS\SetEnv.cmd"
@SET INCLUDE=$PG_PATH_WINDOWS\apache.staging\include;%INCLUDE%
@SET LIB=%PGBUILD%\lib;%LIB%
@SET PATH=%PGBUILD%\bin;%PATH%

@cd $PG_PATH_WINDOWS
@SET APACHE_STAGING=%CD%\apache.staging
@SET PHP_STAGING=%CD%\php.staging
@SET BISON_SIMPLE=%PGBUILD%\bin\bison.simple


@IF NOT EXIST "php.zip" GOTO phpzip-not-found
@IF NOT EXIST "php.windows" @unzip php.zip

@IF NOT EXIST "php.windows" GOTO phpwindows-not-found

@cd %BUILD_DIR%/php.windows

@REM Have make to change to compile bcmath properly
@IF EXIST "ext\bcmath\libbcmath\src\config.h" @copy /Y ext\bcmath\libbcmath\src\config.h ext\bcmath\config.h
@REM Copy WinResrc.h in current directory as winres.h
@IF EXIST "$PG_PSDK_WINDOWS\Include\WinResrc.h" @copy "$PG_PSDK_WINDOWS\Include\WinResrc.h" winres.h

@ECHO Generating configuration files
@cscript /nologo win32\build\buildconf.js 

@IF NOT EXIST "configure.js" @GOTO configure-not-build

@ECHO Configure PHP
@cscript /nologo configure.js --enable-cli --enable-cgi  --with-openssl --enable-pdo --with-extra-includes=%PGBUILD%\include;%PG_HOME_PATH%\include;%APACHE_STAGING%\include --with-extra-libs=%PGBUILD%\lib;%PG_HOME_PATH%\lib;%APACHE_STAGING%\lib --enable-apache2filter --enable-apache2-2filter --enable-apache2handler --enable-apache2-4handler --with-apache-hooks --with-pgsql --with-pdo-pgsql --with-prefix=%PHP_STAGING% --enable-one-shot --enable-cli-win32 --enable-embed --enable-isapi --enable-ftp --without-mysqlnd --with-xsl=SHARED  --enable-mbstring --enable-mbregex --enable-shmop  --enable-exif --enable-soap --enable-sockets --with-gd=SHARED --without-mysql --without-mysqli --without-sqlite3 --without-pdo-mysql --without-pdo-sqlite

@IF NOT EXIST "Makefile" @GOTO make-not-created

@ECHO Compiling PHP
@nmake
@IF NOT EXIST "Release_TS\php.exe" @GOTO compilation-failed

@nmake install

cd ..
IF NOT EXIST php.staging/php.exe @GOTO installation-failed

@COPY "%PGBUILD%\vcredist\vcredist_x86.exe" php.staging || echo Failed to copy VC redist && EXIT -1
@COPY "%PGBUILD%\bin\ssleay32.dll" php.staging || echo Failed to copy OpenSSL\bin\ssleay32.dll && EXIT -1
@COPY "%PGBUILD%\bin\libeay32.dll" php.staging || echo Failed to copy OpenSSL\bin\libeay32.dll && EXIT -1

@COPY "%PGBUILD%\bin\libintl.dll" php.staging || echo Failed to copy gettext\bin\libintl.dll && EXIT -1
@COPY "%PGBUILD%\bin\iconv.dll" php.staging || echo Failed to copy gettext\bin\libiconv.dll && EXIT -1
@COPY "%PGBUILD%\bin\libxml2.dll" php.staging || echo Failed to copy libxml2\bin\libxml2.dll && EXIT -1
@COPY "%PGBUILD%\bin\libxslt.dll" php.staging || echo Failed to copy libxslt\bin\libxslt.dll && EXIT -1
@COPY "%PGBUILD%\bin\zlib1.dll" php.staging || echo Failed to copy zlib.dll && EXIT -1
@COPY "%PG_HOME_PATH%\bin\libpq.dll" php.staging || echo Failed to copy libpq.dll && EXIT -1

@GOTO end

:configure-not-build
    @ECHO Configuration could not be built.
    @ECHO "cscript /nologo win32\build\buildconf.js" failed to create configure.js
    @EXIT -1

:phpzip-not-found
    @ECHO php.zip not found @ "%BUILD_DIR%\.."
    @EXIT -1

:phpwindows-not-found
    @ECHO Something wrong has happened.
    @ECHO 'unzip ../php.zip" could not create php.windows
    @EXIT -1

:make-not-created
    @ECHO Configuration could not create Makefile
    @ECHO 'cscript /nologo configure.js' failed to create the Makefile
    @EXIT -1

:compilation-failed
    @ECHO Compilation of php failed
    @EXIT -1

:intallation-failed
    @ECHO Installation Failed
    @EXIT -1

:end
    @cd %BUILD_DIR%

EOT
    scp build-php.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-php.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/php.windows; cmd /c if EXIST php.ini-recommended copy php.ini-recommended $PG_PATH_WINDOWS\\\\php.staging\\\\php.ini " || _die "Failed to copy php.ini"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/php.windows; cmd /c if EXIST php.ini-production copy php.ini-production $PG_PATH_WINDOWS\\\\php.staging\\\\php.ini " || _die "Failed to copy php.ini"
    

    # Zip up the installed code, copy it back here, and unpack.
    mkdir $WD/ApachePhp/staging/windows/apache || _die "Failed to create directory for apache"
    echo "Copying apache built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\apache.staging; cmd /c zip -r ..\\\\apache-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache-staging.zip $WD/ApachePhp/staging/windows/apache || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/apache-staging.zip)"
    unzip $WD/ApachePhp/staging/windows/apache/apache-staging.zip -d $WD/ApachePhp/staging/windows/apache || _die "Failed to unpack the built source tree ($WD/staging/windows/apache-staging.zip)"
    rm $WD/ApachePhp/staging/windows/apache/apache-staging.zip

    TEMP_PATH=`echo $PG_PATH_WINDOWS | sed -e 's:\\\\\\\\:/:g'`

    # Configure the httpd.conf file
    _replace "$TEMP_PATH/apache.staging" "@@INSTALL_DIR@@" "$WD/ApachePhp/staging/windows/apache/conf/httpd.conf"
    _replace "Listen 8080" "Listen @@PORT@@" "$WD/ApachePhp/staging/windows/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$WD/ApachePhp/staging/windows/apache/conf/httpd.conf"
    _replace "#ServerName www.example.com:8080" "ServerName localhost:@@PORT@@" "$WD/ApachePhp/staging/windows/apache/conf/httpd.conf"
    _replace "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "$WD/ApachePhp/staging/windows/apache/conf/httpd.conf"

    mkdir $WD/ApachePhp/staging/windows/php || _die "Failed to create directory for php"
    echo "Copying php built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\php.staging; cmd /c zip -r ..\\\\php-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/php.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/php-staging.zip $WD/ApachePhp/staging/windows/php || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/php-staging.zip)"
    unzip $WD/ApachePhp/staging/windows/php/php-staging.zip -d $WD/ApachePhp/staging/windows/php || _die "Failed to unpack the built source tree ($WD/staging/windows/php-staging.zip)"
    rm $WD/ApachePhp/staging/windows/php/php-staging.zip

    echo "END BUILD ApachePhp Windows"
}



################################################################################
# ApachePhp Postprocess
################################################################################

_postprocess_ApachePhp_windows() {
    echo "BEGIN POST ApachePhp Windows"

    cd $WD/ApachePhp
    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/windows/apache/htdocs staging/windows/apache/www || _die "Failed to change Server Root"

    mkdir -p staging/windows/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/windows/apache/www/images || _die "Failed to create a directory for the images"

    cp scripts/windows/start-apache.bat staging/windows/installer/ApachePhp/start-apache.bat || _die "Failed to copy the start-apache script (scripts/windows/start-apache.bat)"
    cp scripts/windows/install-apache.bat staging/windows/installer/ApachePhp/install-apache.bat || _die "Failed to copy the install-apache script (scripts/windows/install-apache.bat)"
    cp scripts/windows/uninstall-apache.bat staging/windows/installer/ApachePhp/uninstall-apache.bat || _die "Failed to copy the uninstall-apache script (scripts/windows/uninstall-apache.bat)"
    cp scripts/windows/stopApacheService.bat staging/windows/installer/ApachePhp/stopApacheService.bat || _die "Failed to copy the stopApacheService script (scripts/windows/stopApacheService.bat)"
    cp scripts/windows/startApache.vbs staging/windows/installer/ApachePhp/startApache.vbs || _die "Failed to copy the startApache vbs script (scripts/windows/startApache.vbs)"
    cp scripts/windows/stopApache.vbs staging/windows/installer/ApachePhp/stopApache.vbs || _die "Failed to copy the stopApache vbs script (scripts/windows/stopApache.vbs)"

    mkdir -p staging/windows/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/windows/launchApachePhp.vbs staging/windows/scripts/launchApachePhp.vbs || _die "Failed to copy the launchApachePhp script (scripts/windows/launchApachePhp.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/logo.ico)" 

    cp resources/index.php staging/windows/apache/www || _die "Failed to copy index.php"
    chmod ugo+x staging/windows/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/windows/apache/www/index.php"
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/windows/apache/www/index.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-windows.exe"
	
     cd $WD
    echo "END POST ApachePhp Windows"
}

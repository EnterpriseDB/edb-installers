#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_linux_x64() {

    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    if [ -e apache.linux-x64 ];
    then
      echo "Removing existing apache.linux-x64 source directory"
      rm -rf apache.linux-x64  || _die "Couldn't remove the existing apache.linux-x64 source directory (source/apache.linux-x64)"
    fi

    echo "Creating apache source directory ($WD/ApachePhp/source/apache.linux-x64)"
    mkdir -p apache.linux-x64 || _die "Couldn't create the apache.linux-x64 directory"
    chmod ugo+w apache.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -R httpd-$PG_VERSION_APACHE/* apache.linux-x64 || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    chmod -R ugo+w apache.linux-x64 || _die "Couldn't set the permissions on the source directory"

    if [ -e php.linux-x64 ];
    then
      echo "Removing existing php.linux-x64 source directory"
      rm -rf php.linux-x64  || _die "Couldn't remove the existing php.linux-x64 source directory (source/php.linux-x64)"
    fi

    echo "Creating php source directory ($WD/ApachePhp/source/php.linux-x64)"
    mkdir -p php.linux-x64 || _die "Couldn't create the php.linux-x64 directory"
    chmod ugo+w php.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the php source tree
    cp -R php-$PG_VERSION_PHP/* php.linux-x64 || _die "Failed to copy the source code (source/php-$PG_VERSION_PHP)"
    chmod -R ugo+w php.linux-x64 || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApachePhp/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/linux-x64)"
    mkdir -p $WD/ApachePhp/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApachePhp/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

}


################################################################################
# PG Build
################################################################################

_build_ApachePhp_linux_x64() {

    # build apache

    PG_STAGING=$PG_PATH_LINUX_X64/ApachePhp/staging/linux-x64

    # Configure the source tree
    echo "Configuring the apache source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/apache.linux-x64/; sh ./configure --prefix=$PG_STAGING/apache --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache --with-ssl=/usr/local/openssl --enable-mods-shared=all"  || _die "Failed to configure apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/apache.linux-x64/modules/ssl; sed -i \"s^\\(\\t\\\$(SH_LINK).*$\\)^\\1 -Wl,-rpath,\\\${libexecdir}^\" modules.mk"

    echo "Building apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/apache.linux-x64; make" || _die "Failed to build apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/apache.linux-x64; make install" || _die "Failed to install apache"

    # Configure the httpd.conf file
    cd $WD/ApachePhp/staging/linux-x64/apache/conf
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "httpd.conf"
    _replace "htdocs" "www" "httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "httpd.conf"
	# Comment out the unique_id_module, do not load it
	sed -e "s,^LoadModule unique_id_module modules/mod_unique_id.so,#LoadModule unique_id_module modules/mod_unique_id.so,g" httpd.conf > "/tmp/httpd.conf.tmp"
	mv /tmp/httpd.conf.tmp httpd.conf

    # Configure the apachectl script file
    cd $WD/ApachePhp/staging/linux-x64/apache/bin
    _replace "\$HTTPD -k \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD -t" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    ssh $PG_SSH_LINUX_X64 "chmod ugo+x \"$PG_STAGING/apache/bin/apachectl\""

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/openssl/lib/libssl.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/openssl/lib/libcrypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcrypt.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcrypt)"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libcom_err.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libkeyutils.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkeyutils)"
    ssh $PG_SSH_LINUX_X64 "cp -R /lib64/libexpat.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libgssapi_krb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libkrb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libkrb5support.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5support)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libk5crypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/local/lib/libxml2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libxml2)"

    echo "Configuring the php source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/php.linux-x64/; export LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib:/usr/local/openssl/lib; sh ./configure --prefix=$PG_STAGING/php --with-libdir=lib64 --with-apxs2=$PG_STAGING/apache/bin/apxs --with-config-file-path=/usr/local/etc --with-pgsql=$PG_PGHOME_LINUX_X64 --with-openssl=/usr/local/openssl --with-pdo-pgsql=$PG_PGHOME_LINUX_X64 --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite --with-gd --with-png-dir=/usr --with-jpeg-dir=/usr --with-freetype-dir=/usr --enable-gd-native-ttf --enable-mbstring=all" || _die "Failed to configure php"

    echo "Building php"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/php.linux-x64; export LD_LIBRARY_PATH=$PG_PGHOME_LINUX_X64/lib make" || _die "Failed to build php"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/ApachePhp/source/php.linux-x64; make install" || _die "Failed to install php"
    cd $WD/ApachePhp
    if [ -f source/php.linux-x64/php.ini-production ]; then
      cp source/php.linux-x64/php.ini-production staging/linux-x64/php/php.ini || _die "Failed to copy php.ini file"
    else
      cp source/php.linux-x64/php.ini-recommended staging/linux-x64/php/php.ini || _die "Failed to copy php.ini file"
    fi
    cd $WD

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/lib/libpq.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library(libpq)"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/lib/liblber*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library(liblber*)"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/lib/libldap*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library(libldap*)"
    ssh $PG_SSH_LINUX_X64 "cp -R $PG_PGHOME_LINUX_X64/lib/libsasl2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library(libsasl2)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libpng12.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library(libpng12)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libjpeg.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library(libjpeg)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libfreetype.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library(libfreetype)"
    ssh $PG_SSH_LINUX_X64 "cp -R /usr/lib64/libz.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library(libz)"

    # Add LD_PRELOAD in envvars scripts
    cd $WD/ApachePhp/staging/linux-x64/apache/bin
    echo "CWD=\`pwd\`" >> envvars
    echo "cd @@INSTALL_DIR@@/php/lib" >> envvars
    echo "files=\`ls *.so*\`" >> envvars
    echo "cd \$CWD" >> envvars
    echo "for f in \$files " >> envvars
    echo "do" >> envvars
    echo "    BROKEN=\`file @@INSTALL_DIR@@/php/lib/\$f | grep broken\`" >> envvars
    echo "    if [ \"x\$BROKEN\" = \"x\" ] ; then " >> envvars
    echo "        LD_PRELOAD=@@INSTALL_DIR@@/php/lib/\$f:\$LD_PRELOAD" >> envvars
    echo "    fi" >> envvars
    echo "done" >> envvars
    echo "cd @@INSTALL_DIR@@/apache/lib" >> envvars
    echo "files=\`ls *.so*\`" >> envvars
    echo "cd \$CWD" >> envvars
    echo "for f in \$files " >> envvars
    echo "do" >> envvars
    echo "    BROKEN=\`file @@INSTALL_DIR@@/apache/lib/\$f | grep broken\`" >> envvars
    echo "    if [ \"x\$BROKEN\" = \"x\" ] ; then " >> envvars
    echo "        LD_PRELOAD=@@INSTALL_DIR@@/apache/lib/\$f:\$LD_PRELOAD" >> envvars
    echo "    fi" >> envvars
    echo "done" >> envvars
    echo "export LD_PRELOAD" >> envvars
    echo " " >> envvars
    ssh $PG_SSH_LINUX_X64 "chmod ugo+x \"$PG_STAGING/apache/bin/envvars\""

    # Configure the php script files
    cd $WD/ApachePhp/staging/linux-x64/php
    _replace "--with-pgsql=$PG_PGHOME_LINUX_X64" "--with-pgsql" bin/php-config
    _replace "--with-pdo-pgsql=$PG_PGHOME_LINUX_X64" "--with-pdo-pgsql" bin/php-config
    _replace "--with-openssl=/usr/local/openssl" "--with-openssl" bin/php-config
    _replace " -L/usr/local/openssl/lib" "" bin/php-config
    _replace " -L$PG_PGHOME_LINUX_X64/lib" "" bin/php-config
    _replace "--with-pgsql=$PG_PGHOME_LINUX_X64" "--with-pgsql" include/php/main/build-defs.h
    _replace "--with-pdo-pgsql=$PG_PGHOME_LINUX_X64" "--with-pdo-pgsql" include/php/main/build-defs.h
    _replace "--with-openssl=/usr/local/openssl" "--with-openssl" include/php/main/build-defs.h
    _replace "$PG_STAGING/php" "@@INSTALL_DIR@@/php" bin/phar.phar
    ssh $PG_SSH_LINUX_X64 "chmod a+rx \"$PG_STAGING/php/bin/php-config\""
    ssh $PG_SSH_LINUX_X64 "chmod a+rx \"$PG_STAGING/php/bin/phar.phar\""

    # Change the rpath for php
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/php/bin; chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../apache/lib php"

    # Change the rpath for php
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/apache; chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../php/lib modules/libphp5.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 2 -mindepth 2\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\${RPATH} != x ]]; then chrpath --replace \\\${ORIGIN}/../lib \$F; fi done"

    cd $WD

}



################################################################################
# PG Build
################################################################################

_postprocess_ApachePhp_linux_x64() {

    PG_STAGING=$PG_PATH_LINUX_X64/ApachePhp/staging/linux-x64

    #Configure the files in apache and php
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApachePhp/staging/linux-x64" | grep -v Binary`

    cd $WD/ApachePhp/staging/linux-x64

    for file in $filelist
    do
    _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done

    cd $WD/ApachePhp

    # Setup the installer scripts.

    #Changing the ServerRoot from htdocs to www in apache
    cp -R staging/linux-x64/apache/htdocs staging/linux-x64/apache/www || _die "Failed to change Server Root"
    chmod ugo+wx staging/linux-x64/apache/www

    mkdir -p staging/linux-x64/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/linux-x64/apache/www/images || _die "Failed to create a directory for the images"
    chmod ugo+wx staging/linux-x64/apache/www/images

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/ApachePhp/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/ApachePhp/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/ApachePhp/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/ApachePhp/removeshortcuts.sh

    cp scripts/linux/configureApachePhp.sh staging/linux-x64/installer/ApachePhp/configureApachePhp.sh || _die "Failed to copy the configureApachePhp script (scripts/linux/configureApachePhp.sh)"
    chmod ugo+x staging/linux-x64/installer/ApachePhp/configureApachePhp.sh

    cp scripts/linux/startupcfg.sh staging/linux-x64/installer/ApachePhp/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux-x64/installer/ApachePhp/startupcfg.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/linux/launchApachePhp.sh staging/linux-x64/scripts/launchApachePhp.sh || _die "Failed to copy the launchApachePhp script (scripts/linux/launchApachePhp.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchApachePhp.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    chmod ugo+x staging/linux-x64/php/php.ini

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-apachephp.directory staging/linux-x64/scripts/xdg/pg-apachephp.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchApachePhp.desktop staging/linux-x64/scripts/xdg/pg-launchApachePhp.desktop || _die "Failed to copy a menu pick desktop"

    cp resources/index.php staging/linux-x64/apache/www || _die "Failed to copy index.php"
    chmod ugo+x staging/linux-x64/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/linux-x64/apache/www/index.php"
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/linux-x64/apache/www/index.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


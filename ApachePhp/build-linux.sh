#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_linux() {

    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    if [ -e apache.linux ];
    then
      echo "Removing existing apache.linux source directory"
      rm -rf apache.linux  || _die "Couldn't remove the existing apache.linux source directory (source/apache.linux)"
    fi

    echo "Creating apache source directory ($WD/ApachePhp/source/apache.linux)"
    mkdir -p apache.linux || _die "Couldn't create the apache.linux directory"
    chmod ugo+w apache.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -pR httpd-$PG_VERSION_APACHE/* apache.linux || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    chmod -R ugo+w apache.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e php.linux ];
    then
      echo "Removing existing php.linux source directory"
      rm -rf php.linux  || _die "Couldn't remove the existing php.linux source directory (source/php.linux)"
    fi

    echo "Creating php source directory ($WD/ApachePhp/source/php.linux)"
    mkdir -p php.linux || _die "Couldn't create the php.linux directory"
    chmod ugo+w php.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the php source tree
    cp -pR php-$PG_VERSION_PHP/* php.linux || _die "Failed to copy the source code (source/php-$PG_VERSION_PHP)"
    chmod -R ugo+w php.linux || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApachePhp/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/linux)"
    mkdir -p $WD/ApachePhp/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApachePhp/staging/linux || _die "Couldn't set the permissions on the staging directory"

}


################################################################################
# PG Build
################################################################################

_build_ApachePhp_linux() {

    # build apache

    PG_STAGING=$PG_PATH_LINUX/ApachePhp/staging/linux

    # Configure the source tree
    echo "Configuring the apache source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux/; LD_LIBRARY_PATH=/usr/local/lib CFLAGS=\"-I/usr/local/include\" LDFLAGS=\"-L/usr/local/lib\" ./configure --prefix=$PG_STAGING/apache --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache --with-ssl=/usr/local --enable-mods-shared=all"  || _die "Failed to configure apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux/modules/ssl; sed -i \"s^\\(\\t\\\$(SH_LINK).*$\\)^\\1 -Wl,-rpath,\\\${libexecdir}^\" modules.mk"

    echo "Building apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux; make" || _die "Failed to build apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/apache.linux; make install" || _die "Failed to install apache"

    # Configure the httpd.conf file
    cd $WD/ApachePhp/staging/linux/apache/conf
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "httpd.conf"
    _replace "htdocs" "www" "httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "httpd.conf"
	# Comment out the unique_id_module, do not load it
	sed -e "s,^LoadModule unique_id_module modules/mod_unique_id.so,#LoadModule unique_id_module modules/mod_unique_id.so,g" httpd.conf > "/tmp/httpd.conf.tmp"
	mv /tmp/httpd.conf.tmp httpd.conf

    # Configure the apachectl script file
    cd $WD/ApachePhp/staging/linux/apache/bin
    _replace "\$HTTPD -k \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD -t" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\"@@INSTALL_DIR@@/php/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    ssh $PG_SSH_LINUX "chmod ugo+rx \"$PG_STAGING/apache/bin/apachectl\""

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libssl.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libcrypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libcom_err.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libexpat.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libgssapi_krb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libkrb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libkrb5support.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5support)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libk5crypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libxml2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libiconv.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libiconv)"

    echo "Configuring the php source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux/; export LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib:/usr/local/lib; sh ./configure --prefix=$PG_STAGING/php --with-apxs2=$PG_STAGING/apache/bin/apxs --with-config-file-path=/usr/local/etc --with-pgsql=$PG_PGHOME_LINUX --with-openssl=/usr/local --with-pdo-pgsql=$PG_PGHOME_LINUX --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite --with-gd --with-png-dir=/usr --with-jpeg-dir=/usr/local --with-freetype-dir=/usr/local --with-iconv=/usr/local --enable-gd-native-ttf --enable-mbstring=all" || _die "Failed to configure php"

    echo "Building php"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux; LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib:/usr/local/lib make" || _die "Failed to build php"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApachePhp/source/php.linux; LD_LIBRARY_PATH=$PG_PGHOME_LINUX/lib:/usr/local/lib make install" || _die "Failed to install php"
    cd $WD/ApachePhp
    if [ -f source/php.linux/php.ini-production ]; then
      cp source/php.linux/php.ini-production staging/linux/php/php.ini || _die "Failed to copy php.ini file"
    else
      cp source/php.linux/php.ini-recommended staging/linux/php/php.ini || _die "Failed to copy php.ini file"
    fi
    cd $WD

    # Copy in the dependency libraries (apache/php)
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/liblber*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libldap*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libldap*)"
    ssh $PG_SSH_LINUX "cp -pR /usr/lib/libpng12.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library (libpng12)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libjpeg.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library (jpeg)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libfreetype.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library (freetype)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libz.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library (libz)"
    ssh $PG_SSH_LINUX "cp -pR /usr/local/lib/libxml2.so* $PG_STAGING/php/lib" || _die "Failed to copy the dependency library (libxml2)"

    # Add LD_PRELOAD in envvars scripts
    cat <<EOT >> $WD/ApachePhp/staging/linux/apache/bin/envvars
CWD=\`pwd\`
cd @@INSTALL_DIR@@/php/lib
files=\`ls *.so*\`
cd \$CWD
for f in \$files
do
    BROKEN=\`file @@INSTALL_DIR@@/php/lib/\$f | grep broken\`
    if [ \"x\$BROKEN\" = \"x\" ] ; then
        LD_PRELOAD=@@INSTALL_DIR@@/php/lib/\$f:\$LD_PRELOAD
    fi
done
cd @@INSTALL_DIR@@/apache/lib
files=\`ls *.so*\`
cd \$CWD
for f in \$files
do
    BROKEN=\`file @@INSTALL_DIR@@/apache/lib/\$f | grep broken\`
    if [ \"x\$BROKEN\" = \"x\" ] ; then
        LD_PRELOAD=@@INSTALL_DIR@@/apache/lib/\$f:\$LD_PRELOAD
    fi
done
export LD_PRELOAD
EOT
    ssh $PG_SSH_LINUX "chmod ugo+rx \"$PG_STAGING/apache/bin/envvars\""

    # Configure the php script file
    cd $WD/ApachePhp/staging/linux/php
    _replace "--with-pgsql=$PG_PGHOME_LINUX" "--with-pgsql" bin/php-config
    _replace "--with-pdo-pgsql=$PG_PGHOME_LINUX" "--with-pdo-pgsql" bin/php-config
    _replace "--with-openssl=/usr/local" "--with-openssl" bin/php-config
    _replace " -L/usr/local/lib" "" bin/php-config
    _replace " -L$PG_PGHOME_LINUX/lib" "" bin/php-config
    _replace "--with-pgsql=$PG_PGHOME_LINUX" "--with-pgsql" include/php/main/build-defs.h
    _replace "--with-pdo-pgsql=$PG_PGHOME_LINUX" "--with-pdo-pgsql" include/php/main/build-defs.h
    _replace "--with-openssl=/usr/local" "--with-openssl" include/php/main/build-defs.h
    _replace "$PG_STAGING/php" "@@INSTALL_DIR@@/php" bin/phar.phar
    ssh $PG_SSH_LINUX "chmod a+rx \"$PG_STAGING/php/bin/php-config\""
    ssh $PG_SSH_LINUX "chmod a+rx \"$PG_STAGING/php/bin/phar.phar\""

    # Change the rpath for php
    ssh $PG_SSH_LINUX "cd $PG_STAGING/php; chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../apache/lib php; chmod 755 php"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/php; FILES=\`file \\\`find . -maxdepth 2 -mindepth 2\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../apache/lib \$F; chmod 755 \$F; fi done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/php; FILES=\`file \\\`find . -maxdepth 3 -mindepth 3\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../../lib:\\\${ORIGIN}/../../../apache/lib \$F; chmod 755 \$F; fi done"

    # Change the rpath for apache
    ssh $PG_SSH_LINUX "cd $PG_STAGING/apache; chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../php/lib modules/libphp5.so"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 2 -mindepth 2\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../lib \$F; chmod 755 \$F; fi done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 3 -mindepth 3\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../../lib \$F; chmod 755 \$F; fi done"

    cd $WD

}



################################################################################
# PG Build
################################################################################

_postprocess_ApachePhp_linux() {

    PG_STAGING=$PG_PATH_LINUX/ApachePhp/staging/linux

    #Configure the files in apache and php
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApachePhp/staging/linux" | grep -v Binary`

    cd $WD/ApachePhp/staging/linux

    for file in $filelist
    do
    _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done

    cd $WD/ApachePhp

    # Setup the installer scripts.

    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/linux/apache/htdocs staging/linux/apache/www || _die "Failed to change Server Root"
    chmod ugo+wx staging/linux/apache/www

    mkdir -p staging/linux/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/linux/apache/www/images || _die "Failed to create a directory for the images"
    chmod ugo+wx staging/linux/apache/www/images

    cp scripts/linux/createshortcuts.sh staging/linux/installer/ApachePhp/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/ApachePhp/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/removeshortcuts.sh

    cp scripts/linux/configureApachePhp.sh staging/linux/installer/ApachePhp/configureApachePhp.sh || _die "Failed to copy the configureApachePhp script (scripts/linux/configureApachePhp.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/configureApachePhp.sh

    cp scripts/linux/startupcfg.sh staging/linux/installer/ApachePhp/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux/installer/ApachePhp/startupcfg.sh

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/linux/launchApachePhp.sh staging/linux/scripts/launchApachePhp.sh || _die "Failed to copy the launchApachePhp script (scripts/linux/launchApachePhp.sh)"
    chmod ugo+x staging/linux/scripts/launchApachePhp.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    chmod ugo+x staging/linux/php/php.ini

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -pR $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-apachephp.directory staging/linux/scripts/xdg/pg-apachephp.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchApachePhp.desktop staging/linux/scripts/xdg/pg-launchApachePhp.desktop || _die "Failed to copy a menu pick desktop"

    cp resources/index.php staging/linux/apache/www || _die "Failed to copy index.php"
    chmod ugo+x staging/linux/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/linux/apache/www/index.php"
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/linux/apache/www/index.php"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}


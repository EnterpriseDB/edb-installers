#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ApachePhp_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/ApachePhp/source

    if [ -e apache.osx ];
    then
      echo "Removing existing apache.osx source directory"
      rm -rf apache.osx  || _die "Couldn't remove the existing apache.osx source directory (source/apache.osx)"
    fi

    echo "Creating apache source directory ($WD/ApachePhp/source/apache.osx)"
    mkdir -p apache.osx || _die "Couldn't create the apache.osx directory"
    chmod ugo+w apache.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -R httpd-$PG_VERSION_APACHE/* apache.osx || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    chmod -R ugo+w apache.osx || _die "Couldn't set the permissions on the source directory"

    if [ -e php.osx ];
    then
      echo "Removing existing php.osx source directory"
      rm -rf php.osx  || _die "Couldn't remove the existing php.osx source directory (source/php.osx)"
    fi
    
    echo "Creating php source directory ($WD/ApachePhp/source/php.osx)"
    mkdir -p php.osx || _die "Couldn't create the php.osx directory"
    chmod ugo+w php.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the php source tree
    cp -R php-$PG_VERSION_PHP/* php.osx || _die "Failed to copy the source code (source/php-$PG_VERSION_PHP)"
    chmod -R ugo+w php.osx || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApachePhp/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApachePhp/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApachePhp/staging/osx)"
    mkdir -p $WD/ApachePhp/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApachePhp/staging/osx || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_ApachePhp_osx() {

    # build apache
    PG_PATH_OSX=$WD
    PG_STAGING=$PG_PATH_OSX/ApachePhp/staging/osx

    cd $PG_PATH_OSX/ApachePhp/source/apache.osx
    # Configure the source tree

    echo "Configuring the apache source tree for Intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" ./configure --prefix=$PG_STAGING/apache --disable-dependency-tracking --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for i386"
  
    echo "Configuring the apache source tree for ppc"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" ./configure --prefix=$PG_STAGING/apache --disable-dependency-tracking --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for ppc"

    echo "Configuring the apache source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 " ./configure --prefix=$PG_STAGING/apache --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache  || _die "Failed to configure apache for Universal"

    echo "Building apache"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" make || _die "Failed to build apache"
    make install || _die "Failed to install apache"

    #Configure the httpd.conf file
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "$WD/ApachePhp/staging/osx/apache/conf/httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "$WD/ApachePhp/staging/osx/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$WD/ApachePhp/staging/osx/apache/conf/httpd.conf"

    #Configure the apachectl script file
    _replace "\$HTTPD -k \$ARGV" "\"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/osx/apache/bin/apachectl"
    _replace "\$HTTPD -t" "\"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/osx/apache/bin/apachectl"
    _replace "\$HTTPD \$ARGV" "\"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$WD/ApachePhp/staging/osx/apache/bin/apachectl"   chmod ugo+x "$PG_STAGING/apache/bin/apachectl" 
     
    cd $PG_PATH_OSX/ApachePhp/source/php.osx

    echo "Configuring the php source tree for intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" ./configure --with-libxml-dir=/usr --with-openssl --prefix=$PG_STAGING/php --with-pgsql=$PG_PGHOME_OSX --with-pdo-pgsql=$PG_PGHOME_OSX --with-apxs2=$PG_STAGING/apache/bin/apxs --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite || _die "Failed to configure PHP for intel"
 
    echo "Configuring the php source tree for ppc"
    CFLAGS="$PG_ARCH_OSX_CFLAG -arch ppc" ./configure --with-libxml-dir=/usr --with-openssl --prefix=$PG_STAGING/php --with-pgsql=$PG_PGHOME_OSX --with-pdo-pgsql=$PG_PGHOME_OSX --with-apxs2=$PG_STAGING/apache/bin/apxs --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite || _die "Failed to configure PHP for ppc"
 
    echo "Configuring the php source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" ./configure --with-libxml-dir=/usr --with-openssl --prefix=$PG_STAGING/php --with-pgsql=$PG_PGHOME_OSX --with-pdo-pgsql=$PG_PGHOME_OSX --with-apxs2=$PG_STAGING/apache/bin/apxs --without-mysql --without-pdo-mysql --without-sqlite --without-pdo-sqlite || _die "Failed to configure PHP for Universal" 

    echo "Building php"
    cd $PG_PATH_OSX/ApachePhp/source/php.osx
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 " make || _die "Failed to build php"
    install_name_tool -change "libpq.5.dylib" "$PG_PGHOME_OSX/lib/libpq.5.dylib" "$PG_PATH_OSX/ApachePhp/source/php.osx/sapi/cli/php"

    make install || _die "Failed to install php"
    cd $PG_PATH_OSX/ApachePhp/source/php.osx
    cp php.ini-recommended $PG_STAGING/php/php.ini || _die "Failed to copy php.ini file"
 
    cp $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/php/lib || _die "Failed to copy libpq to php lib "
    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/ApachePhp/staging/osx apache/modules/libphp*.so @loader_path/../../..

    cd $WD
}



################################################################################
# PG Build
################################################################################

_postprocess_ApachePhp_osx() {

    PG_PATH_OSX=$WD

    PG_STAGING=$PG_PATH_OSX/ApachePhp/staging/osx
    
    #Configure the files in apache and php
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApachePhp/staging/osx" | grep -v Binary`

    cd $WD/ApachePhp/staging/osx

    for file in $filelist
    do
	_replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
	chmod ugo+x "$file"
    done  

    cd $WD/ApachePhp

    # Setup the installer scripts. 

    #Changing the ServerRoot from htdocs to www in apache
    cp -R staging/osx/apache/htdocs staging/osx/apache/www || _die "Failed to change Server Root"
    chmod ugo+wx staging/osx/apache/www

    mkdir -p staging/osx/installer/ApachePhp || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/osx/apache/www/images || _die "Failed to create a directory for the images"
    chmod ugo+wx staging/osx/apache/www/images

    cp scripts/osx/createshortcuts.sh staging/osx/installer/ApachePhp/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/createshortcuts.sh

    cp scripts/osx/configureApachePhp.sh staging/osx/installer/ApachePhp/configureApachePhp.sh || _die "Failed to copy the configureApachePhp script (scripts/osx/configureApachePhp.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/configureApachePhp.sh

    cp scripts/osx/startupcfg.sh staging/osx/installer/ApachePhp/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/ApachePhp/startupcfg.sh
   
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts

    cp scripts/osx/launchbrowser.sh staging/osx/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/osx/launchbrowser.sh)"
    chmod ugo+x staging/osx/scripts/launchbrowser.sh

    cp scripts/osx/runApache.sh staging/osx/scripts/runApache.sh || _die "Failed to copy the runApache script (scripts/osx/runApache.sh)"
    chmod ugo+x staging/osx/scripts/runApache.sh

    chmod ugo+x staging/osx/php/php.ini

    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    cp scripts/osx/enterprisedb-launchApachePhp.applescript.in staging/osx/scripts/enterprisedb-launchApachePhp.applescript || _die "Failed to copy a menu pick desktop"
    cp scripts/osx/enterprisedb-startApache.applescript.in staging/osx/scripts/enterprisedb-startApache.applescript || _die "Failed to copy a menu pick desktop"
    cp scripts/osx/enterprisedb-stopApache.applescript.in staging/osx/scripts/enterprisedb-stopApache.applescript || _die "Failed to copy a menu pick desktop"
    cp scripts/osx/enterprisedb-restartApache.applescript.in staging/osx/scripts/enterprisedb-restartApache.applescript || _die "Failed to copy a menu pick desktop"

    cp resources/index.php staging/osx/apache/www || _die "Failed to copy index.php"
    chmod ugo+x staging/osx/apache/www/index.php

    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/osx/apache/www/index.php" 
    _replace PG_VERSION_PHP $PG_VERSION_PHP "staging/osx/apache/www/index.php" 

    # Build the installer"
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.zip apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf apachephp-$PG_VERSION_APACHE-$PG_VERSION_PHP-$PG_BUILDNUM_APACHEPHP-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


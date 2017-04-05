#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_ApacheHTTPD_linux() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP ApacheHTTPD Linux"

    # Enter the source directory and cleanup if required
    cd $WD/ApacheHTTPD/source

    if [ -e apache.linux ];
    then
      echo "Removing existing apache.linux source directory"
      rm -rf apache.linux  || _die "Couldn't remove the existing apache.linux source directory (source/apache.linux)"
    fi

    echo "Creating apache source directory ($WD/ApacheHTTPD/source/apache.linux)"
    mkdir -p apache.linux || _die "Couldn't create the apache.linux directory"
    mkdir -p apache.linux/mod_wsgi || _die "Couldn't create the mod_wsgi directory"
    chmod ugo+w apache.linux || _die "Couldn't set the permissions on the source directory"
    chmod ugo+w apache.linux/mod_wsgi || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -pR httpd-$PG_VERSION_APACHE/* apache.linux || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    cp -pR mod_wsgi-$PG_VERSION_WSGI/* apache.linux/mod_wsgi || _die "Failed to copy the source code (source/mod_wsgi-$PG_VERSION_WSGI)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApacheHTTPD/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApacheHTTPD/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApacheHTTPD/staging/linux)"
    mkdir -p $WD/ApacheHTTPD/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/ApacheHTTPD/staging/linux || _die "Couldn't set the permissions on the staging directory"

    echo "END PREP ApacheHTTPD Linux"
}


################################################################################
# PG Build
################################################################################

_build_ApacheHTTPD_linux() {
    echo "BEGIN BUILD ApacheHTTPD Linux"

    # For PEM7, apachehttpd needs to be built with python3.5 (LP10)
    if [ ! -z $PEM_PYTHON_LINUX ];
    then
        PG_PYTHON_LINUX=$PEM_PYTHON_LINUX
    fi

    # build apache

    PG_STAGING=$PG_PATH_LINUX/ApacheHTTPD/staging/linux

    # Configure the source tree
    echo "Configuring the apache source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux/; LD_LIBRARY_PATH=/opt/local/Current/lib CFLAGS=\"-I/opt/local/Current/include\" LDFLAGS=\"-L/opt/local/Current/lib -ldl\" ./configure --enable-debug --prefix=$PG_STAGING/apache --with-pcre=/opt/local/Current --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache --with-ssl=/opt/local/Current --enable-mods-shared=all"  || _die "Failed to configure apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux/modules/ssl; sed -i \"s^\\(\\t\\\$(SH_LINK).*$\\)^\\1 -Wl,-rpath,\\\${libexecdir}^\" modules.mk"

    echo "Building apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux; make" || _die "Failed to build apache"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux; make install" || _die "Failed to install apache"

    echo "Configuring the mod_wsgi source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux/mod_wsgi; LD_LIBRARY_PATH=/opt/local/Current/lib:$PG_PYTHON_LINUX/lib CFLAGS=\"-I/opt/local/Current/include -I$PG_PYTHON_LINUX/include\" LDFLAGS=\"-L/opt/local/Current/lib -L$PG_PYTHON_LINUX/lib\" ./configure --prefix=$PG_STAGING/apache --with-apxs=$PG_STAGING/apache/bin/apxs --with-python=$PG_PYTHON_LINUX/bin/python"  || _die "Failed to configure mod_wsgi"

    echo "Building mod_wsgi"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux/mod_wsgi; LD_LIBRARY_PATH=/opt/local/Current/lib:$PG_PYTHON_LINUX/lib:$LD_LIBRARY_PATH make" || _die "Failed to build mod_wsgi"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/ApacheHTTPD/source/apache.linux/mod_wsgi; make install" || _die "Failed to install mod_wsgi"


    # Configure the httpd.conf file
    cd $WD/ApacheHTTPD/staging/linux/apache/conf
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "httpd.conf"
    _replace "htdocs" "www" "httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "httpd.conf"
    _replace "#LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "httpd.conf"
    _replace "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "httpd.conf"
	# Comment out the unique_id_module, do not load it
	sed -e "s,^LoadModule unique_id_module modules/mod_unique_id.so,#LoadModule unique_id_module modules/mod_unique_id.so,g" httpd.conf > "/tmp/httpd.conf.tmp"
	mv /tmp/httpd.conf.tmp httpd.conf

    # disable SSL v3 because of POODLE vulnerability
    echo "SSLProtocol All -SSLv2 -SSLv3" >> extra/httpd-ssl.conf

    # Configure the apachectl script file
    cd $WD/ApacheHTTPD/staging/linux/apache/bin
    _replace "\$HTTPD -k \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD -t" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    ssh $PG_SSH_LINUX "chmod ugo+rx \"$PG_STAGING/apache/bin/apachectl\""



    # Configure the apachectl script file
    cd $WD/ApacheHTTPD/staging/linux/apache/bin
    ssh $PG_SSH_LINUX "chmod ugo+rx \"$PG_STAGING/apache/bin/apachectl\""

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libssl.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libcrypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libcom_err.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libexpat.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libgssapi_krb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libkrb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libkrb5support.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5support)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libk5crypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libxml2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libiconv.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libiconv)"
    ssh $PG_SSH_LINUX "cp -pR /opt/local/Current/lib/libpcre.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libpcre)"

    cd $WD

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libpq.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/liblber*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libsasl*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libsasl*)"
    ssh $PG_SSH_LINUX "cp -pR $PG_PGHOME_LINUX/lib/libldap*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libldap*)"

    # Add LD_LIBRARY_PATH in envvars scripts
    cat <<EOT >> $WD/ApacheHTTPD/staging/linux/apache/bin/envvars
export PYTHONHOME=@@LP_PYTHON_HOME@@
export PYTHONPATH=\$PYTHONHOME
LD_LIBRARY_PATH=@@INSTALL_DIR@@/apache/lib:\$PYTHONPATH/lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
EOT
    ssh $PG_SSH_LINUX "chmod ugo+rx \"$PG_STAGING/apache/bin/envvars\""

    # Change the rpath for apache
    ssh $PG_SSH_LINUX "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 2 -mindepth 2\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../lib \$F; chmod 755 \$F; fi done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 3 -mindepth 3\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\"\${RPATH}\" != x\"\" ]]; then chrpath --replace \\\${ORIGIN}/../../lib \$F; chmod 755 \$F; fi done"

    # Generate debug symbols
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux/ApacheHTTPD ];
    then
        echo "Removing existing $WD/output/symbols/linux/replication directory"
        rm -rf $WD/output/symbols/linux/ApacheHTTPD  || _die "Couldn't remove the existing $WD/output/symbols/linux/ApacheHTTPD directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux || _die "Failed to create $WD/output/symbols/linux directory"
    mv $WD/ApacheHTTPD/staging/linux/symbols $WD/output/symbols/linux/ApacheHTTPD || _die "Failed to move $WD/ApacheHTTPD/staging/linux/symbols to $WD/output/symbols/linux/ApacheHTTPD directory"

    cd $WD

    echo "END BUILD ApacheHTTPD Linux"
}



################################################################################
# PG Build
################################################################################

_postprocess_ApacheHTTPD_linux() {
    echo "BEGIN POST ApacheHTTPD Linux"

    PG_STAGING=$PG_PATH_LINUX/ApacheHTTPD/staging/linux

    #Configure the files in apache
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApacheHTTPD/staging/linux" | grep -v Binary`

    cd $WD/ApacheHTTPD/staging/linux

    for file in $filelist
    do
    _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done

    cd $WD/ApacheHTTPD

    pushd staging/linux
    generate_3rd_party_license "apache_httpd"
    popd

    # Setup the installer scripts.

    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/linux/apache/htdocs staging/linux/apache/www || _die "Failed to change Server Root"
    chmod 755 staging/linux/apache/www

    mkdir -p staging/linux/installer/ApacheHTTPD || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/linux/apache/www/images || _die "Failed to create a directory for the images"
    chmod 755 staging/linux/apache/www/images

    cp scripts/linux/createshortcuts.sh staging/linux/installer/ApacheHTTPD/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApacheHTTPD/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/ApacheHTTPD/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/ApacheHTTPD/removeshortcuts.sh

    cp scripts/linux/configureApacheHTTPD.sh staging/linux/installer/ApacheHTTPD/configureApacheHTTPD.sh || _die "Failed to copy the configure ApacheHTTPD script (scripts/linux/configureApacheHTTPD.sh)"
    chmod ugo+x staging/linux/installer/ApacheHTTPD/configureApacheHTTPD.sh

    cp scripts/linux/startupcfg.sh staging/linux/installer/ApacheHTTPD/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux/installer/ApacheHTTPD/startupcfg.sh

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/linux/launchApacheHTTPD.sh staging/linux/scripts/launchApacheHTTPD.sh || _die "Failed to copy the launchApacheHTTPD script (scripts/linux/launchApacheHTTPD.sh)"
    chmod ugo+x staging/linux/scripts/launchApacheHTTPD.sh

    cp scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -pR $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-apachehttpd.directory staging/linux/scripts/xdg/pg-apachehttpd.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchApacheHTTPD.desktop staging/linux/scripts/xdg/pg-launchApacheHTTPD.desktop || _die "Failed to copy a menu pick desktop"

    cp resources/index.html staging/linux/apache/www || _die "Failed to copy index.html"
    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/linux/apache/www/index.html"

    #Remove the httpd.conf.bak from the staging if exists.
    if [ -f staging/linux/apache/conf/httpd.conf.bak ]; then
      rm -f staging/linux/apache/conf/httpd.conf.bak
    fi

    # Set permissions to all files and folders in staging
    _set_permissions linux

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
    echo "END POST ApacheHTTPD Linux"
}



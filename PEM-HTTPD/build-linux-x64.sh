#!/bin/bash

################################################################################
# Build preparation
################################################################################

_prep_PEM-HTTPD_linux_x64() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP PEM-HTTPD Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/PEM-HTTPD/source

    if [ -e apache.linux-x64 ];
    then
      echo "Removing existing apache.linux-x64 source directory"
      rm -rf apache.linux-x64  || _die "Couldn't remove the existing apache.linux-x64 source directory (source/apache.linux-x64)"
    fi

    echo "Creating apache source directory ($WD/PEM-HTTPD/source/apache.linux-x64)"
    mkdir -p apache.linux-x64 || _die "Couldn't create the apache.linux-x64 directory"
    mkdir -p apache.linux-x64/mod_wsgi || _die "Couldn't create the mod_wsgi directory"
    chmod ugo+w apache.linux-x64 || _die "Couldn't set the permissions on the source directory"
    chmod ugo+w apache.linux-x64/mod_wsgi || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -pR httpd-$PG_VERSION_APACHE/* apache.linux-x64 || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    cp -pR mod_wsgi-$PG_VERSION_WSGI/* apache.linux-x64/mod_wsgi || _die "Failed to copy the source code (source/mod_wsgi-$PG_VERSION_WSGI)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PEM-HTTPD/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PEM-HTTPD/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PEM-HTTPD/staging/linux-x64.build)"
    mkdir -p $WD/PEM-HTTPD/staging/linux-x64.build || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PEM-HTTPD/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"

    echo "END PREP PEM-HTTPD Linux-x64"
}


################################################################################
# PG Build
################################################################################

_build_PEM-HTTPD_linux_x64() {
    echo "BEGIN BUILD PEM-HTTPD Linux-x64"

    # build apache

    PG_STAGING=$PG_PATH_LINUX_X64/PEM-HTTPD/staging/linux-x64.build

    # Configure the source tree
    echo "Configuring the apache source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64/; LD_LIBRARY_PATH=/opt/local/Current/lib CFLAGS=\"-I/opt/local/Current/include\" LDFLAGS=\"-L/opt/local/Current/lib -ldl\" ./configure --enable-debug --prefix=$PG_STAGING/apache --with-pcre=/opt/local/Current --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache --with-ssl=/opt/local/Current --enable-mods-shared=all"  || _die "Failed to configure apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64/modules/ssl; sed -i \"s^\\(\\t\\\$(SH_LINK).*$\\)^\\1 -Wl,-rpath,\\\${libexecdir}^\" modules.mk"

    echo "Building apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64; make" || _die "Failed to build apache"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64; make install" || _die "Failed to install apache"

    echo "Configuring the mod_wsgi source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64/mod_wsgi; LD_LIBRARY_PATH=/opt/local/Current/lib:$PEM_PYTHON_LINUX_X64/lib CFLAGS=\"-I/opt/local/Current/include -I$PEM_PYTHON_LINUX_X64/include\" LDFLAGS=\"-L/opt/local/Current/lib -L$PEM_PYTHON_LINUX_X64/lib\" ./configure --prefix=$PG_STAGING/apache --with-apxs=$PG_STAGING/apache/bin/apxs --with-python=$PEM_PYTHON_LINUX_X64/bin/python"  || _die "Failed to configure mod_wsgi"

    echo "Building mod_wsgi"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64/mod_wsgi; LD_LIBRARY_PATH=/opt/local/Current/lib:$PEM_PYTHON_LINUX_X64/lib:$LD_LIBRARY_PATH make" || _die "Failed to build mod_wsgi"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PEM-HTTPD/source/apache.linux-x64/mod_wsgi; make install" || _die "Failed to install mod_wsgi"

    # Configure the httpd.conf file
    cd $WD/PEM-HTTPD/staging/linux-x64.build/apache/conf
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "httpd.conf"
    _replace "Listen 80" "Listen 0.0.0.0:@@PORT@@" "httpd.conf"
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
    cd $WD/PEM-HTTPD/staging/linux-x64.build/apache/bin
    _replace "\$HTTPD -k \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -k \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD -t" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"
    _replace "\$HTTPD \$ARGV" "LD_LIBRARY_PATH=\"@@INSTALL_DIR@@/apache/lib\":\$LD_LIBRARY_PATH \"\$HTTPD\" \$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "apachectl"

    # Copy in the dependency libraries (apache)
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libssl.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libssl)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libcrypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcrypto)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libcom_err.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libcom_err)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libexpat.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libexpat)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libgssapi_krb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libgssapi_krb5)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libkrb5.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libkrb5support.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libkrb5support)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libk5crypto.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libk5crypto)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libxml2.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libxml2)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libiconv.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libiconv)"
    ssh $PG_SSH_LINUX_X64 "cp -pR /opt/local/Current/lib/libpcre.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libpcre)"

    cd $WD

    # Copy in the dependency libraries (apache/httpd)
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libpq.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libpq)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/liblber*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (liblber*)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libsasl*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libsasl*)"
    ssh $PG_SSH_LINUX_X64 "cp -pR $PG_PGHOME_LINUX_X64/lib/libldap*.so* $PG_STAGING/apache/lib" || _die "Failed to copy the dependency library (libldap*)"

    # Add LD_LIBRARY_PATH in envvars scripts
    cat <<EOT >> $WD/PEM-HTTPD/staging/linux-x64.build/apache/bin/envvars
export PYTHONHOME=@@LP_PYTHON_HOME@@
export PYTHONPATH=\$PYTHONHOME
LD_LIBRARY_PATH=@@INSTALL_DIR@@/apache/lib:\$PYTHONPATH/lib:@@INSTALL_DIR@@/httpd/lib:\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
EOT
    ssh $PG_SSH_LINUX_X64 "chmod ugo+rx \"$PG_STAGING/apache/bin/envvars\""

    # Change the rpath for apache
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/apache; chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../../httpd/lib modules/libhttpd5.so"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 2 -mindepth 2\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\${RPATH} != x ]]; then chrpath --replace \\\${ORIGIN}/../lib \$F; chmod 755 \$F; fi done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/apache; FILES=\`file \\\`find . -maxdepth 3 -mindepth 3\\\` | grep ELF | cut -d: -f1\`; for F in \$FILES; do RPATH=\`chrpath \$F | grep RPATH | grep -v ORIGIN\`; if [[ x\${RPATH} != x ]]; then chrpath --replace \\\${ORIGIN}/../../lib \$F; chmod 755 \$F; fi done"

    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/PEM-HTTPD ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/PEM-HTTPD directory"
        rm -rf $WD/output/symbols/linux-x64/PEM-HTTPD  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/PEM-HTTPD directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/PEM-HTTPD/staging/linux-x64.build/symbols $WD/output/symbols/linux-x64/PEM-HTTPD || _die "Failed to move $WD/PEM-HTTPD/staging/linux-x64.build/symbols to $WD/output/symbols/linux-x64/PEM-HTTPD directory"

    echo "Removing last successful staging directory ($WD/PEM-HTTPD/staging/linux-x64)"
    rm -rf $WD/PEM-HTTPD/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/PEM-HTTPD/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/PEM-HTTPD/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/PEM-HTTPD/staging/linux-x64.build/* $WD/PEM-HTTPD/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_APACHE=$PG_VERSION_APACHE" > $WD/PEM-HTTPD/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_PEMHTTPD=$PG_BUILDNUM_PEMHTTPD" >> $WD/PEM-HTTPD/staging/linux-x64/versions-linux-x64.sh
    cd $WD

    echo "END BUILD PEM-HTTPD Linux-x64"
}



################################################################################
# PG Build
################################################################################

_postprocess_PEM-HTTPD_linux_x64() {
    echo "BEGIN POST PEM-HTTPD Linux-x64"

    source $WD/PEM-HTTPD/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_PEMHTTPD=$(expr $PG_BUILD_PEMHTTPD + $SKIPBUILD)

    PG_STAGING=$PG_PATH_LINUX_X64/PEM-HTTPD/staging/linux-x64.build

    #Configure the files in apache and httpd
    filelist=`grep -rslI "$PG_STAGING" "$WD/PEM-HTTPD/staging/linux-x64" | grep -v Binary`

    cd $WD/PEM-HTTPD/staging/linux-x64

    for file in $filelist
    do
    _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
    chmod ugo+x "$file"
    done

    cd $WD/PEM-HTTPD

    pushd staging/linux-x64
    generate_3rd_party_license "pem_httpd"
    popd

    # Setup the installer scripts.

    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/linux-x64/apache/htdocs staging/linux-x64/apache/www || _die "Failed to change Server Root"
    chmod 755 staging/linux-x64/apache/www

    mkdir -p staging/linux-x64/installer/PEM-HTTPD || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/linux-x64/apache/www/images || _die "Failed to create a directory for the images"
    chmod 755 staging/linux-x64/apache/www/images

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/PEM-HTTPD/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PEM-HTTPD/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/PEM-HTTPD/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PEM-HTTPD/removeshortcuts.sh

    cp scripts/linux/configurePEMHTTPD.sh staging/linux-x64/installer/PEM-HTTPD/configurePEMHTTPD.sh || _die "Failed to copy the configurePEMHTTPD script (scripts/linux/configurePEMHTTPD.sh)"
    chmod ugo+x staging/linux-x64/installer/PEM-HTTPD/configurePEMHTTPD.sh

    cp scripts/linux/startupcfg.sh staging/linux-x64/installer/PEM-HTTPD/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/linux/startupcfg.sh)"
    chmod ugo+x staging/linux-x64/installer/PEM-HTTPD/startupcfg.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    # Copy the launch scripts
    cp scripts/linux/launchPEMHTTPD.sh staging/linux-x64/scripts/launchPEMHTTPD.sh || _die "Failed to copy the launchPEMHTTPD script (scripts/linux/launchPEMHTTPD.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchPEMHTTPD.sh

    cp scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launchbrowser script (scripts/linux/launchbrowser.sh)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -pR $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-pemhttpd.directory staging/linux-x64/scripts/xdg/pg-pemhttpd.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPEMHTTPD.desktop staging/linux-x64/scripts/xdg/pg-launchPEMHTTPD.desktop || _die "Failed to copy a menu pick desktop"

    cp resources/index.html staging/linux-x64/apache/www || _die "Failed to copy index.html"
    _replace PG_VERSION_APACHE $PG_VERSION_APACHE "staging/linux-x64/apache/www/index.html"

    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    #Remove the httpd.conf.bak from the staging if exists.
    if [ -f staging/linux-x64/apache/conf/httpd.conf.bak ]; then
      rm -f staging/linux-x64/apache/conf/httpd.conf.bak
    fi

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_PEMHTTPD -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/pem-httpd-$PG_VERSION_APACHE-$PG_BUILDNUM_PEMHTTPD-linux-x64.run $WD/output/pem-httpd-$PG_VERSION_APACHE-$PG_BUILDNUM_PEMHTTPD-${BUILD_FAILED}linux-x64.run

    cd $WD
    echo "END POST PEM-HTTPD Linux-x64"
}


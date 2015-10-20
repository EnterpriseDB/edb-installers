#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_ApacheHTTPD_osx() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP ApacheHTTPD OSX"

    echo "*******************************************************"
    echo " Pre Process : ApacheHTTPD (OSX)"
    echo "*******************************************************"
      
    # Enter the source directory and cleanup if required
    cd $WD/ApacheHTTPD/source

    if [ -e apache.osx ];
    then
      echo "Removing existing apache.osx source directory"
      rm -rf apache.osx  || _die "Couldn't remove the existing apache.osx source directory (source/apache.osx)"
    fi

    echo "Creating apache source directory ($WD/ApacheHTTPD/source/apache.osx)"
    mkdir -p apache.osx || _die "Couldn't create the apache.osx directory"
    chmod 755 apache.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the apache source tree
    cp -pR httpd-$PG_VERSION_APACHE/* apache.osx || _die "Failed to copy the source code (source/httpd-$PG_VERSION_APACHE)"
    tar -jcvf apache.tar.bz2 apache.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/ApacheHTTPD/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/ApacheHTTPD/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/ApacheHTTPD/staging/osx)"
    mkdir -p $WD/ApacheHTTPD/staging/osx || _die "Couldn't create the staging directory"
    chmod 755 $WD/ApacheHTTPD/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "if [ -d $PG_PATH_OSX/ApacheHTTPD ]; then rm -rf $PG_PATH_OSX/ApacheHTTPD/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/ApacheHTTPD/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/ApacheHTTPD/source/apache.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/ApacheHTTPD/source/ || _die "Failed to copy the source archives to build VM"

    echo "Copy the scripts required to build VM"
    cd $WD/ApacheHTTPD
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/ApacheHTTPD/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/ApacheHTTPD || _die "Failed to copy the scripts to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApacheHTTPD/source; tar -jxvf apache.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApacheHTTPD; tar -jxvf scripts.tar.bz2"

    echo "END PREP ApacheHTTPD OSX"
}


################################################################################
# ApacheHTTPD Build
################################################################################

_build_ApacheHTTPD_osx() {
    echo "BEGIN BUILD ApacheHTTPD OSX"

    echo "*******************************************************"
    echo " Build : ApacheHTTPD (OSX)"
    echo "*******************************************************"

	OLDPATH=$PATH
    PATH=/bin:/sbin:/usr/bin:/usr/sbin
    export PATH

    # build apache
    PG_STAGING=$PG_PATH_OSX/ApacheHTTPD/staging/osx

    cat <<EOT-APACHEHTTPD > build-apachehttpd.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh
    cd $PG_PATH_OSX/ApacheHTTPD/source/apache.osx

    # Configure the source tree
    CONFIG_FILES="include/ap_config_auto include/ap_config_layout \
srclib/apr/include/apr srclib/apr/include/arch/unix/apr_private \
srclib/apr-util/include/apr_ldap srclib/apr-util/include/apu \
srclib/apr-util/include/apu_want srclib/apr-util/include/private/apu_config \
srclib/apr-util/include/private/apu_select_dbm srclib/apr-util/xml/expat/config \
srclib/apr-util/xml/expat/lib/expat"
    ARCHS="i386 x86_64"
    ARCH_FLAGS=""
    for ARCH in \${ARCHS}
    do
      echo "Configuring the apache source tree for \${ARCH}"
      CFLAGS="${PG_ARCH_OSX_CFLAGS} -arch \${ARCH} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} -L/opt/local/Current/lib -arch \${ARCH}" ./configure --prefix=$PG_STAGING/apache --with-ssl=/opt/local/Current --with-pcre=/opt/local/Current --with-included-apr --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for \${ARCH}"
      ARCH_FLAGS="\${ARCH_FLAGS} -arch \${ARCH}"
      for configFile in \${CONFIG_FILES}
      do
           if [ -f "\${configFile}.h" ]; then
              cp "\${configFile}.h" "\${configFile}_\${ARCH}.h"
           fi
      done
    done

    echo "Configuring the apache source tree for Universal"
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib" ./configure --prefix=$PG_STAGING/apache --with-ssl=/opt/local/Current --with-pcre=/opt/local/Current --with-included-apr --enable-so --enable-ssl --enable-rewrite --enable-proxy --enable-info --enable-cache || _die "Failed to configure apache for 32 bit Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    for configFile in \${CONFIG_FILES}
    do
      HEADER_FILE=\${configFile}.h
      if [ -f "\${HEADER_FILE}" ]; then
        CONFIG_BASENAME=\`basename \${configFile}\`
        rm -f "\${HEADER_FILE}"
        cat <<EOT > "\${HEADER_FILE}"
#ifdef __BIG_ENDIAN__
  #error "\${CONFIG_BASENAME}: Does not have support for ppc64 architecture"
#else
 #ifdef __LP64__
  #include "\${CONFIG_BASENAME}_x86_64.h"
 #else
  #include "\${CONFIG_BASENAME}_i386.h"
 #endif
#endif
EOT
      fi
    done

    # Hackup the httpd config to get suitable paths in the binary
    _replace "#define HTTPD_ROOT \"$PG_STAGING/apache\"" "#define HTTPD_ROOT \"/Library/EnterpriseDB-ApacheHTTPD/apache\"" include/ap_config_auto.h

    echo "Building apache"
    CFLAGS="${PG_ARCH_OSX_CFLAGS} \${ARCH_FLAGS} -I/opt/local/Current/include"  LDFLAGS="${PG_ARCH_OSX_LDFLAGS} \${ARCH_FLAGS} -L/opt/local/Current/lib" make || _die "Failed to build apache"
    make install || _die "Failed to install apache"

    PATH=$OLDPATH
    export PATH

    #Configure the httpd.conf file
    _replace "$PG_STAGING/apache" "@@INSTALL_DIR@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "Listen 80" "Listen @@PORT@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "htdocs" "www" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#ServerName www.example.com:80" "ServerName localhost:@@PORT@@" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "LoadModule slotmem_shm_module modules/mod_slotmem_shm.so" "$PG_STAGING/apache/conf/httpd.conf"
    _replace "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" "$PG_STAGING/apache/conf/httpd.conf"

    # disable SSL v3 because of POODLE vulnerability
    echo "SSLProtocol All -SSLv2 -SSLv3" >> extra/httpd-ssl.conf

    #Apply patch to apachectl before continuing
#    echo "Applying apachectl patch to comment ulimit check"
#    cd $PG_STAGING/apache/bin
#    patch ./apachectl $WD/tarballs/apache_fb13276.diff
#    cd $PG_PATH_OSX/ApacheHTTPD/source/apache.osx
    
    #Configure the apachectl script file
    _replace "\\\$HTTPD -k \\\$ARGV" "\\"\\\$HTTPD\\" -k \\\$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"
    _replace "\\\$HTTPD -t" "\\"\\\$HTTPD\\" -t -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"
    _replace "\\\$HTTPD \\\$ARGV" "\\"\\\$HTTPD\\" \\\$ARGV -f '@@INSTALL_DIR@@/apache/conf/httpd.conf'" "$PG_STAGING/apache/bin/apachectl"   chmod ugo+x "$PG_STAGING/apache/bin/apachectl"

    cp -pR /opt/local/Current/lib/libcrypto*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libexpat*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libssl*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"
    cp -pR /opt/local/Current/lib/libpcre.*.dylib $PG_STAGING/apache/lib || _die "Failed to copy the dependency library"

    chmod u+w $PG_STAGING/apache/lib/*

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $PG_STAGING apache/lib @loader_path/../..
    _rewrite_so_refs $PG_STAGING apache/modules @loader_path/../..
    _rewrite_so_refs $PG_STAGING apache/bin @loader_path/../..

    install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.dylib" $PG_STAGING/apache/modules/mod_ssl.so
    install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.dylib" $PG_STAGING/apache/modules/mod_ssl.so

    files=\`ls $PG_STAGING/apache/bin/*\`
    for file in \$files
    do
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libpcre.1.dylib" "@loader_path/../../apache/lib/libpcre.1.dylib" \$file
    done
    files=\`ls $PG_STAGING/apache/lib/lib*.dylib\`
    for file in \$files
    do
        install_name_tool -change "@loader_path/../../lib/libexpat.1.dylib" "@loader_path/../../apache/lib/libexpat.1.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libcrypto.1.0.0.dylib" "@loader_path/../../apache/lib/libcrypto.1.0.0.dylib" \$file
        install_name_tool -change "@loader_path/../../lib/libssl.1.0.0.dylib" "@loader_path/../../apache/lib/libssl.1.0.0.dylib" \$file
    done
EOT-APACHEHTTPD

    scp build-apachehttpd.sh $PG_SSH_OSX:$PG_PATH_OSX/ApacheHTTPD
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/ApacheHTTPD; sh ./build-apachehttpd.sh" || _die "Failed to build ApacheHTTPD on OSX"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_STAGING; tar -jcvf apachehttpd-staging.tar.bz2 *" || _die "Failed to create archive of the apachehttpd staging"
    scp $PG_SSH_OSX:$PG_STAGING/apachehttpd-staging.tar.bz2 $WD/ApacheHTTPD/staging/osx || _die "Failed to scp apachehttpd staging"

    # Extract the staging archive
    cd $WD/ApacheHTTPD/staging/osx
    tar -jxvf apachehttpd-staging.tar.bz2 || _die "Failed to extract the apachehttpd staging archive"
    rm -f apachehttpd-staging.tar.bz2

    echo "END BUILD ApacheHTTPD OSX"
}


################################################################################
# PostProcess ApacheHTTPD
################################################################################

_postprocess_ApacheHTTPD_osx() {
    echo "BEGIN POST ApacheHTTPD OSX"

    echo "*******************************************************"
    echo " Post Process : ApacheHTTPD (OSX)"
    echo "*******************************************************"

    #PG_PATH_OSX=$WD

    PG_STAGING=$PG_PATH_OSX/ApacheHTTPD/staging/osx
    
    #Configure the files in apache and httpd
    filelist=`grep -rslI "$PG_STAGING" "$WD/ApacheHTTPD/staging/osx" | grep -v Binary`

    cd $WD/ApacheHTTPD/staging/osx

    pushd $WD/ApacheHTTPD/staging/osx
    generate_3rd_party_license "apache_httpd"
    popd

    for file in $filelist
    do
        _replace "$PG_STAGING" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done  

    cd $WD/ApacheHTTPD

    # Setup the installer scripts. 

    #Changing the ServerRoot from htdocs to www in apache
    cp -pR staging/osx/apache/htdocs staging/osx/apache/www || _die "Failed to change Server Root"
    chmod 755 staging/osx/apache/www

    mkdir -p staging/osx/installer/ApacheHTTPD || _die "Failed to create a directory for the install scripts"
    mkdir -p staging/osx/apache/www/images || _die "Failed to create a directory for the images"
    chmod 755 staging/osx/apache/www/images

    cp scripts/osx/createshortcuts.sh staging/osx/installer/ApacheHTTPD/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/ApacheHTTPD/createshortcuts.sh

    cp scripts/osx/configureApacheHTTPD.sh staging/osx/installer/ApacheHTTPD/configureApacheHTTPD.sh || _die "Failed to copy the configureApacheHTTPD script (scripts/osx/configureApacheHTTPD.sh)"
    chmod ugo+x staging/osx/installer/ApacheHTTPD/configureApacheHTTPD.sh

    cp scripts/osx/startupcfg.sh staging/osx/installer/ApacheHTTPD/startupcfg.sh || _die "Failed to copy the startupcfg script (scripts/osx/startupcfg.sh)"
    chmod ugo+x staging/osx/installer/ApacheHTTPD/startupcfg.sh
   
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"

    # Copy in the menu pick images 
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/*.icns)"

    cp scripts/osx/pg-launchApacheHTTPD.applescript.in staging/osx/scripts/pg-launchApacheHTTPD.applescript || _die "Failed to copy a menu pick desktop"
    cp scripts/osx/getapacheport.sh staging/osx/scripts/getapacheport.sh || _die "Failed to copy the getapacheport script (scripts/osx/getapacheport.sh)"
    chmod ugo+x staging/osx/scripts/getapacheport.sh

    # Set permissions to all files and folders in staging
    _set_permissions osx

    #Remove the httpd.conf.bak from the staging if exists.
    if [ -f staging/osx/apache/conf/httpd.conf.bak ]; then
      rm -f staging/osx/apache/conf/httpd.conf.bak
    fi

    # Build the installer"
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output

    # Scp the app bundle to the signing machine for signing
    tar -jcvf apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app.tar.bz2 apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf apache*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app; mv apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx-signed.app apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app;" || _die "could not move the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.zip apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/apachehttpd-$PG_VERSION_APACHE-$PG_BUILDNUM_APACHEHTTPD-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."
    
    cd $WD
    echo "END POST ApacheHTTPD OSX"
}


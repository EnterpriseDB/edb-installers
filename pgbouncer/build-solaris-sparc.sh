#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_solaris_sparc() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.solaris-sparc ];
    then
      echo "Removing existing pgbouncer.solaris-sparc source directory"
      rm -rf pgbouncer.solaris-sparc  || _die "Couldn't remove the existing pgbouncer.solaris-sparc source directory (source/pgbouncer.solaris-sparc)"
    fi
   
    if [ -e pgbouncer.solaris-sparc.zip ];
    then
      echo "Removing existing pgbouncer.solaris-sparc zip file"
      rm -rf pgbouncer.solaris-sparc.zip  || _die "Couldn't remove the existing pgbouncer.solaris-sparc zip file (source/pgbouncer.solaris-sparc.zip)"
    fi
   
    echo "Creating staging directory ($WD/pgbouncer/source/libevent.solaris-sparc)"
    mkdir -p $WD/pgbouncer/source/libevent.solaris-sparc || _die "Couldn't create the libevent.solaris-sparc directory"

    echo "Creating staging directory ($WD/pgbouncer/source/pgbouncer.solaris-sparc)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.solaris-sparc || _die "Couldn't create the pgbouncer.solaris-sparc directory"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.solaris-sparc || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.solaris-sparc || _die "Couldn't set the permissions on the source directory"

    # Applying patch for solaris build failure
    cd pgbouncer.solaris-sparc
    patch -p1 < ../../../tarballs/pgbouncer-1.5.4-solaris.patch
    cd $WD/pgbouncer/source
    zip -r pgbouncer.solaris-sparc.zip pgbouncer.solaris-sparc || _die "Failed to zip the pgbouncer source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/solaris-sparc ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/solaris-sparc || _die "Couldn't remove the existing staging directory"
      ssh $PG_SSH_SOLARIS_SPARC "rm -rf  $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc" || _die "Failed to remove the pgbouncer staging directory from Solaris VM"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/solaris-sparc)"
    mkdir -p $WD/pgbouncer/staging/solaris-sparc || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/solaris-sparc || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; rm -f create_debug_symbols.sh"

    ssh $PG_SSH_SOLARIS_SPARC "rm -rf  $PG_PATH_SOLARIS_SPARC/pgbouncer/source" || _die "Failed to remove the pgbouncer source directory from Solaris VM"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/pgbouncer/source" || _die "Failed to create the pgbouncer source directory from Solaris VM"
    scp pgbouncer.solaris-sparc.zip $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/pgbouncer/source/ || _die "Failed to scp the pgbouncer zip file"
    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC/pgbouncer/source; unzip pgbouncer.solaris-sparc.zip" || _die "Failed to unzip the pgbouncer source directory in Solaris VM"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/solaris-sparc/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/solaris-sparc/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/solaris-sparc/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/solaris-sparc/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"

}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_solaris_sparc() {

    cd $WD/pgbouncer/source

    cat <<EOT > "setenv.sh"
export CC="cc"
export CXX="CC"
export CFLAGS="-m64"
export CXXFLAGS="-m64 -library=stlport4"
export CPPFLAGS="-m64"
export LDFLAGS="-m64"
export LD_LIBRARY_PATH=/opt/local/Current/lib
export PATH=$PG_SOLARIS_STUDIO_SOLARIS_SPARC/bin:/opt/local/Current/bin:/usr/ccs/bin:/usr/sfw/bin:/usr/sfw/sbin:/opt/csw/bin:/usr/ucb:\$PATH

EOT
    scp setenv.sh $PG_SSH_SOLARIS_SPARC: || _die "Failed to scp the setenv.sh file"


    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; unset CC; cd $PG_PATH_SOLARIS_SPARC/pgbouncer/source/pgbouncer.solaris-sparc/; LDFLAGS="-Wl,-R,$PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/lib" ./configure --prefix=$PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer --with-libevent=/opt/local/Current" || _die "Failed to configure pgbouncer"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/pgbouncer/source/pgbouncer.solaris-sparc/; gmake" || _die "Failed to build pgbouncer"
    ssh $PG_SSH_SOLARIS_SPARC "source setenv.sh; cd $PG_PATH_SOLARIS_SPARC/pgbouncer/source/pgbouncer.solaris-sparc/; gmake  install" || _die "Failed to install pgbouncer"
    ssh $PG_SSH_SOLARIS_SPARC "cp -R $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/share/doc/pgbouncer/pgbouncer.ini $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/share/" || _die "Failed to copy pgbouncer ini to share folder"


    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/instscripts" || _die "Failed to create the instscripts directory"
    ssh $PG_SSH_SOLARIS_SPARC "mkdir -p $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/lib" || _die "Failed to create the pgbouncer lib directory"
    PG_LIBEVENT_MAJOR_VERSION=`echo $PG_TARBALL_LIBEVENT | cut -f1,2 -d'.'`

    ssh $PG_SSH_SOLARIS_SPARC "rm -rf /tmp/tmp_libs && mkdir /tmp/tmp_libs" || _die "Failed to create tmp_libs in tmp folder"
    ssh $PG_SSH_SOLARIS_SPARC "cp -R /opt/local/Current/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* /tmp/tmp_libs" || _die "Failed to copy libevent libs in tmp folder"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN/../lib/' $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/bin/pgbouncer" || _die "Failed to set rpath of pgbouncer"
    ssh $PG_SSH_SOLARIS_SPARC "cp -R /opt/local/Current/lib/libxml2.so* /tmp/tmp_libs" || _die "Failed to copy libxml libs in tmp folder"
    ssh $PG_SSH_SOLARIS_SPARC "/opt/local/Current/bin/chrpath -r '\$ORIGIN' /tmp/tmp_libs/libxml2.so*" || _die "Failed to set rpath in tmp_libs folder"
    ssh $PG_SSH_SOLARIS_SPARC "cp -R /tmp/tmp_libs/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"

    ###ssh $PG_SSH_SOLARIS_SPARC "cp -R /usr/local/lib/libevent-$PG_LIBEVENT_MAJOR_VERSION* $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer/lib" || _die "Failed to copy libevent libs in pgbouncer lib folder"


    ###ssh $PG_SSH_SOLARIS_SPARC "cp -R /usr/local/lib/libxml2.so* $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/instscripts/" || _die "Failed to copy the dependency library"

    # Generate debug symbols
    scp $WD/create_debug_symbols.sh $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC || _die "Failed to copy create_debug_symbols.sh on solaris-sparc build machine"

    ssh $PG_SSH_SOLARIS_SPARC "cd $PG_PATH_SOLARIS_SPARC; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/pgbouncer" || _die "Failed to execute create_debug_symbols.sh"

    scp -r $PG_SSH_SOLARIS_SPARC:$PG_PATH_SOLARIS_SPARC/pgbouncer/staging/solaris-sparc/* $WD/pgbouncer/staging/solaris-sparc/ || _die "Failed to scp back the staging directory"

    cp -R $WD/server/staging/solaris-sparc/lib/libxml2.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"

    cp -R $WD/server/staging/solaris-sparc/lib/libpq* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R $WD/server/staging/solaris-sparc/bin/psql $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R $WD/server/staging/solaris-sparc/lib/libssl.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libcrypto.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libedit.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libxslt.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libkrb5.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libkrb5support.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libk5crypto.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libcom_err.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libiconv.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libz.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libmemcached*.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libgssapi_krb*.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the dependency library"
    cp -R $WD/server/staging/solaris-sparc/lib/libldap*.so* $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the libldap library"
    cp -R $WD/server/staging/solaris-sparc/lib/liblber*.so*  $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the liblber library"
    cp -R $WD/server/staging/solaris-sparc/lib/libsasl2*.so*  $WD/pgbouncer/staging/solaris-sparc/instscripts/ || _die "Failed to copy the libsasl2 library"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/solaris-sparc/pgbouncer ];
    then
        echo "Removing existing $WD/output/symbols/solaris-sparc/pgbouncer directory"
        rm -rf $WD/output/symbols/solaris-sparc/pgbouncer  || _die "Couldn't remove the existing $WD/output/symbols/solaris-sparc/pgbouncer directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/solaris-sparc || _die "Failed to create $WD/output/symbols/solaris-sparc directory"
    mv $WD/pgbouncer/staging/solaris-sparc/pgbouncer/symbols $WD/output/symbols/solaris-sparc/pgbouncer || _die "Failed to move $WD/pgbouncer/staging/solaris-sparc/pgbouncer/symbols to $WD/output/symbols/solaris-sparc/pgbouncer directory"
 
}


################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_solaris_sparc() {
 

    cd $WD/pgbouncer

    mkdir -p staging/solaris-sparc/installer/pgbouncer || _die "Failed to create directory for installer scripts"

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/solaris-sparc -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/solaris-sparc -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/solaris-sparc -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/solaris-sparc -name \*.sh -exec chmod 755 {} \;

    cp -R scripts/solaris/startupcfg.sh staging/solaris-sparc/installer/pgbouncer/ || _die "Failed to copy the installer script"
    chmod ugo+x staging/solaris-sparc/installer/pgbouncer/startupcfg.sh

    chmod -R 755 staging/solaris-sparc/instscripts

    rm -rf staging/solaris-sparc/pgbouncer/share/doc || _die "Failed to remove the extra doc directory"

    _replace ";foodb =" "@@CON@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "pidfile = /var/run/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder" 
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to comment the extra db details"
    _replace "auth_type = trust" "auth_type = md5" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to change the auth type"
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/solaris-sparc/pgbouncer/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    # Set 644 for all files and folders
    find staging/solaris-sparc/ -type f | xargs -I{} chmod 644 {}

    # Set Permissions for links and folders
    find staging/solaris-sparc/ -xtype l | xargs -I{} chmod 777 {}
    find staging/solaris-sparc/ -type d | xargs -I{} chmod 755 {}

    # " executable" requires a ' ' prefix to ensure it is not a filename
    find staging/solaris-sparc/ -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find staging/solaris-sparc/ -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml solaris-sparc || _die "Failed to build the installer"

    #Copy staging directory
    copy_binaries pgbouncer solaris-sparc

    cd $WD
}


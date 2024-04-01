#!/bin/bash
    
################################################################################
# PostGIS Build Preparation
################################################################################

_prep_PostGIS_osx() {
    
    echo "BEGIN PREP PostGIS OSX"
  
    echo "********************************"
    echo "*  Pre Process: PostGIS (OSX)  *"
    echo "********************************"

    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source

    if [ -e postgis.osx ];
    then
      echo "Removing existing postgis.osx source directory"
      rm -rf postgis.osx  || _die "Couldn't remove the existing postgis.osx source directory (PostGIS/source/postgis.osx)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.osx)"
    mkdir -p postgis.osx || _die "Couldn't create the postgis.osx directory"
    chmod ugo+w postgis.osx || _die "Couldn't set the permissions on the source directory"
    
    #echo "Copying pgJDBC jar files.."
    #cp postgresql-$PG_VERSION_PGJDBC*.jar postgis.osx || _die "Failed to copy pgJDBC jar files."

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.osx || _die "Failed to copy the source code (PostGIS/source/postgis-$PG_VERSION_POSTGIS)"
    tar -jcvf postgis.tar.bz2 postgis.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
       
    echo "Creating staging directory ($WD/PostGIS/staging/osx)"
    mkdir -p $WD/PostGIS/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/osx || _die "Couldn't set the permissions on the staging directory"

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    ssh $PG_SSH_OSX "cd $PG_PGHOME_OSX; rm -f bin/shp2pgsql bin/pgsql2shp lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so" || _die "Failed to remove PostGIS binaries from server staging"
    ssh $PG_SSH_OSX "cd $PG_PGHOME_OSX/share/postgresql/contrib; rm -f spatial_ref_sys.sql *postgis*sql" || _die "Failed to remove postgis sql from server staging"
    ssh $PG_SSH_OSX "cd $PG_PGHOME_OSX/doc/postgresql/postgis; rm -f postgis.html README.postgis" || _die "Failed to remove postgis doc from server staging"
    ssh $PG_SSH_OSX "cd $PG_PGHOME_OSX; rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1" || _die "Failed to remove man pages from server staging"
    
    # Remove existing source and staging directories
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/source" || _die "Falied to clean the PostGIS/source directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/scripts" || _die "Falied to clean the PostGIS/scripts directory on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/*.bz2" || _die "Falied to clean the PostGIS/*.bz2 files on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/*.sh" || _die "Falied to clean the PostGIS/*.sh scripts on Mac OS X VM"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/staging/osx.build" || _die "Falied to clean the PostGIS/staging/osx.build directory on Mac OS X VM"

    echo "Copy the sources to the build VM"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/PostGIS/source" || _die "Failed to create the source dircetory on the build VM"
    scp $WD/PostGIS/source/postgis.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/PostGIS/source/ || _die "Failed to copy the source archives to build VM"
    
      echo "Copy the scripts required to build VM"
    cd $WD/PostGIS
    tar -jcvf scripts.tar.bz2 scripts/osx
    scp $WD/PostGIS/scripts.tar.bz2 $PG_SSH_OSX:$PG_PATH_OSX/PostGIS || _die "Failed to copy the scripts to build VM"
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh $PG_SSH_OSX:$PG_PATH_OSX/ || _die "Failed to copy the scripts to be sourced to build VM"

    echo "Extracting the archives"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/PostGIS/source; tar -jxvf postgis.tar.bz2"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/PostGIS; tar -jxvf scripts.tar.bz2"

    echo "Creating staging directory on remote server"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/PostGIS/staging/osx" || _die "Couldn't create the last successful staging directory"

    cd $WD

    echo "END PREP PostGIS OSX"

}

################################################################################
# PostGIS compilation and installation in the staging directory 
################################################################################

_build_postgis() {

cat <<EOT-POSTGIS > $WD/PostGIS/build-postgis.sh
    source ../settings.sh
    source ../versions.sh
    source ../common.sh

    cd $PG_PATH_OSX/PostGIS/source/postgis.osx || _die "Failed to change to the proj source directory (PostGIS/source/proj.osx)"
   
    #Getting liblwgeom iface current version from source file to avoid the inconsistency of liblwgeom generated library version.
 
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1 -d "."`
    LIBLWGEOM_IFACE_CUR=`echo '\`cat Version.config | grep ^LIBLWGEOM_IFACE_CUR| sed 's/LIBLWGEOM_IFACE_CUR=//'\`'`

    # Configure the source tree
    echo "Configuring the PostGIS source"
    PATH=$IMAGEMAGICK_HOME_OSX/bin:/opt/local/bin:/opt/local/Current_v15/bin:$PG_PERL_OSX/bin:$PATH LD_LIBRARY_PATH=/opt/local/Current_v15/lib:$LD_LIBRARY_PATH; CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS" CFLAGS="$PG_ARCH_OSX_CFLAGS" LDFLAGS="-L/opt/local/Current_v15/lib" MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION PROJ_CFLAGS="-I/opt/local/Current_v15/include" PROJ_LIBS="-L/opt/local/Current_v15/lib -lproj" ./configure --disable-extension-upgrades-install --enable-debug --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=/opt/local/Current_v15/bin/geos-config --with-projdir=/opt/local/Current_v15 --with-xsldir=$PG_DOCBOOK_OSX --with-gdalconfig=/opt/local/Current_v15/bin/gdal-config --with-xml2config=/opt/local/Current_v15/bin/xml2-config --with-libiconv=/opt/local/Current_v15 --with-jsondir=/opt/local/Current_v15 --without-protobuf --with-pcredir=/opt/local/Current_v15 --with-address_standardizer || _die "Failed to configure PostGIS"

    echo "Building PostGIS"
    echo "workaround: Patching topology Makefile to comment out the problematic lines"
    sed -i '' '/prefix = /,+2 s/^/#/' topology/Makefile
    LDFLAGS="-L/opt/local/Current_v15/lib" CFLAGS="$PG_ARCH_OSX_CFLAGS" MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION make || _die "Failed to build PostGIS"
    # Building the comments is not necessary if you are building from a release tar ball
    #echo "Building comments"
    #make comments || _die "Failed to build comments"
    echo "Installing PostGIS"
    make install PGXSOVERRIDE=0 DESTDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS bindir=/bin pkglibdir=/lib/postgresql datadir=/share REGRESS=1 PGSQL_DOCDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/doc PGSQL_MANDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/man PGSQL_SHAREDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/share/postgresql || _die "Failed to install PostGIS"
    #echo "Installing comments"
    #make comments-install PGXSOVERRIDE=0 DESTDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/doc PGSQL_MANDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/man PGSQL_SHAREDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/share/postgresql || _die "Failed to install PostGIS comments"

    echo "Building postgis-doc"
    #cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc/html/image_src;
    #make clean
    LDFLAGS="-L/opt/local/Current_v15/lib" CFLAGS="$PG_ARCH_OSX_CFLAGS" MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION make|| _die "Failed to build postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc; 
    LDFLAGS="-L/opt/local/Current_v15/lib" CFLAGS="$PG_ARCH_OSX_CFLAGS" MACOSX_DEPLOYMENT_TARGET=$MACOSX_MIN_VERSION make html || _die "Failed to build postgis-doc"
    make install PGXSOVERRIDE=0 DESTDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/doc PGSQL_MANDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/man PGSQL_SHAREDIR=$PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/share/postgresql || _die "Failed to install PostGIS-doc"

    cd $PG_PATH_OSX/PostGIS
    mkdir -p staging/osx.build/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/html/images staging/osx.build/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/html/postgis.html staging/osx.build/PostGIS/doc/postgis/
    #cp -pR source/postgis.osx/java/jdbc/src/main/javadoc/overview.html staging/osx.build/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/postgis-$PG_VERSION_POSTGIS.pdf staging/osx.build/PostGIS/doc/postgis/

    mkdir -p staging/osx.build/PostGIS/man
    cp -pR source/postgis.osx/doc/man staging/osx.build/PostGIS/

    mkdir -p staging/osx.build/PostGIS/utils
    echo "Copying postgis-utils"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/utils
    cp *.pl $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/utils || _die "Failed to copy the utilities "

#    echo "Building postgis-jdbc"
#    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc
#    CLASSPATH=$PG_PATH_OSX/PostGIS/source/postgis.osx/postgresql-$PG_JAR_POSTGRESQL.jar:\$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_OSX $PG_MAVEN_HOME_OSX/bin/mvn -U clean install || _die "Failed to build postgis-jdbc jar."
#
#    mkdir -p $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/java/jdbc
#
#    echo "Copying postgis-jdbc"
#    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java
#    cp jdbc/target/postgis*.jar $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/java/jdbc || _die "Failed to copy postgis jars into postgis-jdbc"
#    cp -R ejb2 ejb3 $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/java/ || _die "Failed to copy ejb2, ejb3 into postgis-java"

EOT-POSTGIS

    cd $WD
}


################################################################################
# PostGIS Build
################################################################################

_build_PostGIS_osx() {

    echo "BEGIN BUILD PostGIS OSX"

    echo "**************************"
    echo "*  Build: PostGIS (OSX)  *"
    echo "**************************"

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx.build
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1 -d "."`

    # Building PostGIS
    _build_postgis
cat <<EOT-POSTGIS >> $WD/PostGIS/build-postgis.sh

    cd $PG_PATH_OSX/PostGIS
    cp -pR staging/osx.build/PostGIS/$PG_PGHOME_OSX/bin/* $PG_STAGING/PostGIS/bin/
    rm -rf staging/osx.build/PostGIS/usr
    rm -rf staging/osx.build/PostGIS/mnt

    echo "Copying Dependent libraries"
    cp -pR /opt/local/Current_v15/lib/libgeos*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy libgeos libraries"
    cp -pR /opt/local/Current_v15/lib/libproj*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy libproj libraries"
    cp -pR /opt/local/Current_v15/lib/libgdal*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy libgdal libraries"
    cp -pR /opt/local/Current_v15/lib/libcurl*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy libcurl libraries"
    cp -pR /opt/local/Current_v15/lib/libpcre2*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy libpcre2 libraries"
    cp -pR /opt/local/Current_v15/lib/libjson-c.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (libjson-c) libraries"
    cp -pR /opt/local/Current_v15/lib/libtiff.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (libtiff) libraries"
    cp -pR /opt/local/Current_v15/lib/libjpeg.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (libjpeg) libraries"
    cp -pR /opt/local/Current_v15/lib/libpng*.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (libpng) libraries"
    cp -pR /opt/local/Current_v15/lib/libexpat*.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (expat) libraries"
    cp -pR /opt/local/Current_v15/lib/libsqlite*.*dylib staging/osx.build/PostGIS/lib || _die "Failed to copy dependent (sqlite) libraries"
    cp -pR /opt/local/Current_v15/share/proj staging/osx.build/PostGIS/share/ || _die "Failed to copy share/proj"
    cp -pR /opt/local/Current_v15/share/gdal staging/osx.build/PostGIS/share/ || _die "Failed to copy share/gdal"

    _rewrite_so_refs $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS bin @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS lib @loader_path/..
    _rewrite_so_refs $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS lib/postgresql @loader_path/../..

    chmod +rx $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/lib/postgresql/*
    chmod +rx $PG_PATH_OSX/PostGIS/staging/osx.build/PostGIS/bin/*
    
EOT-POSTGIS
    cd $WD
    scp PostGIS/build-postgis.sh $PG_SSH_OSX:$PG_PATH_OSX/PostGIS
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/PostGIS; sh ./build-postgis.sh" || _die "Failed to build PostGIS on OSX"

    # Generate debug symbols
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    echo "Removing last successful staging directory ($PG_PATH_OSX/PostGIS/staging/osx)"
    ssh $PG_SSH_OSX "rm -rf $PG_PATH_OSX/PostGIS/staging/osx" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_OSX "mkdir -p $PG_PATH_OSX/PostGIS/staging/osx" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX; cp -PR PostGIS/staging/osx.build/* PostGIS/staging/osx" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_OSX "echo PG_VERSION_POSTGIS=$PG_VERSION_POSTGIS > $PG_PATH_OSX/PostGIS/staging/osx/versions-osx.sh" || _die "Failed to write PostGIS version number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_VERSION_POSTGIS_JAVA=$PG_VERSION_POSTGIS_JAVA >> $PG_PATH_OSX/PostGIS/staging/osx/versions-osx.sh" || _die "Failed to write PostGIS build number into versions-osx.sh"
    ssh $PG_SSH_OSX "echo PG_BUILDNUM_POSTGIS=$PG_BUILDNUM_POSTGIS >> $PG_PATH_OSX/PostGIS/staging/osx/versions-osx.sh" || _die "Failed to write PostGIS build number into versions-osx.sh"


    echo "END BUILD PostGIS OSX"
 
}
    

################################################################################
# PostGIS Post-Process
################################################################################

_postprocess_PostGIS_osx() {

    echo "BEGIN POST PostGIS OSX"

    echo "*********************************"
    echo "*  Post Process: PostGIS (OSX)  *"
    echo "*********************************"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/osx || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/PostGIS/staging/osx)"
    mkdir -p $WD/PostGIS/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/osx || _die "Couldn't set the permissions on the staging directory"

    # Copy the staging to controller to build the installers
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/PostGIS/staging/osx; rm -f postgis-staging.tar.bz2" || _die "Failed to remove archive of the PostGIS staging"
    ssh $PG_SSH_OSX "cd $PG_PATH_OSX/PostGIS/staging/osx; tar -jcvf postgis-staging.tar.bz2 *" || _die "Failed to create archive of the postgis staging"
    scp $PG_SSH_OSX:$PG_PATH_OSX/PostGIS/staging/osx/postgis-staging.tar.bz2 $WD/PostGIS/staging/osx || _die "Failed to scp postgis staging"

   # sign the binaries and libraries
   scp $WD/common.sh $WD/settings.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy commons.sh and settings.sh on signing server"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf postgis-staging.tar.bz2" || _die "Failed to remove PostGIS-staging.tar from signing server"
   scp $WD/PostGIS/staging/osx/postgis-staging.tar.bz2 $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN || _die "Failed to copy postgis-staging.tar.bz2 on signing server"
   rm -rf $WD/PostGIS/staging/osx/postgis-staging.tar.bz2 || _die "Failed to remove PostGIS-staging.tar from controller"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN;rm -rf staging" || _die "Failed to remove staging from signing server"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; mkdir staging; cd staging; tar -zxvf ../postgis-staging.tar.bz2"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh; sign_binaries staging" || _die "Failed to do binaries signing"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; source settings.sh; source common.sh; sign_libraries staging" || _die "Failed to do libraries signing"
   ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN; cd staging;tar -jcvf postgis-staging.tar.bz2 *" || _die "Failed to create postgis-staging tar on signing server"
   scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/staging/postgis-staging.tar.bz2 $WD/PostGIS/staging/osx || _die "Failed to copy postgis-staging to controller vm"

    # Extract the staging archive
    cd $WD/PostGIS/staging/osx
    tar -jxvf postgis-staging.tar.bz2 || _die "Failed to extract the postgis staging archive"
    rm -f postgis-staging.tar.bz2

    # Restructing the staging for debug symbols
    mv $WD/PostGIS/staging/osx/debug_symbols/PostGIS/* $WD/PostGIS/staging/osx/debug_symbols/
    rm -rf $WD/PostGIS/staging/osx/debug_symbols/PostGIS

    source $WD/PostGIS/staging/osx/versions-osx.sh
    PG_BUILD_POSTGIS=$(expr $PG_BUILD_POSTGIS + $SKIPBUILD)

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_POSTGIS -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    PG_STAGING=$WD/PostGIS/staging/osx    

    pushd $WD/PostGIS/staging/osx
    generate_3rd_party_license "postgis"
    popd

    mkdir -p $PG_STAGING/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp $WD/PostGIS/scripts/osx/createshortcuts.sh $PG_STAGING/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createshortcuts.sh

    mkdir -p $PG_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp -pR $WD/PostGIS/scripts/osx/pg-launchPostGISDocs.applescript.in $PG_STAGING/scripts/pg-launchPostGISDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchPostGISDocs.applescript.in)"
    cp -pR $WD/PostGIS/scripts/osx/pg-launchJdbcDocs.applescript.in $PG_STAGING/scripts/pg-launchJdbcDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchJdbcDocs.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p $WD/PostGIS/staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp -pR $WD/PostGIS/resources/pg-launchPostGISDocs.icns $WD/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPostGISDocs.icns)"
    cp -pR $WD/PostGIS/resources/pg-launchPostGISJDBCDocs.icns $WD/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPostGISJDBCDocs.icns)"
    
    cd $WD/PostGIS/

    if [ -f installer_1.xml ]; then
        rm -f installer_1.xml
    fi

    if [ ! -f $WD/scripts/risePrivileges ]; then
        cp installer.xml installer_1.xml
        _replace "<requireInstallationByRootUser>\${admin_rights}</requireInstallationByRootUser>" "<requireInstallationByRootUser>1</requireInstallationByRootUser>" installer_1.xml

        # Build the installer (for the root privileges required)
        echo Building the installer with the root privileges required
        "$PG_INSTALLBUILDER_BIN" build installer_1.xml osx || _die "Failed to build the installer"
        cp $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/PostGIS_PG$PG_CURRENT_VERSION $WD/scripts/risePrivileges || _die "Failed to copy the privileges escalation applet"

        rm -rf $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app
    fi

    # Set permissions to all files and folders in staging
    _set_permissions osx

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Rename the installer
    mv $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app/Contents/MacOS/PostGIS_PG$PG_CURRENT_VERSION
    chmod a+x $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app/Contents/MacOS/PostGIS_PG$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PostGIS_PG$PG_CURRENT_VERSION $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app/Contents/MacOS/installbuilder.sh
    
    cd $WD/output
    
    # Copy the versions file to signing server
    scp ../versions.sh ../resources/entitlements.xml $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app.tar.bz2 postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf postgis*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $PG_PATH_OSX_SIGN/entitlements.xml postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app;" || _die "Failed to sign the code"

    #ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app; mv postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx-signed.app  postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app;" || _die "could not move the signed app"

    #macOS signing certificate check
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; codesign -vvv postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy installers to $WD/output."

   # Notarize the OS X installer
   ssh $PG_SSH_OSX_NOTARY "mkdir -p $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/settings.sh $PG_PATH_OSX_NOTARY; cp $PG_PATH_OSX_SIGN/common.sh $PG_PATH_OSX_NOTARY" || _die "Failed to create $PG_PATH_OSX_NOTARY"
   ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; rm -rf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx*" || _die "Failed to remove the installer from notarization installer directory"
   scp $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy installers to $PG_PATH_OSX_NOTARY"
   scp $WD/resources/notarize_apps.sh $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $PG_PATH_OSX_NOTARY"

   echo ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip postgis" || _die "Failed to notarize the app"
   ssh $PG_SSH_OSX_NOTARY "cd $PG_PATH_OSX_NOTARY; ./notarize_apps.sh postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip postgis" || _die "Failed to notarize the app"
   scp $PG_SSH_OSX_NOTARY:$PG_PATH_OSX_NOTARY/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."
    
    cd $WD

    echo "END POST PostGIS OSX"
}


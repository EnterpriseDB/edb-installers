#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_PostGIS_linux_x64() {
   
    echo "BEGIN PREP PostGIS Linux-x64"

    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source

    if [ -e postgis.linux-x64 ];
    then
      echo "Removing existing postgis.linux-x64 source directory"
      rm -rf postgis.linux-x64  || _die "Couldn't remove the existing postgis.linux-x64 source directory (source/postgis.linux-x64)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.linux-x64)"
    mkdir -p postgis.linux-x64 || _die "Couldn't create the postgis.linux-x64 directory"
    chmod ugo+w postgis.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the postgis source tree, adding -p option to preserve the time stamps of all files.
    cp -pR postgis-$PG_VERSION_POSTGIS/* postgis.linux-x64 || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/linux-x64)"
    mkdir -p $WD/PostGIS/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f bin/shp2pgsql bin/pgsql2shp"  || _die "Failed to remove postgis binary files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so"  || _die "Failed to remove postgis library files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/postgresql/contrib/spatial_ref_sys.sql share/postgresql/contrib/postgis.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/postgresql/contrib/uninstall_postgis.sql  share/postgresql/contrib/postgis_upgrade*.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/postgresql/contrib/postgis_comments.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f doc/postgresql/postgis/postgis.html doc/postgresql/postgis/README.postgis" || _die "Failed to remove documentation"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PGHOME_LINUX_X64; rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1" || _die "Failed to remove man pages"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64; rm -f build-postgis-linux-x64.sh" || _die "Failed to remove build-postgis-linux-x64.sh script"
    
    echo "END PREP PostGIS Linux-x64"
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux_x64() {
    
    echo "BEGIN BUILD PostGIS Linux-x64"

    # build postgis

    PLATFORM=linux-x64
    PLATFORM_SSH=$PG_SSH_LINUX_X64
    POSTGRES_REMOTE_PATH=$PG_PGHOME_LINUX_X64
    BLD_REMOTE_PATH=$PG_PATH_LINUX_X64
    PACKAGE_SOURCE=$WD/PostGIS/source
    PACKAGE_SOURCE_REMOTE=$BLD_REMOTE_PATH/PostGIS/source
    PACKAGE_STAGING=$BLD_REMOTE_PATH/PostGIS/staging/$PLATFORM
    PACKAGE_CACHING=$BLD_REMOTE_PATH/PostGIS/caching/$PLATFORM

    POSTGIS_SOURCE=$WD/PostGIS/source/postgis.$PLATFORM
    POSTGIS_SOURCE_REMOTE=$PACKAGE_SOURCE_REMOTE/postgis.$PLATFORM
    POSTGIS_STAGING=$WD/PostGIS/staging/$PLATFORM
    POSTGIS_STAGING_REMOTE=$BLD_REMOTE_PATH/PostGIS/staging/$PLATFORM

cat <<EOT > "build-postgis-$PLATFORM.sh"
#!/bin/bash

_die() {
    echo ""
    echo "FATAL ERROR: \$1"
    echo ""
    exit 1
}

cd $POSTGIS_SOURCE_REMOTE
export PATH=$PG_PERL_LINUX_X64/bin:/opt/local/Current/bin:$PATH
export LD_LIBRARY_PATH=$POSTGRES_REMOTE_PATH/lib:/opt/local/Current/lib:\$LD_LIBRARY_PATH
export LDFLAGS=-Wl,--rpath,'\\\${ORIGIN}/../lib -lz'

echo "Configuring the postgis source tree"
./configure --with-pgconfig=$POSTGRES_REMOTE_PATH/bin/pg_config --with-geosconfig=/opt/local/Current/bin/geos-config --with-libiconv=/opt/local/Current --with-projdir=/opt/local/Current --with-jsondir=/opt/local/Current CFLAGS='-D_GNU_SOURCE -I/opt/local/Current/include' || _die "Failed to configure postgis"

echo "Building postgis ($PLATFORM)"
make || _die "Failed to build postgis (make on $PLATFORM)"
make comments || _die "Failed to build postgis ('make comments' on $PLATFORM)"
make install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql REGRESS=1 || _die "Failed to install postgis ($PLATFORM)"
make comments-install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql REGRESS=1 || _die "Failed to install comments postgis ($PLATFORM)"

echo "Building postgis-docs"
cd $POSTGIS_SOURCE_REMOTE/doc
make html || _die "Failed to build PostGIS docs"
make install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql || _die "Failed to install postgis ($PLATFORM)"

echo "Copying the utils"
mkdir -p $POSTGIS_STAGING_REMOTE/PostGIS/utils
cp $POSTGIS_SOURCE_REMOTE/utils/*.pl $POSTGIS_STAGING_REMOTE/PostGIS/utils/  || _die "Failed to copy the utilities"

echo "Building postgis-jdbc"
cd $POSTGIS_SOURCE_REMOTE/java/jdbc
CLASSPATH=$PACKAGE_SOURCE_REMOTE/postgresql-$PG_JAR_POSTGRESQL.jar:\$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_MAVEN_HOME_LINUX_X64/bin/mvn clean install || _die "Failed to build postgis-jdbc jar."

mkdir -p $POSTGIS_STAGING_REMOTE/PostGIS/java/jdbc

echo "Copying postgis-jdbc"
cd $POSTGIS_SOURCE_REMOTE/java
cp jdbc/target/postgis*.jar $POSTGIS_STAGING_REMOTE/PostGIS/java/jdbc/ || _die "Failed to copy postgis jars into postgis-jdbc"
cp -R ejb2 ejb3 $POSTGIS_STAGING_REMOTE/PostGIS/java/ || _die "Failed to copy ejb2, ejb3 into postgis-java"

echo "Copy dependent libraries"
cd $POSTGIS_STAGING_REMOTE/PostGIS/lib
cp -pR /opt/local/Current/lib/libproj.so* . || _die "Failed to copy the proj libraries"
cp -pR /opt/local/Current/lib/libgeos*.so* . || _die "Failed to copy the geos libraries"
cp -pR /opt/local/Current/lib/libgdal.so* . || _die "Failed to copy the gdal libraries"
cp -pR /opt/local/Current/lib/libcurl.so* . || _die "Failed to copy the curl libraries"
cp -pR /opt/local/Current/lib/libpcre.so* . || _die "Failed to copy the pcre libraries"
cp -pR /opt/local/Current/lib/libtiff.so* . || _die "Failed to copy the libtiff libraries"
cp -pR /opt/local/Current/lib/libjpeg.so* . || _die "Failed to copy the libjpeg libraries"
cp -pR /opt/local/Current/lib/libexpat.so* . || _die "Failed to copy the libexpat libraries"
cp -pR /opt/local/Current/lib/libpng12.so* . || _die "Failed to copy the png libraries"
cp -pR /opt/local/Current/lib/libjson-c.so* . || _die "Failed to copy the libjson-c libraries"

cp -pR $POSTGIS_STAGING_REMOTE/PostGIS/$PG_PGHOME_LINUX_X64/bin/* $POSTGIS_STAGING_REMOTE/PostGIS/bin/

cd $POSTGIS_STAGING_REMOTE/PostGIS
cp -pR usr/local/include . || _die "Failed to copy liblwgeom include files"
cp -pR usr/local/lib/* lib/ || _die "Failed to copy liblwgeom lib files"
rm -rf usr
rm -rf mnt

echo "Changing the rpath for the PostGIS executables and libraries"
cd $POSTGIS_STAGING_REMOTE/PostGIS/bin
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \\\${ORIGIN}/../lib:\\\${ORIGIN}/../lib/postgresql \$f; done

cd $POSTGIS_STAGING_REMOTE/PostGIS/lib
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \\\${ORIGIN}/../../lib:\\\${ORIGIN} \$f; done
chmod a+rx *

EOT


    scp build-postgis-$PLATFORM.sh $PLATFORM_SSH:$BLD_REMOTE_PATH || _die "Failed to copy build script on $PLATFORM VM"
    ssh $PLATFORM_SSH "cd $BLD_REMOTE_PATH; bash ./build-postgis-$PLATFORM.sh $BUILD_PROJ $BUILD_GEOS" || _die "Failed to execution of build script on $PLATFORM"

    mkdir -p $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/html/images $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/html/postgis.html $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/postgis-$PG_VERSION_POSTGIS.pdf $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/man $WD/PostGIS/staging/linux-x64/PostGIS/


    cd $WD/PostGIS

    echo "END BUILD PostGIS Linux-x64"

}


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux_x64() {

    echo "BEGIN POST PostGIS Linux-x64"

    cd $WD/PostGIS
    mkdir -p staging/linux-x64/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    pushd staging/linux-x64
    generate_3rd_party_license "postgis"
    popd

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/removeshortcuts.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh
    cp -R scripts/linux/launchPostGISDocs.sh staging/linux-x64/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    chmod ugo+x staging/linux-x64/scripts/launchPostGISDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "." | sed 's/\./_/g'`
    
    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-postgresql.png staging/linux-x64/scripts/images/pg-postgresql-$PG_VERSION_STR.png || _die "Failed to copy a menu pick png"
    cp resources/pg-postgis.png staging/linux-x64/scripts/images/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.png || _die "Failed to copy a menu pick png"
    cp resources/pg-launchPostGISDocs.png staging/linux-x64/scripts/images/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.png || _die "Failed to copy a menu pick image"

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux-x64/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux-x64/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR-$PG_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    
    # Set permissions to all files and folders in staging
    _set_permissions linux-x64

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD

    echo "END POST PostGIS Linux-x64"
}


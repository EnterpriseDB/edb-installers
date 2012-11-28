#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_PostGIS_linux_x64() {

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

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.linux-x64 || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"
    chmod -R ugo+w postgis.linux-x64 || _die "Couldn't set the permissions on the source directory"

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

}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux_x64() {

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
export PATH=$PG_PERL_LINUX_X64/bin:/usr/local/bin:$PATH
export LD_LIBRARY_PATH=$POSTGRES_REMOTE_PATH/lib:/usr/local/lib:\$LD_LIBRARY_PATH
export LDFLAGS=-Wl,--rpath,'\\\${ORIGIN}/../lib'

echo "Configuring the postgis source tree"
./configure --with-pgconfig=$POSTGRES_REMOTE_PATH/bin/pg_config --with-geosconfig=/usr/local/bin/geos-config --with-projdir=/usr/local || _die "Failed to configure postgis"

echo "Building postgis ($PLATFORM)"
make || _die "Failed to build postgis (make on $PLATFORM)"
make comments || _die "Failed to build postgis ('make comments' on $PLATFORM)"
make install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql REGRESS=1 || _die "Failed to install postgis ($PLATFORM)"
make comments-install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql REGRESS=1 || _die "Failed to install comments postgis ($PLATFORM)"

echo "Copying the utils"
mkdir -p $POSTGIS_STAGING_REMOTE/PostGIS/utils
cp $POSTGIS_SOURCE_REMOTE/utils/*.pl $POSTGIS_STAGING_REMOTE/PostGIS/utils/  || _die "Failed to copy the utilities"

echo "Building postgis-jdbc"
cd $POSTGIS_SOURCE_REMOTE/java/jdbc
CLASSPATH=$PACKAGE_SOURCE_REMOTE/postgresql-$PG_VERSION_PGJDBC.jdbc3.jar:\$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX_X64/bin/ant

mkdir -p $POSTGIS_STAGING_REMOTE/PostGIS/java/jdbc

echo "Copying postgis-jdbc"
cd $POSTGIS_SOURCE_REMOTE/java
cp jdbc/target/postgis*.jar $POSTGIS_STAGING_REMOTE/PostGIS/java/jdbc/ || _die "Failed to copy postgis jars into postgis-jdbc"
cp -R ejb2 ejb3 $POSTGIS_STAGING_REMOTE/PostGIS/java/ || _die "Failed to copy ejb2, ejb3 into postgis-java"

echo "Copy dependent libraries"
cd $POSTGIS_STAGING_REMOTE/PostGIS/lib
cp -pR /usr/local/lib/libproj.so* . || _die "Failed to copy the proj libraries"
cp -pR /usr/local/lib/libgeos*.so* . || _die "Failed to copy the geos libraries"
cp -pR /usr/local/lib/libgdal.so* . || _die "Failed to copy the gdal libraries"
cp -pR /usr/local/lib/libcurl.so* . || _die "Failed to copy the curl libraries"
cp -pR /usr/local/lib/libtiff.so* . || _die "Failed to copy the libtiff libraries"
cp -pR /usr/local/lib/libjpeg.so* . || _die "Failed to copy the libjpeg libraries"
cp -pR /usr/local/lib/libexpat.so* . || _die "Failed to copy the libexpat libraries"
cp -pR /usr/local/lib/libodbc.so* . || _die "Failed to copy the libodbc libraries"
cp -pR /usr/local/lib/libodbcinst.so* . || _die "Failed to copy the libodbcinst libraries"

cp -pR $POSTGIS_STAGING_REMOTE/PostGIS/$PG_PGHOME_LINUX_X64/bin/* $POSTGIS_STAGING_REMOTE/PostGIS/bin/

echo "Changing the rpath for the PostGIS executables and libraries"
cd $POSTGIS_STAGING_REMOTE/PostGIS/bin
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \\\${ORIGIN}/../lib \$f; done

cd $POSTGIS_STAGING_REMOTE/PostGIS/lib
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \\\${ORIGIN}/../lib \$f; done
chmod a+rx *

echo "Creating wrapper script for pgsql2shp and shp2pgsql"
cd $POSTGIS_STAGING_REMOTE/PostGIS/bin
for f in pgsql2shp shp2pgsql raster2pgsql; do mv \$f \$f.bin; done

cat <<EOS > pgsql2shp
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/pgsql2shp.bin $*

cd \\\$CURRENTWD
EOS

cat <<EOS > shp2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/shp2pgsql.bin $*

cd \\\$CURRENTWD
EOS

cat <<EOS > raster2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/raster2pgsql.bin $*

cd \\\$CURRENTWD
EOS

chmod a+rx *
EOT


    scp build-postgis-$PLATFORM.sh $PLATFORM_SSH:$BLD_REMOTE_PATH || _die "Failed to copy build script on $PLATFORM VM"
    ssh $PLATFORM_SSH "cd $BLD_REMOTE_PATH; bash ./build-postgis-$PLATFORM.sh $BUILD_PROJ $BUILD_GEOS" || _die "Failed to execution of build script on $PLATFORM"

    cd $POSTGIS_STAGING/PostGIS

    mkdir -p $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/html/images $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/html/postgis.html $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/postgis-$PG_VERSION_POSTGIS.pdf $WD/PostGIS/staging/linux-x64/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux-x64/doc/man $WD/PostGIS/staging/linux-x64/PostGIS/

    cp -pR $WD/PostGIS/staging/linux-x64/PostGIS/usr/local/include . || _die "Failed to copy liblwgeom include files"
    cp -pR $WD/PostGIS/staging/linux-x64/PostGIS/usr/local/lib/* lib/ || _die "Failed to copy liblwgeom lib files"
    rm -rf $WD/PostGIS/staging/linux-x64/PostGIS/usr
    rm -rf $WD/PostGIS/staging/linux-x64/PostGIS/mnt

    cd $WD/PostGIS

}


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux_x64() {

    cd $WD/PostGIS
    mkdir -p staging/linux-x64/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux-x64/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-x64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/removeshortcuts.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh
    cp -R scripts/linux/launchPostGISDocs.sh staging/linux-x64/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    chmod ugo+x staging/linux-x64/scripts/launchPostGISDocs.sh
    cp -R scripts/linux/launchJDBCDocs.sh staging/linux-x64/scripts/launchJDBCDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-x64)"
    chmod ugo+x staging/linux-x64/scripts/launchJDBCDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-x64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-x64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-x64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "." | sed 's/\./_/g'`

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux-x64/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux-x64/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/pg-launchPostGISJDBCDocs.desktop staging/linux-x64/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}


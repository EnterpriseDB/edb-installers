#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_PostGIS_linux() {
       
    echo "BEGIN PREP PostGIS Linux"    

    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source

    if [ -e postgis.linux ];
    then
      echo "Removing existing postgis.linux source directory"
      rm -rf postgis.linux  || _die "Couldn't remove the existing postgis.linux source directory (source/postgis.linux)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.linux)"
    mkdir -p postgis.linux || _die "Couldn't create the postgis.linux directory"
    chmod ugo+w postgis.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.linux || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/linux)"
    mkdir -p $WD/PostGIS/staging/linux || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/linux || _die "Couldn't set the permissions on the staging directory"

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f bin/shp2pgsql bin/pgsql2shp"  || _die "Failed to remove postgis binary files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so"  || _die "Failed to remove postgis library files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f share/postgresql/contrib/spatial_ref_sys.sql share/postgresql/contrib/postgis.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f share/postgresql/contrib/uninstall_postgis.sql  share/postgresql/contrib/postgis_upgrade*.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f share/postgresql/contrib/postgis_comments.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f doc/postgresql/postgis/postgis.html doc/postgresql/postgis/README.postgis" || _die "Failed to remove documentation"
    ssh $PG_SSH_LINUX "cd $PG_PGHOME_LINUX; rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1" || _die "Failed to remove man pages"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX; rm -f build-postgis-linux.sh" || _die "Failed to remove build-postgis-linux.sh script"
    
    echo "END PREP PostGIS Linux"

}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux() {
    
    echo "BEGIN BUILD PostGIS Linux"    
 
    # build postgis

    PLATFORM=linux
    PLATFORM_SSH=$PG_SSH_LINUX
    POSTGRES_REMOTE_PATH=$PG_PGHOME_LINUX
    BLD_REMOTE_PATH=$PG_PATH_LINUX
    PACKAGE_SOURCE=$WD/PostGIS/source
    PACKAGE_SOURCE_REMOTE=$BLD_REMOTE_PATH/PostGIS/source
    PACKAGE_STAGING=$BLD_REMOTE_PATH/PostGIS/staging/$PLATFORM
    PACKAGE_CACHING=$BLD_REMOTE_PATH/PostGIS/caching/$PLATFORM

    POSTGIS_SOURCE=$WD/PostGIS/source/postgis.$PLATFORM
    POSTGIS_SOURCE_REMOTE=$PACKAGE_SOURCE_REMOTE/postgis.$PLATFORM
    POSTGIS_STAGING=$WD/PostGIS/staging/$PLATFORM
    POSTGIS_STAGING_REMOTE=$BLD_REMOTE_PATH/PostGIS/staging/$PLATFORM

    cd $PACKAGE_SOURCE

cat <<EOT > "build-postgis-$PLATFORM.sh"
#!/bin/bash

_die() {
    echo ""
    echo "FATAL ERROR: \$1"
    echo ""
    exit 1
}

cd $POSTGIS_SOURCE_REMOTE
export PATH=$PG_PERL_LINUX/bin:/opt/local/Current/bin:$PATH
export LD_LIBRARY_PATH=$POSTGRES_REMOTE_PATH/lib:/opt/local/Current/lib:\$LD_LIBRARY_PATH
export LDFLAGS=-Wl,--rpath,'\\\${ORIGIN}/../lib -lz'

echo "Configuring the postgis source tree"
./configure --with-pgconfig=$POSTGRES_REMOTE_PATH/bin/pg_config --with-geosconfig=/opt/local/Current/bin/geos-config --with-projdir=/opt/local/Current --with-libiconv=/opt/local/Current --with-jsondir=/opt/local/Current CFLAGS='-D_GNU_SOURCE -I/opt/local/Current/include' || _die "Failed to configure postgis"

echo "Building postgis ($PLATFORM)"
make || _die "Failed to build postgis (make on $PLATFORM)"
make comments || _die "Failed to build postgis ('make comments' on $PLATFORM)"
make install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql || _die "Failed to install postgis ($PLATFORM)"
make comments-install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib REGRESS=1 datadir=/share PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql || _die "Failed to install comments postgis ($PLATFORM)"

echo "Building postgis-docs"
cd $POSTGIS_SOURCE_REMOTE/doc
make html || _die "Failed to build PostGIS docs"
make install PGXSOVERRIDE=0 DESTDIR=$POSTGIS_STAGING_REMOTE/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$POSTGIS_STAGING_REMOTE/PostGIS/doc PGSQL_MANDIR=$POSTGIS_STAGING_REMOTE/PostGIS/man PGSQL_SHAREDIR=$POSTGIS_STAGING_REMOTE/PostGIS/share/postgresql || _die "Failed to install postgis ($PLATFORM)"

echo "Copying the utils"
mkdir -p $POSTGIS_STAGING_REMOTE/PostGIS/utils
cp $POSTGIS_SOURCE_REMOTE/utils/*.pl $POSTGIS_STAGING_REMOTE/PostGIS/utils/  || _die "Failed to copy the utilities"

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
cp -pR /opt/local/Current/lib/libodbc.so* . || _die "Failed to copy the libodbc libraries"
cp -pR /opt/local/Current/lib/libodbcinst.so* . || _die "Failed to copy the libodbcinst libraries"
cp -pR /opt/local/Current/lib/libpng12.so* . || _die "Failed to copy the png libraries"
cp -pR /opt/local/Current/lib/libjson-c.so* . || _die "Failed to copy the libjson-c libraries"

cp -pR $POSTGIS_STAGING_REMOTE/PostGIS/$PG_PGHOME_LINUX/bin/* $POSTGIS_STAGING_REMOTE/PostGIS/bin/

echo "Changing the rpath for the PostGIS executables and libraries"
cd $POSTGIS_STAGING_REMOTE/PostGIS/bin
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done

cd $POSTGIS_STAGING_REMOTE/PostGIS/lib
for f in \`file * | grep ELF | cut -d : -f 1 \`; do chrpath --replace \\\${ORIGIN}/../../lib:\\\${ORIGIN} \$f; done
chmod a+rx *

echo "Creating wrapper script for pgsql2shp and shp2pgsql"
cd $POSTGIS_STAGING_REMOTE/PostGIS/bin
for f in pgsql2shp shp2pgsql raster2pgsql; do mv \$f \$f.bin; done

cat <<EOS > pgsql2shp
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\$(cd \\\`dirname \\\$0\\\` && pwd)
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$PWD/postgresql:\\\$LD_LIBRARY_PATH \\\$WD/pgsql2shp.bin \\\$*

cd \\\$CURRENTWD
EOS

cat <<EOS > shp2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\$(cd \\\`dirname \\\$0\\\` && pwd)
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$PWD/postgresql:\\\$LD_LIBRARY_PATH \\\$WD/shp2pgsql.bin \\\$*

cd \\\$CURRENTWD
EOS

cat <<EOS > raster2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\$(cd \\\`dirname \\\$0\\\` && pwd)
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$PWD/postgresql:\\\$LD_LIBRARY_PATH \\\$WD/raster2pgsql.bin \\\$*

cd \\\$CURRENTWD
EOS

chmod a+rx *

EOT

    scp build-postgis-$PLATFORM.sh $PLATFORM_SSH:$BLD_REMOTE_PATH || _die "Failed to copy build script on $PLATFORM VM"
    ssh $PLATFORM_SSH "cd $BLD_REMOTE_PATH; bash ./build-postgis-$PLATFORM.sh" || _die "Failed to execution of build script on $PLATFORM"

    cd $POSTGIS_STAGING/PostGIS

    mkdir -p $WD/PostGIS/staging/linux/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux/doc/html/images $WD/PostGIS/staging/linux/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux/doc/html/postgis.html $WD/PostGIS/staging/linux/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux/doc/postgis-$PG_VERSION_POSTGIS.pdf $WD/PostGIS/staging/linux/PostGIS/doc/postgis/
    cp -pR $WD/PostGIS/source/postgis.linux/doc/man $WD/PostGIS/staging/linux/PostGIS/ 


    cp -pR $WD/PostGIS/staging/linux/PostGIS/usr/local/include . || _die "Failed to copy liblwgeom include files"
    cp -pR $WD/PostGIS/staging/linux/PostGIS/usr/local/lib/* lib/ || _die "Failed to copy liblwgeom lib files"
    rm -rf $WD/PostGIS/staging/linux/PostGIS/usr
    rm -rf $WD/PostGIS/staging/linux/PostGIS/mnt

    cd $WD/PostGIS
    
    echo "END BUILD PostGIS Linux"
}


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux() {

    echo "BEGIN POST PostGIS Linux"

    cd $WD/PostGIS
    mkdir -p staging/linux/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    pushd staging/linux
    generate_3rd_party_license "postgis"
    popd

    cp scripts/linux/createshortcuts.sh staging/linux/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/removeshortcuts.sh

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchbrowser.sh
    cp -R scripts/linux/launchPostGISDocs.sh staging/linux/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchPostGISDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "." | sed 's/\./_/g'`

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

    echo "END POST PostGIS Linux"
}


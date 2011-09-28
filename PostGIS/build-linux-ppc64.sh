#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS_linux_ppc64() {
      
    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source

    if [ -e postgis.linux-ppc64 ];
    then
      echo "Removing existing postgis.linux-ppc64 source directory"
      rm -rf postgis.linux-ppc64  || _die "Couldn't remove the existing postgis.linux-ppc64 source directory (source/postgis.linux-ppc64)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.linux-ppc64)"
    mkdir -p postgis.linux-ppc64 || _die "Couldn't create the postgis.linux-ppc64 directory"
    chmod ugo+w postgis.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.linux-ppc64 || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"
    chmod -R ugo+w postgis.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    if [ -e geos.linux-ppc64 ];
    then
      echo "Removing existing geos.linux-ppc64 source directory"
      rm -rf geos.linux-ppc64  || _die "Couldn't remove the existing geos.linux-ppc64 source directory (source/geos.linux-ppc64)"
    fi

    echo "Creating geos source directory ($WD/PostGIS/source/geos.linux-ppc64)"
    mkdir -p geos.linux-ppc64 || _die "Couldn't create the geos.linux-ppc64 directory"
    chmod ugo+w geos.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.linux-ppc64 || _die "Failed to copy the source code (source/geos.linux-ppc64)"
    chmod -R ugo+w geos.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    if [ -e proj.linux-ppc64 ];
    then
       echo "Removing existing proj.linux-ppc64 source directory"
       rm -rf proj.linux-ppc64  || _die "Couldn't remove the existing proj.linux-ppc64 source directory (source/proj.linux-ppc64)"
    fi

    echo "Creating proj source directory ($WD/PostGIS/source/proj.linux-ppc64)"
    mkdir -p proj.linux-ppc64 || _die "Couldn't create the proj.linux-ppc64 directory"
    chmod ugo+w proj.linux-ppc64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.linux-ppc64 || _die "Failed to copy the source code (source/proj.linux-ppc64)"
    chmod -R ugo+w proj.linux-ppc64 || _die "Couldn't set the permissions on the source directory"


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/linux-ppc64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/linux-ppc64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/linux-ppc64)"
    mkdir -p $WD/PostGIS/staging/linux-ppc64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/linux-ppc64 || _die "Couldn't set the permissions on the staging directory"

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f bin/shp2pgsql bin/pgsql2shp"  || _die "Failed to remove postgis binary files"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so"  || _die "Failed to remove postgis library files"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f share/postgresql/contrib/spatial_ref_sys.sql share/postgresql/contrib/postgis.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f share/postgresql/contrib/uninstall_postgis.sql  share/postgresql/contrib/postgis_upgrade*.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f share/postgresql/contrib/postgis_comments.sql"  || _die "Failed to remove postgis share files"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f doc/postgresql/postgis/postgis.html doc/postgresql/postgis/README.postgis" || _die "Failed to remove documentation"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PGHOME_LINUX_PPC64; rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1" || _die "Failed to remove man pages"

         
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux_ppc64() {

    # build postgis    
    PG_STAGING=$PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64    
    PG_CACHING=$PG_PATH_LINUX_PPC64/PostGIS/caching/linux-ppc64    

    if [ ! -e $WD/PostGIS/caching/linux-ppc64/proj-$PG_TARBALL_PROJ.linux-ppc64 ];
    then 
      # Configure the source tree
      echo "Configuring the proj source tree"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/proj.linux-ppc64/; sh ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-ppc64"  || _die "Failed to configure postgis"
  
      echo "Building proj"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/proj.linux-ppc64; make" || _die "Failed to build proj"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/proj.linux-ppc64; make install" || _die "Failed to install proj"
    fi
   
    if [ ! -e $WD/PostGIS/caching/linux-ppc64/geos-$PG_TARBALL_GEOS.linux-ppc64 ];
    then
      echo "Configuring the geos source tree"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/geos.linux-ppc64/; sh ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-ppc64" || _die "Failed to configure geos"

      echo "Building geos"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/geos.linux-ppc64; make" || _die "Failed to build geos"
      ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/geos.linux-ppc64; make install" || _die "Failed to install geos"
    fi

    echo "Configuring the postgis source tree"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/; eX/Port PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-ppc64/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-ppc64/bin:\$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-ppc64/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-ppc64/lib:\$LD_LIBRARY_PATH; ./configure --prefix=$PG_CACHING/PostGIS --with-pgconfig=$PG_PGHOME_LINUX_PPC64/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-ppc64/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-ppc64"  || _die "Failed to configure postgis"

    echo "Building postgis"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64; make; make comments" || _die "Failed to build postgis"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64; make install; make comments-install" || _die "Failed to install postgis"
    
    echo "Building postgis-jdbc"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/java/jdbc ;CLASSPATH=$PG_PATH_LINUX_PPC64/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_LINUX_PPC64 $PG_ANT_HOME_LINUX_PPC64/bin/ant" || _die "Failed to build postgis-jdbc"
   
    cd $WD/PostGIS

    mkdir -p staging/linux-ppc64/PostGIS
    cd staging/linux-ppc64/PostGIS

    echo "Copying Postgis files from PG directory"
    mkdir bin
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/bin/shp2pgsql bin/" || _die "Failed to copy PostGIS binaries" 
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/bin/pgsql2shp bin/" || _die "Failed to copy PostGIS binaries" 

    mkdir lib
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so lib/" || _die "Failed to copy PostGIS library" 
 
    mkdir -p share/contrib
  
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/uninstall_postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/postgis_upgrade*.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/spatial_ref_sys.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/staging/linux-ppc64/PostGIS; cp $PG_PGHOME_LINUX_PPC64/share/postgresql/contrib/postgis_comments.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
 
    #Copy the docs and man pages from osx build.
    cp -R $WD/PostGIS/staging/osx/PostGIS/doc . || _die "Failed to copy the doc folder from staging directory"
    cp -R $WD/PostGIS/staging/osx/PostGIS/man . || _die "Failed to copy the man folder from staging directory"
 
    cd $WD/PostGIS

    mkdir -p staging/linux-ppc64/PostGIS/utils
    echo "Copying postgis-utils"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/utils; cp *.pl $PG_STAGING/PostGIS/utils" || _die "Failed to copy the utilities "
    
    cd $WD/PostGIS

    mkdir -p staging/linux-ppc64/PostGIS/java/jdbc
 
    echo "Copying postgis-jdbc"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/java; cp jdbc/postgis*.jar $PG_STAGING/PostGIS/java/jdbc/" || _die "Failed to copy postgis jars into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/java; cp -R ejb2 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb2 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/java; cp -R ejb3 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb3 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_PATH_LINUX_PPC64/PostGIS/source/postgis.linux-ppc64/java; cp -R pljava $PG_STAGING/PostGIS/java/" || _die "Failed to copy pljava into postgis-jdbc directory "

    # Copy dependent libraries
    ssh $PG_SSH_LINUX_PPC64 "cp $PG_CACHING/proj-$PG_TARBALL_PROJ.linux-ppc64/lib/libproj* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the proj libraries"
    ssh $PG_SSH_LINUX_PPC64 "cp $PG_CACHING/geos-$PG_TARBALL_GEOS.linux-ppc64/lib/libgeos* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the geos libraries"

    echo "Changing the rpath for the PostGIS executables and libraries"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"

    echo "Creating wrapper script for pgsql2shp and shp2pgsql"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/bin; for f in pgsql2shp shp2pgsql ; do mv \$f \$f.bin; done"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/bin; cat <<EOT > pgsql2shp
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/pgsql2shp.bin $*

cd \\\$CURRENTWD
EOT
"

    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/bin; cat <<EOT > shp2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/shp2pgsql.bin $*

cd \\\$CURRENTWD
EOT
"
    ssh $PG_SSH_LINUX_PPC64 "cd $PG_STAGING/PostGIS/bin; chmod +x *"

    cd $WD/PostGIS
} 


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux_ppc64() {

    cd $WD/PostGIS
    mkdir -p staging/linux-ppc64/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-ppc64/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux-ppc64/createshortcuts.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/createtemplatedb.sh staging/linux-ppc64/installer/PostGIS/createtemplatedb.sh || _die "Failed to copy the createtemplatedb script (scripts/linux-ppc64/createtemplatedb.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/createtemplatedb.sh

    cp scripts/linux/createpostgisdb.sh staging/linux-ppc64/installer/PostGIS/createpostgisdb.sh || _die "Failed to copy the createpostgisdb script (scripts/linux-ppc64/createpostgisdb.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/createpostgisdb.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-ppc64/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux-ppc64/removeshortcuts.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/removeshortcuts.sh    

    cp scripts/linux/check-connection.sh staging/linux-ppc64/installer/PostGIS/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux-ppc64/check-connection.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/check-connection.sh

    cp scripts/linux/check-pgversion.sh staging/linux-ppc64/installer/PostGIS/check-pgversion.sh || _die "Failed to copy the check-pgversion script (scripts/linux-ppc64/check-pgversion.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/check-pgversion.sh
 
    cp scripts/linux/check-db.sh staging/linux-ppc64/installer/PostGIS/check-db.sh || _die "Failed to copy the check-db script (scripts/linux-ppc64/check-db.sh)"
    chmod ugo+x staging/linux-ppc64/installer/PostGIS/check-db.sh

    mkdir -p staging/linux-ppc64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux-ppc64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux-ppc64)"
	chmod ugo+x staging/linux-ppc64/scripts/launchbrowser.sh
    cp -R scripts/linux/launchPostGISDocs.sh staging/linux-ppc64/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-ppc64)"
	chmod ugo+x staging/linux-ppc64/scripts/launchPostGISDocs.sh
    cp -R scripts/linux/launchJDBCDocs.sh staging/linux-ppc64/scripts/launchJDBCDocs.sh || _die "Failed to copy the launch scripts (scripts/linux-ppc64)"
    chmod ugo+x staging/linux-ppc64/scripts/launchJDBCDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux-ppc64/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux-ppc64/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux-ppc64/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux-ppc64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux-ppc64/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "." | sed 's/\./_/g'`

    mkdir -p staging/linux-ppc64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-ppc64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux-ppc64/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux-ppc64/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/pg-launchPostGISJDBCDocs.desktop staging/linux-ppc64/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-ppc || _die "Failed to build the installer"

    mv $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-ppc.bin $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-linux-ppc64.bin     
    cd $WD
}


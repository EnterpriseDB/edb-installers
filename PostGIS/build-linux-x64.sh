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

    if [ -e geos.linux-x64 ];
    then
      echo "Removing existing geos.linux-x64 source directory"
      rm -rf geos.linux-x64  || _die "Couldn't remove the existing geos.linux-x64 source directory (source/geos.linux-x64)"
    fi

    echo "Creating geos source directory ($WD/PostGIS/source/geos.linux-x64)"
    mkdir -p geos.linux-x64 || _die "Couldn't create the geos.linux-x64 directory"
    chmod ugo+w geos.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.linux-x64 || _die "Failed to copy the source code (source/geos.linux-x64)"
    chmod -R ugo+w geos.linux-x64 || _die "Couldn't set the permissions on the source directory"

    if [ -e proj.linux-x64 ];
    then
       echo "Removing existing proj.linux-x64 source directory"
       rm -rf proj.linux-x64  || _die "Couldn't remove the existing proj.linux-x64 source directory (source/proj.linux-x64)"
    fi

    echo "Creating proj source directory ($WD/PostGIS/source/proj.linux-x64)"
    mkdir -p proj.linux-x64 || _die "Couldn't create the proj.linux-x64 directory"
    chmod ugo+w proj.linux-x64 || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.linux-x64 || _die "Failed to copy the source code (source/proj.linux-x64)"
    chmod -R ugo+w proj.linux-x64 || _die "Couldn't set the permissions on the source directory"


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

         
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux_x64() {

    # build postgis    
    PG_STAGING=$PG_PATH_LINUX_X64/PostGIS/staging/linux-x64    
    PG_CACHING=$PG_PATH_LINUX_X64/PostGIS/caching/linux-x64    

    if [ ! -e $WD/PostGIS/caching/linux-x64/proj-$PG_TARBALL_PROJ.linux-x64 ];
    then 
      # Configure the source tree
      echo "Configuring the proj source tree"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64/; sh ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-x64"  || _die "Failed to configure postgis"
  
      echo "Building proj"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64; make" || _die "Failed to build proj"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64; make install" || _die "Failed to install proj"
    fi
   
    if [ ! -e $WD/PostGIS/caching/linux-x64/geos-$PG_TARBALL_GEOS.linux-x64 ];
    then
      echo "Configuring the geos source tree"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64/; sh ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-x64" || _die "Failed to configure geos"

      echo "Building geos"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64; make" || _die "Failed to build geos"
      ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64; make install" || _die "Failed to install geos"
    fi

    echo "Configuring the postgis source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/; eX/Port PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-x64/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-x64/bin:\$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-x64/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-x64/lib:\$LD_LIBRARY_PATH; ./configure --prefix=$PG_CACHING/PostGIS --with-pgconfig=$PG_PGHOME_LINUX_X64/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux-x64/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux-x64"  || _die "Failed to configure postgis"

    echo "Building postgis"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64; make; make comments" || _die "Failed to build postgis"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64; make PGXSOVERRIDE=0 install; make comments-install" || _die "Failed to install postgis"
    
    echo "Building postgis-jdbc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java/jdbc ;CLASSPATH=$PG_PATH_LINUX_X64/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant" || _die "Failed to build postgis-jdbc"
   
    cd $WD/PostGIS

    mkdir -p staging/linux-x64/PostGIS
    cd staging/linux-x64/PostGIS

    echo "Copying Postgis files from PG directory"
    mkdir bin
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/bin/shp2pgsql bin/" || _die "Failed to copy PostGIS binaries" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/bin/pgsql2shp bin/" || _die "Failed to copy PostGIS binaries" 

    mkdir lib
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so lib/" || _die "Failed to copy PostGIS library" 
 
    mkdir -p share/contrib
 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/postgis-$POSTGIS_MAJOR_VERSION/* $PG_PGHOME_LINUX_X64/share/postgresql/contrib/" || _die "Failed to copy PostGIS share files to contrib folder" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/uninstall_postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/postgis_upgrade*.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/spatial_ref_sys.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/staging/linux-x64/PostGIS; cp $PG_PGHOME_LINUX_X64/share/postgresql/contrib/postgis_comments.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
  
    #Copy the docs and man pages from osx build.
    cp -R $WD/PostGIS/staging/osx/PostGIS/doc . || _die "Failed to copy the doc folder from staging directory"
    cp -R $WD/PostGIS/staging/osx/PostGIS/man . || _die "Failed to copy the man folder from staging directory"

    cd $WD/PostGIS

    mkdir -p staging/linux-x64/PostGIS/utils
    echo "Copying postgis-utils"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/utils; cp *.pl $PG_STAGING/PostGIS/utils" || _die "Failed to copy the utilities "
    
    cd $WD/PostGIS

    mkdir -p staging/linux-x64/PostGIS/java/jdbc
 
    echo "Copying postgis-jdbc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java; cp jdbc/postgis*.jar $PG_STAGING/PostGIS/java/jdbc/" || _die "Failed to copy postgis jars into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java; cp -R ejb2 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb2 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java; cp -R ejb3 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb3 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java; cp -R pljava $PG_STAGING/PostGIS/java/" || _die "Failed to copy pljava into postgis-jdbc directory "

    # Copy dependent libraries
    ssh $PG_SSH_LINUX_X64 "cp $PG_CACHING/proj-$PG_TARBALL_PROJ.linux-x64/lib/libproj* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the proj libraries"
    ssh $PG_SSH_LINUX_X64 "cp $PG_CACHING/geos-$PG_TARBALL_GEOS.linux-x64/lib/libgeos* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the geos libraries"

    echo "Changing the rpath for the PostGIS executables and libraries"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN/../lib\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\$ORIGIN:\\\$ORIGIN/..\" \$f; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/lib; chmod +r *" 
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; chmod +rx *" 

    echo "Creating wrapper script for pgsql2shp and shp2pgsql"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; for f in pgsql2shp shp2pgsql ; do mv \$f \$f.bin; done"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; cat <<EOT > pgsql2shp
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/pgsql2shp.bin $*

cd \\\$CURRENTWD
EOT
"

    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; cat <<EOT > shp2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/shp2pgsql.bin $*

cd \\\$CURRENTWD
EOT
"
    ssh $PG_SSH_LINUX_X64 "cd $PG_STAGING/PostGIS/bin; chmod +x *"

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
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | sed 's/\./_/g'`

    mkdir -p staging/linux-x64/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux-x64/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux-x64/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux-x64/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/pg-launchPostGISJDBCDocs.desktop staging/linux-x64/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD
}


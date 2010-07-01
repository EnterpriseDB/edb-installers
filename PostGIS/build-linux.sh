#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS_linux() {
      
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
    chmod -R ugo+w postgis.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e geos.linux ];
    then
      echo "Removing existing geos.linux source directory"
      rm -rf geos.linux  || _die "Couldn't remove the existing geos.linux source directory (source/geos.linux)"
    fi

    echo "Creating geos source directory ($WD/PostGIS/source/geos.linux)"
    mkdir -p geos.linux || _die "Couldn't create the geos.linux directory"
    chmod ugo+w geos.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.linux || _die "Failed to copy the source code (source/geos.linux)"
    chmod -R ugo+w geos.linux || _die "Couldn't set the permissions on the source directory"

    if [ -e proj.linux ];
    then
       echo "Removing existing proj.linux source directory"
       rm -rf proj.linux  || _die "Couldn't remove the existing proj.linux source directory (source/proj.linux)"
    fi

    echo "Creating proj source directory ($WD/PostGIS/source/proj.linux)"
    mkdir -p proj.linux || _die "Couldn't create the proj.linux directory"
    chmod ugo+w proj.linux || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.linux || _die "Failed to copy the source code (source/proj.linux)"
    chmod -R ugo+w proj.linux || _die "Couldn't set the permissions on the source directory"

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

         
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux() {

    # build postgis    
    PG_STAGING=$PG_PATH_LINUX/PostGIS/staging/linux    
    PG_CACHING=$PG_PATH_LINUX/PostGIS/caching/linux    

    if [ ! -e $WD/PostGIS/caching/linux/proj-$PG_TARBALL_PROJ.linux ];
    then 
      # Configure the source tree
      echo "Configuring the proj source tree"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux/; sh ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux"  || _die "Failed to configure postgis"
  
      echo "Building proj"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux; make" || _die "Failed to build proj"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux; make install" || _die "Failed to install proj"
    fi
   
    if [ ! -e $WD/PostGIS/caching/linux/geos-$PG_TARBALL_GEOS.linux ];
    then
      echo "Configuring the geos source tree"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux/; sh ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux" || _die "Failed to configure geos"

      echo "Building geos"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux; make" || _die "Failed to build geos"
      ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux; make install" || _die "Failed to install geos"
    fi

    echo "Configuring the postgis source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/; export PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux/bin:\$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.linux/lib:\$LD_LIBRARY_PATH; LDFLAGS=\"-Wl,--rpath,'\\\$ORIGIN/../lib'\"; ./configure --with-pgconfig=$PG_PGHOME_LINUX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.linux/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.linux"  || _die "Failed to configure postgis"

    echo "Building postgis"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; make; make comments" || _die "Failed to build postgis"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; make install; make comments-install" || _die "Failed to install postgis"
    
    echo "Building postgis-jdbc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java/jdbc ;CLASSPATH=$PG_PATH_LINUX/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant" || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/doc; make html" || _die "Failed to build postgis-doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/doc; make install" || _die "Failed to install postgis-doc"
    
    cd $WD/PostGIS

    mkdir -p staging/linux/PostGIS
    cd staging/linux/PostGIS

    echo "Copying Postgis files from PG directory"
    mkdir bin
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/bin/shp2pgsql bin/" || _die "Failed to copy PostGIS binaries" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/bin/pgsql2shp bin/" || _die "Failed to copy PostGIS binaries" 

    mkdir lib
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so lib/" || _die "Failed to copy PostGIS library" 
 
    mkdir -p share/contrib
  
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/postgresql/contrib/postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/postgresql/contrib/uninstall_postgis.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/postgresql/contrib/postgis_upgrade*.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/postgresql/contrib/spatial_ref_sys.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/postgresql/contrib/postgis_comments.sql share/contrib/" || _die "Failed to copy PostGIS share files" 
  
    mkdir -p doc/postgis

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/doc/postgresql/postgis/postgis.html doc/postgis/" || _die "Failed to copy documentation"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/doc/postgresql/postgis/README.postgis doc/postgis/" || _die "Failed to copy documentation"

    mkdir -p man/man1
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/man/man1/pgsql2shp.1 man/man1/" || _die "Failed to copy the man pages"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/staging/linux/PostGIS; cp $PG_PGHOME_LINUX/share/man/man1/shp2pgsql.1 man/man1/" || _die "Failed to copy the man pages"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; cp loader/README.shp2pgsql $PG_STAGING/PostGIS/doc/postgis" || _die "Failed to copy README.shp2pgsql "
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; cp loader/README.pgsql2shp $PG_STAGING/PostGIS/doc/postgis" || _die "Failed to copy README.shp2pgsql "

    mkdir -p doc/postgis/jdbc/

    echo "Copying jdbc docs"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java/jdbc; cp postgis-jdbc-javadoc.zip $PG_STAGING/PostGIS/doc/postgis/jdbc" || _die "Failed to copy jdbc docs "
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/doc/postgis/jdbc; unzip postgis-jdbc-javadoc.zip; rm postgis-jdbc-javadoc.zip" || _die "Failed to remove jdbc docs zip file"

    cd $WD/PostGIS

    mkdir -p staging/linux/PostGIS/utils
    echo "Copying postgis-utils"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/utils; cp *.pl $PG_STAGING/PostGIS/utils" || _die "Failed to copy the utilities "
    
    cd $WD/PostGIS

    mkdir -p staging/linux/PostGIS/java/jdbc
 
    echo "Copying postgis-jdbc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java; cp jdbc/postgis*.jar $PG_STAGING/PostGIS/java/jdbc/" || _die "Failed to copy postgis jars into postgis-jdbc directory "
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java; cp -R ejb2 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb2 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java; cp -R ejb3 $PG_STAGING/PostGIS/java/" || _die "Failed to copy ejb3 into postgis-jdbc directory "
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java; cp -R pljava $PG_STAGING/PostGIS/java/" || _die "Failed to copy pljava into postgis-jdbc directory "

    # Copy dependent libraries
    ssh $PG_SSH_LINUX "cp $PG_CACHING/proj-$PG_TARBALL_PROJ.linux/lib/libproj* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the proj libraries"
    ssh $PG_SSH_LINUX "cp $PG_CACHING/geos-$PG_TARBALL_GEOS.linux/lib/libgeos* $PG_STAGING/PostGIS/lib" || _die "Failed to copy the geos libraries"

    echo "Changing the rpath for the PostGIS executables and libraries"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/bin; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}/../lib\" \$f; done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/lib; for f in \`file * | grep ELF | cut -d : -f 1 \`; do  chrpath --replace \"\\\${ORIGIN}\" \$f; done"

    echo "Creating wrapper script for pgsql2shp and shp2pgsql"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/bin; for f in pgsql2shp shp2pgsql ; do mv \$f \$f.bin; done"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/bin; cat <<EOT > pgsql2shp
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/pgsql2shp.bin $*

cd \\\$CURRENTWD
EOT
"

    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/bin; cat <<EOT > shp2pgsql
#!/bin/sh

CURRENTWD=\\\$PWD
WD=\\\`dirname \\\$0\\\`
cd \\\$WD/../lib

LD_LIBRARY_PATH=\\\$PWD:\\\$LD_LIBRARY_PATH \\\$WD/shp2pgsql.bin $*

cd \\\$CURRENTWD
EOT
"
    ssh $PG_SSH_LINUX "cd $PG_STAGING/PostGIS/bin; chmod +x *"

    cd $WD/PostGIS
} 


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux() {

    cd $WD/PostGIS
    mkdir -p staging/linux/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/removeshortcuts.sh    

    mkdir -p staging/linux/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux)"
	chmod ugo+x staging/linux/scripts/launchbrowser.sh
    cp -R scripts/linux/launchPostGISDocs.sh staging/linux/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
	chmod ugo+x staging/linux/scripts/launchPostGISDocs.sh
    cp -R scripts/linux/launchJDBCDocs.sh staging/linux/scripts/launchJDBCDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux/scripts/launchJDBCDocs.sh

    # Copy the XDG scripts
    mkdir -p staging/linux/installer/xdg || _die "Failed to create a directory for the xdg scripts"
    cp -R $WD/scripts/xdg/xdg* staging/linux/installer/xdg || _die "Failed to copy the xdg scripts (scripts/xdg/*)"
    chmod ugo+x staging/linux/installer/xdg/xdg*

    # Copy in the menu pick images and XDG items
    mkdir -p staging/linux/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.png staging/linux/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Version string, for the xdg filenames
    PG_VERSION_STR=`echo $PG_MAJOR_VERSION | sed 's/\./_/g'`
    POSTGIS_VERSION_STR=`echo $PG_VERSION_POSTGIS | sed 's/\./_/g'`

    mkdir -p staging/linux/scripts/xdg || _die "Failed to create a directory for the menu pick items"
    cp resources/xdg/pg-postgresql.directory staging/linux/scripts/xdg/pg-postgresql-$PG_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-postgis.directory staging/linux/scripts/xdg/pg-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/pg-launchPostGISDocs.desktop staging/linux/scripts/xdg/pg-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/pg-launchPostGISJDBCDocs.desktop staging/linux/scripts/xdg/pg-launchPostGISJDBCDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"
    
    cd $WD
}


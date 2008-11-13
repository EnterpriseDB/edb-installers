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
    cp -R geos-$PG_TARBALL_GEOS/* geos.linux || _die "Failed to copy the source code (source/geos-$PG_TARBALL_GEOS)"
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
    cp -R proj-$PG_TARBALL_PROJ/* proj.linux || _die "Failed to copy the source code (source/proj-$PG_TARBALL_PROJ)"
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
        
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux() {

    # build postgis    
    PG_STAGING=$PG_PATH_LINUX/PostGIS/staging/linux    

    # Configure the source tree
    echo "Configuring the proj source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux/; sh ./configure --prefix=$PG_STAGING/proj"  || _die "Failed to configure postgis"

    echo "Building proj"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux; make" || _die "Failed to build proj"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/proj.linux; make install" || _die "Failed to install proj"

    echo "Configuring the geos source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux/; sh ./configure --prefix=$PG_STAGING/geos" || _die "Failed to configure geos"

    echo "Building geos"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux; make" || _die "Failed to build geos"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/geos.linux; make install" || _die "Failed to install geos"

    echo "Configuring the postgis source tree"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/; export PATH=$PG_STAGING/proj/bin:$PG_STAGING/geos/bin:\$PATH; LD_LIBRARY_PATH=$PG_STAGING/proj/lib:$PG_STAGING/geos/lib:\$LD_LIBRARY_PATH; ./configure --prefix=$PG_STAGING/PostGIS --with-pgsql=$PG_PGHOME_LINUX/bin/pg_config --with-geos=$PG_STAGING/geos/bin/geos-config --with-proj=$PG_STAGING/proj"  || _die "Failed to configure postgis"

    echo "Building postgis"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; make" || _die "Failed to build postgis"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; make install" || _die "Failed to install postgis"


    echo "Building postgis-jdbc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java/jdbc; export CLASSPATH=$PG_PATH_LINUX/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH; JAVA_HOME=$PG_JAVA_HOME_LINUX $PG_ANT_HOME_LINUX/bin/ant" || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/doc; make" || _die "Failed to build postgis-doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/doc; make install" || _die "Failed to install postgis-doc"
    
    cd $WD/PostGIS
    
    echo "Moving doc folder to proper place"
    mv staging/linux/PostGIS/share/doc staging/linux/PostGIS/
    mv staging/linux/PostGIS/share/man staging/linux/PostGIS/
}
    


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux() {

    PG_STAGING=$PG_PATH_LINUX/PostGIS/staging/linux

    #Configure the files in PostGIS
    filelist=`grep -rlI "$PG_STAGING" "$WD/PostGIS/staging/linux" | grep -v Binary`

    cd  $WD/PostGIS/staging/linux

    for file in $filelist
    do
        _replace "$PG_STAGING/PostGIS" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done

    cd $WD/PostGIS

    echo "Copying required dependent libraries from proj and geos packages"
    cp staging/linux/geos/lib/libgeos_c.so.1 staging/linux/PostGIS/lib/
    cp staging/linux/geos/lib/libgeos-$PG_TARBALL_GEOS.so staging/linux/PostGIS/lib/
    cp staging/linux/proj/lib/libproj.so.0 staging/linux/PostGIS/lib/  

    echo "Copying Readme files"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux; cp README.postgis $PG_STAGING/PostGIS/doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/loader; cp README.shp2pgsql $PG_STAGING/PostGIS/doc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/loader; cp README.pgsql2shp $PG_STAGING/PostGIS/doc"

    mkdir -p staging/linux/PostGIS/doc/contrib/html/postgis/
    mkdir -p staging/linux/PostGIS/doc/postgis/jdbc

    echo "Copying postgis docs"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/doc/; cp html/* $PG_STAGING/PostGIS/doc/contrib/html/postgis/"

    echo "Copying jdbc docs"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java/jdbc; cp postgis-jdbc-javadoc.zip $PG_STAGING/PostGIS/doc/postgis/jdbc"
    cd staging/linux/PostGIS/doc/postgis/jdbc
    extract_file postgis-jdbc-javadoc || exit 1
    rm postgis-jdbc-javadoc.zip  || _warn "Failed to remove jdbc docs zip file"

    cd $WD/PostGIS

    mkdir -p staging/linux/PostGIS/share/contrib/postgis/utils
    echo "Copying postgis-utils"

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/utils; cp create_undef.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/utils; cp postgis_restore.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/utils; cp postgis_proc_upgrade.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"

    mkdir -p staging/linux/PostGIS/jdbc

    echo "Copying postgis-jdbc"
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/PostGIS/source/postgis.linux/java/jdbc; cp postgis_$PG_VERSION_POSTGIS.jar $PG_STAGING/PostGIS/jdbc"

    mkdir -p staging/linux/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/createtemplatedb.sh staging/linux/installer/PostGIS/createtemplatedb.sh || _die "Failed to copy the createtemplatedb script (scripts/linux/createtemplatedb.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/createtemplatedb.sh

    cp scripts/linux/createpostgisdb.sh staging/linux/installer/PostGIS/createpostgisdb.sh || _die "Failed to copy the createpostgisdb script (scripts/linux/createpostgisdb.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/createpostgisdb.sh

    cp scripts/linux/removeshortcuts.sh staging/linux/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/removeshortcuts.sh    

    cp scripts/linux/check-connection.sh staging/linux/installer/PostGIS/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/check-connection.sh

    cp scripts/linux/configurePostGIS.sh staging/linux/installer/PostGIS/configurePostGIS.sh || _die "Failed to copy the configurePostGIS script (scripts/linux/configurePostGIS.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/configurePostGIS.sh

    cp scripts/linux/check-pgversion.sh staging/linux/installer/PostGIS/check-pgversion.sh || _die "Failed to copy the check-pgversion script (scripts/linux/check-pgversion.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/check-pgversion.sh
 
    cp scripts/linux/check-db.sh staging/linux/installer/PostGIS/check-db.sh || _die "Failed to copy the check-db script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux/installer/PostGIS/check-db.sh

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


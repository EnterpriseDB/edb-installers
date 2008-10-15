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
    cp -R geos-$PG_TARBALL_GEOS/* geos.linux-x64 || _die "Failed to copy the source code (source/geos-$PG_TARBALL_GEOS)"
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
    cp -R proj-$PG_TARBALL_PROJ/* proj.linux-x64 || _die "Failed to copy the source code (source/proj-$PG_TARBALL_PROJ)"
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
        
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_linux_x64() {

    # build postgis    
    PG_STAGING=$PG_PATH_LINUX_X64/PostGIS/staging/linux-x64    

    # Configure the source tree
    echo "Configuring the proj source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64/; sh ./configure --prefix=$PG_STAGING/proj"  || _die "Failed to configure postgis"

    echo "Building proj"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64; make" || _die "Failed to build proj"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/proj.linux-x64; make install" || _die "Failed to install proj"

    echo "Configuring the geos source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64/; sh ./configure --prefix=$PG_STAGING/geos" || _die "Failed to configure geos"

    echo "Building geos"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64; make" || _die "Failed to build geos"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/geos.linux-x64; make install" || _die "Failed to install geos"

    echo "Configuring the postgis source tree"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/; export PATH=$PG_STAGING/proj/bin:$PG_STAGING/geos/bin:\$PATH; LD_LIBRARY_PATH=$PG_STAGING/proj/lib:$PG_STAGING/geos/lib:\$LD_LIBRARY_PATH; ./configure --prefix=$PG_STAGING/PostGIS --with-pgsql=$PG_PGHOME_LINUX_X64/bin/pg_config --with-geos=$PG_STAGING/geos/bin/geos-config --with-proj=$PG_STAGING/proj"  || _die "Failed to configure postgis"

    echo "Building postgis"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64; make" || _die "Failed to build postgis"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64; make install" || _die "Failed to install postgis"


    echo "Building postgis-jdbc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java/jdbc; export CLASSPATH=$PG_PATH_LINUX_X64/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH; JAVA_HOME=$PG_JAVA_HOME_LINUX_X64 $PG_ANT_HOME_LINUX_X64/bin/ant" || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/doc; make" || _die "Failed to build postgis-doc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/doc; make install" || _die "Failed to install postgis-doc"
    
    cd $WD/PostGIS
    
    echo "Moving doc folder to proper place"
    mv staging/linux-x64/PostGIS/share/doc staging/linux-x64/PostGIS/
    mv staging/linux-x64/PostGIS/share/man staging/linux-x64/PostGIS/
}
    


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_linux_x64() {

    PG_STAGING=$PG_PATH_LINUX_X64/PostGIS/staging/linux-x64    

    #Configure the files in PostGIS
    filelist=`grep -rlI "$PG_STAGING" "$WD/PostGIS/staging/linux-x64" | grep -v Binary`

    cd  $WD/PostGIS/staging/linux-x64

    for file in $filelist
    do
        _replace "$PG_STAGING/PostGIS" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done

    cd $WD/PostGIS

    echo "Copying required dependent libraries from proj and geos packages"
    cp staging/linux-x64/geos/lib/libgeos_c.so.1 staging/linux-x64/PostGIS/lib/
    cp staging/linux-x64/geos/lib/libgeos-$PG_TARBALL_GEOS.so staging/linux-x64/PostGIS/lib/
    cp staging/linux-x64/proj/lib/libproj.so.0 staging/linux-x64/PostGIS/lib/

    echo "Copying Readme files"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64; cp README.postgis $PG_STAGING/PostGIS/doc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/loader; cp README.shp2pgsql $PG_STAGING/PostGIS/doc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/loader; cp README.pgsql2shp $PG_STAGING/PostGIS/doc"

    mkdir -p staging/linux-x64/PostGIS/doc/contrib/html/postgis/
    mkdir -p staging/linux-x64/PostGIS/doc/postgis/jdbc

    echo "Copying postgis docs"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/doc/; cp html/* $PG_STAGING/PostGIS/doc/contrib/html/postgis/"

    echo "Copying jdbc docs"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java/jdbc; cp postgis-jdbc-javadoc.zip $PG_STAGING/PostGIS/doc/postgis/jdbc"
    cd staging/linux-x64/PostGIS/doc/postgis/jdbc
    extract_file postgis-jdbc-javadoc.zip || exit 1
    rm postgis-jdbc-javadoc.zip  || _warn "Failed to remove jdbc docs zip file"

    cd $WD/PostGIS

    mkdir -p staging/linux-x64/PostGIS/share/contrib/postgis/utils
    echo "Copying postgis-utils"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/utils; cp create_undef.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/utils; cp postgis_restore.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/utils; cp postgis_proc_upgrade.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils"

    mkdir -p staging/linux-x64/PostGIS/jdbc

    echo "Copying postgis-jdbc"
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/PostGIS/source/postgis.linux-x64/java/jdbc; cp postgis_$PG_VERSION_POSTGIS.jar $PG_STAGING/PostGIS/jdbc" || _die "Failed to copy PostGIS jar file into $PG_STAGING/PostGIS/jdbc directory"


    mkdir -p staging/linux-x64/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/linux/createshortcuts.sh staging/linux-x64/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/linux/createshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/createshortcuts.sh

    cp scripts/linux/createtemplatedb.sh staging/linux-x64/installer/PostGIS/createtemplatedb.sh || _die "Failed to copy the createtemplatedb script (scripts/linux/createtemplatedb.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/createtemplatedb.sh

    cp scripts/linux/createpostgisdb.sh staging/linux-x64/installer/PostGIS/createpostgisdb.sh || _die "Failed to copy the createpostgisdb script (scripts/linux/createpostgisdb.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/createpostgisdb.sh

    cp scripts/linux/removeshortcuts.sh staging/linux-x64/installer/PostGIS/removeshortcuts.sh || _die "Failed to copy the removeshortcuts script (scripts/linux/removeshortcuts.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/removeshortcuts.sh    

    cp scripts/linux/check-connection.sh staging/linux-x64/installer/PostGIS/check-connection.sh || _die "Failed to copy the check-connection script (scripts/linux/check-connection.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/check-connection.sh

    cp scripts/linux/configurePostGIS.sh staging/linux-x64/installer/PostGIS/configurePostGIS.sh || _die "Failed to copy the configurePostGIS script (scripts/linux/configurePostGIS.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/configurePostGIS.sh

    cp scripts/linux/check-pgversion.sh staging/linux-x64/installer/PostGIS/check-pgversion.sh || _die "Failed to copy the check-pgversion script (scripts/linux/check-pgversion.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/check-pgversion.sh

    cp scripts/linux/check-db.sh staging/linux-x64/installer/PostGIS/check-db.sh || _die "Failed to copy the check-db script (scripts/linux/check-db.sh)"
    chmod ugo+x staging/linux-x64/installer/PostGIS/check-db.sh

    mkdir -p staging/linux-x64/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/linux/launchbrowser.sh staging/linux-x64/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/launchbrowser.sh

    cp -R scripts/linux/launchPostGISDocs.sh staging/linux-x64/scripts/launchPostGISDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
    chmod ugo+x staging/linux-x64/scripts/launchPostGISDocs.sh

    cp -R scripts/linux/launchJDBCDocs.sh staging/linux-x64/scripts/launchJDBCDocs.sh || _die "Failed to copy the launch scripts (scripts/linux)"
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
    cp resources/xdg/enterprisedb-postgis.directory staging/linux-x64/scripts/xdg/enterprisedb-postgis-$POSTGIS_VERSION_STR.directory || _die "Failed to copy a menu pick directory"
    cp resources/xdg/enterprisedb-launchPostGISDocs.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchPostGISDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"
    cp resources/xdg/enterprisedb-launchJDBCDocs.desktop staging/linux-x64/scripts/xdg/enterprisedb-launchJDBCDocs-$POSTGIS_VERSION_STR.desktop || _die "Failed to copy a menu pick desktop"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    
    cd $WD
}


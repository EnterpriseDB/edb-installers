
    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source

    if [ -e postgis.osx ];
    then
      echo "Removing existing postgis.osx source directory"
      rm -rf postgis.osx  || _die "Couldn't remove the existing postgis.osx source directory (source/postgis.osx)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.osx)"
    mkdir -p postgis.osx || _die "Couldn't create the postgis.osx directory"
    chmod ugo+w postgis.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.osx || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"
    chmod -R ugo+w postgis.osx || _die "Couldn't set the permissions on the source directory"

    if [ -e geos.osx ];
    then
      echo "Removing existing geos.osx source directory"
      rm -rf geos.osx  || _die "Couldn't remove the existing geos.osx source directory (source/geos.osx)"
    fi
    
    echo "Creating geos source directory ($WD/PostGIS/source/geos.osx)"
    mkdir -p geos.osx || _die "Couldn't create the geos.osx directory"
    chmod ugo+w geos.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.osx || _die "Failed to copy the source code (source/geos-$PG_TARBALL_GEOS)"
    chmod -R ugo+w geos.osx || _die "Couldn't set the permissions on the source directory"

    if [ -e proj.osx ];
    then
      echo "Removing existing proj.osx source directory"
      rm -rf proj.osx  || _die "Couldn't remove the existing proj.osx source directory (source/proj.osx)"
    fi

    echo "Creating proj source directory ($WD/PostGIS/source/proj.osx)"
    mkdir -p proj.osx || _die "Couldn't create the proj.osx directory"
    chmod ugo+w proj.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.osx || _die "Failed to copy the source code (source/proj-$PG_TARBALL_PROJ)"
    chmod -R ugo+w proj.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/osx)"
    mkdir -p $WD/PostGIS/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/osx || _die "Couldn't set the permissions on the staging directory"
        
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_osx() {

    # build postgis    
    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx    

    # Configure the source tree
    cd $PG_PATH_OSX/PostGIS/source/proj.osx/    
    echo "Configuring the proj source tree"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" ./configure --prefix=$PG_STAGING/proj --disable-dependency-tracking  || _die "Failed to configure proj"

    echo "Building proj"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" make || _die "Failed to build proj"
    make install || _die "Failed to install proj"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/PostGIS/staging/osx/proj lib @loader_path/..

    cd $PG_PATH_OSX/PostGIS/source/geos.osx

    echo "Configuring the geos source tree"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" ./configure --prefix=$PG_STAGING/geos --disable-dependent-tracking || _die "Failed to configure geos"

    echo "Building geos"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" make || _die "Failed to build geos"
    make install || _die "Failed to install geos"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/PostGIS/staging/osx/geos lib @loader_path/..

    echo "Configuring the postgis source tree"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/
    PATH=$PG_STAGING/proj/bin:$PG_STAGING/geos/bin:$PATH; LD_LIBRARY_PATH=$PG_STAGING/proj/lib:$PG_STAGING/geos/lib:\$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" ./configure --disable-dependency-tracking --prefix=$PG_STAGING/PostGIS --with-pgsql=$PG_PGHOME_OSX/bin/pg_config --with-geos=$PG_STAGING/geos/bin/geos-config --with-proj=$PG_STAGING/proj || _die "Failed to configure postgis"

    echo "Building postgis"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" make || _die "Failed to build postgis"
    make install || _die "Failed to install postgis"

    echo "Building postgis-jdbc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc 
    export CLASSPATH=$PG_PATH_OSX/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH 
    $PG_ANT_HOME_OSX/bin/ant || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc; 
    make || _die "Failed to build postgis-doc"
    make install || _die "Failed to install postgis-doc"
    
    cd $WD/PostGIS
    
    echo "Moving doc folder to proper place"
    mv staging/osx/PostGIS/share/doc staging/osx/PostGIS/
    mv staging/osx/PostGIS/share/man staging/osx/PostGIS/

    echo "Copying Dependent libraries"
    cp staging/osx/geos/lib/*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp staging/osx/proj/lib/*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS bin @loader_path/..
    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS lib @loader_path/..


     
}
    


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_osx() {

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx    

    #Configure the files in PostGIS
    filelist=`grep -rlI "$PG_STAGING" "$WD/PostGIS/staging/osx" | grep -v Binary`

    cd  $WD/PostGIS/staging/osx

    for file in $filelist
    do
        _replace "$PG_STAGING/PostGIS" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done

    cd $WD/PostGIS

    echo "Copying Readme files"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx
    cp README.postgis $PG_STAGING/PostGIS/doc || _die "Failed to copy README.postgis "
    cp loader/README.shp2pgsql $PG_STAGING/PostGIS/doc || _die "Failed to copy README.shp2pgsql "
    cp loader/README.pgsql2shp $PG_STAGING/PostGIS/doc || _die "Failed to copy README.pgsql2shp "

    mkdir -p $PG_STAGING/PostGIS/doc/contrib/html/postgis/
    mkdir -p $PG_STAGING/PostGIS/doc/postgis/jdbc/

    echo "Copying postgis docs"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc/
    cp -R html/ $PG_STAGING/PostGIS/doc/contrib/html/postgis/ || _die "Failed to copy postgis docs "

    echo "Copying jdbc docs"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc
    if [ -e postgis-jdbc-javadoc.zip ];
    then
        cp postgis-jdbc-javadoc.zip $PG_STAGING/PostGIS/doc/postgis/jdbc || _die "Failed to copy jdbc docs "
        cd $PG_STAGING/PostGIS/doc/postgis/jdbc
        extract_file postgis-jdbc-javadoc.zip || exit 1
        rm postgis-jdbc-javadoc.zip  || echo "Failed to remove jdbc docs zip file"
    else
        echo "Couldn't find the jdbc docs zip file"
    fi

    cd $WD/PostGIS

    mkdir -p staging/osx/PostGIS/share/contrib/postgis/utils
    echo "Copying postgis-utils"

    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/utils
    cp create_undef.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils || _die "Failed to copy create_undef.p1 "
    cp postgis_restore.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils || _die "Failed to copy postgis_restore.p1 "
    cp postgis_proc_upgrade.pl $PG_STAGING/PostGIS/share/contrib/postgis/utils || _die "Failed to copy postgres_proc_upgrade.p1 "

    mkdir -p $WD/PostGIS/staging/osx/PostGIS/jdbc

    echo "Copying postgis-jdbc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc
    cp postgis_$PG_VERSION_POSTGIS.jar $PG_STAGING/PostGIS/jdbc/ || _die "Failed to copy postgis_$PG_VERSION_POSTGIS.jar into postgis-jdbc directory "

    mkdir -p $PG_STAGING/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createshortcuts.sh $PG_STAGING/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createshortcuts.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createtemplatedb.sh $PG_STAGING/installer/PostGIS/createtemplatedb.sh || _die "Failed to copy the createtemplatedb script (scripts/osx/createtemplatedb.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createtemplatedb.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createpostgisdb.sh $PG_STAGING/installer/PostGIS/createpostgisdb.sh || _die "Failed to copy the createpostgisdb script (scripts/osx/createpostgisdb.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createpostgisdb.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/check-connection.sh $PG_STAGING/installer/PostGIS/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/check-connection.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/configurePostGIS.sh $PG_STAGING/installer/PostGIS/configurePostGIS.sh || _die "Failed to copy the configurePostGIS script (scripts/osx/configurePostGIS.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/configurePostGIS.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/check-db.sh $PG_STAGING/installer/PostGIS/check-db.sh || _die "Failed to copy the check-db script (scripts/osx/check-db.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/check-db.sh

    mkdir -p $PG_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/launchbrowser.sh $PG_STAGING/scripts/launchbrowser.sh || _die "Failed to copy the launch scripts (scripts/osx)"
    chmod ugo+x $PG_STAGING/scripts/launchbrowser.sh

    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/enterprisedb-launchJdbcDocs.applescript.in $PG_STAGING/scripts/enterprisedb-launchJdbcDocs.applescript || _die "Failed to copy the launch script (scripts/osx/enterprisedb-launchJdbcDocs.applescript.in)"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/enterprisedb-launchPostGISDocs.applescript.in $PG_STAGING/scripts/enterprisedb-launchPostGISDocs.applescript || _die "Failed to copy the launch script (scripts/osx/enterprisedb-launchPostGISDocs.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PG_PATH_OSX/PostGIS/resources/enterprisedb-launchPostGISDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/enterprisedb-launchPostGISDocs.icns)"
    cp $PG_PATH_OSX/PostGIS/resources/enterprisedb-launchJdbcDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/enterprisedb-launchJdbcDocs.icns)"

    cd $PG_PATH_OSX/PostGIS/
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Now we need to turn this into a DMG file
    echo "Creating disk image"
    cd $WD/output
    if [ -d postgis.img ];
    then
        rm -rf postgis.img
    fi
    mkdir postgis.img || _die "Failed to create DMG staging directory"
    mv postgis_PG$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app postgis.img || _die "Failed to copy the installer bundle into the DMG staging directory"
    hdiutil create -quiet -srcfolder postgis.img -format UDZO -volname "postgis_PG$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS" -ov "postgis_PG$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.dmg" || _die "Failed to create the disk image (output/postgis-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.dmg)"
    rm -rf postgis.img
    
    cd $WD
}


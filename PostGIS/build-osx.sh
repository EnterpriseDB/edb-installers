
    
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

    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.osx || _die "Failed to copy the source code (PostGIS/source/postgis-$PG_VERSION_POSTGIS)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/osx)"
    mkdir -p $WD/PostGIS/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/osx || _die "Couldn't set the permissions on the staging directory"

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    cd $PG_PGHOME_OSX
    rm -f bin/shp2pgsql bin/pgsql2shp  || _die "Failed to remove postgis binary files"
    rm -f lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so  || _die "Failed to remove postgis library files"
    rm -f share/postgresql/contrib/spatial_ref_sys.sql share/postgresql/contrib/postgis.sql  || _die "Failed to remove postgis share files"
    rm -f share/postgresql/contrib/uninstall_postgis.sql  share/postgresql/contrib/postgis_upgrade*.sql  || _die "Failed to remove postgis share files"
    rm -f share/postgresql/contrib/postgis_comments.sql  || _die "Failed to remove postgis share files"
    rm -f doc/postgresql/postgis/postgis.html doc/postgresql/postgis/README.postgis || _die "Failed to remove documentation"
    rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1 || _die "Failed to remove man pages"
    cd $WD
    
    echo "END PREP PostGIS OSX"
}


#########################################################################################
#Change so reference --Copy of common.sh's _rewrite_so_reference modified to suit postgis
#########################################################################################

_change_so_refs() {

    BASE_PATH=$1
    FILE_PATH=$BASE_PATH/$2
    LOADER_PATH=$3

    FLIST=`ls $FILE_PATH`

    for FILE in $FLIST; do

            IS_EXECUTABLE=`file $FILE_PATH/$FILE | grep "Mach-O executable" | wc -l`
            IS_SHAREDLIB=`file $FILE_PATH/$FILE | grep -E "(Mach-O\ dynamically\ linked\ shared\ library|Mach-O\ bundle)" | wc -l`

               if [ $IS_EXECUTABLE -ne 0 -o $IS_SHAREDLIB -ne 0 ]; then

                    # We need to ignore symlinks
                    IS_SYMLINK=`file $FILE_PATH/$FILE | grep "symbolic link" | wc -l`

                    if [ $IS_SYMLINK -eq 0 ]; then

                            if [ $IS_EXECUTABLE -ne 0 ]; then
                                    echo "Post-processing executable: $FILE_PATH/$FILE"
                            else
                                    echo "Post-processing shared library: $FILE_PATH/$FILE"
                            fi

                            if [ $IS_SHAREDLIB -ne 0 ]; then
                                    # Change the library ID
                                    ID=`otool -D $FILE_PATH/$FILE | grep $BASE_PATH | grep -v ":"`
                                    ID1=`otool -D $FILE_PATH/$FILE | grep "$PG_CACHING/proj-$PG_TARBALL_PROJ.osx" | grep -v ":"`
                                    ID2=`otool -D $FILE_PATH/$FILE | grep "$PG_CACHING/geos-$PG_TARBALL_GEOS.osx" | grep -v ":"`
                                   
                                    for DLL in $ID; do
                                            echo "    - rewriting ID: $DLL"

                                            NEW_DLL=`echo $DLL | sed -e "s^$FILE_PATH/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE" 
                                    done

                                    for DLL in $ID1; do
                                            echo "    - rewriting ID: $DLL"
                                            NEW_DLL=`echo $DLL | sed -e "s^$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE"
                                    done
                                    
                                    for DLL in $ID2; do
                                            echo "    - rewriting ID: $DLL"
                                            NEW_DLL=`echo $DLL | sed -e "s^$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE"
                                    done
                                    
                            fi

                            # Now change the referenced libraries
                            DLIST=`otool -L $FILE_PATH/$FILE | grep $BASE_PATH | grep -v ":" | awk '{ print $1 }'`
                            DLIST1=`otool -L $FILE_PATH/$FILE | grep "$PG_CACHING/proj-$PG_TARBALL_PROJ.osx" | grep -v ":" | awk '{ print $1 }'`
                            DLIST2=`otool -L $FILE_PATH/$FILE | grep "$PG_CACHING/geos-$PG_TARBALL_GEOS.osx" | grep -v ":" | awk '{ print $1 }'`

                            for DLL in $DLIST; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^$BASE_PATH/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done

                            for DLL in $DLIST1; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done

                            for DLL in $DLIST2; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done
                    fi
            fi
    done
}


################################################################################
# PostGIS compilation and installation in the staging directory 
################################################################################

_build_postgis() {

    cd $PG_PATH_OSX/PostGIS/source/postgis.osx || _die "Failed to change to the proj source directory (PostGIS/source/proj.osx)"

    # Configure the source tree
    echo "Configuring the PostGIS source tree for Intel"
    LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-L/usr/local/lib -arch i386" PATH=/usr/local/bin:$PG_PERL_OSX/bin:$PATH MACOSX_DEPLOYMENT_TARGET=10.6 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=/usr/local/bin/geos-config --with-projdir=/usr/local --with-xsldir=$PG_DOCBOOK_OSX  --with-gdalconfig=/usr/local/bin/gdal-config --with-xml2config=/usr/local/bin/xml2-config --with-libiconv=/usr/local || _die "Failed to configure PostGIS for i386"
    mv postgis_config.h postgis_config_i386.h

    echo "Configuring the PostGIS source tree for x86_64"
    LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" LDFLAGS="-L/usr/local/lib -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.6 PATH=/usr/local/bin:$PG_PERL_OSX/bin:$PATH ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=/usr/local/bin/geos-config --with-projdir=/usr/local --with-xsldir=$PG_DOCBOOK_OSX --with-gdalconfig=/usr/local/bin/gdal-config --with-xml2config=/usr/local/bin/xml2-config --with-libiconv=/usr/local || _die "Failed to configure PostGIS for x86_64"
    mv postgis_config.h postgis_config_x86_64.h

    echo "Configuring the PostGIS source tree for Universal"
    LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -arch i386" LDFLAGS="-L/usr/local/lib -arch x86_64 -arch i386" MACOSX_DEPLOYMENT_TARGET=10.6 PATH=/usr/local/bin:$PG_PERL_OSX/bin:$PATH ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=/usr/local/bin/geos-config --with-projdir=/usr/local --with-xsldir=$PG_DOCBOOK_OSX --with-gdalconfig=/usr/local/bin/gdal-config --with-xml2config=/usr/local/bin/xml2-config --with-libiconv=/usr/local || _die "Failed to configure PostGIS for x86_64"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifndef __BIG_ENDIAN__" > postgis_config.h
    echo "  #ifdef __LP64__" >> postgis_config.h
    echo "    #include \"postgis_config_x86_64.h\"" >> postgis_config.h
    echo "  #else" >> postgis_config.h
    echo "    #include \"postgis_config_i386.h\"" >> postgis_config.h
    echo "  #endif" >> postgis_config.h
    echo "#endif" >> postgis_config.h

    echo "Building PostGIS"
    LDFLAGS="-L/usr/local/lib -arch x86_64 -arch i386" CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -arch i386" MACOSX_DEPLOYMENT_TARGET=10.6 make || _die "Failed to build PostGIS"
    make comments || _die "Failed to build comments"
    make install PGXSOVERRIDE=0 DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$WD/PostGIS/staging/osx/PostGIS/doc PGSQL_MANDIR=$WD/PostGIS/staging/osx/PostGIS/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS"
    make comments-install PGXSOVERRIDE=0 DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$WD/PostGIS/staging/osx/PostGIS/doc PGSQL_MANDIR=$WD/PostGIS/staging/osx/PostGIS/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS comments"

    echo "Building postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc/html/image_src;
    make clean
    LDFLAGS="-L/usr/local/lib -arch x86_64 -arch i386" CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -arch i386" MACOSX_DEPLOYMENT_TARGET=10.6 make|| _die "Failed to build postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc; 
    LDFLAGS="-L/usr/local/lib -arch x86_64 -arch i386" CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64 -arch i386" MACOSX_DEPLOYMENT_TARGET=10.6 make html || _die "Failed to build postgis-doc"
    make install PGXSOVERRIDE=0 DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share REGRESS=1 PGSQL_DOCDIR=$WD/PostGIS/staging/osx/PostGIS/doc PGSQL_MANDIR=$WD/PostGIS/staging/osx/PostGIS/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS-doc"
    
    cd $WD/PostGIS
    mkdir -p staging/osx/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/html/images staging/osx/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/html/postgis.html staging/osx/PostGIS/doc/postgis/
    cp -pR source/postgis.osx/doc/postgis-$PG_VERSION_POSTGIS.pdf staging/osx/PostGIS/doc/postgis/
   
    mkdir -p staging/osx/PostGIS/man
    cp -pR source/postgis.osx/doc/man staging/osx/PostGIS/

    mkdir -p staging/osx/PostGIS/utils
    echo "Copying postgis-utils"
    cd $WD/PostGIS/source/postgis.osx/utils
    cp *.pl $PG_STAGING/PostGIS/utils || _die "Failed to copy the utilities "
    
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

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    # Building PostGIS
    _build_postgis

    cd $WD/PostGIS
    cp -pR staging/osx/PostGIS/$PG_PGHOME_OSX/bin/* $PG_STAGING/PostGIS/bin/ 
    cp -pR staging/osx/PostGIS/usr/local/include $PG_STAGING/PostGIS
    cp -pR staging/osx/PostGIS/usr/local/lib/* $PG_STAGING/PostGIS/lib/
    rm -rf staging/osx/PostGIS/Users
    rm -rf staging/osx/PostGIS/usr

    echo "Copying Dependent libraries"
    cp -pR /usr/local/lib/libgeos*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp -pR /usr/local/lib/libproj*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp -pR /usr/local/lib/libgdal*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp -pR /usr/local/lib/libcurl*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp -pR /usr/local/lib/libpcre.*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp -pR /usr/local/lib/libintl.*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"

    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS bin @loader_path/..
    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS lib @loader_path/../..
    #_change_so_refs $WD/PostGIS/staging/osx/PostGIS bin @loader_path/..
    #_change_so_refs $WD/PostGIS/staging/osx/PostGIS lib @loader_path/../..
    install_name_tool -change "libxml2.2.dylib" "@loader_path/../../lib/libxml2.2.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/postgis-*.so
    install_name_tool -change "@loader_path/../../lib/libgeos-$PG_TARBALL_GEOS.dylib" "@loader_path/libgeos-$PG_TARBALL_GEOS.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/libgeos_c.1.dylib
    install_name_tool -change "@loader_path/../../lib/libpcre.1.dylib" "@loader_path/libpcre.1.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/libgdal.1.dylib
    install_name_tool -change "@loader_path/../../lib/libcurl.4.dylib" "@loader_path/libcurl.4.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/libgdal.1.dylib
    install_name_tool -change "@loader_path/../../lib/libgeos_c.1.dylib" "@loader_path/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/postgis-2.0.so
    install_name_tool -change "@loader_path/../../lib/libgeos_c.1.dylib" "@loader_path/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/rtpostgis-2.0.so
    install_name_tool -change "@loader_path/../../lib/libproj.0.dylib" "@loader_path/libproj.0.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/postgis-2.0.so
    install_name_tool -change "@loader_path/../../lib/libgdal.1.dylib" "@loader_path/libgdal.1.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/rtpostgis-2.0.so

    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsq
    install_name_tool -change "@loader_path/../../lib/libgeos-$PG_TARBALL_GEOS.dylib" "@loader_path/libgeos-$PG_TARBALL_GEOS.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/liblwgeom-$PG_VERSION_POSTGIS.dylib
    install_name_tool -change "@loader_path/../../lib/libgeos_c.1.dylib" "@loader_path/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/liblwgeom-$PG_VERSION_POSTGIS.dylib
    install_name_tool -change "@loader_path/../../lib/libproj.0.dylib" "@loader_path/libproj.0.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/liblwgeom-$PG_VERSION_POSTGIS.dylib
    # Change the path for libs that will be installed in lib/postgresql
    install_name_tool -change "@loader_path/../lib/liblwgeom-$PG_VERSION_POSTGIS.dylib" "@loader_path/../lib/postgresql/liblwgeom-$PG_VERSION_POSTGIS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "@loader_path/../lib/libgeos_c.1.dylib" "@loader_path/../lib/postgresql/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "@loader_path/../lib/libgeos-$PG_TARBALL_GEOS.dylib" "@loader_path/../lib/postgresql/libgeos-$PG_TARBALL_GEOS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "@loader_path/../lib/libproj.0.dylib" "@loader_path/../lib/postgresql/libproj.0.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "@loader_path/../lib/libintl.8.dylib" "@loader_path/../lib/postgresql/libintl.8.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/pgsql2shp
    install_name_tool -change "@loader_path/../lib/liblwgeom-$PG_VERSION_POSTGIS.dylib" "@loader_path/../lib/postgresql/liblwgeom-$PG_VERSION_POSTGIS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/shp2pgsql
    install_name_tool -change "@loader_path/../lib/libgeos_c.1.dylib" "@loader_path/../lib/postgresql/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/shp2pgsql
    install_name_tool -change "@loader_path/../lib/libgeos-$PG_TARBALL_GEOS.dylib" "@loader_path/../lib/postgresql/libgeos-$PG_TARBALL_GEOS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/shp2pgsql
    install_name_tool -change "@loader_path/../lib/libproj.0.dylib" "@loader_path/../lib/postgresql/libproj.0.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/shp2pgsql
    install_name_tool -change "@loader_path/../lib/libintl.8.dylib" "@loader_path/../lib/postgresql/libintl.8.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/shp2pgsql
    install_name_tool -change "@loader_path/../lib/liblwgeom-$PG_VERSION_POSTGIS.dylib" "@loader_path/../lib/postgresql/liblwgeom-$PG_VERSION_POSTGIS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libgeos_c.1.dylib" "@loader_path/../lib/postgresql/libgeos_c.1.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libgeos-$PG_TARBALL_GEOS.dylib" "@loader_path/../lib/postgresql/libgeos-$PG_TARBALL_GEOS.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libproj.0.dylib" "@loader_path/../lib/postgresql/libproj.0.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libintl.8.dylib" "@loader_path/../lib/postgresql/libintl.8.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libcurl.4.dylib" "@loader_path/../lib/postgresql/libcurl.4.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libgdal.1.dylib" "@loader_path/../lib/postgresql/libgdal.1.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql
    install_name_tool -change "@loader_path/../lib/libpcre.1.dylib" "@loader_path/../lib/postgresql/libpcre.1.dylib" $WD/PostGIS/staging/osx/PostGIS/bin/raster2pgsql

    chmod +r $WD/PostGIS/staging/osx/PostGIS/lib/*
    chmod +rx $WD/PostGIS/staging/osx/PostGIS/bin/*
    

    cd $WD
   
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

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx    

    mkdir -p $PG_STAGING/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createshortcuts.sh $PG_STAGING/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createshortcuts.sh

    mkdir -p $PG_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp -pR $PG_PATH_OSX/PostGIS/scripts/osx/pg-launchPostGISDocs.applescript.in $PG_STAGING/scripts/pg-launchPostGISDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchPostGISDocs.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp -pR $PG_PATH_OSX/PostGIS/resources/pg-launchPostGISDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPostGISDocs.icns)"

    cd $PG_PATH_OSX/PostGIS/

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

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/PostGIS_PG$PG_CURRENT_VERSION
    chmod a+x $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/PostGIS_PG$PG_CURRENT_VERSION
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ PostGIS_PG$PG_CURRENT_VERSION $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/Contents/MacOS/installbuilder.sh


    # Zip up the output
    cd $WD/output
    zip -r postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD

    echo "END POST PostGIS OSX" 
}


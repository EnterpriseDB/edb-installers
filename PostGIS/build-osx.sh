
    
################################################################################
# PostGIS Build Preparation
################################################################################

_prep_PostGIS_osx() {
      
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
    chmod -R ugo+w postgis.osx || _die "Couldn't set the permissions on the source directory"

    if [ -e geos.osx ];
    then
      echo "Removing existing geos.osx source directory"
      rm -rf geos.osx  || _die "Couldn't remove the existing geos.osx source directory (PostGIS/source/geos.osx)"
    fi

    echo "Creating geos source directory ($WD/PostGIS/source/geos-$PG_TARBALL_GEOS.osx)"
    mkdir -p geos.osx || _die "Couldn't create the geos-$PG_TARBALL_GEOS.osx directory"
    chmod ugo+w geos.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.osx || _die "Failed to copy the source code (PostGIS/source/geos-$PG_TARBALL_GEOS)"
    chmod -R ugo+w geos.osx || _die "Couldn't set the permissions on the source directory"
    

    if [ -e proj.osx ];
    then
      echo "Removing existing proj.osx source directory"
      rm -rf proj.osx  || _die "Couldn't remove the existing proj.osx source directory (PostGIS/source/proj.osx)"
    fi

    echo "Creating proj source directory ($WD/PostGIS/source/proj-$PG_TARBALL_PROJ.osx)"
    mkdir -p proj.osx || _die "Couldn't create the proj.osx directory"
    chmod ugo+w proj.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.osx || _die "Failed to copy the source code (PostGIS/source/proj-$PG_TARBALL_PROJ)"
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

    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    echo "Removing existing PostGIS files from the PostgreSQL directory"
    cd $PG_PGHOME_OSX
    rm -f bin/shp2pgsql bin/pgsql2shp  || _die "Failed to remove postgis binary files"
    rm -f lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so  || _die "Failed to remove postgis library files"
    rm -f share/postgresql/contrib/spatial_ref_sys.sql share/postgresql/contrib/postgis.sql  || _die "Failed to remove postgis share files"
    rm -f share/postgresql/contrib/uninstall_postgis.sql  share/postgresql/contrib/postgis_upgrade.sql  || _die "Failed to remove postgis share files"
    rm -f share/postgresql/contrib/postgis_comments.sql  || _die "Failed to remove postgis share files"
    rm -f doc/postgresql/postgis/postgis.html doc/postgresql/postgis/README.postgis || _die "Failed to remove documentation"
    rm -f share/man/man1/pgsql2shp.1 share/man/man1/shp2pgsql.1 || _die "Failed to remove man pages"
    cd $WD

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
# Geos build
################################################################################

_build_geos() {


    cd $WD/PostGIS/source/geos.osx || _die "Failed to change to the geos source directory (PostGIS/source/geos.osx)"

    # Configure the source tree
    echo "Configuring the Geos source tree for Intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for i386"
    mv source/headers/config.h source/headers/config_i386.h

    echo "Configuring the Geos source tree for PPC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for PPC"
    mv source/headers/config.h source/headers/config_ppc.h

    echo "Configuring the Geos source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for Universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > source/headers/config.h
    echo "#include \"config_ppc.h\"" >> source/headers/config.h
    echo "#else" >> source/headers/config.h
    echo "#include \"config_i386.h\"" >> source/headers/config.h
    echo "#endif" >> source/headers/config.h

    echo "Building Geos"
    MACOSX_DEPLOYMENT_TARGET=10.4 make LDFLAGS="-arch i386 -arch ppc" -j 2 || _die "Failed to build Geos"
    make prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx install || _die "Failed to install Geos"

    cd $WD

}

################################################################################
# Proj build
################################################################################

_build_proj() {

    cd $PG_PATH_OSX/PostGIS/source/proj.osx || _die "Failed to change to the proj source directory (PostGIS/source/proj.osx)"

    # Configure the source tree
    echo "Configuring the Proj source tree for Intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for i386"
    mv src/proj_config.h src/proj_config_i386.h

    echo "Configuring the Proj source tree for PPC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for PPC"
    mv src/proj_config.h src/proj_config_ppc.h

    echo "Configuring the Proj source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for Universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > src/proj_config.h
    echo "#include \"proj_config_ppc.h\"" >> src/proj_config.h
    echo "#else" >> src/proj_config.h
    echo "#include \"proj_config_i386.h\"" >> src/proj_config.h
    echo "#endif" >> src/proj_config.h

    echo "Building Proj"
    MACOSX_DEPLOYMENT_TARGET=10.4 make -j 2 || _die "Failed to build Proj"
    make prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx install || _die "Failed to install Proj"

    cd $WD
}

################################################################################
# PostGIS compilation and installation in the staging directory 
################################################################################

_build_postgis() {

    cd $PG_PATH_OSX/PostGIS/source/postgis.osx || _die "Failed to change to the proj source directory (PostGIS/source/proj.osx)"

    # Configure the source tree
    echo "Configuring the PostGIS source tree for Intel"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for i386"
    mv postgis_config.h postgis_config_i386.h

    echo "Configuring the PostGIS source tree for PPC"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for PPC"
    mv postgis_config.h postgis_config_ppc.h

    echo "Configuring the PostGIS source tree for Universal"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.4 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx  --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > postgis_config.h
    echo "#include \"postgis_config_ppc.h\"" >> postgis_config.h
    echo "#else" >> postgis_config.h
    echo "#include \"postgis_config_i386.h\"" >> postgis_config.h
    echo "#endif" >> postgis_config.h

    echo "Building PostGIS"
    #MACOSX_DEPLOYMENT_TARGET=10.4 make CFLAGS="-mmacosx-version-min=10.4 -headerpad_max_install_names -arch i386 -arch ppc" LDFLAGS="-arch i386 -arch ppc" -j 2 || _die "Failed to build PostGIS"
    MACOSX_DEPLOYMENT_TARGET=10.4 make || _die "Failed to build PostGIS"
    make comments || _die "Failed to build comments"
    make install || _die "Failed to install PostGIS"
    make comments-install || _die "Failed to install PostGIS comments"

    cd $WD
}


################################################################################
# PostGIS Build
################################################################################

_build_PostGIS_osx() {

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx
    PG_CACHING=$PG_PATH_OSX/PostGIS/caching/osx
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    if [ ! -e $WD/PostGIS/caching/osx/proj-$PG_TARBALL_PROJ.osx ];
    then
      # Building proj
      _build_proj
    fi

    if [ ! -e $WD/PostGIS/caching/osx/geos-$PG_TARBALL_GEOS.osx ];
    then
      # Building geos
      _build_geos
    fi

    # Building PostGIS
    _build_postgis

    echo "Building postgis-jdbc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc 
    export CLASSPATH=$PG_PATH_OSX/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH 
    $PG_ANT_HOME_OSX/bin/ant || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc; 
    make html || _die "Failed to build postgis-doc"
    make install || _die "Failed to install postgis-doc"
    
    cd $WD/PostGIS

    mkdir -p staging/osx/PostGIS
    cd staging/osx/PostGIS

    echo "Copying Postgis files from PG directory"
    mkdir bin
    cp $PG_PGHOME_OSX/bin/shp2pgsql bin/ || _die "Failed to copy PostGIS binaries" 
    cp $PG_PGHOME_OSX/bin/pgsql2shp bin/ || _die "Failed to copy PostGIS binaries"

    mkdir lib
    cp $PG_PGHOME_OSX/lib/postgresql/postgis-$POSTGIS_MAJOR_VERSION.so lib/ || _die "Failed to copy PostGIS library" 
 
    mkdir -p share/contrib
  
    cp $PG_PGHOME_OSX/share/postgresql/contrib/postgis.sql share/contrib/ || _die "Failed to copy PostGIS share files" 
    cp $PG_PGHOME_OSX/share/postgresql/contrib/uninstall_postgis.sql share/contrib/ || _die "Failed to copy PostGIS share files" 
    cp $PG_PGHOME_OSX/share/postgresql/contrib/postgis_upgrade.sql share/contrib/ || _die "Failed to copy PostGIS share files" 
    cp $PG_PGHOME_OSX/share/postgresql/contrib/spatial_ref_sys.sql share/contrib/ || _die "Failed to copy PostGIS share files" 
    cp $PG_PGHOME_OSX/share/postgresql/contrib/postgis_comments.sql share/contrib/ || _die "Failed to copy PostGIS share files" 
  
    mkdir -p doc/postgis

    cp $PG_PGHOME_OSX/doc/postgresql/postgis/postgis.html doc/postgis || _die "Failed to copy documentation"
    cp $PG_PGHOME_OSX/doc/postgresql/postgis/README.postgis doc/postgis || _die "Failed to copy documentation"

    mkdir -p man/man1
    cp $PG_PGHOME_OSX/share/man/man1/pgsql2shp.1 man/man1/ || _die "Failed to copy the man pages"
    cp $PG_PGHOME_OSX/share/man/man1/shp2pgsql.1 man/man1/ || _die "Failed to copy the man pages"

    cd $PG_PATH_OSX/PostGIS/source/postgis.osx
    cp loader/README.shp2pgsql $PG_STAGING/PostGIS/doc/postgis || _die "Failed to copy README.shp2pgsql "
    cp loader/README.pgsql2shp $PG_STAGING/PostGIS/doc/postgis || _die "Failed to copy README.pgsql2shp "

    mkdir -p $PG_STAGING/PostGIS/doc/postgis/jdbc/

    echo "Copying jdbc docs"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc
    if [ -e postgis-jdbc-javadoc.zip ];
    then
        cp postgis-jdbc-javadoc.zip $PG_STAGING/PostGIS/doc/postgis/jdbc || _die "Failed to copy jdbc docs "
        cd $PG_STAGING/PostGIS/doc/postgis/jdbc
        extract_file postgis-jdbc-javadoc || exit 1
        rm postgis-jdbc-javadoc.zip  || echo "Failed to remove jdbc docs zip file"
    else
        echo "Couldn't find the jdbc docs zip file"
    fi

    cd $WD/PostGIS

    mkdir -p staging/osx/PostGIS/utils
    echo "Copying postgis-utils"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/utils
    cp *.pl $PG_STAGING/PostGIS/utils || _die "Failed to copy the utilities "
    
    cd $WD/PostGIS

    mkdir -p staging/osx/PostGIS/java/jdbc
 
    echo "Copying postgis-jdbc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java
    cp jdbc/postgis*.jar $PG_STAGING/PostGIS/java/jdbc/ || _die "Failed to copy postgis jars into postgis-jdbc directory "
    cp -R ejb2 $PG_STAGING/PostGIS/java/ || _die "Failed to copy ejb2 into postgis-jdbc directory "
    cp -R ejb3 $PG_STAGING/PostGIS/java/ || _die "Failed to copy ejb3 into postgis-jdbc directory "
    cp -R pljava $PG_STAGING/PostGIS/java/ || _die "Failed to copy pljava into postgis-jdbc directory "

    # Copy proj and geos from staging for re-writing its dylib reference"
    cp -R $PG_CACHING/proj-$PG_TARBALL_PROJ.osx $PG_STAGING/proj || _die "Failed to copy the cached proj"
    cp -R $PG_CACHING/geos-$PG_TARBALL_GEOS.osx $PG_STAGING/geos || _die "Failed to copy the cached geos"
    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _change_so_refs $WD/PostGIS/staging/osx/geos lib @loader_path/..
    _change_so_refs $WD/PostGIS/staging/osx/proj lib @loader_path/..

    cd $WD/PostGIS
    echo "Copying Dependent libraries"
    cp staging/osx/geos/lib/*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"
    cp staging/osx/proj/lib/*dylib staging/osx/PostGIS/lib || _die "Failed to copy dependent libraries"

    rm -rf $PG_STAGING/proj || _die "Failed to remove the proj directory from staging directory"
    rm -rf $PG_STAGING/geos || _die "Failed to remove the geos directory from staging directory"

    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS bin @loader_path/..
    _rewrite_so_refs $WD/PostGIS/staging/osx/PostGIS lib @loader_path/..
    _change_so_refs $WD/PostGIS/staging/osx/PostGIS bin @loader_path/..
    _change_so_refs $WD/PostGIS/staging/osx/PostGIS lib @loader_path/..

    cd $WD
 
}
    


################################################################################
# PostGIS Post-Process
################################################################################

_postprocess_PostGIS_osx() {

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx    

    mkdir -p $PG_STAGING/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createshortcuts.sh $PG_STAGING/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createshortcuts.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createtemplatedb.sh $PG_STAGING/installer/PostGIS/createtemplatedb.sh || _die "Failed to copy the createtemplatedb script (scripts/osx/createtemplatedb.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createtemplatedb.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createpostgisdb.sh $PG_STAGING/installer/PostGIS/createpostgisdb.sh || _die "Failed to copy the createpostgisdb script (scripts/osx/createpostgisdb.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createpostgisdb.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/check-connection.sh $PG_STAGING/installer/PostGIS/check-connection.sh || _die "Failed to copy the check-connection script (scripts/osx/check-connection.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/check-connection.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/check-pgversion.sh $PG_STAGING/installer/PostGIS/check-pgversion.sh || _die "Failed to copy the check-pgversion script (scripts/osx/check-pgversion.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/check-pgversion.sh

    cp $PG_PATH_OSX/PostGIS/scripts/osx/check-db.sh $PG_STAGING/installer/PostGIS/check-db.sh || _die "Failed to copy the check-db script (scripts/osx/check-db.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/check-db.sh

    mkdir -p $PG_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/pg-launchJdbcDocs.applescript.in $PG_STAGING/scripts/pg-launchJdbcDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchJdbcDocs.applescript.in)"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/pg-launchPostGISDocs.applescript.in $PG_STAGING/scripts/pg-launchPostGISDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchPostGISDocs.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PG_PATH_OSX/PostGIS/resources/pg-launchPostGISDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPostGISDocs.icns)"
    cp $PG_PATH_OSX/PostGIS/resources/pg-launchPostGISJDBCDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchJdbcDocs.icns)"

    cd $PG_PATH_OSX/PostGIS/
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
    zip -r postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app/ || _die "Failed to remove the unpacked installer bundle"
    
    cd $WD
}


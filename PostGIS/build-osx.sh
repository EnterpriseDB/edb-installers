
    
################################################################################
# PostGIS Build Preparation
################################################################################

_prep_PostGIS_osx() {
      
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
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for i386"
    mv source/headers/config.h source/headers/config_i386.h

    echo "Configuring the Geos source tree for PPC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for PPC"
    mv source/headers/config.h source/headers/config_ppc.h

    echo "Configuring the Geos source tree for x86_64"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for PPC"
    mv source/headers/config.h source/headers/config_x86_64.h

    echo "Configuring the Geos source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 -arch x86_64" CXXFLAGS="$PG_ARCH_OSX_CXXFLAGS -arch i386 -arch ppc -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx --disable-dependency-tracking || _die "Failed to configure Geos for Universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > source/headers/config.h
    echo "  #include \"config_ppc.h\"" >> source/headers/config.h
    echo "#else" >> source/headers/config.h
    echo "  #ifdef __LP64__" >> source/headers/config.h
    echo "    #include \"config_x86_64.h\"" >> source/headers/config.h
    echo "  #else" >> source/headers/config.h
    echo "    #include \"config_i386.h\"" >> source/headers/config.h
    echo "  #endif" >> source/headers/config.h
    echo "#endif" >> source/headers/config.h

    echo "Building Geos"
    MACOSX_DEPLOYMENT_TARGET=10.5 make LDFLAGS="-arch i386 -arch ppc -arch x86_64" -j 2 || _die "Failed to build Geos"
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
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for i386"
    mv src/proj_config.h src/proj_config_i386.h

    echo "Configuring the Proj source tree for PPC"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for PPC"
    mv src/proj_config.h src/proj_config_ppc.h

    echo "Configuring the Proj source tree for x86_64"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for PPC"
    mv src/proj_config.h src/proj_config_x86_64.h

    echo "Configuring the Proj source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --prefix=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --disable-dependency-tracking || _die "Failed to configure Proj for Universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > src/proj_config.h
    echo "  #include \"proj_config_ppc.h\"" >> src/proj_config.h
    echo "#else" >> src/proj_config.h
    echo "  #ifdef __LP64__" >> src/proj_config.h
    echo "    #include \"proj_config_x86_64.h\"" >> src/proj_config.h
    echo "  #else" >> src/proj_config.h
    echo "    #include \"proj_config_i386.h\"" >> src/proj_config.h
    echo "  #endif" >> src/proj_config.h
    echo "#endif" >> src/proj_config.h

    echo "Building Proj"
    MACOSX_DEPLOYMENT_TARGET=10.5 make -j 2 || _die "Failed to build Proj"
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
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for i386"
    mv postgis_config.h postgis_config_i386.h

    echo "Configuring the PostGIS source tree for PPC"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for PPC"
    mv postgis_config.h postgis_config_ppc.h

    echo "Configuring the PostGIS source tree for x86_64"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for PPC"
    mv postgis_config.h postgis_config_x86_64.h

    echo "Configuring the PostGIS source tree for Universal"
    PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/bin:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin:$PATH; LD_LIBRARY_PATH=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx/lib:$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/lib:$LD_LIBRARY_PATH; CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386 -arch ppc -arch x86_64" MACOSX_DEPLOYMENT_TARGET=10.5 ./configure --with-pgconfig=$PG_PGHOME_OSX/bin/pg_config --with-geosconfig=$PG_CACHING/geos-$PG_TARBALL_GEOS.osx/bin/geos-config --with-projdir=$PG_CACHING/proj-$PG_TARBALL_PROJ.osx  --with-xsldir=$PG_DOCBOOK_OSX  || _die "Failed to configure PostGIS for universal"

    # Create a replacement config.h that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > postgis_config.h
    echo "  #include \"postgis_config_ppc.h\"" >> postgis_config.h
    echo "#else" >> postgis_config.h
    echo "  #ifdef __LP64__" >> postgis_config.h
    echo "    #include \"postgis_config_x86_64.h\"" >> postgis_config.h
    echo "  #else" >> postgis_config.h
    echo "    #include \"postgis_config_i386.h\"" >> postgis_config.h
    echo "  #endif" >> postgis_config.h
    echo "#endif" >> postgis_config.h

    echo "Building PostGIS"
    MACOSX_DEPLOYMENT_TARGET=10.5 make || _die "Failed to build PostGIS"
    make comments || _die "Failed to build comments"
    make install DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$WD/PostGIS/staging/osx/PostGIS/doc PGSQL_MANDIR=$WD/PostGIS/staging/osx/PostGIS/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS"
    make comments-install DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$WD/PostGIS/staging/osx/PostGIS/doc PGSQL_MANDIR=$WD/PostGIS/staging/osx/PostGIS/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS"

    echo "Building postgis-jdbc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/java/jdbc 
    export CLASSPATH=$PG_PATH_OSX/PostGIS/source/postgresql-$PG_JAR_POSTGRESQL.jar:$CLASSPATH 
    $PG_ANT_HOME_OSX/bin/ant || _die "Failed to build postgis-jdbc"
   
    echo "Building postgis-doc"
    cd $PG_PATH_OSX/PostGIS/source/postgis.osx/doc; 
    make html || _die "Failed to build postgis-doc"
    make install DESTDIR=$WD/PostGIS/staging/osx/PostGIS bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=/doc PGSQL_MANDIR=/man PGSQL_SHAREDIR=$WD/PostGIS/staging/osx/PostGIS/share/postgresql || _die "Failed to install PostGIS-doc"
    
    cd $WD/PostGIS

    cd staging/osx/PostGIS

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

    cd $WD
}


################################################################################
# PostGIS Build
################################################################################

_build_PostGIS_osx() {

    echo "**************************"
    echo "*  Build: PostGIS (OSX)  *"
    echo "**************************"

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
    install_name_tool -change "libxml2.2.dylib" "@loader_path/../lib/libxml2.2.dylib" $WD/PostGIS/staging/osx/PostGIS/lib/postgis-*.so

    chmod +r $WD/PostGIS/staging/osx/PostGIS/lib/*
    chmod +rx $WD/PostGIS/staging/osx/PostGIS/bin/*
    

    cd $WD
 
}
    

################################################################################
# PostGIS Post-Process
################################################################################

_postprocess_PostGIS_osx() {

    echo "*********************************"
    echo "*  Post Process: PostGIS (OSX)  *"
    echo "*********************************"

    PG_STAGING=$PG_PATH_OSX/PostGIS/staging/osx    

    pushd $WD/PostGIS/staging/osx
    generate_3rd_party_license "postgis"
    popd

    mkdir -p $PG_STAGING/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp $PG_PATH_OSX/PostGIS/scripts/osx/createshortcuts.sh $PG_STAGING/installer/PostGIS/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x $PG_STAGING/installer/PostGIS/createshortcuts.sh

    mkdir -p $PG_STAGING/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/pg-launchJdbcDocs.applescript.in $PG_STAGING/scripts/pg-launchJdbcDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchJdbcDocs.applescript.in)"
    cp -R $PG_PATH_OSX/PostGIS/scripts/osx/pg-launchPostGISDocs.applescript.in $PG_STAGING/scripts/pg-launchPostGISDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchPostGISDocs.applescript.in)"

    # Copy in the menu pick images 
    mkdir -p $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp $PG_PATH_OSX/PostGIS/resources/pg-launchPostGISDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchPostGISDocs.icns)"
    cp $PG_PATH_OSX/PostGIS/resources/pg-launchPostGISJDBCDocs.icns $PG_PATH_OSX/PostGIS/staging/osx/scripts/images || _die "Failed to copy the menu pick image (resources/pg-launchJdbcDocs.icns)"

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

    cd $WD/output

    # Copy the versions file to signing server
    scp ../versions.sh $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN

    # Scp the app bundle to the signing machine for signing
    tar -jcvf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app.tar.bz2 postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app || _die "Failed to create the archive."
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf postgis*" || _die "Failed to clean the $PG_PATH_OSX_SIGN/output directory on sign server."
    scp postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app.tar.bz2  $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/ || _die "Failed to copy the archive to sign server."
    rm -fr postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app* || _die "Failed to clean the output directory."

    # Sign the app
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; source $PG_PATH_OSX_SIGN/versions.sh; tar -jxvf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; $PG_PATH_OSX_SIGNTOOL --keychain ~/Library/Keychains/login.keychain --keychain-password $KEYCHAIN_PASSWD --identity 'Developer ID Application' --identifier 'com.edb.postgresql' postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app;" || _die "Failed to sign the code"
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; rm -rf postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app; mv postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx-signed.app  postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app;" || _die "could not rename the signed app"

    # Archive the .app and copy back to controller
    ssh $PG_SSH_OSX_SIGN "cd $PG_PATH_OSX_SIGN/output; zip -r postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.app" || _die "Failed to zip the installer bundle"
    scp $PG_SSH_OSX_SIGN:$PG_PATH_OSX_SIGN/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."
    
    cd $WD
}


#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS_windows() {

    echo "BEGIN PREP PostGIS Windows"
      
    # Enter the source directory and cleanup if required
    cd $WD/PostGIS/source


    if [ ! -e postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows ]; 
    then 
         echo "Creating postgresql_mingw source directory ($WD/PostGIS/source/postgresql_mingw.windows)"
         mkdir -p postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't create the postgresql_mingw.windows directory"
         chmod ugo+w postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't set the permissions on the source directory"
         cp -R postgresql-$PG_TARBALL_POSTGRESQL/* postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Failed to copy the source code (source/postgresql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/)"
         if [ ! -e postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip ];
         then
                zip -r postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows/ || _die "Couldn't create archieve of the postgis sources (postgis.zip)"
         fi
    fi   

    if [ -e postgis.windows ];
    then
      echo "Removing existing postgis.windows source directory"
      rm -rf postgis.windows  || _die "Couldn't remove the existing postgis.windows source directory (source/postgis.windows)"
    fi

    echo "Creating postgis source directory ($WD/PostGIS/source/postgis.windows)"
    mkdir -p postgis.windows || _die "Couldn't create the postgis.windows directory"
    chmod ugo+w postgis.windows || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the postgis source tree
    cp -R postgis-$PG_VERSION_POSTGIS/* postgis.windows || _die "Failed to copy the source code (source/postgis-$PG_VERSION_POSTGIS)"
    cd postgis.windows
    patch -p1 < ../../../tarballs/postgis_mingw_1_5_2.patch || _die "Failed to apply the patch (postgis_mingw_1_5_2.patch)"
    cd ..
    cp -R postgresql-$PG_JAR_POSTGRESQL.jar postgis.windows || _die "Failed to copy the postgresql jar file "
 
    echo "Archieving postgis sources"
    zip -r postgis.zip postgis.windows/ || _die "Couldn't create archieve of the postgis sources (postgis.zip)"
    chmod -R ugo+w postgis.windows || _die "Couldn't set the permissions on the source directory"

    if [ ! -e geos-$PG_TARBALL_GEOS.windows ];
    then
      echo "Creating geos source directory ($WD/PostGIS/source/geos-$PG_TARBALL_GEOS.windows)"
      mkdir -p geos-$PG_TARBALL_GEOS.windows || _die "Couldn't create the geos-$PG_TARBALL_GEOS.windows directory"
      chmod ugo+w geos-$PG_TARBALL_GEOS.windows || _die "Couldn't set the permissions on the source directory"
      # Grab a copy of the geos source tree
      cp -R geos-$PG_TARBALL_GEOS/* geos-$PG_TARBALL_GEOS.windows || _die "Failed to copy the source code (source/geos-$PG_TARBALL_GEOS)"
      chmod -R ugo+w geos-$PG_TARBALL_GEOS.windows || _die "Couldn't set the permissions on the source directory"
      echo "Archieving geos sources"
      zip -r geos-$PG_TARBALL_GEOS.zip geos-$PG_TARBALL_GEOS.windows/ || _die "Couldn't create archieve of the geos sources (geos-$PG_TARBALL_GEOS.zip)"
    fi

    if [ ! -e proj-$PG_TARBALL_PROJ.windows ];
    then
      echo "Creating proj source directory ($WD/PostGIS/source/proj-$PG_TARBALL_PROJ.windows)"
      mkdir -p proj-$PG_TARBALL_PROJ.windows || _die "Couldn't create the proj-$PG_TARBALL_PROJ.windows directory"
      chmod ugo+w proj-$PG_TARBALL_PROJ.windows || _die "Couldn't set the permissions on the source directory"
      # Grab a copy of the proj source tree
      cp -R proj-$PG_TARBALL_PROJ/* proj-$PG_TARBALL_PROJ.windows || _die "Failed to copy the source code (source/proj-$PG_TARBALL_PROJ)"
      chmod -R ugo+w proj-$PG_TARBALL_PROJ.windows || _die "Couldn't set the permissions on the source directory"
      cd proj-$PG_TARBALL_PROJ.windows
      patch -p0 < ../../../tarballs/proj_4_7_0_mingw.patch || _die "Failed to apply the patch (proj_4_7_0_mingw.patch)"
      cd ..
      echo "Archieving proj sources"
      zip -r proj-$PG_TARBALL_PROJ.zip proj-$PG_TARBALL_PROJ.windows/ || _die "Couldn't create archieve of the proj sources (proj.zip)"
    fi

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/PostGIS/staging/windows)"
    mkdir -p $WD/PostGIS/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/windows || _die "Couldn't set the permissions on the staging directory"

    # Remove any existing staging directory that might exist, and create a clean one
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST proj-$PG_TARBALL_PROJ.zip del /S /Q proj-$PG_TARBALL_PROJ.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\proj.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST proj-$PG_TARBALL_PROJ.windows rd /S /Q proj-$PG_TARBALL_PROJ.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\proj.zip on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos-$PG_TARBALL_GEOS.zip del /S /Q geos-$PG_TARBALL_GEOS.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos-$PG_TARBALL_GEOS.windows rd /S /Q geos-$PG_TARBALL_GEOS.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.zip on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.zip del /S /Q postgis.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.windows rd /S /Q postgis.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.staging.build rd /S /Q postgis.staging.build" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.staging.build directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgis.bat del /S /Q build-postgis.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgis.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis-staging.zip del /S /Q postgis-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis-staging.zip on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip del /S /Q postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgresql_mingw.bat del /S /Q build-postgresql_mingw.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgresql_mingw.bat on Windows VM"

    # Copy sources on windows VM
    echo "Copying postgresql sources to Windows VM"
    scp postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgresql archieve to windows VM ( postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows unzip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't extract postgresql archieve on windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"

    # Copy sources on windows VM
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos.staging rd /S /Q geos.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.staging directory on Windows VM"
    echo "Copying proj sources to Windows VM"
    scp proj-$PG_TARBALL_PROJ.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the proj archieve to windows VM (proj-$PG_TARBALL_PROJ.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST proj-$PG_TARBALL_PROJ.windows unzip proj-$PG_TARBALL_PROJ.zip" || _die "Couldn't extract proj archieve on windows VM (proj-$PG_TARBALL_PROJ.zip)"

    echo "Copying geos sources to Windows VM"
    scp geos-$PG_TARBALL_GEOS.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the geos archieve to windows VM (geos-$PG_TARBALL_GEOS.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST geos-$PG_TARBALL_GEOS.windows unzip geos-$PG_TARBALL_GEOS.zip" || _die "Couldn't extract geos archieve on windows VM (geos-$PG_TARBALL_GEOS.zip)"

    echo "Copying postgis sources to Windows VM"
    scp postgis.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgis archieve to windows VM (postgis.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip postgis.zip" || _die "Couldn't extract postgis archieve on windows VM (postgis.zip)"
 
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`

    #Clear postgis file in the pgsql folder
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/bin; cmd /c del /S /Q pgsql2shp.exe shp2pgsql.exe" || _die "Failed to clear postgis bin files"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/lib; cmd /c del /S /Q postgis-$POSTGIS_MAJOR_VERSION.dll" || _die "Failed to clear postgis lib files"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/share/contrib; cmd /c del /S /Q spatial_ref_sys.sql postgis.sql postgis_upgrade*.sql uninstall_postgis.sql" || _die "Failed to clear postgis lib files"

    echo "END PREP PostGIS Windows"         
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_windows() {

    echo "BEGIN BUILD PostGIS Windows"

    # build postgis    
    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGHOME_MINGW_WINDOWS=$PG_STAGING/pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION
    PG_PATH_MINGW_WINDOWS=`echo $PG_MINGW_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGBUILD_MINGW_WINDOWS=`echo $PG_PGBUILD_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`
    PG_JAVA_HOME_MINGW_WINDOWS=`echo $PG_JAVA_HOME_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g' -e 's:\\ :\\\\ :g'`
    PG_ANT_HOME_MINGW_WINDOWS=`echo $PG_ANT_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g' -e 's:\\ :\\\\ :g'`
    POSTGIS_MAJOR_VERSION=`echo $PG_VERSION_POSTGIS | cut -f1,2 -d "."`
    cat <<EOT > "build-postgresql_mingw.bat"

@ECHO OFF

@SET PATH=%PATH%;$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;$PG_MINGW_WINDOWS\bison\bin;$PG_MINGW_WINDOWS\flex\bin


@ECHO cd $PG_PATH_WINDOWS\\\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows; ./configure --prefix=$PG_PGHOME_MINGW_WINDOWS --with-includes=$PG_PGBUILD_MINGW_WINDOWS/OpenSSL/include:$PG_PGBUILD_MINGW_WINDOWS/zlib/include --with-libs=$PG_PGBUILD_MINGW_WINDOWS/krb5/lib/i386:$PG_PGBUILD_MINGW_WINDOWS/OpenSSL/lib:$PG_PGBUILD_MINGW_WINDOWS/zlib/lib --without-zlib; make; make install | $PG_MSYS_WINDOWS\bin\bash --login -i


EOT

    scp build-postgresql_mingw.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION build-postgresql_mingw.bat" 
     

    cat <<EOT > "build-postgis.bat"

IF EXIST "$PG_PATH_WINDOWS\\proj-$PG_TARBALL_PROJ.staging" GOTO skip-proj
@SET PATH=%PATH%;$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;$PG_PGBUILD_WINDOWS\flex\bin;$PG_PGBUILD_WINDOWS\bison\bin
REM Configuring the proj source tree
@echo cd $PG_PATH_WINDOWS/proj-$PG_TARBALL_PROJ.windows; ./configure --prefix=$PG_STAGING/proj-$PG_TARBALL_PROJ.staging; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Creating libproj.dll
@echo cd $PG_PATH_WINDOWS/proj-$PG_TARBALL_PROJ.staging/lib; gcc -shared -o libproj.dll -Wl,--out-implib=libproj.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive libproj.a -Wl,--no-whole-archive $PG_PATH_MINGW_WINDOWS/lib/libmingw32.a | $PG_MSYS_WINDOWS\bin\sh --login -i

:skip-proj


IF EXIST $PG_PATH_WINDOWS\\geos-$PG_TARBALL_GEOS.staging GOTO skip-geos
@SET PATH=%PATH%;$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;$PG_PGBUILD_WINDOWS\flex\bin;$PG_PGBUILD_WINDOWS\bison\bin
REM Configuring the geos source tree
@echo cd $PG_PATH_WINDOWS/geos-$PG_TARBALL_GEOS.windows; ./configure --prefix=$PG_STAGING/geos-$PG_TARBALL_GEOS.staging; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i
:skip-geos

@SET PATH=%PATH%;$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;$PG_PGBUILD_WINDOWS\flex\bin;$PG_PGBUILD_WINDOWS\bison\bin
REM Configuring the postgis source tree
@echo cd $PG_PATH_WINDOWS/postgis.windows/; export PATH=$PG_STAGING/proj-$PG_TARBALL_PROJ.staging/bin:$PG_STAGING/geos-$PG_TARBALL_GEOS.staging:\$PATH; LD_LIBRARY_PATH=$PG_STAGING/proj-$PG_TARBALL_PROJ.staging/lib:$PG_STAGING/geos-$PG_TARBALL_GEOS.staging:\$LD_LIBRARY_PATH; ./configure --with-pgconfig=$PG_PGHOME_MINGW_WINDOWS/bin/pg_config  --with-projdir=$PG_STAGING/proj-$PG_TARBALL_PROJ.staging --with-geosconfig=$PG_STAGING/geos-$PG_TARBALL_GEOS.staging/bin/geos-config --with-xml2config=$PG_PGBUILD_MINGW_WINDOWS/libxml2_mingw/bin/xml2-config --with-libiconv=$PG_PGBUILD_MINGW_WINDOWS/iconv; make | $PG_MSYS_WINDOWS\bin\sh --login -i

@echo  cd $PG_PATH_WINDOWS/postgis.windows/; make install DESTDIR=$PG_STAGING/postgis.staging.build bindir=/bin pkglibdir=/lib datadir=/share PGSQL_DOCDIR=$PG_STAGING/postgis.staging.build/doc/postgresql PGSQL_MANDIR=$PG_STAGING/postgis.staging.build/man PGSQL_SHAREDIR=$PG_STAGING/postgis.staging.build/share/postgresql | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Building postgis-jdbc
@echo cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; export CLASSPATH=$PG_STAGING/postgis.windows/postgresql-$PG_JAR_POSTGRESQL.jar; export JAVA_HOME=$PG_JAVA_HOME_MINGW_WINDOWS; $PG_ANT_HOME_MINGW_WINDOWS/bin/ant | $PG_MSYS_WINDOWS\bin\sh --login -i
   
EOT

    scp build-postgis.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-postgis.bat"

    echo "Copying Readme files"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build; mkdir -p doc/postgis" || _die "Failed to create doc directory"   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build; mkdir -p man/man1" || _die "Failed to create man pages directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp README.postgis $PG_PATH_WINDOWS/postgis.staging.build/doc/postgis/" || _die "Failed to copy README.postgis "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp loader/README.shp2pgsql $PG_PATH_WINDOWS/postgis.staging.build/doc/postgis/" || _die "Failed to copy README.shp2pgsql "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp loader/README.pgsql2shp $PG_PATH_WINDOWS/postgis.staging.build/doc/postgis/" || _die "Failed to copy README.pgsql2shp "

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build; mkdir -p doc/postgis/jdbc" || _die "Failed to create doc directory"

    echo "Copying jdbc docs"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; cp postgis-jdbc-javadoc.zip $PG_PATH_WINDOWS/postgis.staging.build/doc/postgis/jdbc/" || _die "Failed to copy jdbc docs "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build/doc/postgis/jdbc; unzip postgis-jdbc-javadoc.zip; rm -f postgis-jdbc-javadoc.zip "

    echo "Copying postgis-utils"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build; mkdir -p utils" || _die "Failed to create doc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp utils/*.pl $PG_PATH_WINDOWS/postgis.staging.build/utils/" || _die "Failed to copy postgis-utils "

    mkdir -p $WD/PostGIS/staging/osx/PostGIS/jdbc
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build; mkdir -p java/jdbc" || _die "Failed to create jdbc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; cp postgis*.jar $PG_PATH_WINDOWS/postgis.staging.build/java/jdbc/" || _die "Failed to copy postgis-jdbc "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java; cp -R ejb2 $PG_PATH_WINDOWS/postgis.staging.build/java/" || _die "Failed to copy ejb2 "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java; cp -R ejb3 $PG_PATH_WINDOWS/postgis.staging.build/java/" || _die "Failed to copy ejb3 "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java; cp -R pljava $PG_PATH_WINDOWS/postgis.staging.build/java/" || _die "Failed to copy pljava "

   echo "Copying required dependent libraries from proj and geos packages"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging.build/lib; cp *.dll $PG_PATH_WINDOWS/postgis.staging.build/bin" || _die "Failed to copy dependent dll"
   ssh $PG_SSH_WINDOWS "rm -rf $PG_PATH_WINDOWS/postgis.staging.build/lib" || _die "Failed to delete the lib directory"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/geos-$PG_TARBALL_GEOS.staging/bin; cp *.dll $PG_PATH_WINDOWS/postgis.staging.build/bin" || _die "Failed to copy dependent dll"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/proj-$PG_TARBALL_PROJ.staging/lib; cp *.dll $PG_PATH_WINDOWS/postgis.staging.build/bin" || _die "Failed to copy dependent dll"
   ssh $PG_SSH_WINDOWS "cd $PG_PGBUILD_WINDOWS/libxml2_mingw/bin; cp *.dll $PG_PATH_WINDOWS/postgis.staging.build/bin" || _die "Failed to copy dependent dll"

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS/postgis.staging)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.staging rd /S /Q postgis.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\postgis.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c xcopy /E /Q /Y postgis.staging.build\\\\* postgis.staging\\\\" || _die "Couldn't copy the existing staging directory"
    
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_VERSION_POSTGIS=$PG_VERSION_POSTGIS > $PG_PATH_WINDOWS\\\\postgis.staging/versions-windows.sh" || _die "Failed to write spatial version number into versions-windows.sh"
    ssh $PG_SSH_WINDOWS "cmd /c echo PG_BUILDNUM_POSTGIS=$PG_BUILDNUM_POSTGIS >> $PG_PATH_WINDOWS\\\\postgis.staging/versions-windows.sh" || _die "Failed to write spatial build number into versions-windows.sh"

    echo "END BUILD PostGIS Windows"
}
    


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_windows() {

    echo "BEGIN POST PostGIS Windows"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/PostGIS/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/PostGIS/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/PostGIS/staging/windows)"
    mkdir -p $WD/PostGIS/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/PostGIS/staging/windows || _die "Couldn't set the permissions on the staging directory"
    mkdir -p $WD/PostGIS/staging/osx/PostGIS/jdbc
    mkdir -p $WD/PostGIS/staging/windows/PostGIS/

   # Zip up the installed code, copy it back here, and unpack.
    echo "Copying postgis built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis-staging.zip del /S /Q postgis-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis-staging.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\postgis.staging; cmd /c zip -r ..\\\\postgis-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis-staging.zip $WD/PostGIS/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis-staging.zip)"
    unzip $WD/PostGIS/staging/windows/postgis-staging.zip -d $WD/PostGIS/staging/windows/PostGIS || _die "Failed to unpack the built source tree ($WD/staging/windows/postgis-staging.zip)"
    rm $WD/PostGIS/staging/windows/postgis-staging.zip

    dos2unix $WD/PostGIS/staging/windows/versions-windows.sh || _die "Failed to convert format of versions-windows.sh from dos to unix"
    source $WD/PostGIS/staging/windows/versions-windows.sh
    PG_BUILD_POSTGIS=$(expr $PG_BUILD_POSTGIS + $SKIPBUILD)

    cd $WD/PostGIS/staging/windows/PostGIS
    mkdir -p man/man1
    cp $WD/PostGIS/staging/osx/PostGIS/man/man1/pgsql2shp.1 man/man1/ || _die "Failed to copy the man pages"
    cp $WD/PostGIS/staging/osx/PostGIS/man/man1/shp2pgsql.1 man/man1/ || _die "Failed to copy the man pages"

    #Copy postgis.html from osx build
    cp $WD/PostGIS/staging/osx/PostGIS/doc/postgis/postgis.html $WD/PostGIS/staging/windows/PostGIS/doc/postgis/ || _die "Failed to copy the postgis.html file"

    cd $WD/PostGIS

    pushd staging/windows
    generate_3rd_party_license "postgis"
    popd

    mkdir -p staging/windows/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_POSTGIS -gt 0 ];
    then
        BUILD_FAILED=""
    fi

     # Rename the installer
     mv $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-windows.exe $WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}windows.exe

	# Sign the installer
	win32_sign "postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-${BUILD_FAILED}windows.exe"
	
    cd $WD

    echo "END POST PostGIS Windows"
}


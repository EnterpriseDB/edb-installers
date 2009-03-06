#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_PostGIS_windows() {
      
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
    cp -R postgresql-$PG_JAR_POSTGRESQL.jar postgis.windows || _die "Failed to copy the postgresql jar file "
 
    echo "Archieving postgis sources"
    zip -r postgis.zip postgis.windows/ || _die "Couldn't create archieve of the postgis sources (postgis.zip)"
    chmod -R ugo+w postgis.windows || _die "Couldn't set the permissions on the source directory"

    if [ -e geos.windows ];
    then
      echo "Removing existing geos.windows source directory"
      rm -rf geos.windows  || _die "Couldn't remove the existing geos.windows source directory (source/geos.windows)"
    fi
    echo "Creating geos source directory ($WD/PostGIS/source/geos.windows)"
    mkdir -p geos.windows || _die "Couldn't create the geos.windows directory"
    chmod ugo+w geos.windows || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the geos source tree
    cp -R geos-$PG_TARBALL_GEOS/* geos.windows || _die "Failed to copy the source code (source/geos-$PG_TARBALL_GEOS)"
    chmod -R ugo+w geos.windows || _die "Couldn't set the permissions on the source directory"
    echo "Archieving geos sources"
    zip -r geos.zip geos.windows/ || _die "Couldn't create archieve of the geos sources (geos.zip)"

    if [ -e proj.windows ];
    then
      echo "Removing existing proj.windows source directory"
      rm -rf proj.windows  || _die "Couldn't remove the existing proj.windows source directory (source/proj.windows)"
    fi
    echo "Creating proj source directory ($WD/PostGIS/source/proj.windows)"
    mkdir -p proj.windows || _die "Couldn't create the proj.windows directory"
    chmod ugo+w proj.windows || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the proj source tree
    cp -R proj-$PG_TARBALL_PROJ/* proj.windows || _die "Failed to copy the source code (source/proj-$PG_TARBALL_PROJ)"
    chmod -R ugo+w proj.windows || _die "Couldn't set the permissions on the source directory"
    echo "Archieving proj sources"
    zip -r proj.zip proj.windows/ || _die "Couldn't create archieve of the proj sources (proj.zip)"

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
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST proj.zip del /S /Q proj.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\proj.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST proj.windows rd /S /Q proj.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\proj.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST proj.staging rd /S /Q proj.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\proj.staging directory on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos.zip del /S /Q geos.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos.windows rd /S /Q geos.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST geos.staging rd /S /Q geos.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\geos.staging directory on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.zip del /S /Q postgis.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.windows rd /S /Q postgis.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgis.staging rd /S /Q postgis.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgis.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgis.bat del /S /Q build-postgis.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgis.bat on Windows VM"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip del /S /Q postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgresql_mingw.bat del /S /Q build-postgresql_mingw.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgresql_mingw.bat on Windows VM"

    # Copy sources on windows VM
    echo "Copying postgresql sources to Windows VM"
    scp postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgresql archieve to windows VM ( postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows unzip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't extract postgresql archieve on windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"

    # Copy sources on windows VM
    echo "Copying proj sources to Windows VM"
    scp proj.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the proj archieve to windows VM (proj.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip proj.zip" || _die "Couldn't extract proj archieve on windows VM (proj.zip)"

    echo "Copying geos sources to Windows VM"
    scp geos.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the geos archieve to windows VM (geos.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip geos.zip" || _die "Couldn't extract geos archieve on windows VM (geos.zip)"

    echo "Copying postgis sources to Windows VM"
    scp postgis.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgis archieve to windows VM (postgis.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip postgis.zip" || _die "Couldn't extract postgis archieve on windows VM (postgis.zip)"

        
}


################################################################################
# PG Build
################################################################################

_build_PostGIS_windows() {

    # build postgis    
    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGHOME_MINGW_WINDOWS=$PG_STAGING/pgsql
    PG_PATH_MINGW_WINDOWS=`echo $PG_MINGW_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGBUILD_MINGW_WINDOWS=`echo $PG_PGBUILD_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`
    PG_JAVA_HOME_MINGW_WINDOWS=`echo $PG_JAVA_HOME_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g' -e 's:\\ :\\\\ :g'`
    PG_ANT_HOME_MINGW_WINDOWS=`echo $PG_ANT_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g' -e 's:\\ :\\\\ :g'`
    cat <<EOT > "build-postgresql_mingw.bat"

@ECHO OFF

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin

@ECHO cd $PG_PATH_WINDOWS\\\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows; ./configure --prefix=$PG_PGHOME_MINGW_WINDOWS --with-libs=$PG_PGBUILD_MINGW_WINDOWS/krb5/lib/i386:$PG_PGBUILD_MINGW_WINDOWS/openssl/lib; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i


EOT

    scp build-postgresql_mingw.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql build-postgresql_mingw.bat" 
     

    cat <<EOT > "build-postgis.bat"

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin

REM Configuring, building the proj source tree
@echo cd $PG_PATH_WINDOWS/proj.windows; ./configure --prefix=$PG_STAGING/proj.staging; make; make install  | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Creating libproj.dll
@echo cd $PG_PATH_WINDOWS/proj.staging/lib; gcc -shared -o libproj.dll -Wl,--out-implib=libproj.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--whole-archive libproj.a -Wl,--no-whole-archive $PG_PATH_MINGW_WINDOWS/lib/libmingw32.a | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Configuring the geos source tree
@echo cd $PG_PATH_WINDOWS/geos.windows; ./configure --prefix=$PG_STAGING/geos.staging; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Configuring the postgis source tree
@echo cd $PG_PATH_WINDOWS/postgis.windows/; export PATH=$PG_STAGING/proj.staging/bin:$PG_STAGING/geos.staging/bin:\$PATH; LD_LIBRARY_PATH=$PG_STAGING/proj.staging/lib:$PG_STAGING/geos.staging/lib:\$LD_LIBRARY_PATH; ./configure --prefix=$PG_STAGING/postgis.staging --with-pgsql=$PG_PGHOME_MINGW_WINDOWS/bin/pg_config --with-geos=$PG_STAGING/geos.staging/bin/geos-config --with-proj=$PG_STAGING/proj.staging; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i

REM Building postgis-jdbc
@echo cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; export CLASSPATH=$PG_STAGING/postgis.windows/postgresql-$PG_JAR_POSTGRESQL.jar; export JAVA_HOME=$PG_JAVA_HOME_MINGW_WINDOWS; $PG_ANT_HOME_MINGW_WINDOWS/bin/ant | $PG_MSYS_WINDOWS\bin\sh --login -i
   
EOT

   scp build-postgis.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-postgis.bat"

    echo "Copying required dependent libraries from proj and geos packages"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/geos.staging/bin; cp *.dll $PG_PATH_WINDOWS/postgis.staging/bin" || _die "Failed to copy dependent dll"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/proj.staging/lib; cp *.dll $PG_PATH_WINDOWS/postgis.staging/bin" || _die "Failed to copy dependent dll"

    echo "Copying Readme files"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p doc" || _die "Failed to create doc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p man/man1" || _die "Failed to create man pages directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp README.postgis $PG_PATH_WINDOWS/postgis.staging/doc" || _die "Failed to copy README.postgis "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp loader/README.shp2pgsql $PG_PATH_WINDOWS/postgis.staging/doc" || _die "Failed to copy README.shp2pgsql "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp loader/README.pgsql2shp $PG_PATH_WINDOWS/postgis.staging/doc" || _die "Failed to copy README.pgsql2shp "

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p doc/contrib/html/postgis" || _die "Failed to create doc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p doc/postgis/jdbc" || _die "Failed to create doc directory"

    echo "Copying postgis docs"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/doc; cp -R html/* $PG_PATH_WINDOWS/postgis.staging/doc/contrib/html/postgis/" || _die "Failed to copy postgis docs /"

    echo "Copying postgis man pages"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/doc; cp -R man/* $PG_PATH_WINDOWS/postgis.staging/man/man1/" || _die "Failed to copy postgis man pages/"

    echo "Copying jdbc docs"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; cp postgis-jdbc-javadoc.zip $PG_PATH_WINDOWS/postgis.staging/doc/postgis/jdbc/" || _die "Failed to copy jdbc docs "
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging/doc/postgis/jdbc; unzip postgis-jdbc-javadoc.zip; rm -f postgis-jdbc-javadoc.zip "

    echo "Copying postgis-utils"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p share/contrib/postgis/utils" || _die "Failed to create doc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows; cp utils/*.pl $PG_PATH_WINDOWS/postgis.staging/share/contrib/postgis/utils/" || _die "Failed to copy postgis-utils "

    mkdir -p $WD/PostGIS/staging/osx/PostGIS/jdbc
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.staging; mkdir -p jdbc" || _die "Failed to create jdbc directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgis.windows/java/jdbc; cp postgis_$PG_VERSION_POSTGIS.jar $PG_PATH_WINDOWS/postgis.staging/jdbc" || _die "Failed to copy postgis-jdbc "


   # Zip up the installed code, copy it back here, and unpack.
    echo "Copying postgis built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\postgis.staging; cmd /c zip -r ..\\\\postgis-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis-staging.zip $WD/PostGIS/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgis-staging.zip)"
    unzip $WD/PostGIS/staging/windows/postgis-staging.zip -d $WD/PostGIS/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/postgis-staging.zip)"
    rm $WD/PostGIS/staging/windows/postgis-staging.zip

 
}
    


################################################################################
# PG Build
################################################################################

_postprocess_PostGIS_windows() {

    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    #Configure the files in PostGIS
    filelist=`grep -rlI "$PG_STAGING/postgis.staging" "$WD/PostGIS/staging/windows" | grep -v Binary`

    cd  $WD/PostGIS/staging/windows

    for file in $filelist
    do
        _replace "$PG_STAGING/postgis.staging" @@INSTALL_DIR@@ "$file"
        chmod ugo+x "$file"
    done

    #Copy postgis.html from osx build
    cp $WD/PostGIS/staging/osx/PostGIS/doc/postgis/postgis.html $WD/PostGIS/staging/windows/doc/contrib/html/postgis/ || _die "Failed to copy the postgis.html file"

    cd $WD/PostGIS

    mkdir -p staging/windows/installer/PostGIS || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/check-connection.bat staging/windows/installer/PostGIS/check-connection.bat || _die "Failed to copy the check-connection script (scripts/windows/check-connection.bat)"
    cp scripts/windows/check-db.bat staging/windows/installer/PostGIS/check-db.bat || _die "Failed to copy the check-db script (scripts/windows/check-db.bat)"
    cp scripts/windows/createtemplatedb.bat staging/windows/installer/PostGIS/createtemplatedb.bat || _die "Failed to copy the createtemplatedb script (scripts/windows/createtemplatedb.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    
    cd $WD
}


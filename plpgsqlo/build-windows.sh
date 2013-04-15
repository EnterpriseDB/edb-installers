#!/bin/bash


################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_windows() {

    cd $WD/server/source

    PGSOURECEDIR=$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL
    PGPLATFORMDIR=$WD/server/source/postgres.windows
    PLPGSQLOSTAGING=$WD/plpgsqlo/staging/windows
    PGBUILDSSH=$PG_SSH_WINDOWS
    PGREMOTEBUILDPATH=$PG_PATH_WINDOWS
    PGSERVERPATH=postgres.windows

    # Remove any existing plpgsqlo directory that might exist, in server
    if [ -e $PGPLATFORMDIR/src/pl/plpgsqlo ];
    then
      echo "Removing existing plpgsqlo directory"
      rm -rf $PGPLATFORMDIR/src/pl/plpgsqlo || _die "Couldn't remove the existing plpgsqlo directory"
    fi

    # create a copy of the plpgsql tree
    cp -R $PGSOURECEDIR/src/pl/plpgsql $PGPLATFORMDIR/src/pl/plpgsqlo || _die "Failed to create copy of plpgsql tree ($PGSOURECEDIR/src/pl/plpgsql)"
    grep -irl plpgsql $PGPLATFORMDIR/src/pl/plpgsqlo |xargs sed -i .bak 's/\([pP][lL][pP][gG][sS][qQ][lL]\)/\1o/g'
    grep -rl PLPGSQLo_ $PGPLATFORMDIR/src/pl/plpgsqlo |xargs sed -i .bak 's/\(PLPGSQL\)o/\1/g'
    mv $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsql.h $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsqlo.h || _die "Failed to move plpgsql.h to plpgsqlo.h"
    mv $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsql.control $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsqlo.control || _die "Failed to move plpgsql.control to plpgsqlo.control"
    # Copy files from pg-sources into plpgsqlo
    cp $PGSOURECEDIR/src/backend/utils/adt/encode.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy encode.c"
    cp $PGSOURECEDIR/contrib/pgcrypto/md5.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy md5.c"
    cp $PGSOURECEDIR/contrib/pgcrypto/md5.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy md5.h"
    cp $PGSOURECEDIR/contrib/pgcrypto/px.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy px.h"
    # copy wrap.c and wrap.h in plpgsqlo. These 2 files are taken from edb sources.
    cp $WD/plpgsqlo/resources/wrap.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy wrap.c file for plpgsqlo obfuscation"
    cp $WD/plpgsqlo/resources/wrap.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy wrap.h file for plpgsqlo obfuscation"
    # Copy files from pg-sources into plpgsqlo which are required for windows build
    cp $PGSOURECEDIR/src/tools/msvc/Project.pm   $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $PGSOURECEDIR/src/tools/msvc/Mkvcbuild.pm $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $PGSOURECEDIR/src/tools/msvc/pgbison.bat  $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd $PGPLATFORMDIR
    patch -p1 -f -c < $WD/plpgsqlo/resources/plpgsqlo.patch || _die "Failed to apply patch on plpgsqlo tree (plpgsqlo.patch)"

    cd $WD/server/source

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PLPGSQLOSTAGING ];
    then
      echo "Removing existing staging directory"
      rm -rf $PLPGSQLOSTAGING || _die "Couldn't remove the existing staging directory ($PLPGSQLOSTAGING)"
    fi

    echo "Creating staging directory ($PLPGSQLOSTAGING)"
    mkdir -p $PLPGSQLOSTAGING || _die "Couldn't create the staging directory"
    chmod ugo+w $PLPGSQLOSTAGING || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging share directory ($PLPGSQLOSTAGING/share)"
    mkdir -p $PLPGSQLOSTAGING/share || _die "Couldn't create the staging share directory"
    chmod 755 $PLPGSQLOSTAGING/share || _die "Couldn't set the permissions on the staging share directory"
    echo "Copying plpgsqlo.sql to staging share directory"
    cp $WD/plpgsqlo/resources/plpgsqlo.sql $PLPGSQLOSTAGING/share/ || _die "Couldn't copy plpgsqlo.sql to staging share directory"

    echo "Creating staging doc directory ($PLPGSQLOSTAGING/doc)"
    mkdir -p $PLPGSQLOSTAGING/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $PLPGSQLOSTAGING/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying readme.sqlprotect to staging doc directory"
    cp $WD/plpgsqlo/resources/README.plsecure $PLPGSQLOSTAGING/doc/ || _die "Couldn't copy README.plsecure to staging doc directory"

    echo "Archieving plpgsqlo sources"
    zip -r plpgsqlo.zip $PGSERVERPATH/src/pl/plpgsqlo || _die "Couldn't create archieve of the plpgsqlo sources (plpgsqlo.zip)"

    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH; cmd /c if EXIST plpgsqlo.zip del /S /Q plpgsqlo.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\plpgsqlo.zip on Windows VM"
    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH; cmd /c if EXIST plpgsqlo.staging rd /S /Q plpgsqlo.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\plpgsqlo.staging directory on Windows VM"

    # Removing plpgsqlo if it already exists
    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH/$PGSERVERPATH/src/pl; cmd /c if EXIST plpgsqlo del /S /Q plpgsqlo" || _die "Couldn't remove plpgsqlo on windows VM (plpgsqlo)"
    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH/$PGSERVERPATH/release; cmd /c if EXIST plpgsqlo del /S /Q plpgsqlo" || _die "Couldn't remove plpgsqlo on windows VM (plpgsqlo)"
    # Copy sources on windows VM
    echo "Copying plpgsqlo sources to Windows VM"
    scp plpgsqlo.zip $PGBUILDSSH:$PGREMOTEBUILDPATH || _die "Couldn't copy the plpgsqlo archieve to windows VM (plpgsqlo.zip)"
    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH; cmd /c  unzip plpgsqlo.zip" || _die "Couldn't extract postgresql archieve on windows VM (plpgsqlo.zip)"
    scp $PGPLATFORMDIR/src/tools/msvc/Mkvcbuild.pm $PGBUILDSSH:$PGREMOTEBUILDPATH/$PGSERVERPATH/src/tools/msvc || _die "Couldn't copy the Mkvcbuild.pm to windows VM (Mkvcbuild.pm)"
    scp $PGPLATFORMDIR/src/tools/msvc/Project.pm $PGBUILDSSH:$PGREMOTEBUILDPATH/$PGSERVERPATH/src/tools/msvc || _die "Couldn't copy the Project.pm to windows VM (Project.pm)"
    scp $PGPLATFORMDIR/src/tools/msvc/pgbison.bat $PGBUILDSSH:$PGREMOTEBUILDPATH/$PGSERVERPATH/src/tools/msvc || _die "Couldn't copy the pgbison.bat to windows VM (pgbison.bat)"

}

################################################################################
# PG Build
################################################################################

_build_plpgsqlo_windows() {

cat <<EOT > "$WD/server/source/build32-plpgsqlo.bat"

@SET PATH=%PATH%;$PG_PERL_WINDOWS\bin
build.bat RELEASE
EOT
    scp $WD/server/source/build32-plpgsqlo.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgres.windows/src/tools/msvc || _die "Failed to copy the build32.bat"
   
    PGSOURECEDIR=$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL
    PGPLATFORMDIR=$WD/server/source/postgres.windows
    PLPGSQLOSTAGING=$WD/plpgsqlo/staging/windows
    PGBUILDSSH=$PG_SSH_WINDOWS
    PGREMOTEBUILDPATH=$PG_PATH_WINDOWS
    PGSERVERPATH=postgres.windows
    PGPLATFORMDIR=$WD/server/source/postgres.windows

    ssh $PGBUILDSSH "cd $PGREMOTEBUILDPATH/$PGSERVERPATH/src/tools/msvc; ./build32-plpgsqlo.bat" || _die "could not build plpgsqlo on windows vm"

   # We need to copy shared objects to staging directory
   ssh $PGBUILDSSH "mkdir -p $PGREMOTEBUILDPATH/plpgsqlo.staging/lib" || _die "Failed to create the lib directory"
   ssh $PGBUILDSSH "cp $PGREMOTEBUILDPATH/$PGSERVERPATH/release/plpgsqlo/plpgsqlo.dll $PGREMOTEBUILDPATH/plpgsqlo.staging/lib" || _die "Failed to copy plpgsqlo.dll to staging directory"

   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying plpgsqlo build tree to Unix host"
   ssh $PGBUILDSSH "cd $PG_PATH_WINDOWS\\\\plpgsqlo.staging; cmd /c zip -r ..\\\\plpgsqlo-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/plpgsqlo.staging)"
   scp $PGBUILDSSH:$PGREMOTEBUILDPATH/plpgsqlo-staging.zip $PLPGSQLOSTAGING || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/plpgsqlo-staging.zip)"
   unzip $PLPGSQLOSTAGING/plpgsqlo-staging.zip -d $PLPGSQLOSTAGING || _die "Failed to unpack the built source tree ($WD/staging/windows/plpgsqlo-staging.zip)"
   rm $PLPGSQLOSTAGING/plpgsqlo-staging.zip

   cd $PGPLATFORMDIR
   patch -p1 -f -c -R < $WD/plpgsqlo/resources/plpgsqlo.patch

}


################################################################################
# plsecure Post Process
################################################################################

_postprocess_plpgsqlo_windows() {


    cd $WD/plpgsqlo

    if [ -f installer-win.xml ];
    then
	rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml

    _replace @@WIN64MODE@@ "0" installer-win.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ "windows" installer-win.xml || _die "Failed to replace the WINDIR setting in the installer.xml"
    _replace "registration_plus_component" "registration_plus_component_windows" installer-win.xml || _die "Failed to replace the registration_plus component file name"
    _replace "registration_plus_preinstallation" "registration_plus_preinstallation_windows" installer-win.xml || _die "Failed to replace the registration_plus preinstallation file name"
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-windows.exe"

    cd $WD

}

